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
**¡Manos a la Obra (Mental)!** Define 2-3 `error_code` que usarías en una API de gestión de tareas (ej: `TAREA_NO_ENCONTRADA`, `FECHA_INVALIDA`).

---

## 4.2. Exception Handlers en FastAPI: Tus Porteros de Discoteca para Errores

FastAPI te deja poner "porteros" (Exception Handlers) que atrapan excepciones específicas y deciden cómo responder, ¡usando tu formato JSON estándar!

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

## 4.4. Patrón Retry con `tenacity`: Si a la Primera no Sale, ¡Insiste (con Gracia)!

A veces, llamar a otra API o a la BBDD falla por un instante. ¡No te rindas! Reintenta, pero con cabeza: espera un poco más cada vez (backoff exponencial) y añade un toque de azar (jitter) para no saturar.

La librería `tenacity` es tu amiga: `pip install tenacity`

```python
# cliente_externo_resistente.py
import httpx
from tenacity import retry, stop_after_attempt, wait_exponential, RetryError, retry_if_exception_type
import asyncio
import random # Para simular fallos

# --- 1. Define qué errores quieres reintentar ---
def es_error_reintentable(exception) -> bool:
    """Decide si una excepción merece un reintento."""
    # Solo reintentamos timeouts de red o errores 503 (Servicio No Disponible)
    # o errores 429 (Too Many Requests) si el servicio nos pide esperar.
    return isinstance(exception, (httpx.TimeoutException, httpx.NetworkError)) or \
           (isinstance(exception, httpx.HTTPStatusError) and \
            exception.response.status_code in [status.HTTP_503_SERVICE_UNAVAILABLE, status.HTTP_429_TOO_MANY_REQUESTS])

# --- 2. Decora tu función de llamada externa ---
@retry(
    stop=stop_after_attempt(3),  # Máximo 3 intentos (1 original + 2 reintentos)
    wait=wait_exponential(multiplier=1, min=2, max=10), # Espera 2s, luego 4s, etc. (max 10s) con jitter
    retry=retry_if_exception_type((httpx.TimeoutException, httpx.NetworkError, httpx.HTTPStatusError)), # Simplificado para este ejemplo, usar es_error_reintentable en real
    reraise=True # Si todos fallan, lanza la última excepción
)
async def llamar_api_externa_con_reintentos(url: str):
    print(f"Intentando llamar a {url}...")
    # Simular fallo de red o del servicio externo aleatoriamente
    if random.random() < 0.7: # Falla el 70% de las veces
        error_type = random.choice(["timeout", "network_error", "http_503"])
        print(f"SIMULANDO FALLO: {error_type}")
        if error_type == "timeout":
            raise httpx.TimeoutException("Simulated timeout", request=None)
        elif error_type == "network_error":
            raise httpx.NetworkError("Simulated network error", request=None)
        else: # http_503
            # Crear una respuesta simulada para HTTPStatusError
            mock_response = httpx.Response(status.HTTP_503_SERVICE_UNAVAILABLE, request=httpx.Request("GET", url))
            raise httpx.HTTPStatusError("Simulated 503", request=mock_response.request, response=mock_response)

    print(f"ÉXITO llamando a {url}")
    return {"data_externa": f"Datos de {url} recibidos!"}

# --- 3. En tu endpoint FastAPI, usa esta función ---
# En main.py (o donde tengas tu app FastAPI)
# from fastapi import FastAPI, HTTPException (ya importados antes)
# import cliente_externo_resistente (este archivo)

# app = FastAPI() ... (ya definido antes)

@app.get("/datos-externos-retry")
async def get_datos_con_retry():
    # URL de un servicio que a veces falla (puedes usar un mock server o una URL real que sepas que a veces da problemas)
    # Para simulación local, podemos apuntar a un endpoint inexistente o uno que tarde mucho
    url_externa_test = "http://un-servicio-que-a-veces-falla.com/api/data" # Cambia por algo para probar
    try:
        # Si usas la simulación de llamar_api_externa_con_reintentos, la URL no importa tanto.
        resultado = await llamar_api_externa_con_reintentos(url_externa_test)
        return resultado
    except RetryError as e: # Tenacity lanza esto si todos los reintentos fallan
        print(f"FALLO DEFINITIVO tras reintentos llamando a {url_externa_test}: {e.last_attempt.exception()}")
        # Aquí puedes acceder a e.last_attempt.exception() para saber la causa del último fallo
        last_exc = e.last_attempt.exception()
        status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        error_code_detail = "EXTERNAL_SERVICE_UNAVAILABLE"
        if isinstance(last_exc, httpx.TimeoutException):
            status_code = status.HTTP_504_GATEWAY_TIMEOUT
            error_code_detail = "EXTERNAL_SERVICE_TIMEOUT"

        # Aquí deberías usar tu handler de excepciones centralizado o una excepción personalizada
        # que sea capturada por un handler. Para simplificar, lanzamos HTTPException directamente.
        # Pero idealmente, lanzarías algo como ExternalServiceError que tu handler convierte
        # al JSON estándar.
        raise HTTPException(status_code=status_code, detail=f"El servicio externo en {url_externa_test} no está disponible tras reintentos. Causa: {str(last_exc)}")
    except Exception as e: # Otros errores no relacionados con reintentos
        print(f"Error inesperado no manejado por tenacity: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Error inesperado: {str(e)}")

```

