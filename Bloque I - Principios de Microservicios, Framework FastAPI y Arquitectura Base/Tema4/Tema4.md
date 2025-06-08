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


## 4.7. Diseño de Endpoints que Aceptan el Fallo (Degradación Controlada)

#### Definición

Un endpoint resiliente no es aquel que nunca falla, sino aquel que **sabe cómo fallar bien**. La degradación controlada es la técnica de diseñar un endpoint para que, cuando una de sus dependencias no críticas falle, pueda seguir ofreciendo una respuesta útil en lugar de un error completo (como un `500 Internal Server Error`). La idea es devolver datos parciales, datos de una caché, o una versión simplificada de la respuesta.

#### Ejemplo Práctico

Imagina un endpoint que muestra los detalles de un producto. Obtiene la información principal de un servicio (`servicio-productos`) y el stock en tiempo real de otro (`servicio-inventario`). Si el servicio de inventario falla, preferimos mostrar la información del producto con un aviso de "Stock no disponible" antes que no mostrar nada.

**1. Crea un mock de los servicios externos (`mock_servicios.py`):**
Este servidor simula nuestras dependencias. Podemos hacer que el servicio de inventario falle si le pasamos un parámetro en la URL.

```python
# mock_servicios.py
from fastapi import FastAPI, Response, status

app = FastAPI()

@app.get("/products/{product_id}")
async def get_product_info(product_id: str):
    return {"id": product_id, "name": "Poción de Maná", "description": "Restaura 100 MP."}

@app.get("/inventory/{product_id}")
async def get_inventory(product_id: str, fail: bool = False):
    if fail:
        return Response(status_code=status.HTTP_503_SERVICE_UNAVAILABLE)
    return {"product_id": product_id, "stock": 42}

```

**2. Crea tu API principal resiliente (`main_resiliente.py`):**

```python
# main_resiliente.py
from fastapi import FastAPI, HTTPException
import httpx

app = FastAPI()

PRODUCT_API_URL = "http://localhost:9001/products"
INVENTORY_API_URL = "http://localhost:9002/inventory"

@app.get("/product-details/{product_id}")
async def get_product_details(product_id: str):
    try:
        async with httpx.AsyncClient() as client:
            # 1. Obtener información principal (crítica)
            product_response = await client.get(f"{PRODUCT_API_URL}/{product_id}")
            product_response.raise_for_status() # Si esto falla, el endpoint entero falla
            product_data = product_response.json()

            # 2. Obtener stock (no crítico) con fallback
            stock_data = {"stock": None, "status": "No se pudo verificar el stock"}
            try:
                inventory_response = await client.get(f"{INVENTORY_API_URL}/{product_id}", timeout=2.0)
                inventory_response.raise_for_status()
                stock_data = {"stock": inventory_response.json()["stock"], "status": "Verificado"}
            except (httpx.RequestError, httpx.HTTPStatusError):
                # Fallback: Si la llamada al inventario falla, no rompemos.
                # Simplemente usamos los datos por defecto y seguimos.
                pass

            # 3. Componer la respuesta final
            return {
                "product_info": product_data,
                "inventory": stock_data
            }

    except httpx.HTTPStatusError as e:
        # Si el servicio crítico de productos falla
        raise HTTPException(status_code=502, detail=f"El servicio de productos falló: {e.response.status_code}")
```

#### Pruebas con `curl`

**Paso 1: Ejecuta los servidores**
```bash
# Terminal 1: Mock de productos
uvicorn mock_servicios:app --host 0.0.0.0 --port 9001

# Terminal 2: Mock de inventario
uvicorn mock_servicios:app --host 0.0.0.0 --port 9002

# Terminal 3: API principal
uvicorn main_resiliente:app --host 0.0.0.0 --port 8000
```

