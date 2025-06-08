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



## 4.1. Estrategia Global de Errores

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
|               | No autenticado                             | 401         | ¡NO!         | Token JWT erróneo.                               |
|               | No autorizado                              | 403         | ¡NO!         | Eres user, no admin.                            |
|               | Recurso no existe                          | 404         | ¡NO!         | Buscas `GET /items/999` y 999 no está.          |
| **Servidor** | Regla de negocio rota                      | 409 / 400   | ¡NO!         | "Email ya existe", "Stock insuficiente".        |
|               | ¡Ups! Un bug en *mi* código FastAPI        | 500         | NO (hasta arreglar) | `variable_none.metodo()`                   |
|               | Servicio externo (BBDD, otra API) KO       | 503 / 504   | **¡SÍ!** (con cabeza) | La API de pagos no responde.                 |

**Paso Práctico 2: El Formato JSON de Error Universal**

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

# --- 3. Esto es lo que tú configuras (Exception Handlers) ---
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

## 4.4. Aplicación del patrón Retry con backoff exponencial


---



> Implementar el patrón **Retry** en una API basada en **FastAPI** para hacer la aplicación más resiliente a fallos temporales de servicios externos.

Cuando un microservicio hace una petición HTTP a otro servicio, este puede fallar de manera **intermitente** (por ejemplo, `503 Service Unavailable`). En estos casos, es una **buena práctica reintentar** la petición en lugar de fallar inmediatamente.

Aplicaremos un **Retry automático** con una estrategia de:

* **Número máximo de reintentos**.
* **Tiempo de espera** entre reintentos (backoff simple o exponencial).

---

### **¿Qué es el patrón Retry?**

* **Retry**: Volver a intentar una operación fallida, suponiendo que el error puede resolverse solo (por ejemplo, en un pico de carga).
* **Backoff**: Añadir una espera entre reintentos para no saturar el sistema.
* **Exponencial**: Incrementar el tiempo de espera de forma progresiva entre intentos.

**Beneficios**:

* Mejora la **resiliencia**.
* Reduce el **impacto** de fallos temporales.
* Evita saturar servicios que están bajo estrés.

---

### **Ejemplo práctico con FastAPI y Tenacity**

### 🔹 **Librerías necesarias**

```bash
pip install fastapi uvicorn tenacity httpx
```

---

#### 1. **Servicio externo simulado (`fake_service`)**

Un servicio que falla aleatoriamente un 70% de las veces para simular fallos temporales:

```python
# fake_service.py
from fastapi import FastAPI, Response
import random

app = FastAPI()

@app.get("/fake_service")
def fake_service():
    if random.random() < 0.7:
        return Response(
            content="{'error': 'Temporary failure'}",
            status_code=503,
            media_type="application/json"
        )
    return {"message": "Service OK"}
```

✅ **Este servicio** responderá 503 muchas veces aleatoriamente.

---

#### 2. **Cliente con Retry en FastAPI**

Este cliente reintentará automáticamente si recibe un `503 Service Unavailable`:

```python
# retry_client.py
from fastapi import FastAPI, HTTPException
import httpx
from tenacity import retry, stop_after_attempt, wait_fixed, RetryError
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()

EXTERNAL_SERVICE_URL = "http://localhost:9000/fake_service"

# Retry decorator: reintenta hasta 3 veces si hay un fallo 503
@retry(
    stop=stop_after_attempt(3),    # máximo 3 intentos
    wait=wait_fixed(2)             # espera fija de 2 segundos entre intentos
)
def call_external_service():
    response = httpx.get(EXTERNAL_SERVICE_URL)
    if response.status_code == 503:
        logger.warning(f"503 Service Unavailable, reintentando...")
        raise Exception("503 Service Unavailable")
    response.raise_for_status()
    return response.json()

@app.get("/call-service/")
def call_service():
    try:
        result = call_external_service()
        return {"result": result}
    except RetryError:
        raise HTTPException(status_code=500, detail="Servicio no disponible después de varios intentos")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

---

#### 3. **Cómo ejecutarlo**

🔹 **Terminal 1**: Levantar el servicio que falla

```bash
uvicorn fake_service:app --host 0.0.0.0 --port 9000 --reload
```

🔹 **Terminal 2**: Levantar el cliente con retry

```bash
uvicorn retry_client:app --host 0.0.0.0 --port 8000 --reload
```

🔹 **Probar**

```bash
curl http://localhost:8000/call-service/
```
 **Resultados esperados**:

* Si el servicio externo responde 503, se verá:

  ```
  WARNING:root:503 Service Unavailable, reintentando...
  ```

  repetido hasta 3 veces y, si sigue fallando, respuesta:

  ```json
  {
    "detail": "Servicio no disponible después de varios intentos"
  }
  ```

* Si en alguno de los intentos responde 200 OK:

  ```json
  {
    "result": {
      "message": "Service OK"
    }
  }
  ```

---



| Configuración                      | Valor                                 |
| ---------------------------------- | ------------------------------------- |
| **Máximo número de intentos**      | `3`                                   |
| **Tiempo entre intentos**          | `2 segundos`                          |
| **Error que dispara retry**        | `503 Service Unavailable`             |
| **Comportamiento si todos fallan** | Devolver `500 Servicio no disponible` |



* **Tenacity** solo reintenta si lanzas una **excepción**.
* No debes capturar las excepciones dentro de la función decorada; déjalas subir.
* Se puede configurar **backoff exponencial** con `wait_exponential()` en vez de `wait_fixed()` para un patrón más realista.



---

## 4.5 Introducción a patrones Circuit Breaker y Bulkhead

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

## 4.6 Implementación de circuit breakers con pybreaker


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

## 4.8 Captura y log de trazas con contexto de peticiones
## 4.9 Visibilidad de errores mediante dashboards
## 4.10 Pruebas para simular fallos y degradación controlada
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