**¡Pruébalo!**
1.  Añade el endpoint `/datos-externos-retry` a tu `main.py` de FastAPI.
2.  Ejecuta `uvicorn main:app --reload`.
3.  Llama a `GET http://localhost:8000/datos-externos-retry` varias veces.
4.  **Observa la consola:** Verás los reintentos. A veces funcionará, a veces fallará después de varios intentos (por la simulación del 70% de fallo).
5.  Presta atención a las pausas entre reintentos (serán mensajes en la consola).

**Desafío Práctico:**
* Ajusta `stop_after_attempt` y `wait_exponential` y observa cómo cambia el comportamiento.
* Modifica `es_error_reintentable` para que *no* reintente un `HTTPStatusError` si el código es 401 (No Autorizado).

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

```python
# cliente_con_circuit_breaker.py
import httpx
from pybreaker import CircuitBreaker, CircuitBreakerError
import asyncio
import random
import logging # Importa logging

# Configura un logger básico para ver los mensajes del listener
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__) # Crea un logger para este módulo

# --- 1. Un Listener para ver qué hace el breaker ---
class MiListener(pybreaker.CircuitBreakerListener):
    def state_change(self, cb, old_state, new_state):
        logger.warning(f"CIRCUIT BREAKER '{cb.name}': Estado cambió de {old_state.name} a {new_state.name}")
    def failure(self, cb, exc):
        logger.info(f"CIRCUIT BREAKER '{cb.name}': Fallo registrado. Fallos: {cb.fail_counter}")
    def success(self, cb):
        logger.info(f"CIRCUIT BREAKER '{cb.name}': Éxito registrado. Reseteando contador de fallos.")

# --- 2. Crea tu Circuit Breaker (¡uno por servicio externo que llamas!) ---
# Estos deberían ser globales o gestionados de forma centralizada, no recreados en cada request.
# fail_max: Cuántos fallos seguidos para abrir.
# reset_timeout: Cuántos segundos abierto antes de ir a semi-abierto.
servicio_X_breaker = CircuitBreaker(
    fail_max=3,
    reset_timeout=20, # 20 segundos
    listeners=[MiListener()],
    name="ServicioX" # Dale un nombre para los logs
)

# --- 3. Decora tu función de llamada externa ---
# O usa @servicio_X_breaker para la forma de decorador programático:
# @servicio_X_breaker
async def llamar_a_servicio_X_protegido(url: str):
    print(f"Intentando llamar a {url} (protegido por Circuit Breaker)...")
    # Simular fallo del servicio X aleatoriamente
    if servicio_X_breaker.current_state == "open": # Solo para simulación, en real no harías esto aquí
        print(f"SIMULACIÓN DENTRO DE FUNCIÓN: Breaker para {url} está ABIERTO. No se llamará.")
        # La llamada ni se haría si el breaker está abierto y se usa como decorador.
        # Si se llama programáticamente, la excepción CircuitBreakerError se lanzaría antes.

    if random.random() < 0.6: # Falla el 60% de las veces
        print(f"SIMULANDO FALLO en {url}")
        raise httpx.RequestError(f"Simulated RequestError para {url}", request=None)

    print(f"ÉXITO llamando a {url}")
    return {"data_servicio_x": f"Datos de {url}!"}

# --- 4. En tu endpoint FastAPI, usa la llamada protegida ---
# En main.py (o donde tengas tu app FastAPI)
# from fastapi import FastAPI, HTTPException (ya importados)
# import cliente_con_circuit_breaker (este archivo)

# app = FastAPI() ... (ya definido)

@app.get("/datos-servicio-x-cb")
async def get_datos_de_servicio_x_cb():
    url_servicio_x = "http://servicio-x-que-falla-mucho.com/api" # Cambia por algo para probar
    try:
        # Forma programática de usar el breaker (más control para el ejemplo)
        # Para el decorador, simplemente llamarías a la función decorada.
        resultado = await servicio_X_breaker.call_async(llamar_a_servicio_X_protegido, url_servicio_x)
        return resultado
    except CircuitBreakerError as e:
        logger.error(f"CIRCUIT BREAKER ABIERTO para {url_servicio_x}: {e}")
        # Idealmente, lanzarías tu excepción de negocio/infra que el handler convierte a JSON estándar
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Servicio X no disponible (Circuito Abierto). Intenta más tarde."
        )
    except httpx.RequestError as e: # Si el breaker está cerrado pero la llamada falla
        logger.error(f"Error de red llamando a {url_servicio_x} (breaker registrará fallo): {e}")
        # Este error será contado por el breaker. Si se repite, abrirá el circuito.
        # Aquí también, lanzarías tu excepción centralizada.
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Error contactando Servicio X: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Error inesperado llamando a {url_servicio_x}: {e}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e))

```