**Paso 2: Prueba el caso de éxito**
Todos los servicios funcionan. `curl` devuelve la respuesta completa.
```bash
curl http://localhost:8000/product-details/mana-potion
```
**Salida esperada (éxito):**
```json
{
  "product_info": {
    "id": "mana-potion",
    "name": "Poción de Maná",
    "description": "Restaura 100 MP."
  },
  "inventory": {
    "stock": 42,
    "status": "Verificado"
  }
}
```

**Paso 3: Prueba la degradación controlada**
Forzamos el fallo del servicio de inventario (`?fail=true`). El endpoint no devuelve un error 5xx, sino la respuesta parcial.
```bash
curl "http://localhost:9002/inventory/mana-potion?fail=true" # Así se llama para simular el fallo en el servicio de inventario
```
Ahora, al llamar a nuestro endpoint principal, este manejará el error internamente.
```bash
#Llamamos al endpoint principal. Él internamente llamará al servicio de inventario que fallará.
curl http://localhost:8000/product-details/mana-potion
```
**Salida esperada (degradada):**
```json
{
  "product_info": {
    "id": "mana-potion",
    "name": "Poción de Maná",
    "description": "Restaura 100 MP."
  },
  "inventory": {
    "stock": null,
    "status": "No se pudo verificar el stock"
  }
}
```

---

## 4.8 Captura y log de trazas con contexto de peticiones

#### Definición

El logging con contexto consiste en enriquecer cada mensaje de log con información clave sobre la petición que lo generó. En lugar de un inútil `"Conexión fallida"`, obtenemos un registro que nos dice **quién, qué y cuándo**. El **`trace_id`** es un identificador único que se crea para cada petición y se propaga por todos los logs y llamadas a otros servicios, permitiendo reconstruir la secuencia completa de eventos. El **logging estructurado** (en formato JSON) hace que estos logs sean legibles por máquinas, facilitando su búsqueda y análisis.

#### Ejemplo Práctico

Usaremos `structlog` para generar logs en JSON, con un middleware en FastAPI que inyecta automáticamente un `trace_id`.

```python
# main_logs.py
import uuid
from fastapi import FastAPI, Request, HTTPException
import structlog

# Configura structlog para que use el contexto y renderice a JSON
structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars, # Clave para el trace_id
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso", utc=True),
        structlog.processors.JSONRenderer(),
    ],
    logger_factory=structlog.PrintLoggerFactory(),
)
log = structlog.get_logger()

app = FastAPI()

# Middleware para inyectar el trace_id en el contexto de log
@app.middleware("http")
async def add_context_middleware(request: Request, call_next):
    trace_id = str(uuid.uuid4())
    structlog.contextvars.clear_contextvars()
    structlog.contextvars.bind_contextvars(trace_id=trace_id)
    
    response = await call_next(request)
    response.headers["X-Trace-ID"] = trace_id
    return response

@app.get("/user/{user_id}")
async def get_user(user_id: str):
    log.info("user_lookup_started", user_id=user_id) # Log con contexto
    
    if user_id == "admin":
        log.warn("admin_user_accessed", permissions="full")
        return {"user": user_id, "status": "ok"}
    
    raise HTTPException(status_code=404, detail="Usuario no encontrado")

# Un handler genérico que también loguea con contexto
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    log.error(
        "http_error",
        status_code=exc.status_code,
        detail=exc.detail,
        path=request.url.path
    )
    return await request.app.default_exception_handler(request, exc)
```

#### Pruebas con `curl`

**Paso 1: Ejecuta el servidor**
```bash
# Terminal 1
uvicorn main_logs:app --host 0.0.0.0 --port 8000
```

**Paso 2: Lanza peticiones con `curl` y observa la consola del servidor**

**Prueba 1: Un usuario normal que falla**
```bash
curl -i http://localhost:8000/user/bob
```
**Salida en la consola del servidor:**
```json
{"trace_id": "...", "log_level": "info", "event": "user_lookup_started", "user_id": "bob", "timestamp": "..."}
{"trace_id": "...", "log_level": "error", "event": "http_error", "status_code": 404, "detail": "Usuario no encontrado", "path": "/user/bob", "timestamp": "..."}
```

