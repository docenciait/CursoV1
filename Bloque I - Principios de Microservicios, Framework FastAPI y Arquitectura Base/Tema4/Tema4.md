# Tema 4. Manejo de errores y Circuit Breakers en Microservicios

  - [Objetivos](#objetivos)
  - [4.1 Diseño de estrategia global de manejo de errores](#41-diseño-de-estrategia-global-de-manejo-de-errores)
  - [4.2 Implementación de controladores de excepciones personalizados en FastAPI](#42-implementación-de-controladores-de-excepciones-personalizados-en-fastapi)
  - [4.3 Definición de errores de negocio vs errores técnicos](#43-definición-de-errores-de-negocio-vs-errores-técnicos)
  - [4.4 Aplicación del patrón Retry con backoff exponencial](#44-aplicación-del-patrón-retry-con-backoff-exponencial)
  - [4.5 Introducción a patrones Circuit Breaker y Bulkhead](#45-introducción-a-patrones-circuit-breaker-y-bulkhead)
  - [4.6 Implementación de circuit breakers con `pybreaker`](#46-implementación-de-circuit-breakers-con-pybreaker)
  - [4.7 Diseño de endpoints resilientes a fallos de servicios externos](#47-diseño-de-endpoints-resilientes-a-fallos-de-servicios-externos)
  - [4.8 Captura y log de trazas con contexto de peticiones](#48-captura-y-log-de-trazas-con-contexto-de-peticiones)
  - [4.9 Visibilidad de errores mediante dashboards](#49-visibilidad-de-errores-mediante-dashboards)
  - [4.10 Pruebas para simular fallos y degradación controlada](#410-pruebas-para-simular-fallos-y-degradación-controlada)
  - [Referencias Bibliográficas](#referencias-bibliográficas)
---
 
## Objetivos


* **Diseñar un escudo anti-errores** para tus APIs FastAPI, distinguiendo problemas del cliente de fallos internos, ¡y comunicándolos con clase!
* **Implementar Exception Handlers personalizados en FastAPI** que capturen errores específicos y devuelvan respuestas JSON estandarizadas y útiles.
* **Aplicar el patrón Retry con `tenacity`** en tus llamadas a servicios externos desde FastAPI, para superar fallos temporales como un campeón.
* **Desplegar Circuit Breakers con `pybreaker`** para proteger tus endpoints FastAPI de servicios dependientes que fallan en cascada.
* **Construir endpoints FastAPI que no se vienen abajo**, sino que se degradan con elegancia cuando las cosas se ponen feas.
* **Inyectar `trace_id` en tus logs y peticiones FastAPI** para seguir la pista a los problemas como un detective experto, usando logging estructurado.
* **Idear dashboards que te cuenten la verdad** sobre los errores de tus servicios, sin ahogarte en datos.
* **Jugar al "Ingeniero del Caos" (¡en pequeñito!)** simulando fallos en tus tests FastAPI para probar tus defensas.

---



## 4.1. Estrategia Global de Errores: Tu Plan Maestro Anti-Caos

Imagina que eres el arquitecto de un rascacielos. No esperas a que haya un incendio para pensar en salidas de emergencia. ¡Lo mismo con los errores!

**Principios Prácticos para FastAPI:**

1.  **Errores Claros, No Silencios Raros:** Si algo falla, FastAPI debe decirlo alto y claro.
2.  **Contratos de Error:** Tu OpenAPI (`/docs`) debe insinuar (o definir) cómo se ven tus errores.
3.  **Aislar el Fuego:** Un fallo en un endpoint no debe tumbar todo el server FastAPI.
4.  **Todo Queda Registrado (con Contexto):** Cada error importante, un log. ¡Con `trace_id`!

**Paso Práctico 1: Clasifica Tus Errores (La Tabla de Diagnóstico Rápido)**

| Quién Falla   | Qué Pasa                                   | Código HTTP | ¿Reintentar? | Ejemplo FastAPI                                 |
| :------------ | :----------------------------------------- | :---------- | :----------- | :---------------------------------------------- |
| **Cliente** | Datos malformados (Pydantic no valida)     | 422         | ¡NO!         | Falta un campo en el JSON.                      |
|               | Datos no válidos (pero bien formados)      | 400         | ¡NO!         | Pides 1000 items, y el máx es 100.              |
|               | No autenticado                             | 401         | ¡NO!         | Token JWT chungo.                               |
|               | No autorizado                              | 403         | ¡NO!         | Eres user, no admin.                            |
|               | Recurso no existe                          | 404         | ¡NO!         | Buscas `GET /items/999` y 999 no está.          |
| **Servidor** | Regla de negocio rota                      | 409 / 400   | ¡NO!         | "Email ya existe", "Stock insuficiente".        |
|               | ¡Ups! Un bug en *mi* código FastAPI        | 500         | NO (hasta arreglar) | `variable_none.metodo()`                   |
|               | Servicio externo (BBDD, otra API) KO       | 503 / 504   | **¡SÍ!** (con cabeza) | La API de pagos no responde.                 |

**Paso Práctico 2: El Formato JSON de Error Universal (¡Tu Comunicado Oficial!)**

Cualquier error que devuelva FastAPI, que tenga esta pinta:

```json
{
  "trace_id": "un-uuid-super-unico-por-peticion",
  "error_code": "STOCK_INSUFICIENTE", // Un código tuyo, para máquinas
  "message": "No hay suficiente 'SuperPocion'. Pediste: 10, Quedan: 2.", // Para humanos
  "status_code": 409, // El HTTP que es
  "service_name": "mi-servicio-fastapi", // Quién soy yo
  "context": {"item_id": "SuperPocion", "solicitado": 10, "disponible": 2} // Chicha extra
}
```
> Ejemplo; `error_code` que usarías en una API de gestión de tareas (ej: `TAREA_NO_ENCONTRADA`, `FECHA_INVALIDA`).

---

## 4.2. Exception Handlers en FastAPI

FastAPI te deja poner (*Exception Handlers*) que atrapan excepciones específicas y deciden cómo responder

**La Magia: `@app.exception_handler(MiErrorCustom)`**

```python
# main.py (o donde definas tu app FastAPI)
from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import uuid

# --- 1. Tus Errores Personalizados (¡Hereda de Exception!) ---
class RecursoNoEncontradoError(Exception):
    def __init__(self, nombre_recurso: str, id_recurso: any):
        self.nombre_recurso = nombre_recurso
        self.id_recurso = id_recurso
        self.message = f"{nombre_recurso} con ID '{id_recurso}' no encontrado."
        self.error_code = f"{nombre_recurso.upper()}_NOT_FOUND"
        super().__init__(self.message)

class ReglaNegocioError(Exception):
    def __init__(self, message: str, error_code: str, context: dict = None):
        self.message = message
        self.error_code = error_code
        self.context = context or {}
        super().__init__(self.message)

# --- 2. Tu App FastAPI ---
app = FastAPI(title="API Resiliente")

# --- Middleware para Trace ID (simplificado) ---
@app.middleware("http")
async def add_trace_id_middleware(request: Request, call_next):
    trace_id = str(uuid.uuid4())
    request.state.trace_id = trace_id # Guardamos en request.state
    response = await call_next(request)
    response.headers["X-Trace-ID"] = trace_id
    return response

# --- 3. Tus Porteros (Exception Handlers) ---
@app.exception_handler(RecursoNoEncontradoError)
async def handle_recurso_no_encontrado(request: Request, exc: RecursoNoEncontradoError):
    trace_id = getattr(request.state, "trace_id", "N/A")
    return JSONResponse(
        status_code=status.HTTP_404_NOT_FOUND,
        content={
            "trace_id": trace_id, "error_code": exc.error_code,
            "message": exc.message, "status_code": 404, "service_name": app.title,
            "context": {"recurso": exc.nombre_recurso, "id": exc.id_recurso}
        }
    )

@app.exception_handler(ReglaNegocioError)
async def handle_regla_negocio(request: Request, exc: ReglaNegocioError):
    trace_id = getattr(request.state, "trace_id", "N/A")
    # El status code podría ser un atributo de la excepción o decidirse aquí
    status_code_http = status.HTTP_400_BAD_REQUEST # Default, podría ser 409
    if "EMAIL_ALREADY_EXISTS" in exc.error_code or "STOCK_INSUFFICIENTE" in exc.error_code: # Ejemplo de lógica
        status_code_http = status.HTTP_409_CONFLICT

    return JSONResponse(
        status_code=status_code_http,
        content={
            "trace_id": trace_id, "error_code": exc.error_code,
            "message": exc.message, "status_code": status_code_http, "service_name": app.title,
            "context": exc.context
        }
    )

# --- Handler Genérico para 500 (¡El último recurso!) ---
@app.exception_handler(Exception)
async def handle_generic_exception(request: Request, exc: Exception):
    trace_id = getattr(request.state, "trace_id", "N/A")
    # ¡Loggear este con ERROR y stack trace! Aquí solo mostramos la respuesta.
    print(f"ERROR INESPERADO (RID: {trace_id}): {exc}", exc_info=True) # A consola por ahora
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "trace_id": trace_id, "error_code": "INTERNAL_SERVER_ERROR",
            "message": "Ocurrió un error inesperado en el servidor.",
            "status_code": 500, "service_name": app.title
        }
    )

# --- Tus Endpoints (que pueden lanzar estos errores) ---
db_items = {"item1": {"id": "item1", "nombre": "Poción de Salud"}, "item2": {"id": "item2", "nombre": "Espada de Luz"}}
db_users_emails = {"test@example.com"}

class UserCreate(BaseModel):
    email: str
    nombre: str

@app.get("/items/{item_id}")
async def get_item(item_id: str):
    if item_id not in db_items:
        raise RecursoNoEncontradoError(nombre_recurso="Item", id_recurso=item_id)
    return db_items[item_id]

@app.post("/users")
async def create_user(user: UserCreate):
    if user.email in db_users_emails:
        raise ReglaNegocioError(
            message=f"El email '{user.email}' ya está registrado.",
            error_code="EMAIL_ALREADY_EXISTS",
            context={"email_conflictivo": user.email}
        )
    if not "@" in user.email: # Simulación de otra regla de negocio
         raise ReglaNegocioError(message="Formato de email inválido.", error_code="INVALID_EMAIL_FORMAT")

    # Simular un fallo inesperado a veces
    import random
    if random.random() < 0.1: # 10% de las veces
        raise ValueError("¡Algo explotó inesperadamente!") # Esto será capturado por handle_generic_exception

    db_users_emails.add(user.email)
    return {"mensaje": f"Usuario {user.nombre} creado con email {user.email}"}

```

**¡Pruébalo!**
1.  Guarda como `main.py`. Instala `fastapi` y `uvicorn`.
2.  Ejecuta: `uvicorn main:app --reload`
3.  Prueba en tu navegador o Postman:
    * `GET http://localhost:8000/items/item1` (Éxito)
    * `GET http://localhost:8000/items/item_NO_EXISTE` (Debería dar 404 con tu JSON formateado)
    * `POST http://localhost:8000/users` con JSON `{"email": "nuevo@example.com", "nombre": "Tester"}` (Éxito la primera vez)
    * `POST http://localhost:8000/users` con JSON `{"email": "nuevo@example.com", "nombre": "Tester"}` (¡Error 409 con tu JSON!)
    * `POST http://localhost:8000/users` con JSON `{"email": "emailinvalido", "nombre": "Tester Inválido"}` (¡Error 400 con tu JSON!)
    * Llama varias veces a `POST /users` con emails válidos y nuevos hasta que te toque el 10% de `ValueError` (¡Error 500 con tu JSON!).
4.  Observa la cabecera `X-Trace-ID` en las respuestas.

**Desafío Práctico:**
* Crea una nueva excepción `AutenticacionFallidaError` y su handler para que devuelva un 401. Lánzala en un nuevo endpoint `/secure_data` si una cabecera `X-Token` no es "secreto123".

---

## 4.3. Errores de Negocio vs. Técnicos: ¿Culpa del Cliente o Mía?

Es vital saber si el error es porque el cliente pidió algo "imposible" (Negocio) o porque nuestro código/infra "explotó" (Técnico).

* **Errores de Negocio (Normalmente 4xx):**
    * "No puedes reservar un hotel para ayer." (FastAPI devuelve 400/409)
    * "Ese usuario no existe." (FastAPI devuelve 404)
    * FastAPI te ayuda con Pydantic (422 si el JSON no machea el modelo).
    * **Acción:** El cliente debe arreglar su petición. Tú loggeas `INFO` o `WARNING`. **¡No despiertes a nadie!**

* **Errores Técnicos (Normalmente 5xx):**
    * "¡No me puedo conectar a la base de datos!" (FastAPI devuelve 500/503)
    * "Una variable es `None` y esperaba un objeto." (FastAPI devuelve 500)
    * **Acción:** ¡Es tu culpa (o de tu infra)! El cliente no puede hacer nada. Loggea `ERROR` con todo el detalle (stack trace), ¡y que suenen las alarmas!

**¡Pruébalo! (Con el código anterior):**
* `RecursoNoEncontradoError` y `ReglaNegocioError` son **Errores de Negocio**.
* El `ValueError` que simulamos es un **Error Técnico** (un bug imprevisto).
* Observa cómo los handlers devuelven 404/400/409 para los de negocio y 500 para el técnico.

---

## 4.4. Patrón Retry con `tenacity`: 

A veces, llamar a otra API o a la BBDD falla por un instante. Reintenta, pero con cabeza: espera un poco más cada vez (backoff exponencial) y añade un toque de azar (jitter) para no saturar.

La librería `tenacity` es tu amiga: `pip install tenacity`

De acuerdo, entiendo que el ejemplo anterior tenía bastantes detalles. Vamos a simplificarlo significativamente para que los conceptos básicos de Tenacity y el manejo de errores sean más fáciles de seguir. También simplificaremos el desafío.

### Ejemplo Simplificado de Cliente Resistente

Nos centraremos en:
1.  Reintentar solo `TimeoutException`, `NetworkError` y un `HTTPStatusError` específico (503).
2.  Menos intentos y una estrategia de espera más simple por defecto.
3.  Simulación de menos tipos de error.
4.  Manejo de excepciones en el endpoint un poco más directo.

```python
# cliente_externo_simple.py
from fastapi import FastAPI, HTTPException, status
import httpx
import uvicorn
from tenacity import retry, stop_after_attempt, wait_fixed, RetryError, retry_if_exception
import random

# --- 0. Definición de la App FastAPI ---
app = FastAPI(title="Cliente Externo Simple")

# --- 1. Define qué errores quieres reintentar (versión simplificada) ---
def es_error_reintentable_simple(exception: Exception) -> bool:
    """Decide si una excepción merece un reintento (lógica simplificada)."""
    if isinstance(exception, (httpx.TimeoutException, httpx.NetworkError)):
        print(f"DEBUG: Reintentando por Timeout/Network: {type(exception).__name__}")
        return True
    
    if isinstance(exception, httpx.HTTPStatusError):
        # Solo reintentamos errores 503 (Servicio No Disponible)
        if exception.response.status_code == status.HTTP_503_SERVICE_UNAVAILABLE:
            print(f"DEBUG: Reintentando por HTTPStatusError 503: Código {exception.response.status_code}")
            return True
            
    print(f"DEBUG: NO se reintenta: {type(exception).__name__} - {str(exception)}")
    return False

# --- 2. Decora tu función de llamada externa (parámetros simplificados) ---
@retry(
    stop=stop_after_attempt(2),  # Máximo 2 intentos (1 original + 1 reintento)
    wait=wait_fixed(1),          # Espera fija de 1 segundo entre reintentos
    retry=retry_if_exception(es_error_reintentable_simple),
    reraise=True
)
async def llamar_api_externa_simple(url: str, client: httpx.AsyncClient):
    print(f"Intentando llamar a {url}...")
    
    # Simular fallo aleatoriamente (50% de probabilidad)
    if random.random() < 0.6: # Falla el 60% de las veces para ver reintentos
        # Elige un tipo de error para simular (lista simplificada)
        error_type = random.choice(["timeout", "http_503", "http_400"]) 
        print(f"SIMULANDO FALLO: {error_type}")
        
        mock_request = httpx.Request("GET", url)

        if error_type == "timeout":
            raise httpx.TimeoutException("Timeout simulado", request=mock_request)
        elif error_type == "http_503": # Error reintentable
            mock_response = httpx.Response(status.HTTP_503_SERVICE_UNAVAILABLE, request=mock_request, content=b"Servicio no disponible")
            raise httpx.HTTPStatusError("503 Servicio No Disponible simulado", request=mock_request, response=mock_response)
        elif error_type == "http_400": # Error NO reintentable
            mock_response = httpx.Response(status.HTTP_400_BAD_REQUEST, request=mock_request, content=b"Peticion incorrecta")
            raise httpx.HTTPStatusError("400 Bad Request simulado", request=mock_request, response=mock_response)

    print(f"ÉXITO llamando a {url}")
    return {"data_externa": f"Datos de {url} recibidos!"}

# --- 3. Endpoint FastAPI (manejo de errores simplificado) ---
@app.get("/datos-externos-simple")
async def get_datos_simple():
    url_externa_test = "http://servicio-simulado-simple.com/api/data"
    
    async with httpx.AsyncClient() as client:
        try:
            resultado = await llamar_api_externa_simple(url_externa_test, client)
            return resultado
        except RetryError as e: 
            last_exc = e.last_attempt.exception()
            print(f"FALLO DEFINITIVO tras {e.attempt_number} intentos. Última excepción: {type(last_exc).__name__} - {str(last_exc)}")
            
            # Devolvemos un 503 genérico si todos los reintentos fallaron
            # Podrías inspeccionar last_exc para un código más específico si quisieras
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE, 
                detail=f"Servicio externo no disponible tras reintentos. Causa final: {str(last_exc)}"
            )
        except httpx.HTTPStatusError as e_http: 
            # Captura HTTPStatusError que no fueron reintentados (ej. el 400 simulado)
            print(f"Error HTTP no reintentado: {e_http.response.status_code} - {e_http}")
            raise HTTPException(status_code=e_http.response.status_code, detail=str(e_http))
        except Exception as e: 
            # Otros errores inesperados
            print(f"Error inesperado: {type(e).__name__} - {e}")
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Error inesperado en el servidor.")

# --- Para ejecutar este script directamente ---
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
```


### Desafío Práctico Simplificado

Ahora, basado en este código más simple:

**Desafío 1: Observar el Número de Intentos**

1.  Ejecuta el script `cliente_externo_simple.py`.
2.  Llama al endpoint `http://localhost:8000/datos-externos-simple` varias veces hasta que veas que ocurre un error reintentable (como "Timeout simulado" o "503 Servicio No Disponible simulado") y luego falla definitivamente.
3.  **Observa la consola del servidor**: ¿Cuántas veces se imprime "Intentando llamar a..." antes de que aparezca "FALLO DEFINITIVO"? Debería ser 2 veces (el intento original + 1 reintento).
4.  **Modifica** la línea `@retry( stop=stop_after_attempt(2), ...)` para que sea `@retry( stop=stop_after_attempt(4), ...)`.
5.  Vuelve a ejecutar y prueba. Ahora, ¿cuántas veces se intenta antes del fallo definitivo? (Debería ser 4).




---

## 4.5. Circuit Breaker y Bulkhead

* **Circuit Breaker (Interruptor Automático):**
    * Si un servicio externo falla *demasiado*, ¡deja de llamarlo por un rato! Es como un fusible.
    * Estados: **Cerrado** (pasan llamadas), **Abierto** (¡no pasa nada!, fallo rápido), **Semi-Abierto** (deja pasar una llamada de prueba a ver si ya funciona).
    * Lo veremos en acción en 4.6.

* **Bulkhead (Compartimentos Estancos):**
    * No dejes que un servicio lento te consuma *todos* los recursos (hilos, conexiones). Aísla los recursos por cada servicio externo al que llamas.
    * **En FastAPI/asyncio:** Es menos sobre hilos y más sobre limitar tareas concurrentes a un servicio específico (ej: usando `asyncio.Semaphore` para envolver las llamadas a un servicio X).

**¡Pruébalo (Conceptual)!**
* Imagina que llamas a 3 servicios (A, B, C). Si B se pone superlento y no tienes Bulkhead, podría acaparar todas tus "manos" (trabajadores asyncio) y ni A ni C recibirían atención. Con Bulkhead, B solo puede usar sus "manos" asignadas.

---

## 4.6. Circuit Breakers con `pybreaker`: El Fusible Inteligente

La librería `pybreaker` es genial para esto: `pip install pybreaker`


Cuando un servicio externo falla repetidamente, es mejor **detener las llamadas** para no saturarlo y proteger nuestro sistema. Para esto usamos un **Circuit Breaker**.

### ¿Qué es un Circuit Breaker?

Es un *patrón de resiliencia* que:

* **CLOSED (cerrado)**: deja pasar llamadas normalmente.
* **OPEN (abierto)**: bloquea las llamadas tras un número de fallos.
* **HALF-OPEN (semiabierto)**: prueba si el servicio ha vuelto y reabre si tiene éxito.

---

### Instalación

```bash
pip install fastapi uvicorn httpx pybreaker
```

¡Perfecto! Vamos a montarlo todo bien, en dos archivos: uno será el **Mock API** y otro tu **Breaker con FastAPI**.

---
**PASO 1: Mock API que falla aleatoriamente**

**Crea un archivo `mock_service.py`:**

```python
# mock_service.py

from fastapi import FastAPI, HTTPException
import random

app = FastAPI()

@app.get("/unstable")
def unstable_service():
    if random.random() < 0.5:  # 50% de probabilidades de fallo
        raise HTTPException(status_code=500, detail="Fallo simulado")
    return {"message": "Todo OK"}
```

---


**PASO 2: FastAPI + PyBreaker**

**Crea un archivo `main.py`:**

```python
# main.py

from fastapi import FastAPI, HTTPException
import httpx
import pybreaker
import logging

# Configuración de logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Listener para ver el estado del breaker
class MyListener(pybreaker.CircuitBreakerListener):
    def state_change(self, cb, old_state, new_state):
        logger.warning(f"Circuit Breaker {cb.name} cambió de {old_state.name} a {new_state.name}")

# Circuit Breaker configuración
breaker = pybreaker.CircuitBreaker(
    fail_max=3,            # Máximo 3 fallos para abrir
    reset_timeout=10,      # 10 segundos antes de HALF-OPEN
    listeners=[MyListener()],
    name="MockServiceBreaker"
)

app = FastAPI()

URL = "http://localhost:9000/unstable"  # Nuestro servicio inestable

# Función protegida
@breaker
def call_mock_service():
    response = httpx.get(URL, timeout=2.0)
    response.raise_for_status()  # Lanza excepción en error HTTP
    return response.json()

# Endpoint para probar
@app.get("/call-external")
def get_mock_service():
    try:
        data = call_mock_service()
        return {"status": "ok", "data": data}
    except pybreaker.CircuitBreakerError:
        logger.error("Circuit Breaker ABIERTO. Servicio Mock NO disponible.")
        raise HTTPException(status_code=503, detail="Servicio no disponible (Circuito Abierto).")
    except Exception as e:
        logger.error(f"Error contactando servicio Mock: {e}")
        raise HTTPException(status_code=502, detail="Error contactando servicio externo.")

# Endpoint para ver el estado del breaker
@app.get("/breaker-status")
def breaker_status():
    return {
        "state": breaker.current_state.name,
        "failures": breaker.fail_counter
    }
```

---

**Corre tu FastAPI:**

```bash
uvicorn main:app --reload
```

---

**PASO 3: Atacar el sistema**

Un pequeño script para hacer **muchas llamadas** rápidas:

**Crea un `attack.py`:**

```python
# attack.py

import requests
import time

URL = "http://localhost:8000/call-external"

for i in range(20):
    try:
        response = requests.get(URL)
        print(f"{i+1:02d} --> {response.status_code} | {response.json()}")
    except Exception as e:
        print(f"{i+1:02d} --> ERROR: {e}")
    time.sleep(0.5)  # medio segundo entre llamadas
```

Lanza este script:

```bash
python attack.py
```

---

**¿Qué vas a ver?**

* **Al principio**: respuestas `200 OK` o fallos `502 Bad Gateway`.
* **Cuando falle 3 veces seguidas**:
  El breaker se pone en **OPEN** y empiezas a recibir **503 Service Unavailable** instantáneamente.
* **Después de 10 segundos**:
  El breaker entra en **HALF-OPEN**.
* **Una llamada de prueba**:

  * Si sale bien → vuelve a **CLOSED**.
  * Si falla → vuelve a **OPEN**.

✅ Además, puedes consultar en cualquier momento el estado del breaker:

```bash
curl http://localhost:8000/breaker-status
```

Te dirá:

```json
{
  "state": "CLOSED",
  "failures": 0
}
```

o

```json
{
  "state": "OPEN",
  "failures": 3
}
```

o

```json
{
  "state": "HALF_OPEN",
  "failures": 3
}
```

---



* Cómo el **Circuit Breaker** protege tu app:
  Evita seguir llamando a un servicio roto.
* Cómo hace **reintentos** controlados (`HALF-OPEN`) para ver si ya se recuperó.
* **Evita** que tu API explote por servicios inestables externos.



---
## 4.7. Diseño de endpoints resilientes a fallos de servicios externos

Tu endpoint FastAPI es un héroe, ¡pero no invencible! Si depende de otros para funcionar, debe saber qué hacer cuando esos otros fallan.

**Estrategias Prácticas:**

1.  **Timeouts Agresivos (¡Ya los vimos!):** Usa `httpx.Timeout` en tus clientes. No esperes eternamente.
2.  **Fallbacks (Plan B):** Si el servicio de recomendaciones falla, ¿puedes mostrar la página de producto sin ellas? O con recomendaciones cacheadas/por defecto?

    ```python
    # En tu servicio de aplicación (no en el endpoint FastAPI directamente)
     async def get_product_page_data(product_id: str, user_id: str):
         producto = await self.product_repo.get_by_id(product_id)
         if not producto: raise RecursoNoEncontradoError(...)

         try:
             # Esta llamada usa cliente con Retry y Circuit Breaker
             recomendaciones = await self.reco_service_client.get_for_product(product_id, user_id)
         except (CircuitBreakerError, httpx.HTTPError) as e: # O tu ExternalServiceError
             logger.warning(f"Recomendaciones no disponibles para {product_id}. Usando fallback. Error: {e}")
             recomendaciones = [{"id": "default1", "nombre": "Producto Popular 1"}] # Fallback!

         return {"producto": producto, "recomendaciones": recomendaciones}
    ```
3.  **Degradación Agraciada:** Es el resultado del fallback. El servicio sigue funcionando, pero quizás con menos funcionalidades. ¡Mejor eso que un error 500 total!
4.  **Health Checks (`/health`):**
    * **Shallow (`/health/live`):** ¿Está FastAPI vivo? Devuelve 200 OK.
    * **Deep (`/health/ready`):** ¿Están *mis dependencias críticas* (BBDD, API clave) vivas? Si no, devuelve 503. Kubernetes usa esto para saber si mandar tráfico o reiniciar.


---

## 4.8. Diseño de endpoints resilientes a fallos de servicios externos

Cuando tienes 1000 peticiones por segundo y algo falla, ¿cómo encuentras *esa* petición? ¡Con un `trace_id` (o Correlation ID)! Es un ID único que viaja con la petición por todos tus servicios.

**Implementación Práctica (Simplificada) en FastAPI:**
* **Middleware (ya lo hicimos en 4.2):**
    * Al llegar una petición: ¿Tiene cabecera `X-Trace-ID` (o `X-Correlation-ID`)? Úsala. Si no, genera un `uuid.uuid4()`.
    * Guárdala en `request.state.trace_id`.
    * **Importante:** ¡Añádela a TODOS tus logs!
    * Al responder, incluye la cabecera `X-Trace-ID` en la respuesta.
* **Logging Estructurado (JSON):** Usa `python-json-logger` o `structlog` para que tus logs sean JSON y siempre incluyan el `trace_id`.

    ```python
    # Ejemplo de cómo usar el trace_id en un log dentro de un endpoint
     logger = logging.getLogger(__name__) # Configurado para JSON y con filtro/adapter para trace_id

     @app.get("/algun-endpoint")
     async def mi_endpoint(request: Request):
         trace_id = getattr(request.state, "trace_id", "N/A")
         logger.info(f"Procesando endpoint (RID: {trace_id})", extra={"trace_id_field": trace_id})
         # ... tu lógica ...
         if algo_malo_pero_no_excepcion:
              logger.warning(f"Algo raro pasó (RID: {trace_id})", extra={"trace_id_field": trace_id, "detalle": "info extra"})
         return {"ok": True}
    ```
* **Propagación:** Cuando tu servicio FastAPI llame a *otro* servicio, ¡pasa el `trace_id` en las cabeceras de esa nueva petición!

**¡Pruébalo!**
* Asegúrate que el middleware de 4.2 está activo.
* En tus endpoints, añade logs (un simple `print` con el `trace_id` de `request.state.trace_id` sirve para esta prueba rápida).
* Llama a tus endpoints y verifica que el `trace_id` aparece en la consola y en las cabeceras de respuesta.

---

## 4.9. Visibilidad de errores mediante dashboards

Tus logs y métricas son oro, ¡pero necesitas un mapa del tesoro! Un dashboard (en Grafana, Kibana, Datadog...) te muestra de un vistazo:

* **Tasa de Errores Global (5xx vs 4xx):** ¿Estamos ardiendo?
* **Errores por Endpoint:** ¿Qué endpoint es el más problemático?
* **Top N `error_code`:** ¿Qué errores de negocio son los más comunes?
* **Latencia (P95, P99):** ¿Estamos lentos? ¡La lentitud es el nuevo downtime!
* **Estado de Circuit Breakers:** ¿Cuántos están abiertos? ¿Cuáles?
* **Métricas de Saturación:** CPU, memoria, tamaño de colas.

**¡Pruébalo (Mentalmente)!**
* Imagina un dashboard con un gran número rojo si la tasa de 5xx sube del 1%.
* Otro gráfico con las barras de los 5 endpoints que más errores 404 dan.
* Un semáforo por cada Circuit Breaker (Verde=Cerrado, Rojo=Abierto).

**Herramientas Populares:**
* **Logs:** ELK Stack (Elasticsearch, Logstash, Kibana), Grafana Loki.
* **Métricas:** Prometheus + Grafana.
* **Tracing Distribuido:** Jaeger, Zipkin, Grafana Tempo (con OpenTelemetry).

---

## 4.10. Pruebas para simular fallos y degradación controlada

¿Cómo sabes que tus Retries, Circuit Breakers y Fallbacks funcionan? ¡Provocándolos!

**En FastAPI (Pruebas de Integración con `pytest`):**

Usa `app.dependency_overrides` para inyectar un "cliente falso" que simule fallos cuando tu endpoint lo llame.

```python
# tests/test_resiliencia_endpoints.py (requiere pytest, httpx)
 from fastapi.testclient import TestClient
 from main import app # Tu app FastAPI
 from app.dependencies import get_servicio_x_client # Tu dependencia original
 from app.clients.base import BaseServicioXClient # Clase base de tu cliente

 class MockServicioXFallaSiempre(BaseServicioXClient): # Implementa la interfaz de tu cliente real
     async def get_data(self, param: str) -> dict:
         print("MOCK SERVICIO X: Simulando fallo siempre...")
         raise httpx.RequestError("Mock: Fallo de red en Servicio X", request=None)

 class MockServicioXFallaAlPrincipioLuegoOk(BaseServicioXClient):
     intentos = 0
     max_fallos = 2 # Falla las primeras 2 veces
     async def get_data(self, param: str) -> dict:
         MockServicioXFallaAlPrincipioLuegoOk.intentos += 1
         if MockServicioXFallaAlPrincipioLuegoOk.intentos <= MockServicioXFallaAlPrincipioLuegoOk.max_fallos:
             print(f"MOCK SERVICIO X (Falla/Ok): Intento {MockServicioXFallaAlPrincipioLuegoOk.intentos}, simulando fallo...")
             raise httpx.RequestError("Mock: Fallo temporal en Servicio X", request=None)
         print(f"MOCK SERVICIO X (Falla/Ok): Intento {MockServicioXFallaAlPrincipioLuegoOk.intentos}, simulando ÉXITO!")
         return {"data_mock": "Datos del mock exitosos!"}


 client = TestClient(app)

 def test_endpoint_con_servicio_x_cb_abierto():
     # Configura el breaker para que se abra rápido para el test
     # Esto es un poco más complejo de testear unitariamente sin acceso directo al breaker global.
#     # Una opción es tener un breaker por test o resetearlo.
#     # Para este ejemplo, asumimos que podemos manipular el breaker o que el test lo llevará a OPEN.

     app.dependency_overrides[get_servicio_x_client] = lambda: MockServicioXFallaSiempre()
     print("\n--- Testeando Circuit Breaker (esperamos que se abra) ---")
#     # Llamar varias veces para abrir el circuit breaker (según fail_max del breaker)
     for i in range(servicio_X_breaker.fail_max + 1): # +1 para asegurar que intentó abrirse
         print(f"Llamada {i+1} para intentar abrir CB...")
         response = client.get("/datos-servicio-x-cb") # Asume que este endpoint usa el cliente que estamos mockeando
         if servicio_X_breaker.is_open:
             assert response.status_code == status.HTTP_503_SERVICE_UNAVAILABLE # CB Abierto
             assert "Circuito Abierto" in response.json()["detail"]
             print(f"CB ABIERTO como se esperaba en llamada {i+1}!")
             break
     else: # Si el bucle termina sin break
         assert False, f"El Circuit Breaker no se abrió después de {servicio_X_breaker.fail_max + 1} llamadas fallidas."

     app.dependency_overrides = {} # Limpiar

 def test_endpoint_con_retry_y_luego_exito():
      # Reiniciar contador de intentos del mock para este test
     MockServicioXFallaAlPrincipioLuegoOk.intentos = 0
#     # Asegúrate que el breaker esté cerrado al inicio de este test o usa un breaker diferente.
#     # Aquí asumimos que el breaker se resetea o es diferente.
#     # Para un test real, el estado del breaker entre tests puede ser un problema.
#     # Resetear el breaker o usar uno nuevo por test es más robusto.
     servicio_X_breaker.close() # Ejemplo de reset, si el breaker lo permite

#     # Esta prueba es para el endpoint /datos-externos-retry que usa tenacity
     app.dependency_overrides[llamar_api_externa_con_reintentos_dependency] = lambda: MockServicioXFallaAlPrincipioLuegoOk() # Asumiendo que tienes una dependencia para esto
     print("\n--- Testeando Retry (esperamos éxito después de fallos) ---")
     response = client.get("/datos-externos-retry") # Este endpoint usa tenacity
     assert response.status_code == status.HTTP_200_OK
     assert response.json()["data_mock"] == "Datos del mock exitosos!"
     print(f"ÉXITO con Retry después de {MockServicioXFallaAlPrincipioLuegoOk.intentos} intentos totales.")
     app.dependency_overrides = {}
```
**(Nota: El código de testeo anterior es conceptual y avanzado. Testear Circuit Breakers y Retries de forma aislada y fiable en tests de integración requiere un buen manejo del estado de estos componentes entre tests o el uso de mocks más sofisticados. Para `tenacity`, podrías mockear `httpx.AsyncClient` directamente en el módulo donde se usa).**

**Herramientas Más Pro (Fuera de FastAPI puro):**
* **Toxiproxy:** Un proxy que pones entre tu servicio y sus dependencias para inyectar latencia, errores de red, etc., ¡sin tocar tu código!
* **Chaos Mesh / LitmusChaos (para Kubernetes):** Para "romper" cosas a nivel de infraestructura.

---

#### Diseño de Endpoints Resilientes

Un endpoint resiliente no se rinde fácil. Si una dependencia falla, intenta dar la mejor respuesta posible, ¡incluso si es parcial!

**Escenario Práctico:** Un endpoint que muestra detalles de un producto y, opcionalmente, opiniones de usuarios (que vienen de otro servicio). Si las opiniones fallan, ¡al menos devolvemos el producto!

```python
# main_resiliente.py
from fastapi import FastAPI, HTTPException, Request, status
from fastapi.responses import JSONResponse
import httpx # pip install httpx
import asyncio
import random
import uvicorn
import uuid # Para el trace_id

# --- Configuración básica de logging para ver el trace_id ---
import logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - TRACE_ID: %(trace_id)s - %(message)s')
logger = logging.getLogger(__name__)

# --- Middleware para Trace ID (simple) ---
@app.middleware("http")
async def add_trace_id_middleware(request: Request, call_next):
    # Intenta obtener el trace_id de la cabecera, o genera uno nuevo
    trace_id = request.headers.get("X-Trace-ID") or str(uuid.uuid4())
    request.state.trace_id = trace_id # Lo guardamos en el estado de la petición

    # Adaptador para que el logger pueda acceder al trace_id de request.state
    class RequestStateAdapter(logging.LoggerAdapter):
        def process(self, msg, kwargs):
            try:
                # Intenta acceder a request.state.trace_id de forma segura
                current_trace_id = request.state.trace_id
            except AttributeError: # Si request.state no existe o no tiene trace_id
                current_trace_id = "N/A" # O un valor por defecto
            
            # Asegura que 'extra' exista en kwargs
            if 'extra' not in kwargs:
                kwargs['extra'] = {}
            kwargs['extra']['trace_id'] = current_trace_id
            return msg, kwargs

    # Usamos un logger específico adaptado para este request
    request_logger = RequestStateAdapter(logger, {})

    # Para uso dentro de los endpoints, podemos pasar el logger o el trace_id
    # request.state.logger = request_logger # Opcional, para pasarlo directamente

    response = await call_next(request)
    response.headers["X-Trace-ID"] = trace_id
    return response


app = FastAPI(title="API Resiliente de Productos")

# --- Simulación de Clientes a Servicios Externos ---
async def get_product_data_from_db(product_id: str, current_trace_id: str):
    # Simula una BBDD rápida y fiable para datos del producto
    await asyncio.sleep(0.05)
    if product_id == "P001":
        return {"id": "P001", "nombre": "Super Teclado Pro", "precio": 99.99}
    return None

async def get_opiniones_from_service(product_id: str, current_trace_id: str):
    # Simula un servicio de opiniones que a veces falla o tarda
    # ¡Importante! Propagar X-Trace-ID si esto fuera una llamada HTTP real
    headers = {"X-Trace-ID": current_trace_id}
    logger.info(f"Llamando a servicio de opiniones para {product_id} (Simulado con headers: {headers})")

    await asyncio.sleep(random.uniform(0.1, 0.8)) # Latencia variable
    if random.random() < 0.4: # 40% de probabilidad de fallo
        logger.error(f"Fallo simulado en servicio de opiniones para {product_id}")
        raise httpx.RequestError("Fallo simulado en servicio de opiniones", request=None)
    return [
        {"usuario": "User123", "rating": 5, "texto": "¡Excelente!"},
        {"usuario": "FanDelProducto", "rating": 4, "texto": "Muy bueno, lo recomiendo."},
    ]

# --- Endpoint Resiliente ---
@app.get("/productos/{product_id}/detalles")
async def get_producto_con_opiniones(product_id: str, request: Request):
    trace_id = request.state.trace_id # Obtenemos el trace_id
    request_logger = logging.LoggerAdapter(logger, {'trace_id': trace_id})


    request_logger.info(f"Petición para detalles del producto {product_id}")
    producto_data = await get_product_data_from_db(product_id, trace_id)

    if not producto_data:
        request_logger.warning(f"Producto {product_id} no encontrado.")
        # Usaremos nuestro handler para RecursoNoEncontradoError si lo tuviéramos
        # Por ahora, una HTTPException directa para simplificar
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Producto {product_id} no encontrado")

    opiniones_data = [] # Fallback: lista vacía
    mensaje_degradacion = None
    try:
        # Timeout agresivo para el servicio de opiniones
        opiniones_data = await asyncio.wait_for(
            get_opiniones_from_service(product_id, trace_id),
            timeout=0.5 # ¡Solo 500ms de paciencia!
        )
        request_logger.info(f"Opiniones para {product_id} obtenidas exitosamente.")
    except httpx.RequestError:
        request_logger.error(f"Servicio de opiniones falló para {product_id}. Degradando respuesta.")
        mensaje_degradacion = "Opiniones no disponibles temporalmente (fallo de servicio)."
    except asyncio.TimeoutError:
        request_logger.warning(f"Servicio de opiniones timed out para {product_id}. Degradando respuesta.")
        mensaje_degradacion = "Opiniones no disponibles temporalmente (timeout)."
    
    respuesta_final = {"producto": producto_data, "opiniones": opiniones_data}
    if mensaje_degradacion:
        respuesta_final["aviso_degradacion"] = mensaje_degradacion
        
    request_logger.info(f"Respuesta para {product_id} ensamblada.")
    return respuesta_final

# --- Health Checks ---
@app.get("/health/live", status_code=status.HTTP_200_OK)
async def health_live():
    # Shallow: Solo verifica que la app FastAPI está arriba
    return {"status": "ok", "message": "Servicio vivo"}

@app.get("/health/ready", status_code=status.HTTP_200_OK)
async def health_ready(request: Request):
    # Deep: Intenta una operación crítica simple para ver si está listo
    # (Ej: ping a la BBDD o a un servicio esencial)
    # Aquí simulamos una dependencia que debe estar ok
    trace_id = request.state.trace_id
    request_logger = logging.LoggerAdapter(logger, {'trace_id': trace_id})
    try:
        # Simula chequear una dependencia esencial (ej: el servicio de productos "P001")
        await asyncio.wait_for(get_product_data_from_db("P001", trace_id), timeout=0.2)
        request_logger.info("Chequeo de dependencia profunda OK.")
        return {"status": "ok", "message": "Servicio listo y dependencias OK"}
    except Exception as e:
        request_logger.error(f"Chequeo de dependencia profunda FALLÓ: {e}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Servicio no listo, dependencia crítica falló: {str(e)}"
        )

if __name__ == "__main__":
    uvicorn.run("main_resiliente:app", host="0.0.0.0", port=8000, reload=True)
```

**¡Pruébalo!**
1.  Guarda como `main_resiliente.py`.
2.  Ejecuta: `uvicorn main_resiliente:app --reload`
3.  Llama a `GET http://localhost:8000/productos/P001/detalles` varias veces:
    * Algunas veces verás el producto Y las opiniones.
    * Otras, verás el producto y el `aviso_degradacion` porque el servicio de opiniones falló o tardó demasiado. ¡Pero la API sigue respondiendo 200 OK con lo que tiene!
4.  Prueba `GET http://localhost:8000/productos/P_NO_EXISTE/detalles` (dará 404).
5.  Prueba `GET http://localhost:8000/health/live` y `GET http://localhost:8000/health/ready`.

**Claves de Resiliencia Aquí:**
* **Fallback:** `opiniones_data` inicia como `[]`.
* **Timeout Específico:** `asyncio.wait_for` para el servicio de opiniones.
* **Degradación Agraciada:** Si las opiniones fallan, se loggea y se añade un `aviso_degradacion`. El endpoint sigue útil.
* **Health Checks:** Para que sistemas externos sepan si tu servicio está bien.

---

#### Captura y Log de Trazas con Contexto

Un `trace_id` (o Correlation ID) es un ID único que se pasa entre servicios para una petición. ¡Esencial para depurar en microservicios!

**Escenario Práctico:** Un middleware en FastAPI que genera/propaga un `trace_id`, y un endpoint que lo loggea.

```python
# main_trazabilidad.py
from fastapi import FastAPI, Request
import uuid
import logging
import uvicorn

# --- Configuración de Logging Estructurado (Simplificado para consola) ---
# En producción usarías python-json-logger o structlog para JSON real.
# Este es un formateador simple para demostrar el concepto.
class TraceIdFormatter(logging.Formatter):
    def format(self, record):
        # Inyecta el trace_id en el registro si está disponible
        record.trace_id = getattr(record, 'trace_id', 'N/A')
        return super().format(record)

# Logger principal
logger = logging.getLogger("mi_app_con_trazas")
logger.setLevel(logging.INFO)
handler = logging.StreamHandler() # A la consola
formatter = TraceIdFormatter('%(asctime)s - %(levelname)s - App: %(name)s - TraceID: %(trace_id)s - %(message)s')
handler.setFormatter(formatter)
logger.addHandler(handler)
# Evitar que se propague al logger root si ya tiene handlers
logger.propagate = False


app = FastAPI(title="API con Trazabilidad")

# --- Middleware para Trace ID ---
@app.middleware("http")
async def trace_id_middleware(request: Request, call_next):
    # 1. Busca un trace_id entrante (ej. de un API Gateway u otro servicio)
    trace_id_entrante = request.headers.get("X-Trace-ID")
    
    # 2. Si no hay, genera uno nuevo
    id_para_esta_peticion = trace_id_entrante or str(uuid.uuid4())
    
    # 3. Guarda el trace_id en el estado de la petición para acceso en endpoints
    request.state.trace_id = id_para_esta_peticion
    
    # 4. Pasa la petición al siguiente en la cadena
    response = await call_next(request)
    
    # 5. Añade el trace_id a la cabecera de la respuesta
    response.headers["X-Trace-ID"] = id_para_esta_peticion
    
    return response

# --- Cliente HTTP para simular llamada a otro servicio ---
async def llamar_a_otro_servicio(trace_id_a_propagar: str):
    # En una llamada real, usarías httpx y añadirías el trace_id a las cabeceras
    logger.info(f"Llamando a servicio_externo... (Propagando TraceID: {trace_id_a_propagar})", extra={'trace_id': trace_id_a_propagar})
    await asyncio.sleep(0.1) # Simula llamada de red
    # Simula respuesta del servicio externo
    logger.info(f"Respuesta de servicio_externo recibida.", extra={'trace_id': trace_id_a_propagar})
    return {"mensaje_externo": "Datos del servicio B!", "trace_id_recibido_por_B_simulado": trace_id_a_propagar}

@app.get("/mi-endpoint-trazable")
async def endpoint_trazable(request: Request):
    # Accede al trace_id desde el estado de la petición
    trace_id_actual = request.state.trace_id
    
    # Usa un diccionario para pasar el trace_id al logger via 'extra'
    log_extra = {'trace_id': trace_id_actual}
    
    logger.info("Inicio del procesamiento en /mi-endpoint-trazable", extra=log_extra)
    
    # ... tu lógica de negocio aquí ...
    datos_intermedios = {"info": "procesamiento local completado"}
    logger.info(f"Datos intermedios: {datos_intermedios}", extra=log_extra)
    
    # Simular llamada a otro servicio, propagando el trace_id
    respuesta_servicio_externo = await llamar_a_otro_servicio(trace_id_actual)
    
    logger.info("Fin del procesamiento en /mi-endpoint-trazable", extra=log_extra)
    return {
        "mensaje_local": "Procesamiento en mi-endpoint-trazable finalizado.",
        "trace_id_usado": trace_id_actual,
        "respuesta_de_otro_servicio": respuesta_servicio_externo
    }

if __name__ == "__main__":
    uvicorn.run("main_trazabilidad:app", host="0.0.0.0", port=8001, reload=True)
```

**¡Pruébalo!**
1.  Guarda como `main_trazabilidad.py`.
2.  Ejecuta: `uvicorn main_trazabilidad:app --reload --port 8001`
3.  Abre tu navegador/Postman y llama a `GET http://localhost:8001/mi-endpoint-trazable`.
    * Observa la consola: Verás los logs, ¡cada uno con su `TraceID`!
    * Observa las cabeceras de la respuesta: Debería estar `X-Trace-ID`.
4.  Ahora, llama de nuevo pero añade una cabecera `X-Trace-ID: MI-TRACE-ID-PERSONALIZADO-123` a tu petición.
    * Observa la consola: ¡Todos los logs para esa petición ahora usan `MI-TRACE-ID-PERSONALIZADO-123`! Y la respuesta también lo tiene.

**Claves de Trazabilidad Aquí:**
* **Middleware:** Centraliza la lógica del `trace_id`.
* `request.state`: Un buen sitio para guardar información de la petición.
* **Logging con `extra`:** Así se pasan datos dinámicos (como el `trace_id`) a los formateadores de logs.
* **Propagación:** Si llamas a otros servicios, ¡no olvides pasarles el `trace_id`!

---



## Referencias bibliográficas

### Estrategias de Manejo de Errores y Principios de Resiliencia

  * **[1] FastAPI - Handling Errors.** (s.f.). Tiangolo - FastAPI Official Documentation.

      * Recuperado de [https://fastapi.tiangolo.com/tutorial/handling-errors/](https://fastapi.tiangolo.com/tutorial/handling-errors/)
      * *Documentación oficial sobre el manejo de `HTTPException` y `RequestValidationError`, y la implementación de controladores de excepciones personalizados (sección 4.2).*

### Implementación de Patrones de Resiliencia

  * **[2] `pybreaker` - PyPI.** (s.f.).

      * Recuperado de [https://pypi.org/project/pybreaker/](https://pypi.org/project/pybreaker/)
      * *Librería Python para implementar el patrón Circuit Breaker, utilizada en la sección 4.6.*
      * Documentación: [https://pybreaker.readthedocs.io/](https://www.google.com/search?q=https://pybreaker.readthedocs.io/)

  * **[3] `tenacity` - PyPI.** (s.f.).

      * Recuperado de [https://pypi.org/project/tenacity/](https://pypi.org/project/tenacity/)
      * *Librería Python para reintentar acciones con diversas estrategias (backoff exponencial), mencionada en la sección 4.4.*
      * Documentación: [https://tenacity.readthedocs.io/](https://tenacity.readthedocs.io/)

### Observabilidad: Logging y Tracing

  * **[6] `structlog` - Structured Logging for Python.** (s.f.).

      * Recuperado de [https://www.structlog.org/en/stable/](https://www.structlog.org/en/stable/)
      * *Librería avanzada para logging estructurado en Python, recomendada en la sección 4.8.*

  * **[7] `python-json-logger` - PyPI.** (s.f.).

      * Recuperado de [https://pypi.org/project/python-json-logger/](https://pypi.org/project/python-json-logger/)
      * *Formateador de logs JSON para la librería estándar `logging` de Python (sección 4.8).*

  * **[8] OpenTelemetry Documentation.** (s.f.). OpenTelemetry Authors.

      * Recuperado de [https://opentelemetry.io/docs/](https://opentelemetry.io/docs/)
      * *Estándar y conjunto de herramientas para telemetría (trazas, métricas, logs), detallado en la sección 4.8. Incluye SDKs para Python e instrumentación para FastAPI, HTTPX, etc.*
      * W3C Trace Context: [https://www.w3.org/TR/trace-context/](https://www.w3.org/TR/trace-context/)

  * **[9] Jaeger Tracing.** (s.f.). Jaeger Authors, CNCF.

      * Recuperado de [https://www.jaegertracing.io/docs/](https://www.jaegertracing.io/docs/)
      * *Backend popular para visualización de trazas distribuidas, compatible con OpenTelemetry.*

  * **[10] Grafana Loki.** (s.f.). Grafana Labs.

      * Recuperado de [https://grafana.com/docs/loki/latest/](https://grafana.com/docs/loki/latest/)
      * *Sistema de agregación de logs inspirado en Prometheus, optimizado para Grafana.*


### Visualización y Dashboards

  * **[11] Grafana Documentation.** (s.f.). Grafana Labs.

      * Recuperado de [https://grafana.com/docs/grafana/latest/](https://grafana.com/docs/grafana/latest/)
      * *Herramienta líder para visualización de métricas y logs, y creación de dashboards (sección 4.9).*

  * **[12] Prometheus Monitoring System.** (s.f.). Prometheus Authors.

      * Recuperado de [https://prometheus.io/docs/introduction/overview/](https://prometheus.io/docs/introduction/overview/)
      * *Sistema de monitorización y alerta, comúnmente usado con Grafana para métricas.*