**¡Pruébalo!**
1.  Añade el endpoint `/datos-servicio-x-cb` a tu `main.py`.
2.  Ejecuta `uvicorn main:app --reload`.
3.  Llama a `GET http://localhost:8000/datos-servicio-x-cb` repetidamente.
4.  **Observa la consola (y los logs de MiListener!):**
    * Al principio, verás intentos de llamada. Algunos fallarán (simulado).
    * Después de `fail_max` (3) fallos, el listener te dirá: "Estado cambió de CLOSED a OPEN".
    * Las siguientes llamadas fallarán *instantáneamente* con el error 503 del `CircuitBreakerError`.
    * Espera `reset_timeout` (20) segundos. El listener dirá: "Estado cambió de OPEN a HALF_OPEN".
    * La siguiente llamada se permitirá. Si tiene éxito (¡baja la probabilidad de fallo en el random.random() para probar esto!), el listener dirá "Estado cambió de HALF_OPEN a CLOSED". Si falla, volverá a OPEN.

**Desafío Práctico:**
* Juega con `fail_max` y `reset_timeout`. ¿Cómo afecta el comportamiento?
* En `llamar_a_servicio_X_protegido`, en lugar de lanzar `httpx.RequestError`, lanza una excepción tuya (ej: `ServicioXError`). Configura `pybreaker` para que solo cuente esa excepción como fallo usando `expected_exception` en el constructor de `CircuitBreaker`.

---
## 4.7. Endpoints Resilientes

Tu endpoint FastAPI es un héroe, ¡pero no invencible! Si depende de otros para funcionar, debe saber qué hacer cuando esos otros fallan.

**Estrategias Prácticas:**