**Prueba 2: Un usuario especial que tiene éxito**
```bash
curl -i http://localhost:8000/user/admin
```
**Salida en la consola del servidor:**
```json
{"trace_id": "...", "log_level": "info", "event": "user_lookup_started", "user_id": "admin", "timestamp": "..."}
{"trace_id": "...", "log_level": "warning", "event": "admin_user_accessed", "permissions": "full", "timestamp": "..."}
```
Como puedes ver, cada línea de log comparte el mismo `trace_id` para una misma petición, y el formato JSON permite filtrar fácilmente por `log_level`, `event` o cualquier otro campo.

---

## 4.9. Visibilidad de Errores Mediante Dashboards

De acuerdo. Tienes toda la razón, la solución con Prometheus y Grafana es potente pero puede ser excesiva para este tema si se verá en detalle más adelante.

Busquemos el equilibrio perfecto: una herramienta de dashboard **real y visual** que sea **extremadamente simple** de levantar, sin Docker ni configuraciones complejas.

Usaremos **Streamlit**, una librería de Python que crea dashboards web interactivos con muy poco código. Es la forma más rápida de pasar de datos a una visualización web.

Aquí tienes la versión final del punto 4.9, simplificada y directa.

---

#### Definición

Un dashboard es una interfaz visual que nos permite entender la salud de nuestra aplicación de un vistazo. En lugar de leer logs o métricas en texto plano, los vemos representados en gráficos y números clave.

Para este ejemplo, usaremos una herramienta real llamada **Streamlit**. Crearemos un dashboard web que se actualizará en tiempo real, leyendo los logs que genera nuestra API. Es la solución perfecta para visualizar datos sin la complejidad de herramientas de producción como Grafana.

#### Ejemplo Práctico

Necesitaremos solo dos ficheros de Python.

**Paso 1: La API que Genera los Datos (`app_generadora.py`)**

Esta es una API FastAPI que, por cada petición, escribe una línea en un fichero de logs (`api_logs.log`) con detalles como el código de estado y la latencia.

```python
# app_generadora.py
import time
import logging
import json
from fastapi import FastAPI, Request

# --- Configuración del Logger para escribir a un fichero en formato JSON ---
log_file = "api_logs.log"
handler = logging.FileHandler(log_file)
# No usamos un formatter complejo, escribiremos el JSON directamente.

logger = logging.getLogger('api_logger')
logger.setLevel(logging.INFO)
logger.addHandler(handler)
logger.propagate = False
# -------------------------------------------------------------

app = FastAPI()

@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = (time.time() - start_time) * 1000  # en milisegundos

    log_entry = {
        "timestamp": time.strftime('%Y-%m-%dT%H:%M:%S'),
        "status_code": response.status_code,
        "latency_ms": process_time,
        "path": request.url.path
    }
    logger.info(json.dumps(log_entry))
    return response

@app.get("/")
def endpoint_exitoso():
    return {"status": "ok"}

@app.get("/lento")
async def endpoint_lento():
    import asyncio
    await asyncio.sleep(1.5)
    return {"status": "ok, pero lento"}

@app.get("/error-cliente")
def endpoint_error_cliente():
    from fastapi import HTTPException
    raise HTTPException(status_code=404, detail="Recurso no encontrado")

@app.get("/error-servidor")
def endpoint_error_servidor():
    _ = 1 / 0
```

**Paso 2: El Dashboard Web con Streamlit (`dashboard_streamlit.py`)**

Este script lee el fichero de logs, lo procesa con la librería `pandas` y muestra los resultados usando `streamlit`.