1.  **Timeouts Agresivos (¡Ya los vimos!):** Usa `httpx.Timeout` en tus clientes. No esperes eternamente.
2.  **Fallbacks (Plan B):** Si el servicio de recomendaciones falla, ¿puedes mostrar la página de producto sin ellas? O con recomendaciones cacheadas/por defecto?

    ```python
    # En tu servicio de aplicación (no en el endpoint FastAPI directamente)
    # async def get_product_page_data(product_id: str, user_id: str):
    #     producto = await self.product_repo.get_by_id(product_id)
    #     if not producto: raise RecursoNoEncontradoError(...)

    #     try:
    #         # Esta llamada usa cliente con Retry y Circuit Breaker
    #         recomendaciones = await self.reco_service_client.get_for_product(product_id, user_id)
    #     except (CircuitBreakerError, httpx.HTTPError) as e: # O tu ExternalServiceError
    #         logger.warning(f"Recomendaciones no disponibles para {product_id}. Usando fallback. Error: {e}")
    #         recomendaciones = [{"id": "default1", "nombre": "Producto Popular 1"}] # Fallback!

    #     return {"producto": producto, "recomendaciones": recomendaciones}
    ```
3.  **Degradación Agraciada:** Es el resultado del fallback. El servicio sigue funcionando, pero quizás con menos funcionalidades. ¡Mejor eso que un error 500 total!
4.  **Health Checks (`/health`):**
    * **Shallow (`/health/live`):** ¿Está FastAPI vivo? Devuelve 200 OK.
    * **Deep (`/health/ready`):** ¿Están *mis dependencias críticas* (BBDD, API clave) vivas? Si no, devuelve 503. Kubernetes usa esto para saber si mandar tráfico o reiniciar.

**¡Pruébalo! (Conceptual con tu código anterior):**
* En el endpoint que llama al `servicio_X_breaker`, si se lanza `CircuitBreakerError`, en lugar de un 503, devuelve un 200 OK con `{"data_servicio_x": null, "message": "Datos de Servicio X no disponibles temporalmente"}`. ¡Eso es degradación!

---

## 4.8. Logs con `trace_id`

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
    # logger = logging.getLogger(__name__) # Configurado para JSON y con filtro/adapter para trace_id

    # @app.get("/algun-endpoint")
    # async def mi_endpoint(request: Request):
    #     trace_id = getattr(request.state, "trace_id", "N/A")
    #     logger.info(f"Procesando endpoint (RID: {trace_id})", extra={"trace_id_field": trace_id})
    #     # ... tu lógica ...
    #     if algo_malo_pero_no_excepcion:
    #          logger.warning(f"Algo raro pasó (RID: {trace_id})", extra={"trace_id_field": trace_id, "detalle": "info extra"})
    #     return {"ok": True}
    ```
* **Propagación:** Cuando tu servicio FastAPI llame a *otro* servicio, ¡pasa el `trace_id` en las cabeceras de esa nueva petición!

**¡Pruébalo!**
* Asegúrate que el middleware de 4.2 está activo.
* En tus endpoints, añade logs (un simple `print` con el `trace_id` de `request.state.trace_id` sirve para esta prueba rápida).
* Llama a tus endpoints y verifica que el `trace_id` aparece en la consola y en las cabeceras de respuesta.

---

## 4.9. Dashboards de Errores

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

## 4.10. Simular Fallos

¿Cómo sabes que tus Retries, Circuit Breakers y Fallbacks funcionan? ¡Provocándolos!

**En FastAPI (Pruebas de Integración con `pytest`):**

Usa `app.dependency_overrides` para inyectar un "cliente falso" que simule fallos cuando tu endpoint lo llame.

```python
# tests/test_resiliencia_endpoints.py (requiere pytest, httpx)
# from fastapi.testclient import TestClient
# from main import app # Tu app FastAPI
# from app.dependencies import get_servicio_x_client # Tu dependencia original
# from app.clients.base import BaseServicioXClient # Clase base de tu cliente

# class MockServicioXFallaSiempre(BaseServicioXClient): # Implementa la interfaz de tu cliente real
#     async def get_data(self, param: str) -> dict:
#         print("MOCK SERVICIO X: Simulando fallo siempre...")
#         raise httpx.RequestError("Mock: Fallo de red en Servicio X", request=None)