```python
# dashboard_streamlit.py
import streamlit as st
import pandas as pd
import json
from datetime import datetime

LOG_FILE = "api_logs.log"

st.set_page_config(
    page_title="Dashboard API en Vivo",
    page_icon="📊",
    layout="wide",
)

def load_data():
    """Lee el fichero de logs y lo convierte en un DataFrame de Pandas."""
    records = []
    try:
        with open(LOG_FILE, 'r') as f:
            for line in f:
                records.append(json.loads(line))
        return pd.DataFrame(records)
    except FileNotFoundError:
        return pd.DataFrame() # Devuelve un DataFrame vacío si el log no existe

# Título del dashboard
st.title("📊 Dashboard de Salud de la API en Vivo")

# Cargar los datos
df = load_data()

if df.empty:
    st.warning("No se han registrado peticiones todavía. ¡Usa `curl` para generar tráfico!")
else:
    # Convertir tipos para asegurar cálculos correctos
    df['timestamp'] = pd.to_datetime(df['timestamp'])
    df['latency_ms'] = pd.to_numeric(df['latency_ms'])
    df['status_code'] = pd.to_numeric(df['status_code'])

    # --- Métricas Principales ---
    col1, col2, col3, col4 = st.columns(4)
    total_requests = len(df)
    server_errors = len(df[df['status_code'] >= 500])
    client_errors = len(df[(df['status_code'] >= 400) & (df['status_code'] < 500)])
    avg_latency = df['latency_ms'].mean()

    col1.metric("Peticiones Totales", f"{total_requests}")
    col2.metric("Errores de Servidor (5xx)", f"{server_errors}")
    col3.metric("Errores de Cliente (4xx)", f"{client_errors}")
    col4.metric("Latencia Media", f"{avg_latency:.2f} ms")

    # --- Gráficos ---
    st.divider()
    col_a, col_b = st.columns(2)

    # Gráfico de peticiones por código de estado
    status_counts = df['status_code'].value_counts().reset_index()
    status_counts.columns = ['Código de Estado', 'Número de Peticiones']
    with col_a:
        st.subheader("Peticiones por Código de Estado")
        st.bar_chart(status_counts, x='Código de Estado', y='Número de Peticiones')

    # Gráfico de latencia a lo largo del tiempo
    with col_b:
        st.subheader("Latencia a lo largo del tiempo (ms)")
        st.line_chart(df, x='timestamp', y='latency_ms')

# Auto-refresco de la página cada 2 segundos
st.rerun(ttl=2)
```

#### Pruebas en Vivo: `curl` vs. tu Dashboard Web

**Paso 1: Instala las librerías necesarias**
```bash
pip install fastapi uvicorn pandas streamlit
```

**Paso 2: Inicia la API**
En una terminal, lanza el servidor que generará los logs.
```bash
# Terminal 1: API
uvicorn app_generadora:app --port 8000
```

**Paso 3: ¡Lanza tu Dashboard Web!**
En una segunda terminal, ejecuta el comando de Streamlit.
```bash
# Terminal 2: Dashboard
streamlit run dashboard_streamlit.py
```
Este comando **abrirá automáticamente una pestaña en tu navegador** mostrando el dashboard. Al principio, estará vacío.

**Paso 4: Ataca la API con `curl` y mira la magia en tu navegador**

Usa una tercera terminal para las peticiones. Verás cómo el dashboard en tu navegador se actualiza solo.

1.  **Genera tráfico exitoso:**
    ```bash
    # Terminal 3: Cliente
    curl http://localhost:8000/
    ```
    *En el navegador:* Aparecerá una petición, una barra para el código 200 y un punto en el gráfico de latencia.

2.  **Provoca un error de servidor (500):**
    ```bash
    # Terminal 3: Cliente
    curl http://localhost:8000/error-servidor
    ```
    *En el navegador:* La métrica "Errores de Servidor" subirá a 1 y aparecerá una barra para el código 500.

3.  **Genera una petición lenta:**
    ```bash
    # Terminal 3: Cliente
    curl http://localhost:8000/lento
    ```
    *En el navegador:* Verás un pico evidente en el gráfico de "Latencia a lo largo del tiempo".