# class MockServicioXFallaAlPrincipioLuegoOk(BaseServicioXClient):
#     intentos = 0
#     max_fallos = 2 # Falla las primeras 2 veces
#     async def get_data(self, param: str) -> dict:
#         MockServicioXFallaAlPrincipioLuegoOk.intentos += 1
#         if MockServicioXFallaAlPrincipioLuegoOk.intentos <= MockServicioXFallaAlPrincipioLuegoOk.max_fallos:
#             print(f"MOCK SERVICIO X (Falla/Ok): Intento {MockServicioXFallaAlPrincipioLuegoOk.intentos}, simulando fallo...")
#             raise httpx.RequestError("Mock: Fallo temporal en Servicio X", request=None)
#         print(f"MOCK SERVICIO X (Falla/Ok): Intento {MockServicioXFallaAlPrincipioLuegoOk.intentos}, simulando ÉXITO!")
#         return {"data_mock": "Datos del mock exitosos!"}


# client = TestClient(app)

# def test_endpoint_con_servicio_x_cb_abierto():
#     # Configura el breaker para que se abra rápido para el test
#     # Esto es un poco más complejo de testear unitariamente sin acceso directo al breaker global.
#     # Una opción es tener un breaker por test o resetearlo.
#     # Para este ejemplo, asumimos que podemos manipular el breaker o que el test lo llevará a OPEN.

#     app.dependency_overrides[get_servicio_x_client] = lambda: MockServicioXFallaSiempre()
#     print("\n--- Testeando Circuit Breaker (esperamos que se abra) ---")
#     # Llamar varias veces para abrir el circuit breaker (según fail_max del breaker)
#     for i in range(servicio_X_breaker.fail_max + 1): # +1 para asegurar que intentó abrirse
#         print(f"Llamada {i+1} para intentar abrir CB...")
#         response = client.get("/datos-servicio-x-cb") # Asume que este endpoint usa el cliente que estamos mockeando
#         if servicio_X_breaker.is_open:
#             assert response.status_code == status.HTTP_503_SERVICE_UNAVAILABLE # CB Abierto
#             assert "Circuito Abierto" in response.json()["detail"]
#             print(f"CB ABIERTO como se esperaba en llamada {i+1}!")
#             break
#     else: # Si el bucle termina sin break
#         assert False, f"El Circuit Breaker no se abrió después de {servicio_X_breaker.fail_max + 1} llamadas fallidas."

#     app.dependency_overrides = {} # Limpiar

# def test_endpoint_con_retry_y_luego_exito():
#     # Reiniciar contador de intentos del mock para este test
#     MockServicioXFallaAlPrincipioLuegoOk.intentos = 0
#     # Asegúrate que el breaker esté cerrado al inicio de este test o usa un breaker diferente.
#     # Aquí asumimos que el breaker se resetea o es diferente.
#     # Para un test real, el estado del breaker entre tests puede ser un problema.
#     # Resetear el breaker o usar uno nuevo por test es más robusto.
#     # servicio_X_breaker.close() # Ejemplo de reset, si el breaker lo permite