Con este método, has usado una **herramienta de dashboard real** de una forma extremadamente simple, probando de manera visual e interactiva el impacto de cada tipo de petición en la salud de tu sistema.

---

## 4.10. Pruebas para Simular Fallos y Degradación Controlada

#### Definición

Probar la resiliencia significa verificar que tus patrones de defensa (Retry, Circuit Breaker, Fallbacks) funcionan como esperas **antes de llegar a producción**. En lugar de probar solo el "camino feliz", creas tests automatizados que simulan activamente las condiciones de fallo: una API que no responde, una base de datos lenta, una respuesta de red corrupta. A esto se le llama una forma de **Ingeniería del Caos a pequeña escala**.

#### Ejemplo Práctico

Vamos a probar automáticamente que el endpoint del **apartado 4.7** (`main_resiliente.py`) se degrada correctamente cuando el servicio de inventario falla. Usaremos `pytest` y `respx` (un mock para `httpx`).

**1. Crea tu archivo de test (`test_resiliencia.py`):**
```python
# test_resiliencia.py
import pytest
import respx
import httpx
from fastapi.testclient import TestClient
from main_resiliente import app # Importa tu app de FastAPI

# URLs de los servicios que vamos a mockear
PRODUCT_API_URL = "http://localhost:9001/products/mana-potion"
INVENTORY_API_URL = "http://localhost:9002/inventory/mana-potion"

client = TestClient(app)

@respx.mock
def test_endpoint_degrades_gracefully_when_inventory_fails():
    # 1. Mock del camino feliz para el servicio de productos (crítico)
    respx.get(PRODUCT_API_URL).mock(
        return_value=httpx.Response(200, json={"id": "mana-potion", "name": "Poción de Maná"})
    )
    
    # 2. Mock del CAMINO DE FALLO para el servicio de inventario (no crítico)
    respx.get(INVENTORY_API_URL).mock(
        return_value=httpx.Response(503) # Service Unavailable
    )

    # 3. Llama a nuestro endpoint
    response = client.get("/product-details/mana-potion")

    # 4. Verificaciones (Asserts)
    # El endpoint debe responder OK (200), no un error 5xx
    assert response.status_code == 200
    
    data = response.json()
    
    # La información del producto debe estar presente
    assert data["product_info"]["name"] == "Poción de Maná"
    
    # La información del inventario debe reflejar el estado de fallback
    assert data["inventory"]["stock"] is None
    assert "No se pudo verificar" in data["inventory"]["status"]

@respx.mock
def test_endpoint_fails_when_critical_service_fails():
    # Mock del servicio de productos fallando
    respx.get(PRODUCT_API_URL).mock(return_value=httpx.Response(500))
    # No necesitamos mockear el inventario porque la ejecución parará antes

    response = client.get("/product-details/mana-potion")

    # Si el servicio crítico falla, todo el endpoint debe fallar
    assert response.status_code == 502 # Bad Gateway
    assert "El servicio de productos falló" in response.json()["detail"]
```

#### Pruebas (ejecución con `pytest`)

En lugar de `curl`, la prueba aquí es ejecutar el motor de tests.

**Paso 1: Instala las dependencias de testing**
```bash
pip install pytest respx
```

**Paso 2: Ejecuta los tests desde tu terminal**
```bash
pytest -v
```

**Salida esperada:**
```
============================= test session starts ==============================
...
collected 2 items

test_resiliencia.py::test_endpoint_degrades_gracefully_when_inventory_fails PASSED [ 50%]
test_resiliencia.py::test_endpoint_fails_when_critical_service_fails PASSED    [100%]

============================== 2 passed in ...s ================================

```

Este resultado `PASSED` es la prueba definitiva y automatizada de que tu lógica de degradación controlada funciona exactamente como la diseñaste. Has verificado tu red de seguridad antes de que ocurra un incendio real.

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