#     # Esta prueba es para el endpoint /datos-externos-retry que usa tenacity
#     app.dependency_overrides[llamar_api_externa_con_reintentos_dependency] = lambda: MockServicioXFallaAlPrincipioLuegoOk() # Asumiendo que tienes una dependencia para esto
#     print("\n--- Testeando Retry (esperamos éxito después de fallos) ---")
#     response = client.get("/datos-externos-retry") # Este endpoint usa tenacity
#     assert response.status_code == status.HTTP_200_OK
#     assert response.json()["data_mock"] == "Datos del mock exitosos!"
#     print(f"ÉXITO con Retry después de {MockServicioXFallaAlPrincipioLuegoOk.intentos} intentos totales.")
#     app.dependency_overrides = {}
```
**(Nota: El código de testeo anterior es conceptual y avanzado. Testear Circuit Breakers y Retries de forma aislada y fiable en tests de integración requiere un buen manejo del estado de estos componentes entre tests o el uso de mocks más sofisticados. Para `tenacity`, podrías mockear `httpx.AsyncClient` directamente en el módulo donde se usa).**

**Herramientas Más Pro (Fuera de FastAPI puro):**
* **Toxiproxy:** Un proxy que pones entre tu servicio y sus dependencias para inyectar latencia, errores de red, etc., ¡sin tocar tu código!
* **Chaos Mesh / LitmusChaos (para Kubernetes):** Para "romper" cosas a nivel de infraestructura.

---

¡Y eso es todo, guerrero de la resiliencia! Has pasado de entender los errores a **anticiparlos, manejarlos, aprender de ellos y probar tus defensas**. Con estas herramientas y mentalidad, tus microservicios FastAPI no solo serán funcionales, sino **auténticas fortalezas digitales**. ¡A construir con calidad y confianza!

## 4.7. Diseño de Endpoints Resilientes

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

# if __name__ == "__main__":
#     uvicorn.run("main_resiliente:app", host="0.0.0.0", port=8000, reload=True)
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

## 4.8. Captura y Log de Trazas con Contexto

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

# if __name__ == "__main__":
#     uvicorn.run("main_trazabilidad:app", host="0.0.0.0", port=8001, reload=True)
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

## 4.9. Visibilidad de Errores con Dashboards

No podemos crear un dashboard Grafana aquí, pero sí podemos generar las **métricas** que alimentarían uno. Usaremos `prometheus-client` (¡instálalo!: `pip install prometheus-client`).

**Escenario Práctico:** Un endpoint FastAPI que cuenta las peticiones HTTP y los errores 5xx, exponiéndolos para Prometheus.

```python
# main_metricas.py
from fastapi import FastAPI, Request, HTTPException, status
from prometheus_client import Counter, Histogram, make_asgi_app # Para métricas
import time
import random
import uvicorn
import uuid # Para el trace_id (reutilizamos el middleware)

# --- Middleware para Trace ID (copiado de main_trazabilidad.py para completitud) ---
# (Opcional para este ejemplo de métricas, pero bueno para la consistencia)
app = FastAPI(title="API con Métricas Prometheus")

@app.middleware("http")
async def trace_id_middleware_metrics(request: Request, call_next):
    trace_id = request.headers.get("X-Trace-ID") or str(uuid.uuid4())
    request.state.trace_id = trace_id
    response = await call_next(request)
    response.headers["X-Trace-ID"] = trace_id
    return response

# --- Métricas Prometheus ---
# Contador para peticiones HTTP totales, desglosado por método y path
PETICIONES_HTTP_TOTAL = Counter(
    "http_requests_total_app", # Nombre de la métrica
    "Total de peticiones HTTP recibidas por la aplicación", # Descripción
    ["method", "path", "status_code"] # Etiquetas (dimensions)
)

# Histograma para la latencia de las peticiones
LATENCIA_PETICIONES_HTTP_SEGUNDOS = Histogram(
    "http_request_duration_seconds_app",
    "Latencia de las peticiones HTTP en segundos",
    ["method", "path"]
)

# Middleware para registrar métricas de cada petición
@app.middleware("http")
async def registrar_metricas_middleware(request: Request, call_next):
    start_time = time.time()
    
    # Intentar obtener el path real, no el completo con parámetros
    # Para plantillas de ruta de FastAPI, esto puede ser más complejo de obtener aquí.
    # Starlette expone request.scope.get('route').path si hay una ruta macheada.
    path_template = request.scope.get('path') # Default a path crudo
    if request.scope.get('root_path') and request.scope.get('path').startswith(request.scope.get('root_path')):
         path_template = request.scope.get('path')[len(request.scope.get('root_path')):]

    if hasattr(request, "url_for") and request.scope.get('route'):
         path_template = request.scope['route'].path # Mejor, usa la plantilla de la ruta

    try:
        response = await call_next(request)
        status_code_for_metric = response.status_code
        return response
    except Exception as e:
        # Si una excepción no manejada llega aquí (debería ser raro con buenos handlers)
        status_code_for_metric = status.HTTP_500_INTERNAL_SERVER_ERROR
        raise e # Relanzar para que los handlers de FastAPI la procesen
    finally:
        process_time = time.time() - start_time
        # Registrar latencia
        LATENCIA_PETICIONES_HTTP_SEGUNDOS.labels(
            method=request.method,
            path=path_template # Usar la plantilla de ruta
        ).observe(process_time)
        # Registrar contador de peticiones
        PETICIONES_HTTP_TOTAL.labels(
            method=request.method,
            path=path_template, # Usar la plantilla de ruta
            status_code=status_code_for_metric
        ).inc()


# --- Endpoint que a veces falla ---
@app.get("/datos-aleatorios")
async def get_datos_aleatorios():
    if random.random() < 0.2: # 20% de probabilidad de error 500
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Fallo aleatorio simulado")
    elif random.random() < 0.4: # Otro 20% (total 40% de no 200) de error 400
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Petición mala simulada")
    return {"data": "Todo bien!", "numero_aleatorio": random.randint(1,100)}

# --- Montar la app de métricas de Prometheus ---
# Esto expone un endpoint /metrics que Prometheus puede scrapear
app_metricas_prometheus = make_asgi_app()
app.mount("/metrics", app_metricas_prometheus)

# if __name__ == "__main__":
#     uvicorn.run("main_metricas:app", host="0.0.0.0", port=8002, reload=True)
```

**¡Pruébalo!**
1.  Guarda como `main_metricas.py`. Necesitas `prometheus-client`.
2.  Ejecuta: `uvicorn main_metricas:app --reload --port 8002`
3.  Llama a `GET http://localhost:8002/datos-aleatorios` varias veces. Algunas darán 200, otras 500, otras 400.
4.  Ahora, ve a `http://localhost:8002/metrics` en tu navegador.
    * Verás un montón de texto. Busca `http_requests_total_app` y `http_request_duration_seconds_app`.
    * Verás cómo se incrementan los contadores y se registran las latencias, ¡con etiquetas (labels) para método, path y código de estado!
    * Esto es lo que Prometheus "scrapearía" y tú visualizarías en Grafana para ver:
        * `sum(rate(http_requests_total_app{status_code=~"5.."}[5m]))` (Tasa de errores 5xx)
        * `histogram_quantile(0.95, sum(rate(http_request_duration_seconds_app_bucket[5m])) by (le, path))` (Latencia P95 por path)

**Claves para Dashboards Aquí:**
* **Métricas Clave:** Peticiones, errores, latencia (los Golden Signals).
* **Etiquetas (Labels):** Permiten filtrar y agregar (ej. errores *solo* del endpoint `/datos-aleatorios`).
* **Prometheus `make_asgi_app()`:** La forma fácil de exponer métricas en FastAPI.

---

## 4.10. Pruebas de Fallos

¿Cómo sabes que tu Circuit Breaker (de 4.6) o tu Fallback (de 4.7) realmente funcionan? ¡Simulando el fallo en un test! FastAPI y `pytest` son tus aliados.

**Escenario Práctico:** Testear el endpoint `/productos/{product_id}/detalles` de `main_resiliente.py` (sección 4.7). Vamos a simular que el servicio de opiniones *siempre* falla o *siempre* da timeout, y verificar que el endpoint principal sigue devolviendo los datos del producto.

```python
# test_main_resiliente.py
# Asegúrate que main_resiliente.py esté en la misma carpeta o PYTHONPATH
# Necesitas: pip install pytest httpx

from fastapi.testclient import TestClient
from main_resiliente import app, get_opiniones_from_service # Importa la app y la función a mockear
import httpx # Para el RequestError
import asyncio # Para el TimeoutError

client = TestClient(app)

# --- Mock del servicio de opiniones que SIEMPRE falla con RequestError ---
async def mock_opiniones_falla_request_error(product_id: str, current_trace_id: str):
    print(f"MOCK OPINIONES (RequestError): Se pidió para {product_id}, simulando fallo.")
    raise httpx.RequestError("Mock: Fallo de red en servicio de opiniones", request=None)

# --- Mock del servicio de opiniones que SIEMPRE da Timeout ---
async def mock_opiniones_falla_timeout(product_id: str, current_trace_id: str):
    print(f"MOCK OPINIONES (Timeout): Se pidió para {product_id}, simulando timeout.")
    # Para que asyncio.wait_for lance TimeoutError, la corrutina debe tardar más que el timeout
    # Aquí, para asegurar que el wait_for del endpoint (0.5s) salte, hacemos que esta tarde un poco más.
    await asyncio.sleep(1) # Tarda 1 segundo, el endpoint espera solo 0.5s
    return [] # Nunca se llegará aquí si el timeout del endpoint es menor

def test_producto_detalles_cuando_opiniones_fallan_con_request_error():
    # Sobrescribimos la dependencia 'get_opiniones_from_service' con nuestro mock
    app.dependency_overrides[get_opiniones_from_service] = mock_opiniones_falla_request_error
    
    response = client.get("/productos/P001/detalles")
    
    app.dependency_overrides = {} # ¡MUY IMPORTANTE limpiar el override después del test!

    assert response.status_code == 200
    data = response.json()
    assert data["producto"]["id"] == "P001"
    assert data["opiniones"] == [] # Fallback a lista vacía
    assert "Opiniones no disponibles temporalmente (fallo de servicio)" in data["aviso_degradacion"]
    print("TEST (RequestError): Pasó OK. Producto devuelto, opiniones degradadas.")

def test_producto_detalles_cuando_opiniones_dan_timeout():
    app.dependency_overrides[get_opiniones_from_service] = mock_opiniones_falla_timeout
    
    response = client.get("/productos/P001/detalles")
    
    app.dependency_overrides = {}

    assert response.status_code == 200
    data = response.json()
    assert data["producto"]["id"] == "P001"
    assert data["opiniones"] == []
    assert "Opiniones no disponibles temporalmente (timeout)" in data["aviso_degradacion"]
    print("TEST (Timeout): Pasó OK. Producto devuelto, opiniones degradadas por timeout.")

def test_producto_no_encontrado_sigue_dando_404():
    # No necesitamos mockear opiniones aquí porque fallará antes
    response = client.get("/productos/P_NO_EXISTE/detalles")
    assert response.status_code == 404
    assert "Producto P_NO_EXISTE no encontrado" in response.json()["detail"]
    print("TEST (404): Pasó OK. Producto no existente gestionado correctamente.")

# Para ejecutar:
# 1. Guarda este archivo como test_main_resiliente.py en la misma carpeta que main_resiliente.py
# 2. Desde la terminal, en esa carpeta, ejecuta: pytest
# (Asegúrate de que uvicorn NO esté corriendo main_resiliente.py mientras corres los tests,
#  ya que TestClient inicia su propia instancia de la app)
```

**¡Pruébalo!**
1.  Guarda `main_resiliente.py` y `test_main_resiliente.py` en la misma carpeta.
2.  Instala `pytest`: `pip install pytest`
3.  Desde la terminal, en esa carpeta, ejecuta: `pytest` o `pytest -s` (para ver los prints).
4.  Verás cómo los tests pasan, demostrando que tu endpoint maneja los fallos del servicio de opiniones y se degrada correctamente.

**Claves para Probar Fallos Aquí:**
* `TestClient`: Para llamar a tu API FastAPI como si fueras un cliente HTTP.
* `app.dependency_overrides`: El truco de FastAPI para reemplazar dependencias (como tu función `get_opiniones_from_service`) con Mocks durante los tests. Esto te da control total sobre lo que hacen tus dependencias.
* **Aserciones Específicas:** Verifica no solo el código de estado, sino también el cuerpo de la respuesta para asegurar que la degradación o el manejo de errores es el esperado.

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


