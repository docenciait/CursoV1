# Tema 4. MANEJO DE ERRORES Y CIRCUIT BREAKERS EN MICROSERVICIOS

## Tabla de Contenidos

- [Tema 4. MANEJO DE ERRORES Y CIRCUIT BREAKERS EN MICROSERVICIOS](#tema-4-manejo-de-errores-y-circuit-breakers-en-microservicios)
  - [Tabla de Contenidos](#tabla-de-contenidos)
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



---

## 4.1 Diseño de estrategia global de manejo de errores 

En arquitecturas de microservicios, donde una solicitud puede atravesar múltiples servicios antes de completarse, el manejo robusto de errores y la implementación de patrones de resiliencia no son opcionales, sino fundamentales para la estabilidad y fiabilidad del sistema. Un fallo en un servicio no debería provocar un colapso en cascada de otros servicios. Este tema explora estrategias y patrones para construir microservicios resilientes, con un enfoque práctico en FastAPI.

Una estrategia global de manejo de errores es la base para construir
sistemas comprensibles, mantenibles y resilientes. Su ausencia conduce a
inconsistencias, dificultad en la depuración y una pobre experiencia
para los desarrolladores y usuarios.

**Importancia:**

-   **Consistencia:** Los clientes (sean otros servicios o interfaces de
    usuario) reciben errores de una manera predecible,
    independientemente del servicio que origine el fallo.
-   **Depuración:** Facilita el rastreo de problemas a través de
    múltiples servicios.
-   **Monitorización y Alertas:** Permite agregar y analizar errores de
    forma centralizada para identificar problemas sistémicos.
-   **Experiencia del Desarrollador (DX) y del Usuario (UX):** Errores
    claros y accionables mejoran la DX. Para los usuarios, mensajes de
    error comprensibles (o una degradación elegante) son preferibles a
    fallos crípticos.

**Aspectos Clave a Definir:**

1.  **Formato de Error Estandarizado:**
    -   Para APIs REST, un formato común es **JSON Problem Details (RFC
        7807)**. Define campos estándar como `type` (un URI que
        identifica el tipo de problema), `title` (un resumen legible),
        `status` (el código de estado HTTP), `detail` (una explicación
        específica) e `instance` (un URI que identifica la ocurrencia
        específica del problema).
    -   Ejemplo de respuesta RFC 7807:
        `json     {       "type": "[https://example.com/probs/out-of-credit](https://example.com/probs/out-of-credit)",       "title": "You do not have enough credit.",       "status": 403,       "detail": "Your current balance is 30, but that costs 50.",       "instance": "/account/12345/msgs/abc"     }`
    -   Independientemente del estándar elegido, debe ser consistente en
        todos los microservicios.
2.  **Uso Semántico de Códigos de Estado HTTP:**
    -   Utilizar los códigos de estado HTTP de manera correcta es
        fundamental para la comunicación REST.
        -   `2xx`: Éxito (ej. `200 OK`, `201 Created`,
            `204 No Content`).
        -   `4xx`: Errores del cliente (ej. `400 Bad Request`,
            `401 Unauthorized`, `403 Forbidden`, `404 Not Found`,
            `422 Unprocessable Entity`, `429 Too Many Requests`).
        -   `5xx`: Errores del servidor (ej.
            `500 Internal Server Error`, `502 Bad Gateway`,
            `503 Service Unavailable`, `504 Gateway Timeout`).
3.  **Logging Detallado:**
    -   Cada error debe ser registrado con suficiente contexto:
        -   Timestamp.
        -   Identificador del servicio y la instancia.
        -   **Correlation ID (ID de Correlación) / Trace ID:** Un
            identificador único que se propaga a través de todas las
            llamadas de una solicitud entre microservicios. Esencial
            para rastrear el flujo completo de una operación.
        -   Detalles de la solicitud (endpoint, método, parámetros
            relevantes, usuario si aplica).
        -   Tipo de error, mensaje y stack trace completo (para errores
            técnicos).
        -   Contexto específico de la aplicación.
    -   Utilizar logging estructurado (ej. JSON) para facilitar el
        análisis por herramientas de agregación de logs.
4.  **Distinción entre Errores de Usuario/Negocio y Errores
    Internos/Técnicos:**
    -   Los errores de negocio (ej. \"saldo insuficiente\") deben ser
        comunicados de forma clara al cliente, a menudo con códigos 4xx.
    -   Los errores técnicos (ej. fallo de conexión a base de datos)
        deben ser registrados con detalle para depuración interna, pero
        se debe evitar exponer información sensible o detalles de
        implementación al cliente final (generalmente un error 5xx
        genérico es suficiente para el cliente, mientras el log interno
        tiene los detalles).
5.  **Manejo de Errores en Comunicación Asíncrona:**
    -   Cuando se usa mensajería (colas, pub/sub), la estrategia debe
        contemplar:
        -   **Dead Letter Queues (DLQs):** Para mensajes que no pueden
            ser procesados repetidamente.
        -   **Reintentos en el consumidor:** Con backoff y políticas
            para evitar el envenenamiento de la cola.
        -   **Alertas y monitorización de DLQs.**
        -   Esquemas de eventos que pueden incluir campos para
            información de error si un evento representa el resultado de
            una operación fallida.
6.  **Propagación vs. Abstracción de Errores:**
    -   Un servicio no siempre debe propagar ciegamente el error exacto
        de un servicio dependiente. Puede ser más apropiado abstraerlo a
        un error más genérico o relevante para su propio contrato API.
        Por ejemplo, si el servicio de usuarios devuelve un 500, el
        servicio de pedidos que depende de él podría devolver un 503
        (\"Servicio de Pedidos temporalmente degradado\") o un 500
        propio, registrando internamente la causa raíz.

**Estrategia para FastAPI:**

-   Aprovechar los manejadores de excepciones de FastAPI para
    implementar respuestas de error estandarizadas.
-   Definir excepciones personalizadas que mapeen a los formatos de
    error y códigos HTTP deseados.

## 4.2 Implementación de controladores de excepciones personalizados en FastAPI 

FastAPI proporciona un sistema flexible para manejar excepciones,
permitiendo centralizar la lógica de cómo se traducen las excepciones en
respuestas HTTP.

**Manejo de Excepciones por Defecto en FastAPI:**

-   `HTTPException`: Si lanzas una `HTTPException` desde tu código,
    FastAPI la captura y genera una respuesta HTTP con el `status_code`
    y `detail` especificados.
-   `RequestValidationError`: Cuando los datos de una solicitud (cuerpo,
    query params, path params) fallan la validación de Pydantic, FastAPI
    lanza esta excepción y devuelve una respuesta HTTP 422 con detalles
    sobre los errores de validación.

**Controladores de Excepciones Personalizados:** Se utiliza el decorador
`@app.exception_handler(NombreDeLaExcepcion)` para registrar una función
que manejará un tipo específico de excepción.

1.  **Crear Excepciones Personalizadas:** Es una buena práctica definir
    tus propias clases de excepción, especialmente para errores de
    negocio.
:::

::: {.cell .code id="gZISL_ue6evI"}
``` python
# en exceptions.py o similar
    class InsufficientFundsError(Exception):
        def __init__(self, account_id: str, needed: float, balance: float):
            self.account_id = account_id
            self.needed = needed
            self.balance = balance
            super().__init__(f"Account {account_id} needs {needed} but only has {balance}.")

    class ProductNotFoundError(Exception):
        def __init__(self, product_id: str):
            self.product_id = product_id
            super().__init__(f"Product {product_id} not found.")
```
:::

::: {.cell .markdown id="XFtqCRz36evK"}
1.  **Implementar los Manejadores:** Estas funciones toman la `Request`
    y la `Exception` como argumentos y deben devolver una `Response` (o
    una subclase como `JSONResponse`).
:::

::: {.cell .code id="RM0MD3S16evK"}
``` python
from fastapi import FastAPI, Request, status
    from fastapi.responses import JSONResponse
    from fastapi.exceptions import RequestValidationError # Para sobrescribir el default
    from pydantic import BaseModel
    import traceback # Para log de stack traces completos

    # --- Definición de excepciones personalizadas (para el ejemplo en un solo archivo) ---
    class InsufficientFundsError(Exception): # Hereda de Exception base de Python
        def __init__(self, account_id: str, needed: float, balance: float):
            self.account_id = account_id
            self.needed = needed
            self.balance = balance
            self.detail = f"Account {account_id} needs {needed} but only has {balance}."
            super().__init__(self.detail)

    class ProductNotFoundError(Exception): # Hereda de Exception base de Python
        def __init__(self, product_id: str):
            self.product_id = product_id
            self.detail = f"Product {product_id} not found."
            super().__init__(self.detail)
    # --- Fin excepciones personalizadas ---

    # --- Modelo para error RFC 7807 (Problem Details) ---
    class ProblemDetail(BaseModel):
        type: str | None = None # Un URI que identifica el tipo de problema
        title: str             # Un resumen legible por humanos
        status: int            # El código de estado HTTP
        detail: str            # Una explicación específica de esta ocurrencia del problema
        instance: str | None = None # Un URI que identifica la ocurrencia específica del problema

    app = FastAPI()

    @app.exception_handler(InsufficientFundsError)
    async def insufficient_funds_exception_handler(request: Request, exc: InsufficientFundsError):
        problem = ProblemDetail(
            type="[https://example.com/probs/insufficient-funds](https://example.com/probs/insufficient-funds)", # Ejemplo de URI de tipo de problema
            title="Insufficient Funds",
            status=status.HTTP_403_FORBIDDEN,
            detail=exc.detail,
            instance=str(request.url)
        )
        return JSONResponse(
            status_code=status.HTTP_403_FORBIDDEN,
            content=problem.model_dump(exclude_none=True), # exclude_none para no enviar campos opcionales si son None
        )

    @app.exception_handler(ProductNotFoundError)
    async def product_not_found_exception_handler(request: Request, exc: ProductNotFoundError):
        problem = ProblemDetail(
            type="[https://example.com/probs/product-not-found](https://example.com/probs/product-not-found)",
            title="Product Not Found",
            status=status.HTTP_404_NOT_FOUND,
            detail=exc.detail,
            instance=str(request.url)
        )
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content=problem.model_dump(exclude_none=True),
        )

    # Opcional: Sobrescribir el manejador de errores de validación de FastAPI para usar el formato ProblemDetail
    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError):
        error_messages = []
        for error in exc.errors():
            field = " -> ".join(map(str, error["loc"])) # ej: "body -> items -> 0 -> price"
            message = error["msg"]
            error_messages.append(f"Field '{field}': {message}")

        formatted_detail = "Validation error(s): " + "; ".join(error_messages)

        problem = ProblemDetail(
            type="[https://example.com/probs/validation-error](https://example.com/probs/validation-error)",
            title="Validation Error",
            status=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=formatted_detail,
            instance=str(request.url)
        )
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content=problem.model_dump(exclude_none=True),
        )

    # Manejador genérico para excepciones no capturadas (errores técnicos inesperados)
    # Este debe ser el último manejador registrado o puede capturar excepciones que otros deberían manejar.
    # Una mejor práctica es registrarlo para Exception, pero asegurarse de que excepciones más específicas
    # (HTTPException, RequestValidationError, tus custom exceptions) se registren ANTES.
    @app.exception_handler(Exception)
    async def generic_exception_handler(request: Request, exc: Exception):
        # Loggear el error detalladamente en el servidor
        # Esto es crucial para la depuración de errores 5xx
        print(f"Unhandled Internal Server Error on path {request.url.path}:")
        traceback.print_exception(type(exc), exc, exc.__traceback__) # Imprime el stack trace a la consola/log

        # No exponer detalles internos de la excepción al cliente para errores 500
        problem = ProblemDetail(
            type="[https://example.com/probs/internal-server-error](https://example.com/probs/internal-server-error)",
            title="Internal Server Error",
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An unexpected error occurred on the server. Please try again later.",
            instance=str(request.url)
        )
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content=problem.model_dump(exclude_none=True),
        )

    # --- Endpoints de ejemplo para probar ---
    @app.get("/products/{product_id}")
    async def get_product(product_id: str):
        if product_id == "existent_product_123":
            return {"product_id": product_id, "name": "Awesome Product"}
        elif product_id == "non_existent_product_456":
            raise ProductNotFoundError(product_id=product_id)
        else: # Simular un error técnico no manejado específicamente
            # Esto será capturado por el generic_exception_handler
            result = 1 / 0
            return {"result": result} # Nunca se alcanzará

    class OrderPayload(BaseModel):
        account_id: str
        amount_needed: float
        current_balance: float

    @app.post("/orders")
    async def create_order(order: OrderPayload):
        if order.amount_needed > order.current_balance:
            raise InsufficientFundsError(
                account_id=order.account_id,
                needed=order.amount_needed,
                balance=order.current_balance
            )
        return {"message": "Order placed successfully", "account_id": order.account_id}

    class ItemForValidation(BaseModel):
        name: str
        price: float > 0 # Validación de Pydantic

    @app.post("/items_validation")
    async def create_item_for_validation(item: ItemForValidation):
        # Si el payload es incorrecto (ej. price = -5), RequestValidationError será lanzado
        # y manejado por validation_exception_handler (si está registrado)
        return item
```
:::

::: {.cell .markdown id="CiDjYHET6evL"}
**Estructura y Mantenibilidad:**

-   Colocar las excepciones personalizadas en un módulo separado (ej.
    `app/core/exceptions.py` o `app/exceptions/business_exceptions.py`).
-   Colocar los manejadores de excepciones en un módulo dedicado (ej.
    `app/core/exception_handlers.py`) y luego importarlos y registrarlos
    en la instancia principal de la aplicación FastAPI (`main.py`).
-   Utilizar una clase base común para las excepciones de negocio si
    comparten lógica o datos (ej. todas heredan de
    `BusinessRuleViolationError`).

## 4.3 Definición de errores de negocio vs errores técnicos 

Distinguir entre estos dos tipos de errores es crucial para la claridad,
el manejo por parte del cliente y la monitorización.

-   **Errores Técnicos (o de Sistema / Infraestructura):**
    -   **Definición:** Fallos que impiden que el sistema funcione
        correctamente debido a problemas en el código, la
        infraestructura subyacente o las dependencias críticas. No están
        relacionados con la lógica de negocio específica que el usuario
        intenta ejecutar, sino con la capacidad del sistema para
        ejecutar *cualquier* lógica.
    -   **Ejemplos:**
        -   Errores de programación no capturados (ej. `AttributeError`,
            `TypeError`, `IndexOutOfBound`, `ZeroDivisionError`).
        -   Fallo de conexión a la base de datos o a la caché.
        -   Servicio dependiente inaccesible (timeout de red, DNS no
            resuelve, conexión rechazada).
        -   Agotamiento de recursos del servidor (memoria, disco, CPU,
            descriptores de fichero).
        -   Errores de configuración del servicio.
        -   Bugs inesperados en el framework FastAPI, bibliotecas de
            terceros, o el sistema operativo.
    -   **Códigos HTTP Típicos:** `500 Internal Server Error` (error
        genérico del servidor), `502 Bad Gateway` (si el error se
        origina en un servicio upstream al que se hizo proxy o llamada),
        `503 Service Unavailable` (si el servicio está temporalmente
        sobrecargado, en mantenimiento, o un Circuit Breaker está
        abierto), `504 Gateway Timeout` (si un servicio upstream no
        respondió a tiempo).
    -   **Manejo:**
        -   Deben ser registrados con el máximo detalle posible (stack
            trace completo, contexto de la solicitud, correlation ID)
            para que los desarrolladores puedan investigarlos y
            corregirlos.
        -   Al cliente final (API consumer o UI) se le debe presentar un
            mensaje genérico y no técnico que no exponga detalles
            internos de la implementación o datos sensibles. (\"Ocurrió
            un error inesperado en nuestros servidores, por favor
            intente más tarde.\").
        -   Generalmente, el cliente no puede hacer mucho para
            solucionarlos, excepto reintentar más tarde (especialmente
            para errores 503/504 o errores 500 que podrían ser
            transitorios).
    -   **Monitorización:** Las tasas altas de errores 5xx son un
        indicador crítico de la salud del sistema y deben generar
        alertas inmediatas para los equipos de operaciones/SRE.
-   **Errores de Negocio (o Funcionales / Dominio):**
    -   **Definición:** Ocurren cuando una solicitud del usuario es
        sintácticamente correcta y el sistema funciona técnicamente
        (infraestructura y código base están bien), pero la operación
        viola una regla de negocio, no cumple con precondiciones del
        dominio, o no puede completarse debido al estado actual de los
        datos de la aplicación.
    -   **Ejemplos:**
        -   Intento de retirar más dinero del disponible en una cuenta
            (`InsufficientFundsError`).
        -   Usuario no autenticado o no autorizado para realizar una
            acción específica (`AuthenticationError`,
            `AuthorizationError`).
        -   Intento de crear un recurso que ya existe con un
            identificador único (ej. email de usuario ya registrado -
            `DuplicateResourceError` o `UserAlreadyExistsError`).
        -   Datos de entrada válidos en formato (pasan la validación de
            Pydantic), pero semánticamente incorrectos para la lógica de
            negocio (ej. una fecha de fin de campaña anterior a la fecha
            de inicio).
        -   Un recurso solicitado no se encuentra por razones de negocio
            (ej. `ProductNotFoundError` porque el producto con ese ID no
            existe o está descatalogado, no porque la base de datos esté
            caída).
        -   Intento de realizar una transición de estado inválida para
            una entidad (ej. intentar cancelar un pedido que ya fue
            enviado).
    -   **Códigos HTTP Típicos:**
        -   `400 Bad Request`: Error genérico del cliente, a menudo por
            datos de entrada que, aunque bien formados, son inválidos
            para la lógica de negocio específica del endpoint (si `422`
            o `404` no son más específicos). También puede usarse para
            violaciones de reglas de negocio simples.
        -   `401 Unauthorized`: Falta autenticación (no se proveyó
            token) o las credenciales son inválidas.
        -   `403 Forbidden`: El cliente está autenticado pero no tiene
            permisos para acceder al recurso o realizar la acción
            solicitada.
        -   `404 Not Found`: El recurso específico al que se dirige la
            URL no existe en el sistema (ej.
            `/users/non_existent_user_id`).
        -   `409 Conflict`: La solicitud no se pudo completar debido a
            un conflicto con el estado actual del recurso (ej. intentar
            actualizar un recurso con una versión obsoleta - optimistic
            locking; o intentar crear un recurso que ya existe si el
            endpoint es idempotente para la creación y se detecta
            duplicado).
        -   `422 Unprocessable Entity`: La solicitud estaba bien formada
            sintácticamente (pasó el parsing inicial) pero no se pudo
            procesar debido a errores semánticos en el contenido (a
            menudo usado por FastAPI para errores de validación de
            Pydantic que van más allá de la estructura básica, ej. un
            email que no tiene formato de email, o un valor numérico
            fuera de rango).
    -   **Manejo:**
        -   Deben ser comunicados al cliente con mensajes claros,
            específicos y accionables que expliquen el problema desde la
            perspectiva del negocio, permitiendo al usuario (o al
            servicio cliente) tomar acciones correctivas (ej. \"El
            formato del email es inválido\", \"El producto ID XZY no
            existe\", \"No tienes saldo suficiente\").
        -   Se registran para auditoría, análisis de patrones de uso
            (ej. qué reglas de negocio se violan más frecuentemente), o
            para detectar posibles problemas de usabilidad, pero no
            necesariamente con la misma urgencia o nivel de detalle
            técnico (stack trace) que los errores 5xx.
    -   **Monitorización:** Es útil monitorizar la frecuencia de ciertos
        errores de negocio para detectar problemas de UX, intentos de
        fraude, o cambios en el comportamiento del usuario que podrían
        requerir ajustes en el producto o en las reglas de negocio. Un
        aumento súbito en errores 4xx podría indicar también un problema
        con un cliente API que está enviando mal las peticiones.

**Importancia de la Distinción en el Diseño:**

-   **Clientes API:** Permite a los clientes (otros servicios o
    frontends) implementar lógicas de manejo de errores diferentes. Un
    4xx puede significar \"no reintentar, el usuario debe corregir la
    solicitud\", mientras que un 503 puede significar \"reintentar más
    tarde\".
-   **Alertas y Priorización:** Las alertas para errores 5xx suelen ser
    de alta prioridad para los equipos de operaciones/SRE. Los errores
    4xx, aunque importantes de monitorizar, generalmente no indican una
    emergencia operativa del servidor (a menos que su volumen sea
    anómalamente alto).
-   **Diseño de Excepciones Personalizadas:** Guiar la creación de
    jerarquías de excepciones en el código, separando claramente las que
    representan fallos del sistema (que podrían mapear a 5xx) de las que
    representan condiciones de negocio (que mapearían a 4xx).

### 4.4 Aplicación del patrón Retry con backoff exponencial 

El patrón Retry (Reintento) mejora la resiliencia de las interacciones
con servicios remotos (otros microservicios, bases de datos, APIs de
terceros) al reintentar automáticamente operaciones que fallan debido a
problemas transitorios.

**Concepto:** Cuando una operación falla, en lugar de que el servicio
cliente falle inmediatamente, espera un corto período y vuelve a
intentar la operación. Esto se repite un número configurable de veces o
hasta que la operación tenga éxito.

**Componentes Clave y Consideraciones:**

1.  **Condiciones para Reintentar (Cuándo Reintentar):**
    -   **Errores Transitorios:** Solo se deben reintentar errores que
        se espera que sean temporales y que puedan resolverse por sí
        mismos en un intento posterior.
        -   **Errores de Red:** Problemas de conectividad (ej.
            `httpx.ConnectError`), fallos de resolución DNS
            (`httpx.NameResolutionError`), timeouts de lectura o
            conexión (`httpx.ReadTimeout`, `httpx.ConnectTimeout`).
        -   **Timeouts Generales:** Si se cree que el servicio
            dependiente estaba temporalmente sobrecargado y podría
            responder en un intento posterior.
        -   **Errores HTTP 5xx del Servidor Dependiente:**
            -   `500 Internal Server Error`: Puede ser transitorio si es
                debido a una sobrecarga momentánea o un bug esporádico
                en el servicio dependiente.
            -   `502 Bad Gateway`: Indica un problema en la cadena de
                proxies o gateways, podría ser transitorio.
            -   `503 Service Unavailable`: Explícitamente indica que el
                servicio no está disponible temporalmente (sobrecargado,
                en mantenimiento, Circuit Breaker abierto en el
                dependiente). Es un candidato ideal para reintento.
            -   `504 Gateway Timeout`: El servicio dependiente (o uno
                más allá) no respondió a tiempo. Reintentar puede ayudar
                si la causa fue una congestión temporal.
        -   **Errores Específicos del Servicio Dependiente que Indican
            Sobrecarga Temporal:** Por ejemplo, un código de estado
            `429 Too Many Requests` (Rate Limiting). Se debe reintentar
            respetando la cabecera `Retry-After` si está presente.
    -   **Cuándo NO Reintentar (o hacerlo con extrema precaución):**
        -   **Errores HTTP 4xx del Cliente (excepto 429 y a veces
            408):** Errores como `400 Bad Request`, `401 Unauthorized`,
            `403 Forbidden`, `404 Not Found`, `422 Unprocessable Entity`
            indican un problema con la solicitud misma (datos inválidos,
            falta de permisos, recurso no existente). Reintentar la
            misma solicitud probablemente resultará en el mismo error y
            añadirá carga innecesaria.
        -   **Errores de Negocio No Transitorios:** Si el fallo se debe
            a una violación de una regla de negocio (ej. \"saldo
            insuficiente\"), reintentar no cambiará el resultado a menos
            que el estado del sistema cambie significativamente entre
            intentos (lo cual es otro tema).
2.  **Idempotencia:**
    -   **Definición:** Una operación es idempotente si realizarla
        múltiples veces tiene el mismo efecto que realizarla una sola
        vez. El estado final del sistema es el mismo independientemente
        de cuántas veces (mayor a cero) se ejecute la operación con los
        mismos parámetros.
    -   **Criticidad para Retries:** Es **fundamental** que las
        operaciones que se reintentan sean idempotentes. Si una
        operación no es idempotente (ej. `POST /orders` para crear un
        nuevo pedido, o una operación que deduce saldo), reintentarla
        después de un fallo (especialmente si el cliente no sabe si la
        primera petición llegó y fue procesada por el servidor, pero la
        respuesta se perdió) podría llevar a la creación de múltiples
        pedidos, cargos duplicados, u otros efectos secundarios no
        deseados.
    -   **Métodos HTTP y la Idempotencia:**
        -   **Idempotentes por definición:** `GET`, `PUT`
            (actualizar/reemplazar un recurso completo), `DELETE`
            (eliminar un recurso), `HEAD`, `OPTIONS`.
        -   **No Idempotente por definición (generalmente):** `POST`
            (usado para crear nuevos recursos o desencadenar acciones
            que cambian el estado de forma no idempotente).
        -   **Condicionalmente Idempotente:** `PATCH` (actualización
            parcial; su idempotencia depende de la naturaleza de la
            operación de parcheo. Por ejemplo, un `PATCH` que incremente
            un contador no es idempotente).
    -   **Estrategias para Operaciones No Idempotentes (especialmente
        POST):**
        -   **Token de Idempotencia (Idempotency Key):** El cliente
            genera un token único para cada instancia lógica de la
            operación (ej. un UUID). Este token se envía en una cabecera
            HTTP (ej. `Idempotency-Key`) o como parte del cuerpo de la
            solicitud. El servidor, al recibir la solicitud, verifica si
            ya ha procesado una operación con ese token.
            -   Si es la primera vez, procesa la operación y almacena el
                token junto con el resultado (o un identificador del
                resultado) durante un tiempo.
            -   Si recibe una solicitud posterior con el mismo token, no
                reprocesa la operación, sino que devuelve el resultado
                almacenado de la primera vez. Esto hace que la operación
                sea efectivamente idempotente desde la perspectiva del
                cliente que reintenta.
3.  **Backoff Exponencial (Retroceso Exponencial):**
    -   **Problema a Evitar:** Reintentar inmediatamente o con un
        retraso fijo después de un fallo puede seguir sobrecargando un
        servicio dependiente que ya está luchando por recuperarse,
        empeorando la situación.
    -   **Solución:** Aumentar el tiempo de espera entre reintentos de
        forma exponencial. Por ejemplo, el primer reintento espera 1
        segundo, el segundo 2 segundos, el tercero 4 segundos, el cuarto
        8 segundos, y así sucesivamente, hasta un máximo si se desea.
    -   **Fórmula Común:**
        `delay = base_interval * (2 ** (attempt_number - 1))`
    -   Esto da al servicio dependiente más tiempo para recuperarse a
        medida que aumentan los fallos.
4.  **Jitter (Aleatoriedad):**
    -   **Problema a Evitar (\"Thundering Herd\"):** Si múltiples
        instancias de un cliente (o múltiples clientes diferentes)
        experimentan un fallo al mismo tiempo y todas usan la misma
        estrategia de backoff exponencial pura, todas reintentarán en
        oleadas sincronizadas. Esto puede golpear al servicio
        dependiente con picos de carga coordinados, dificultando su
        recuperación.
    -   **Solución:** Añadir una pequeña cantidad de aleatoriedad
        (jitter) al tiempo de espera calculado por el backoff
        exponencial.
        -   **Full Jitter:**
            `sleep_time = random.uniform(0, exponential_backoff_delay)`
        -   **Equal Jitter:**
            `half_delay = exponential_backoff_delay / 2; sleep_time = half_delay + random.uniform(0, half_delay)`
        -   **Decorrelated Jitter:** Una técnica más avanzada que
            intenta evitar la correlación entre reintentos sucesivos.
    -   El jitter ayuda a distribuir los reintentos en el tiempo,
        suavizando la carga sobre el servicio dependiente.
5.  **Número Máximo de Reintentos y Timeout Total:**
    -   **Límite de Reintentos:** Definir un número máximo de reintentos
        (ej. 3-5 intentos) para evitar reintentos indefinidos que
        podrían agotar los recursos del cliente o mantener al usuario
        esperando demasiado.
    -   **Timeout por Intento:** Cada intento individual debe tener su
        propio timeout.
    -   **Timeout Total de la Operación:** Considerar un timeout global
        para la operación completa (incluyendo todos los reintentos)
        para asegurar que la solicitud del usuario no se bloquee
        excesivamente.

**Implementación con `tenacity` en Python (ejemplo más detallado):** La
biblioteca `tenacity` es una herramienta robusta y flexible para
implementar estrategias de reintento en Python.
:::

::: {.cell .code id="cBNNeOKq6evL"}
``` python
import httpx
import random
import asyncio
from tenacity import (
    AsyncRetrying, # Usar AsyncRetrying para funciones async
    stop_after_attempt,
    wait_exponential, # Proporciona backoff exponencial básico
    retry_if_exception_type,
    retry_if_exception, # Para lógica de reintento más compleja
    RetryError # Excepción lanzada por tenacity si todos los intentos fallan
)
from fastapi import FastAPI, HTTPException, status

app = FastAPI()

# Excepciones de httpx que indican problemas de red o timeouts transitorios
NETWORK_OR_TIMEOUT_EXCEPTIONS = (
    httpx.TimeoutException, # Incluye ConnectTimeout, ReadTimeout, WriteTimeout, PoolTimeout
    httpx.NetworkError,     # Incluye ConnectError, ReadError (no ReadTimeout), WriteError, etc.
    httpx.ConnectTimeout,
    httpx.ReadTimeout,
    httpx.WriteTimeout,
    httpx.PoolTimeout,
    httpx.ConnectError,
)

# Función para determinar si un HTTPStatusError es reintentable
def is_http_status_retryable(exc: httpx.HTTPStatusError) -> bool:
    # Reintentar en 5xx (errores de servidor) y 429 (Too Many Requests)
    return exc.response.status_code >= 500 or exc.response.status_code == 429

# Función de condición de reintento combinada para tenacity
def should_retry_httpx_call(exception: BaseException) -> bool:
    if isinstance(exception, NETWORK_OR_TIMEOUT_EXCEPTIONS):
        print(f"Tenacity: Retrying due to network/timeout exception: {type(exception).__name__}")
        return True
    if isinstance(exception, httpx.HTTPStatusError):
        retry_flag = is_http_status_retryable(exception)
        print(f"Tenacity: HTTPStatusError {exception.response.status_code}. Retry: {retry_flag}")
        return retry_flag
    print(f"Tenacity: Not retrying exception: {type(exception).__name__}")
    return False

# Función de espera con backoff exponencial y full jitter
def custom_wait_with_jitter(retry_state):
    # retry_state.attempt_number es el número de intento actual (empieza en 1)
    base_delay = 1  # segundos
    max_total_wait = 20 # segundos (para evitar esperas muy largas)

    # Backoff exponencial: base * (2^(intento-1))
    exp_delay = base_delay * (2 ** (retry_state.attempt_number - 1))

    # Full jitter: random entre 0 y el delay exponencial
    actual_delay = random.uniform(0, exp_delay)

    # Asegurar que la suma de esperas no sea excesiva (esto es simplificado,
    # Tenacity no tiene un "stop_after_delay" directo que incluya la ejecución)
    # Aquí simplemente limitamos la espera individual.
    # Opcionalmente, podrías calcular el tiempo total transcurrido en los reintentos y parar.

    print(f"Tenacity: Attempt {retry_state.attempt_number}. Calculated exponential delay: {exp_delay:.2f}s. Jittered delay: {actual_delay:.2f}s.")
    return min(actual_delay, max_total_wait) # Limitar la espera individual también


async def make_resilient_httpx_call(method: str, url: str, **kwargs):
    # httpx.AsyncClient debe ser gestionado idealmente fuera de esta función
    # (ej. con lifespan o dependencia) para reutilizar conexiones.
    # Aquí se crea uno nuevo para simplicidad del ejemplo de retry.
    async with httpx.AsyncClient() as client:
        # Configurar los reintentos para esta llamada específica
        # El número total de ejecuciones será max_attempts. (1 original + (max_attempts-1) reintentos)
        max_attempts = kwargs.pop("max_attempts", 3)

        # El decorador @retry es sintaxis azúcar para esto:
        retryer = AsyncRetrying(
            stop=stop_after_attempt(max_attempts),
            wait=custom_wait_with_jitter, # Nuestra función de espera con jitter
            retry=retry_if_exception(should_retry_httpx_call), # Nuestra función de condición
            reraise=True # Re-lanzar la última excepción si todos los intentos fallan
        )

        # La llamada real dentro del bucle de reintentos de tenacity
        # El timeout aquí es por intento.
        attempt_timeout = kwargs.pop("timeout", 5.0)

        return await retryer.call(client.request, method, url, timeout=attempt_timeout, **kwargs)


@app.get("/fetch-data-resiliently")
async def fetch_data_resiliently(service_url: str = "http://localhost:9999/flaky_service"):
    try:
        # Aquí podríamos pasar headers, json, etc. a make_resilient_httpx_call
        response_data = await make_resilient_httpx_call("GET", service_url, max_attempts=4, timeout=3.0)
        return {"data": response_data, "message": "Successfully fetched data."}

    except RetryError as e: # Esto solo se alcanza si reraise=False en AsyncRetrying
        # Con reraise=True, la excepción original es la que se propaga
        last_exception = e.last_attempt.exception()
        print(f"All retry attempts failed for {service_url}. Last error: {type(last_exception).__name__}: {last_exception}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Service at {service_url} is unavailable after multiple retries. Last error: {str(last_exception)}"
        )
    except httpx.HTTPStatusError as e: # Captura errores HTTP que no fueron reintentados o que fallaron al final
        print(f"HTTPStatusError from {service_url}: {e.response.status_code} - {e.response.text}")
        # Podríamos querer mapear esto a un error específico de nuestro servicio
        # o propagar el error del servicio dependiente si es apropiado.
        # Si es un 4xx (y no 429), probablemente no fue reintentado por `should_retry_httpx_call`.
        if 400 <= e.response.status_code < 500 and e.response.status_code != 429:
             raise HTTPException(status_code=e.response.status_code, detail=f"Client error from dependent service: {e.response.text}")
        else: # 5xx o 429 que falló todos los reintentos
             raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=f"Dependent service error {e.response.status_code} after retries: {e.response.text}")

    except NETWORK_OR_TIMEOUT_EXCEPTIONS as e: # Captura errores de red/timeout que fallaron todos los reintentos
        print(f"Network/Timeout error for {service_url} after retries: {type(e).__name__}: {e}")
        raise HTTPException(
            status_code=status.HTTP_504_GATEWAY_TIMEOUT, # O 503 si es más genérico
            detail=f"Dependent service at {service_url} timed out or had network issues after multiple retries."
        )
    except Exception as e: # Otros errores inesperados
        print(f"Unexpected error during resilient call to {service_url}: {type(e).__name__}: {e}")
        # Loggear el stack trace completo aquí
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An unexpected internal error occurred while contacting a dependent service."
        )

# Para probar: ejecutar este FastAPI y tener un servicio en http://localhost:9999/flaky_service
# que a veces devuelva 200, a veces 500, a veces 429, o que a veces tarde mucho en responder.
```
:::

::: {.cell .markdown id="BGwOxBBT6evM"}
## 4.5 Introducción a patrones Circuit Breaker y Bulkhead 

Estos patrones son fundamentales para construir sistemas distribuidos
que puedan gracefully degradar su funcionalidad y aislar fallos, en
lugar de colapsar por completo.

-   **Circuit Breaker (Interruptor de Circuito):**
    -   **Propósito Principal:** Prevenir que una aplicación realice
        repetidamente llamadas a un servicio dependiente que se sabe (o
        se sospecha fuertemente) que está fallando o no disponible. Esto
        tiene dos beneficios principales:
        1.  **Fail Fast para el Cliente:** Evita que el sistema cliente
            (y, en última instancia, el usuario) espere innecesariamente
            por operaciones que tienen una alta probabilidad de fallar,
            consumiendo recursos (hilos, conexiones, tiempo). En lugar
            de eso, falla rápidamente.
        2.  **Aliviar al Servicio Dependiente:** Reduce la carga sobre
            el servicio dependiente que ya está en problemas
            (sobrecargado, recuperándose de un fallo), dándole \"espacio
            para respirar\" y recuperarse más rápidamente, en lugar de
            ser bombardeado con más solicitudes.
    -   **Analogía Eléctrica:** Funciona como un interruptor de circuito
        eléctrico en una casa. Si hay una sobrecarga o cortocircuito
        (demasiados fallos), el interruptor se \"abre\" (corta el flujo
        de electricidad/peticiones). Después de un tiempo, se puede
        intentar \"cerrarlo\" (semiabierto) para ver si el problema se
        resolvió.
    -   **Estados y Transiciones Detalladas:**
        1.  **`CLOSED` (Cerrado):**
            -   **Comportamiento:** Estado inicial y normal. Las
                solicitudes de la aplicación al servicio dependiente se
                permiten y ejecutan.
            -   **Monitorización:** El Circuit Breaker monitoriza los
                resultados de estas llamadas. Los fallos (definidos por
                el programador, ej. timeouts, excepciones específicas,
                códigos de error HTTP 5xx) se cuentan.
            -   **Transición a `OPEN`:** Si el número de fallos (o la
                tasa de fallos) alcanza un umbral configurado dentro de
                un período de tiempo específico (ventana deslizante o
                número de llamadas recientes), el Circuit Breaker
                transita al estado `OPEN`. El contador de fallos se
                resetea (o no, dependiendo de la implementación) al
                transitar.
        2.  **`OPEN` (Abierto):**
            -   **Comportamiento:** El Circuit Breaker \"ha saltado\".
                Todas las solicitudes de la aplicación al servicio
                dependiente son rechazadas inmediatamente (fallan
                rápido) sin intentar la llamada real al servicio. Se
                devuelve un error (una excepción `CircuitBreakerError`)
                o se ejecuta una función de fallback.
            -   **Duración:** Permanece en estado `OPEN` durante un
                período de tiempo configurado, conocido como \"reset
                timeout\" o \"tiempo de enfriamiento\" (cool-down
                period).
            -   **Transición a `HALF_OPEN`:** Cuando expira el \"reset
                timeout\", el Circuit Breaker transita al estado
                `HALF_OPEN`.
        3.  **`HALF_OPEN` (Semiabierto):**
            -   **Comportamiento:** El Circuit Breaker permite que un
                número limitado y configurado de solicitudes \"de
                prueba\" (trial requests) pasen al servicio dependiente.
                Esto es para sondear si el servicio dependiente se ha
                recuperado.
            -   **Monitorización:** Se observan los resultados de estas
                llamadas de prueba.
            -   **Transición a `CLOSED`:** Si las llamadas de prueba
                tienen éxito (todas, o un porcentaje configurado), se
                asume que el servicio dependiente se ha recuperado. El
                Circuit Breaker transita de nuevo a `CLOSED`. El
                contador de fallos se resetea.
            -   **Transición de nuevo a `OPEN`:** Si alguna de las
                llamadas de prueba falla (o el porcentaje de fallos de
                prueba supera un umbral), se asume que el servicio
                dependiente sigue teniendo problemas. El Circuit Breaker
                vuelve inmediatamente al estado `OPEN` y se inicia otro
                ciclo de \"reset timeout\".
    -   **Beneficios Clave:**
        -   **Fail Fast:** Mejora la capacidad de respuesta del sistema
            cliente.
        -   **Prevención de Fallos en Cascada:** Protege al servicio
            dependiente y al propio sistema cliente del agotamiento de
            recursos.
        -   **Resiliencia del Sistema Cliente:** Permite al cliente
            manejar el fallo del Circuit Breaker de forma más
            controlada, por ejemplo, devolviendo datos de una caché, una
            respuesta por defecto, o informando al usuario de una
            degradación temporal.
    -   **Configuración Importante:**
        -   **Umbral de Fallos (Failure Threshold):** Número de fallos o
            tasa de fallos que dispara la apertura.
        -   **Período de Tiempo para el Umbral (Failure Window):**
            Ventana de tiempo durante la cual se cuentan los fallos.
        -   **Duración del Reset Timeout (Open State Duration):** Cuánto
            tiempo permanece abierto el circuito.
        -   **Número de Pruebas en Semiabierto (Half-Open Trial
            Requests):** Cuántas llamadas se permiten en estado
            semiabierto.
        -   **Tipos de Excepciones que Cuentan como Fallo:** No todos
            los errores deben abrir el circuito (ej. errores de negocio
            4xx generalmente no deberían).
-   **Bulkhead (Mamparo):**
    -   **Propósito Principal:** Aislar los recursos utilizados para
        interactuar con diferentes dependencias (o diferentes tipos de
        solicitudes), de modo que un problema con una dependencia (o un
        tipo de solicitud) no afecte la capacidad de interactuar con
        otras dependencias o de atender otros tipos de solicitudes.
        Previene que un fallo en un componente \"inunde\" y agote los
        recursos de todo el sistema.
    -   **Analogía Naval:** Los mamparos en un barco dividen el casco en
        compartimentos estancos. Si un compartimento sufre una brecha y
        se inunda, los mamparos contienen la inundación en ese
        compartimento, evitando que el barco entero se hunda.
    -   **Implementación Común:**
        -   **Pools de Hilos/Tareas Concurrentes Separados:** En
            aplicaciones multihilo o asíncronas, asignar un pool de
            hilos (o un límite de tareas concurrentes, como un
            `asyncio.Semaphore` en Python) separado para las llamadas a
            cada servicio externo crítico o para manejar diferentes
            tipos de solicitudes.
            -   Por ejemplo, si el `ServicioA` tiene un pool de 10 hilos
                para llamar al `ServicioExternoX` y otro pool de 15
                hilos para llamar al `ServicioExternoY`. Si
                `ServicioExternoX` se vuelve extremadamente lento o no
                responde, solo saturará su pool de 10 hilos. Las
                llamadas al `ServicioExternoY` (que usa su propio pool)
                y otras operaciones del `ServicioA` que no dependan de
                estos pools no se verán directamente afectadas por el
                agotamiento de hilos.
        -   **Pools de Conexiones Separados:** Utilizar pools de
            conexiones (HTTP, base de datos, etc.) distintos para cada
            dependencia. Un cliente HTTP como `httpx.AsyncClient`
            gestiona su propio pool de conexiones. Si se crean
            instancias separadas de `AsyncClient` para diferentes
            servicios base, sus pools de conexiones estarán aislados.
        -   **Límites de Solicitudes Concurrentes (Semáforos en
            `asyncio`):** En entornos asíncronos como FastAPI, se pueden
            usar semáforos (`asyncio.Semaphore`) para limitar el número
            de solicitudes concurrentes que un servicio puede realizar a
            una dependencia particular. Esto actúa como un bulkhead
            ligero, previniendo que se abran demasiadas conexiones o se
            consuman demasiados recursos esperando por una dependencia
            lenta.
    -   **Beneficios Clave:**
        -   **Aislamiento de Fallos:** Un servicio lento o que falla
            solo agota los recursos de su \"mamparo\" (pool/semáforo)
            dedicado.
        -   **Mayor Disponibilidad General del Sistema:** El resto de la
            aplicación (u otras interacciones con dependencias) puede
            seguir funcionando y atendiendo solicitudes que no dependen
            del componente problemático.
        -   **Prevención del Agotamiento de Recursos Globales:** Evita
            que un único punto de fallo consuma todos los hilos,
            conexiones, o memoria del sistema.

**Complementariedad de los Patrones:** Retry, Circuit Breaker y Bulkhead
no son mutuamente excluyentes; de hecho, a menudo se usan juntos para
construir sistemas altamente resilientes:

-   Una llamada a un servicio externo podría estar configurada con una
    política de **Retry** para manejar fallos transitorios.
-   Esta lógica de Retry (o la llamada individual si el retry es
    externo) podría estar, a su vez, envuelta por un **Circuit Breaker**
    para proteger contra fallos persistentes del servicio dependiente.
-   Todo el mecanismo de llamada a esa dependencia particular
    (incluyendo su Retry y Circuit Breaker) podría estar restringido por
    un **Bulkhead** (ej. un semáforo o un pool de conexiones dedicado)
    para aislar los recursos que utiliza de otras partes del sistema.

Esta combinación crea múltiples capas de defensa contra diferentes tipos
y duraciones de fallos en las dependencias.

### 4.6 Implementación de circuit breakers con `pybreaker` 

`pybreaker` es una biblioteca Python popular y sencilla que proporciona
una implementación del patrón Circuit Breaker.

**Características Principales de `pybreaker`:**

-   **Fácil de Usar:** Se puede aplicar mediante decoradores a
    funciones/métodos o usar directamente el objeto `CircuitBreaker`
    para envolver llamadas.
-   **Almacenamiento de Estado:** Por defecto, almacena el estado del
    circuito (abierto/cerrado, contador de fallos) en memoria
    (`pybreaker.CircuitMemoryStorage`). Esto es adecuado para
    aplicaciones de una sola instancia.
-   **Almacenamiento Personalizable:** Permite proporcionar un objeto
    \"storage\" personalizado (implementando
    `pybreaker.CircuitBreakerStorage`) para compartir el estado del
    Circuit Breaker entre múltiples instancias de una aplicación (ej.
    usando Redis, Memcached, o una base de datos).
-   **Listeners:** Se pueden registrar \"listeners\" para ser notificado
    de eventos importantes del Circuit Breaker, como cambios de estado
    (ej. de cerrado a abierto), fallos registrados, y éxitos. Esto es
    muy útil para logging, métricas y alertas.
-   **Exclusión de Excepciones:** Permite configurar una lista de tipos
    de excepciones que, si son lanzadas por la función protegida, *no*
    contarán como fallos para el Circuit Breaker (ej. excepciones de
    negocio personalizadas que no indican un fallo del sistema).
-   **Función de Fallback:** Se puede especificar una
    `fallback_function` que se ejecutará automáticamente si la llamada
    protegida falla y el circuito está abierto, o si la llamada falla y
    se quiere devolver una respuesta alternativa en lugar de propagar la
    excepción.

**Uso Básico con FastAPI (Llamadas Asíncronas):**

1.  **Instalación:** `bash     pip install pybreaker`

2.  **Implementación en un Servicio FastAPI:**
:::

::: {.cell .code id="oGRbmr8K6evM"}
``` python
import pybreaker
    import httpx
    import asyncio
    import random # Para simular fallos
    from fastapi import FastAPI, HTTPException, status

    app = FastAPI()

    # --- Listener Personalizado para Pybreaker (para observabilidad) ---
    class Logging ब्रेakerListener(pybreaker.CircuitBreakerListener): # Renombrado para evitar conflicto
        def state_changed(self, cb, old_state, new_state):
            print(f"PYBREAKER LISTENER: Circuit Breaker '{cb.name}' state changed from {old_state.name} to {new_state.name}")

        def before_call(self, cb, func, *args, **kwargs):
            # print(f"PYBREAKER LISTENER: CB '{cb.name}' Before call (State: {cb.current_state})") # Puede ser muy verboso
            pass

        def failure(self, cb, exc):
            print(f"PYBREAKER LISTENER: CB '{cb.name}' Call FAILED. Exception: {type(exc).__name__}: {exc}")

        def success(self, cb):
            # print(f"PYBREAKER LISTENER: CB '{cb.name}' Call SUCCEEDED.") # También puede ser verboso
            pass

    # --- Configuración del Circuit Breaker ---
    # Este breaker protegerá las llamadas a un servicio externo de "productos"
    product_service_breaker = pybreaker.CircuitBreaker(
        fail_max=3,             # Abrir después de 3 fallos consecutivos (o dentro de la ventana de tiempo si se usa)
        reset_timeout=20,       # Permanecer abierto por 20 segundos antes de intentar HALF_OPEN
        # exclude=[MyBusinessError], # Lista de excepciones que no cuentan como fallo sistémico
        listeners=[Logging ब्रेakerListener()],
        name="ProductServiceCB" # Nombre útil para logs/métricas
    )

    PRODUCT_SERVICE_URL = "http://localhost:9997/products" # URL del servicio de productos simulado

    # Esta es la función que realmente realiza la llamada HTTP.
    # Será envuelta por el Circuit Breaker.
    async def _fetch_product_from_external_service(product_id: str):
        print(f"[{product_service_breaker.name} State: {product_service_breaker.current_state}] Attempting to call product service for ID: {product_id}")
        async with httpx.AsyncClient() as client:
            # Simular que el servicio externo a veces falla
            if random.random() < 0.6: # 60% de probabilidad de fallo para probar el CB
                error_type = random.choice(["timeout", "server_error", "network_error"])
                print(f"[{product_service_breaker.name}] Simulating '{error_type}' for product ID: {product_id}")
                if error_type == "timeout":
                    raise httpx.TimeoutException(f"Simulated timeout for {product_id}", request=httpx.Request("GET", f"{PRODUCT_SERVICE_URL}/{product_id}"))
                elif error_type == "server_error":
                    raise httpx.HTTPStatusError(f"Simulated 503 for {product_id}", request=httpx.Request("GET", f"{PRODUCT_SERVICE_URL}/{product_id}"), response=httpx.Response(503))
                else: # network_error
                    raise httpx.NetworkError(f"Simulated network error for {product_id}", request=httpx.Request("GET", f"{PRODUCT_SERVICE_URL}/{product_id}"))

            # Simulación de llamada exitosa (en un caso real, harías la llamada HTTP aquí)
            # response = await client.get(f"{PRODUCT_SERVICE_URL}/{product_id}", timeout=3.0)
            # response.raise_for_status() # Lanza excepción para errores 4xx/5xx
            # return response.json()
            print(f"[{product_service_breaker.name}] Successfully fetched product {product_id} (simulated)")
            return {"product_id": product_id, "name": f"Product {product_id}", "description": "A great product (simulated)."}

    # Función de fallback que se llamará si el Circuit Breaker está abierto
    # o si la llamada protegida falla y el CB está configurado con un fallback.
    async def get_product_fallback(product_id: str, *args, **kwargs): # Debe aceptar los mismos args que la función protegida
        print(f"[{product_service_breaker.name}] Executing FALLBACK for product ID: {product_id}")
        # Podría devolver datos de caché, un valor por defecto, o lanzar una excepción específica de fallback.
        # Aquí devolvemos un objeto parcial indicando que es un fallback.
        return {"product_id": product_id, "name": f"Product {product_id} (Fallback Data)", "status": "unavailable_serving_fallback"}

    # Configurar el fallback en el breaker
    product_service_breaker.fallback_function = get_product_fallback

    @app.get("/products_resilient/{product_id}")
    async def get_product_resiliently(product_id: str):
        try:
            # Para funciones asíncronas, pybreaker ofrece `call_async`
            # Si la función protegida (`_fetch_product_from_external_service`)
            # o la función de fallback (`get_product_fallback`) lanzan una excepción
            # que no es `pybreaker.CircuitBreakerError`, `call_async` la propagará.
            # Si el circuito está abierto, `call_async` ejecutará el fallback si está definido,
            # o lanzará `pybreaker.CircuitBreakerError` si no hay fallback.
            product_data = await product_service_breaker.call_async(
                _fetch_product_from_external_service, # La función async a proteger
                product_id # Argumentos para la función protegida
            )
            return {
                "data": product_data,
                "circuit_state": product_service_breaker.current_state,
                "failures": product_service_breaker.fail_counter
            }

        except pybreaker.CircuitBreakerError as e:
            # Esto se alcanza si el circuito está abierto Y NO hay función de fallback,
            # o si la función de fallback también lanza una excepción (lo cual sería un problema).
            # Con un fallback_function, `call_async` normalmente no lanza CircuitBreakerError directamente
            # sino que devuelve el resultado del fallback.
            # Sin embargo, si el propio fallback falla, o si se quiere manejar explícitamente.
            print(f"Caught CircuitBreakerError (e.g. fallback failed or no fallback): {e}")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=f"Product service is currently unavailable (Circuit Breaker: {product_service_breaker.current_state}). Original error: {str(e)}"
            )

        except Exception as e:
            # Captura otras excepciones que la función protegida o el fallback podrían haber lanzado
            # y que no fueron manejadas internamente por el fallback o pybreaker.
            print(f"An unexpected error occurred while fetching product {product_id}: {type(e).__name__} - {e}")
            # Loggear 'e' con stack trace
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"An unexpected error occurred. Original error: {str(e)}"
            )
```
:::

::: {.cell .markdown id="1wTpNhD26evN"}
**Consideraciones Clave para `pybreaker` en Entornos Asíncronos
(FastAPI):**

-   **Uso de `call_async`:** Para proteger funciones `async def`,
    siempre se debe usar
    `await breaker.call_async(nombre_funcion_async, arg1, arg2, ...)`.
    El método `breaker.call()` es para funciones síncronas y bloquearía
    el bucle de eventos de `asyncio`.
-   **Decoradores con `async def`:** `pybreaker` no proporciona un
    decorador asíncrono directo como `@breaker.async_decorate`. Si se
    desea usar un estilo de decorador para funciones `async def`, se
    tendría que crear un wrapper manualmente o usar `functools.wraps`
    con una función que internamente llame a `breaker.call_async`. Sin
    embargo, el uso explícito de `call_async` suele ser más claro para
    el flujo asíncrono.
-   **Estado Compartido (Distributed Circuit Breaker):** Es la
    consideración más importante para servicios FastAPI que escalan a
    múltiples instancias.
    -   El `CircuitMemoryStorage` por defecto de `pybreaker` es local a
        cada proceso/instancia. Esto significa que cada instancia de tu
        aplicación FastAPI tendrá su propio estado del Circuit Breaker.
        Una instancia podría tener el circuito abierto mientras otra lo
        tiene cerrado y sigue bombardeando al servicio dependiente.
    -   **Solución:** Implementar una clase de almacenamiento
        personalizada que herede de `pybreaker.CircuitBreakerStorage` y
        use un backend compartido como Redis o Memcached. Esta clase
        necesitaría implementar métodos como `get_state()`,
        `set_state(new_state)`, `increment_counter()`,
        `reset_counter()`. Hay implementaciones de terceros disponibles
        (buscar \"pybreaker redis storage\") o se puede desarrollar una
        a medida.
:::

::: {.cell .code id="0uMLvxWt6evO"}
``` python
# Ejemplo conceptual de cómo se usaría un storage distribuido
        # from pybreaker import CircuitBreaker, CircuitBreakerStorage
        # import redis
        #
        # class RedisCircuitBreakerStorage(CircuitBreakerStorage):
        #     def __init__(self, name, redis_client: redis.Redis):
        #         super().__init__(name)
        #         self.redis_client = redis_client
        #         self.state_key = f"pybreaker::{name}::state"
        #         self.counter_key = f"pybreaker::{name}::counter"
        #         self.opened_at_key = f"pybreaker::{name}::opened_at"
        #
        #     # Implementar get_state, set_state, get_counter, increment_counter, reset_counter
        #     # usando comandos de Redis (SET, GET, INCR, EXPIRE, etc.) de forma atómica si es posible.
        #     # ... (implementación detallada omitida por brevedad) ...
        #
        # redis_client = redis.Redis(host='localhost', port=6379, db=0) # Configurar cliente Redis
        # storage = RedisCircuitBreakerStorage("ProductServiceCB_Distributed", redis_client)
        #
        # distributed_product_service_breaker = pybreaker.CircuitBreaker(
        #     fail_max=5,
        #     reset_timeout=30,
        #     storage=storage, # Usar el storage compartido
        #     listeners=[Logging ब्रेakerListener()],
        #     name="ProductServiceCB_Distributed"
        # )
```
:::

::: {.cell .markdown id="LWiMUIY56evO"}
-   **Configuración Dinámica:** En sistemas maduros, los parámetros de
    los Circuit Breakers (umbrales, timeouts) podrían necesitar ser
    ajustables dinámicamente sin redeployar la aplicación, por ejemplo,
    a través de un sistema de configuración centralizado o una interfaz
    administrativa.

## 4.7 Diseño de endpoints resilientes a fallos de servicios externos 

Un endpoint resiliente es aquel que puede continuar operando y
proporcionando valor, aunque sea de forma degradada, cuando uno o más de
sus servicios dependientes experimentan fallos. Se trata de evitar que
el fallo de una dependencia se convierta en un fallo total del endpoint.

**Estrategias Clave Combinadas:**

1.  **Timeouts Agresivos (pero Realistas):**
    -   **Por Intento:** Cada intento de llamada a un servicio externo
        debe tener un timeout. Esto evita que la solicitud se bloquee
        indefinidamente si el servicio dependiente no responde.
    -   **Global para la Operación:** Si la operación del endpoint
        implica múltiples llamadas o reintentos, considerar un timeout
        global para toda la operación del endpoint para asegurar una
        respuesta al cliente final dentro de un plazo aceptable.
    -   **En FastAPI con `httpx`:** Configurar `timeout` en
        `httpx.AsyncClient()` o en llamadas individuales
        `client.get(..., timeout=5.0)`. Se puede usar
        `httpx.Timeout(connect=2.0, read=5.0)` para control más fino.
2.  **Retries Inteligentes (con Backoff Exponencial y Jitter):**
    -   Aplicar reintentos solo para operaciones idempotentes y errores
        transitorios (ver sección 4.4).
    -   Limitar el número máximo de reintentos y el tiempo total
        acumulado por reintentos para no agravar la latencia percibida
        por el usuario final.
    -   La lógica de reintento (ej. con `tenacity`) debe preceder al
        Circuit Breaker o estar integrada de forma que los fallos
        persistentes tras reintentos contribuyan al contador del Circuit
        Breaker.
3.  **Circuit Breakers:**
    -   Envolver las llamadas a servicios externos (idealmente, la
        unidad que incluye los reintentos) con un Circuit Breaker (ver
        sección 4.6).
    -   Esto permite fallar rápido si el servicio dependiente ha
        demostrado ser inestable, evitando más reintentos y timeouts
        innecesarios.
4.  **Fallbacks (Respuestas Alternativas / Degradación Controlada):**
    -   Si una llamada a un servicio externo falla definitivamente
        (después de agotar reintentos y/o porque el Circuit Breaker está
        abierto o la llamada protegida falla), el endpoint debe intentar
        proporcionar una respuesta útil de otra manera, en lugar de
        simplemente fallar.
    -   **Tipos de Fallbacks:**
        -   **Datos Cacheados (Stale Cache):** Devolver la última
            respuesta exitosa conocida para esa solicitud, que podría
            estar almacenada en una caché (Redis, Memcached, o una caché
            en memoria con TTL como `cachetools`). Es crucial:
            -   Indicar al cliente que los datos podrían estar obsoletos
                (ej. con una cabecera HTTP
                `Warning: 110 Response is Stale` o un campo en el
                payload como `data_freshness: "stale"`).
            -   Tener una estrategia para invalidar o refrescar la caché
                cuando el servicio dependiente se recupere.
        -   **Valores por Defecto / Estáticos:** Si los datos de la
            dependencia no son absolutamente críticos para la
            funcionalidad principal del endpoint, devolver valores por
            defecto razonables, una lista vacía, o una respuesta parcial
            indicando qué datos faltan.
        -   **Lógica de Negocio Simplificada o Alternativa:** Ejecutar
            una versión más simple de la lógica de negocio que no
            requiera la dependencia fallida, o que pueda usar una fuente
            de datos secundaria menos precisa pero más disponible.
        -   **Mensaje de Error Específico de Degradación:** Si no hay un
            fallback de datos posible, devolver un mensaje de error
            claro al cliente (ej. HTTP 503 Service Unavailable si es
            temporal, o un error específico del endpoint si la
            funcionalidad está degradada pero otras partes funcionan)
            que indique que una parte de la funcionalidad no está
            disponible temporalmente. Evitar errores genéricos 500 si se
            puede dar más contexto.
:::

::: {.cell .code id="fT4GFRFY6evP"}
``` python
# Ejemplo de Endpoint Resiliente con Timeouts, Retries (conceptual), Circuit Breaker y Fallback
    # Asumimos que `make_resilient_httpx_call_with_cb` encapsula retry y CB.

    # ... (definiciones de breaker, cache, etc. como en ejemplos anteriores) ...

    # Esta función hipotética ya tendría Retry y Circuit Breaker internamente
    # async def get_external_data_with_retry_and_cb(user_id: str, cache: dict):
    #     # ... Lógica con Tenacity y Pybreaker ...
    #     # Si tiene éxito, actualiza la caché.
    #     # Si falla después de todo, lanza una excepción específica o una de httpx/pybreaker.
    #     # Para este ejemplo, simplificamos y lo integramos en el endpoint.
    #     pass

    user_data_cache = {} # Caché simple en memoria

    user_service_breaker = pybreaker.CircuitBreaker(fail_max=2, reset_timeout=30, name="UserServiceCB")

    async def _fetch_user_details_external(user_id: str):
        # Simulación de llamada externa
        print(f"[{user_service_breaker.name}] Calling external user service for {user_id}")
        await asyncio.sleep(random.uniform(0.1, 0.5)) # Simular latencia
        if random.random() < 0.3: # 30% de probabilidad de fallo
            raise httpx.ReadTimeout("Simulated user service timeout", request=httpx.Request("GET", "..."))
        details = {"user_id": user_id, "name": f"Real Name for {user_id}", "preferences": ["A", "B"]}
        user_data_cache[user_id] = details # Actualizar caché en éxito
        return details

    @app.get("/user_profile_page/{user_id}")
    async def get_user_profile_page(user_id: str):
        user_details = None
        details_source = "unknown"

        try:
            # Aplicar Circuit Breaker (Retry estaría dentro de _fetch_user_details_external o envuelto por tenacity)
            # Timeout por intento está dentro de la llamada httpx en _fetch_user_details_external
            user_details = await user_service_breaker.call_async(_fetch_user_details_external, user_id)
            details_source = "live_data"
        except pybreaker.CircuitBreakerError:
            details_source = "fallback_cache_circuit_open"
            if user_id in user_data_cache:
                user_details = user_data_cache[user_id]
            else: # No hay caché, y el circuito está abierto
                raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="User profile service temporarily unavailable, and no cached data.")
        except (httpx.TimeoutException, httpx.NetworkError, httpx.HTTPStatusError) as e:
            details_source = "fallback_cache_call_failed"
            if user_id in user_data_cache:
                user_details = user_data_cache[user_id]
            else: # No hay caché, y la llamada falló
                # Podríamos devolver un 503 o 504 dependiendo del error 'e'
                error_status = status.HTTP_504_GATEWAY_TIMEOUT if isinstance(e, httpx.TimeoutException) else status.HTTP_503_SERVICE_UNAVAILABLE
                raise HTTPException(status_code=error_status, detail=f"Failed to fetch user profile: {str(e)}. No cached data available.")
        except Exception as e: # Otro error inesperado
            # Loggear 'e' con stack trace
            raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Unexpected error processing profile: {str(e)}")


        # Resto de la lógica del endpoint, que puede funcionar con 'user_details' (que puede ser de caché o live)
        # o manejar el caso donde 'user_details' es None si decidimos no lanzar excepción en el fallback.
        if user_details is None: # Si el fallback no lanzó excepción pero no pudo obtener datos
             # Esto no debería pasar si los fallbacks siempre lanzan o devuelven algo
             pass

        page_content = f"Welcome, {user_details.get('name', 'Guest')}!" if user_details else "Welcome, Guest!"

        return {
            "page_title": f"Profile for {user_id}",
            "user_info": user_details,
            "source_of_user_info": details_source,
            "circuit_breaker_state": user_service_breaker.current_state
        }
```
:::

::: {.cell .markdown id="vbuscUbe6evP"}
1.  **Desacoplamiento con Comunicación Asíncrona:**
    -   Para operaciones que son \"comandos\" (cambian estado) y no
        necesitan completarse inmediatamente para devolver una respuesta
        al usuario (ej. enviar un email de confirmación, actualizar
        contadores secundarios, iniciar un procesamiento batch), la
        comunicación asíncrona (colas de mensajes como RabbitMQ/Kafka, o
        tareas en background como las de FastAPI/Celery/Arq) es una
        estrategia de resiliencia muy poderosa.
    -   El endpoint de FastAPI puede:
        1.  Validar la solicitud del cliente.
        2.  Publicar un mensaje/evento en una cola o crear una tarea en
            background.
        3.  Devolver una respuesta inmediata al cliente (ej. HTTP
            `202 Accepted`, indicando que la solicitud fue aceptada para
            procesamiento pero aún no se ha completado).
    -   Un servicio worker separado (consumidor de la cola o ejecutor de
        tareas) procesará la solicitud de forma asíncrona. Este worker
        puede implementar sus propios Retries y Circuit Breakers para
        interactuar con las dependencias necesarias. Si una dependencia
        falla, el mensaje/tarea puede ser reintentado más tarde sin
        afectar la disponibilidad o latencia del endpoint FastAPI
        original.
2.  **Graceful Degradation (Degradación Elegante) de la Experiencia de
    Usuario (UX):**
    -   No es solo responsabilidad del backend. Las interfaces de
        usuario (frontends) deben ser diseñadas para manejar respuestas
        parciales o la ausencia de cierta información de forma elegante.
    -   Por ejemplo, si el servicio de recomendaciones falla, la página
        principal de un e-commerce podría seguir mostrando los productos
        y la funcionalidad de compra, pero el widget de recomendaciones
        podría mostrar un mensaje como \"Las recomendaciones no están
        disponibles en este momento\" o simplemente no mostrarse, en
        lugar de causar un error en toda la página o una mala
        experiencia.
3.  **Validación de Entradas Temprana y Exhaustiva:**
    -   Validar todas las entradas del usuario y parámetros lo antes
        posible en el ciclo de vida de la solicitud para evitar realizar
        llamadas a servicios externos (que consumen recursos, tiempo y
        pueden fallar) con datos incorrectos. FastAPI con Pydantic
        sobresale en esto para la validación de la estructura y tipos de
        la solicitud. Añadir validaciones de negocio específicas antes
        de proceder con llamadas a dependencias.

## 4.8 Captura y log de trazas con contexto de peticiones 

En un sistema de microservicios, una sola solicitud del usuario puede
desencadenar una cascada de llamadas a través de múltiples servicios.
Sin un rastreo adecuado, diagnosticar problemas, entender el rendimiento
o simplemente seguir el flujo de una operación se vuelve una tarea
hercúlea.

**Principios Clave para la Observabilidad de Errores y Flujos:**

1.  **Structured Logging (Logging Estructurado):**
    -   **Qué es:** En lugar de logs de texto plano y libre, escribir
        logs en un formato estructurado como JSON, donde cada entrada de
        log es un objeto con campos clave-valor bien definidos.
    -   **Ventajas:**
        -   **Fácil de Parsear y Consultar:** Las herramientas de
            agregación y análisis de logs (ELK Stack, Splunk, Grafana
            Loki, Datadog Logs, etc.) pueden ingerir, indexar y permitir
            búsquedas y filtrados potentes sobre estos logs (ej.
            \"mostrar todos los logs con `level=ERROR` y
            `user_id=123`\").
        -   **Análisis Automatizado:** Facilita la creación de métricas
            y alertas basadas en patrones en los logs.
    -   **Bibliotecas en Python:**
        -   **`structlog`:** Una biblioteca muy popular y potente que se
            integra bien con el logging estándar de Python y FastAPI.
            Permite definir procesadores para añadir contexto
            automáticamente, formatear en JSON, etc.
        -   **Configuración del `logging` estándar:** Se puede
            configurar el módulo `logging` de Python para emitir JSON
            usando `JSONFormatter` (hay varias implementaciones
            disponibles o se puede crear una).
    -   **Campos Comunes en Logs Estructurados:** `timestamp` (con
        timezone, ej. ISO 8601), `level` (INFO, ERROR, DEBUG, WARNING),
        `service_name`, `service_version`, `hostname`/`instance_id`,
        `logger_name` (nombre del módulo/logger), `message` (el mensaje
        principal del log), y luego campos de contexto específicos.
2.  **Correlation ID (ID de Correlación) / Trace ID:**
    -   **Definición:** Un identificador único (generalmente un UUID o
        un formato similar) que se genera al inicio de una solicitud
        externa (la primera vez que entra al sistema, ej. en el API
        Gateway, el balanceador de carga, o el primer servicio
        contactado).
    -   **Propagación Consistente:** Este ID debe ser propagado a través
        de todas las llamadas subsiguientes (cabeceras HTTP, metadatos
        de gRPC, propiedades de mensajes en colas/eventos) a otros
        servicios que participen en el manejo de esa solicitud original.
        -   **Cabeceras HTTP Comunes:** `X-Request-ID`,
            `X-Correlation-ID`.
        -   **Estándar W3C Trace Context:** Es el estándar recomendado
            actualmente para interoperabilidad en rastreo distribuido.
            Define dos cabeceras principales:
            -   `traceparent`: Contiene la versión del protocolo, el
                `trace-id` (ID de la traza completa), el `span-id` del
                llamador (que se convierte en el `parent-id` del span
                actual), y flags (ej. para indicar si la traza está
                siendo muestreada). Formato:
                `version-traceid-parentspanid-flags` (ej.
                `00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01`).
            -   `tracestate`: Información adicional específica del
                proveedor o del sistema.
    -   **Inclusión en Todos los Logs:** Cada mensaje de log generado
        por cualquier servicio, mientras procesa su parte de esa
        solicitud original, debe incluir este Correlation ID/Trace ID.
    -   **Beneficio Primordial:** Permite filtrar y correlacionar todos
        los mensajes de log relacionados con una única interacción del
        usuario o una única operación de negocio a través de *todo* el
        sistema distribuido. Esto crea una \"traza\" lógica de la
        operación, esencial para la depuración y el análisis de causa
        raíz.
3.  **FastAPI Middleware para Correlation ID / Trace Context:**
    -   Se puede (y se debe) escribir un middleware en FastAPI para
        gestionar la recepción, generación y propagación de estos
        identificadores de contexto.
    -   **Funcionalidades del Middleware:**
        -   **Recepción:** Verificar si una cabecera de Correlation
            ID/`traceparent` entrante existe. Si existe, usarla.
        -   **Generación:** Si no existe una cabecera entrante, generar
            un nuevo ID (ej. un nuevo `trace-id` y un `span-id` raíz).
        -   **Almacenamiento en Contexto de Solicitud:** Almacenar el
            ID/IDs en el contexto de la solicitud para que sea
            fácilmente accesible por la lógica de la aplicación y,
            crucialmente, por el sistema de logging. `ContextVar` de
            Python es ideal para esto en entornos `asyncio` como
            FastAPI, ya que mantiene el contexto aislado por
            tarea/solicitud.
        -   **Inclusión Automática en Logs:** Configurar el sistema de
            logging (ej. con un filtro de log o un procesador de
            `structlog`) para que incluya automáticamente los IDs de
            `ContextVar` en todos los mensajes de log.
        -   **Propagación en Llamadas Salientes:** Cuando el servicio
            FastAPI realiza llamadas HTTP a otros servicios (usando
            clientes como `httpx`), el middleware (o una utilidad de
            cliente HTTP) debe añadir las cabeceras `traceparent` (con
            el `trace-id` actual y un nuevo `span-id` para la llamada
            saliente, donde el `span-id` actual del servicio se
            convierte en el `parent-id`) a esas solicitudes salientes.
        -   **Propagación en Respuestas (Opcional pero útil para
            depuración):** A veces es útil añadir el Correlation
            ID/Trace ID a las cabeceras de las respuestas HTTP salientes
            (ej. `X-Trace-Id`) para que el cliente original pueda usarlo
            si necesita reportar un problema.
:::

::: {.cell .code id="9kE6ok1B6evP"}
``` python
# Ejemplo de Middleware para Correlation ID y Logging con ContextVar
    import uuid
    import httpx
    from fastapi import FastAPI, Request
    from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseCallNext
    from starlette.responses import Response
    import logging
    from contextvars import ContextVar
    import time # Para medir duración

    # ContextVars para almacenar IDs de la traza actual
    TRACE_ID_CV: ContextVar[str] = ContextVar("trace_id")
    REQUEST_ID_CV: ContextVar[str] = ContextVar("request_id") # Puede ser el span_id raíz de esta solicitud

    # Configuración del logger para incluir los IDs de ContextVar
    class ContextualFilter(logging.Filter):
        def filter(self, record):
            record.trace_id = TRACE_ID_CV.get(None) # Usar None como default si no está seteado
            record.request_id = REQUEST_ID_CV.get(None)
            return True

    logging.basicConfig(level=logging.INFO) # Nivel básico
    logger = logging.getLogger("app_logger")
    logger.addFilter(ContextualFilter()) # Añadir el filtro al logger
    # Formato del log para incluir los campos extra (si no se usa structlog)
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - [%(trace_id)s] [%(request_id)s] - %(name)s - %(message)s')
    # Aplicar el formatter a los handlers del logger (ej. StreamHandler)
    if logger.handlers:
        logger.handlers[0].setFormatter(formatter)
    else: # Si no hay handlers, añadir uno básico
        ch = logging.StreamHandler()
        ch.setFormatter(formatter)
        logger.addHandler(ch)


    def generate_id() -> str:
        return uuid.uuid4().hex

    class LoggingAndTracingMiddleware(BaseHTTPMiddleware):
        async def dispatch(self, request: Request, call_next: RequestResponseCallNext) -> Response:
            start_time = time.perf_counter()

            # Obtener o generar Trace ID y Request ID (Span ID raíz para esta solicitud)
            trace_id = request.headers.get("X-Trace-ID") or generate_id()
            request_id = request.headers.get("X-Request-ID") or generate_id() # O derivar de traceparent

            # Establecer en ContextVars para que estén disponibles en toda la app y logs
            trace_id_token = TRACE_ID_CV.set(trace_id)
            request_id_token = REQUEST_ID_CV.set(request_id)

            logger.info(f"Request IN: {request.method} {request.url.path} - Headers: {dict(request.headers)}")

            response: Response = await call_next(request) # Procesar la solicitud

            duration_ms = (time.perf_counter() - start_time) * 1000

            # Añadir IDs a las cabeceras de respuesta para el cliente
            response.headers["X-Trace-ID"] = trace_id
            response.headers["X-Request-ID"] = request_id
            response.headers["X-Response-Time-ms"] = f"{duration_ms:.2f}"

            logger.info(f"Request OUT: {request.method} {request.url.path} - Status: {response.status_code} - Duration: {duration_ms:.2f}ms")

            # Resetear ContextVars
            TRACE_ID_CV.reset(trace_id_token)
            REQUEST_ID_CV.reset(request_id_token)
            return response

    app = FastAPI()
    app.add_middleware(LoggingAndTracingMiddleware)

    # Cliente HTTP para llamadas salientes que propaga los IDs
    async def get_http_client_with_tracing() -> httpx.AsyncClient:
        headers = {}
        trace_id = TRACE_ID_CV.get(None)
        request_id = REQUEST_ID_CV.get(None) # Este sería el span_id actual

        if trace_id:
            headers["X-Trace-ID"] = trace_id
        if request_id:
            # Para W3C Trace Context, si llamamos a otro servicio, generaríamos un nuevo span_id
            # y el request_id (span_id actual) sería el parent_span_id.
            # Por simplicidad, aquí solo propagamos X-Request-ID como el span_id del llamador.
            headers["X-Request-ID"] = request_id
            # headers["traceparent"] = f"00-{trace_id}-{generate_id()}-{request_id}-01" # Ejemplo W3C

        return httpx.AsyncClient(headers=headers)


    @app.get("/user_info")
    async def get_user_info():
        logger.info("Processing /user_info endpoint logic...")

        # Simular llamada a un servicio de autenticación
        auth_service_url = "http://localhost:9994/auth_check"
        try:
            async with await get_http_client_with_tracing() as client:
                logger.info(f"Calling Auth Service: {auth_service_url}")
                # response = await client.get(auth_service_url, timeout=2.0)
                # response.raise_for_status()
                # auth_data = response.json()
                await asyncio.sleep(0.05) # Simular llamada
                auth_data = {"user_id": "user123", "is_authenticated": True}
                logger.info(f"Auth Service responded: {auth_data}")
        except Exception as e:
            logger.error(f"Error calling Auth Service: {type(e).__name__} - {e}", exc_info=True) # exc_info para stack trace
            raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Auth service failed")

        return {"message": "User info processed", "auth_info": auth_data}
```
:::

::: {.cell .markdown id="mFqRNtri6evQ"}
1.  **Contexto de la Petición en Logs (Detalles Adicionales):**
    -   Además del ID de Correlación/Traza, es útil incluir en los logs
        (especialmente en logs de nivel DEBUG o en caso de error):
        -   Endpoint específico (`request.url.path`), método HTTP
            (`request.method`).
        -   Identificador del usuario (si está autenticado y no es PII
            sensible que deba evitarse en todos los logs; se debe tener
            cuidado con GDPR y otras regulaciones de privacidad. Hashear
            o tokenizar PII si es necesario).
        -   Parámetros de entrada relevantes (query params, path params,
            y partes no sensibles del body, sanitizando cualquier PII o
            secreto).
        -   Duración del procesamiento de la solicitud y de las llamadas
            a dependencias.
        -   Código de estado de la respuesta.
2.  **Stack Traces Detallados y Formateados (para Errores Técnicos):**
    -   Asegurarse de que los stack traces completos se registren en el
        servidor para errores 5xx (o cualquier excepción no manejada),
        pero que *nunca* se expongan al cliente final en la respuesta
        HTTP.
    -   El sistema de logging (o los manejadores de excepciones
        genéricos de FastAPI) debería capturarlos y formatearlos
        adecuadamente (idealmente en formato JSON si se usa logging
        estructurado, para facilitar su análisis en herramientas de
        logs). `logger.error("Mensaje", exc_info=True)` en el `logging`
        estándar de Python incluye el stack trace.
3.  **Distributed Tracing (Rastreo Distribuido) con OpenTelemetry
    (OTel):**
    -   **Más Allá del Logging Correlacionado:** Mientras que un
        Correlation ID/Trace ID ayuda a agrupar logs de diferentes
        servicios, el rastreo distribuido proporciona una vista mucho
        más rica, estructurada y temporizada de las llamadas entre
        servicios. Visualiza el flujo completo como una cascada de
        \"spans\".
    -   **Conceptos Clave de OpenTelemetry:**
        -   **Trace:** Representa el camino completo de una solicitud a
            través de múltiples servicios. Identificado por un
            `Trace ID`.
        -   **Span:** Una unidad de trabajo lógica, nombrada y
            temporizada dentro de un Trace (ej. una llamada HTTP
            entrante en un servicio, una consulta a base de datos, una
            llamada HTTP saliente a otro servicio). Los Spans pueden
            tener hijos (sub-spans), formando un árbol que representa la
            jerarquía de llamadas. Cada Span tiene:
            -   Un `Span ID` único.
            -   El `Trace ID` al que pertenece.
            -   Un `Parent Span ID` (si no es el span raíz de la traza
                en ese servicio).
            -   Un nombre descriptivo (ej. `HTTP GET /users/{id}`,
                `SELECT FROM products`).
            -   Timestamps de inicio y fin (permitiendo calcular su
                duración).
            -   **Atributos (Tags):** Pares clave-valor que añaden
                contexto al span (ej. `http.method="GET"`,
                `db.statement="SELECT ..."`, `user.id="123"`).
            -   **Eventos (Logs dentro de Spans):** Anotaciones
                temporales dentro de un span, como logs específicos que
                ocurrieron durante la ejecución del span.
            -   **Estado (Status):** Indica si el span se completó con
                éxito, con error, o fue cancelado.
    -   **Instrumentación con OTel:**
        -   OTel proporciona SDKs para muchos lenguajes (incluyendo
            Python).
        -   La **instrumentación automática** es ofrecida por
            bibliotecas de instrumentación que \"parchean\" frameworks y
            bibliotecas comunes (ej. FastAPI, httpx, SQLAlchemy, gRPC)
            para crear spans y propagar el contexto de traza
            automáticamente con mínima intervención en el código.
            -   Para FastAPI: `opentelemetry-instrumentation-fastapi`
            -   Para `httpx`: `opentelemetry-instrumentation-httpx`
        -   La **instrumentación manual** permite crear spans
            personalizados en el código para operaciones específicas que
            no son cubiertas automáticamente.
    -   **OpenTelemetry Collector:** Un componente de infraestructura
        (usualmente un agente o un servicio separado) que puede recibir
        datos de telemetría (trazas, métricas, logs) de las aplicaciones
        instrumentadas. Puede procesar estos datos (ej. añadir atributos
        comunes, filtrar, muestrear) y exportarlos a uno o más backends
        de rastreo (ej. Jaeger, Zipkin, Prometheus para métricas,
        backends comerciales como Datadog, Honeycomb, New Relic).
    -   **Beneficios:**
        -   **Visualización de Flujos de Solicitud:** Herramientas como
            Jaeger o Zipkin permiten ver la secuencia completa de
            llamadas, duraciones y dependencias para una traza dada.
        -   **Identificación de Cuellos de Botella de Latencia:**
            Fácilmente visible qué spans (y por ende, qué servicios o
            operaciones) están consumiendo más tiempo.
        -   **Análisis de Dependencias entre Servicios:** Entender cómo
            los servicios interactúan.
        -   **Depuración de Errores en Sistemas Distribuidos:** Ver el
            contexto completo de un error, incluyendo los spans que lo
            precedieron en la traza.

## 4.9 Visibilidad de errores mediante dashboards 

Los logs y trazas son esenciales para la depuración detallada y el
análisis forense, pero para una visión operativa, en tiempo real (o casi
real) y de alto nivel de la salud del sistema, los dashboards visuales
son indispensables. Permiten la observación pasiva y la detección
proactiva de problemas relacionados con errores.

**Propósito de los Dashboards de Errores:**

-   **Visión Agregada:** Proporcionar una vista consolidada y
    cuantitativa de la incidencia y tipos de errores a través de uno o
    múltiples servicios.
-   **Detección de Tendencias y Anomalías:** Identificar patrones como
    aumentos graduales en las tasas de error (que podrían indicar una
    degradación paulatina tras un despliegue), picos anómalos (que
    podrían señalar un incidente en curso), o la recurrencia de errores
    específicos.
-   **Medición del Impacto:** Cuantificar el impacto de los errores en
    los usuarios o en los objetivos de negocio (ej. porcentaje de
    solicitudes fallidas, número de usuarios afectados, impacto en
    conversiones).
-   **Priorización:** Ayudar a los equipos a priorizar la corrección de
    bugs y la mejora de la resiliencia basándose en la frecuencia y
    severidad de los errores.
-   **Evaluación de Cambios y Resiliencia:** Observar el efecto de
    nuevos despliegues en las tasas de error. Evaluar la efectividad de
    los patrones de resiliencia implementados (ej. ¿están los Circuit
    Breakers abriéndose y cerrándose como se espera y reduciendo los
    fallos propagados?).

**Métricas Clave para Dashboards de Errores:**

1.  **Tasa de Errores (Error Rate):**
    -   **Definición:** Porcentaje de solicitudes que resultan en error
        dentro de un período de tiempo. Es uno de los KPIs más
        importantes de la salud del servicio (SLI/SLO).
    -   **Visualización:** Generalmente como un gráfico de líneas a lo
        largo del tiempo.
    -   **Segmentación Crucial:**
        -   **Global:** Tasa de error de todo el sistema o de un
            conjunto de servicios.
        -   **Por Servicio:** Cada microservicio debe tener su propia
            tasa de error visible.
        -   **Por Endpoint/Ruta API:** Identificar los endpoints
            específicos que son más problemáticos o que generan más
            errores.
        -   **Por Tipo de Error (4xx vs. 5xx):** Es fundamental separar
            las tasas de errores 4xx (errores del cliente) de las tasas
            de errores 5xx (errores del servidor). Un aumento en 4xx
            puede indicar un problema en un cliente API, un intento de
            abuso, o un cambio no comunicado que rompe la compatibilidad
            con los clientes. Un aumento en 5xx siempre indica un
            problema en el servidor que necesita atención.
        -   **Por Código de Estado HTTP Específico:** (ej. `400`, `401`,
            `403`, `404`, `422`, `429`, `500`, `502`, `503`, `504`).
        -   **Por Método HTTP:** (GET, POST, PUT, etc.).
2.  **Volumen Absoluto de Errores:**
    -   **Definición:** Número total de errores (global, por servicio,
        por endpoint) en un período de tiempo (ej. por minuto, por
        hora).
    -   **Visualización:** Gráfico de barras o líneas. Útil para
        entender la magnitud absoluta, complementando la tasa de error.
3.  **Top N Errores:**
    -   **Por Tipo de Excepción (Clase):** Un listado o gráfico de las
        clases de excepción más frecuentes (ej.
        `DatabaseConnectionError`, `PaymentServiceTimeoutError`,
        `custom_exceptions.InsufficientFundsError`,
        `NullPointerException`). Ayuda a enfocar los esfuerzos de
        corrección.
    -   **Por Mensaje de Error (Agrupado):** Si los mensajes de error
        son consistentes y parametrizados, agruparlos puede revelar
        problemas específicos.
    -   **Por Endpoint/Ruta que origina o recibe el error.**
    -   **Por Host/Instancia/Contenedor:** Para identificar instancias
        problemáticas.
4.  **Latencia de Solicitudes Exitosas vs. Erróneas:**
    -   **Comparación:** Comparar los percentiles de latencia (p50, p90,
        p95, p99) para solicitudes exitosas y aquellas que terminan en
        error.
    -   **Utilidad:** A veces, la alta latencia precede a los timeouts y
        otros errores. Un aumento en la latencia de errores puede
        indicar que los reintentos están tardando mucho o que los
        timeouts son demasiado largos.
5.  **Estado y Actividad de Patrones de Resiliencia:**
    -   **Circuit Breakers:**
        -   Número de Circuit Breakers actualmente en estado `OPEN` o
            `HALF_OPEN`, desglosado por servicio o dependencia
            protegida.
        -   Frecuencia de transiciones de estado (cuántas veces se abren
            y cierran por minuto/hora).
        -   Tasa de \"fallo rápido\" debido a Circuit Breakers abiertos
            (solicitudes rechazadas por el CB).
        -   Servicios o dependencias más afectadas por Circuit Breakers
            abiertos.
    -   **Reintentos:**
        -   Número de operaciones que necesitaron reintentos.
        -   Distribución del número de intentos por operación (cuántas
            necesitaron 1, 2, 3 reintentos).
6.  **Errores por Versión de Servicio/Despliegue:**
    -   Si se usan estrategias como canary deployments o blue/green, es
        crucial tener dashboards que comparen las tasas de error (y
        otras métricas de salud) de las nuevas versiones con las
        versiones antiguas en tiempo real. Esto es fundamental para
        tomar decisiones de continuar con el despliegue (roll forward) o
        revertir (rollback).
7.  **Errores de Dead Letter Queue (DLQ) / Colas de Fallos:**
    -   Número de mensajes actualmente en las DLQs de los sistemas de
        mensajería.
    -   Tasa de entrada de mensajes a DLQs.
    -   Tipos de errores o excepciones que causan que los mensajes
        terminen en DLQs (si esta información se almacena con el
        mensaje).

**Herramientas para Dashboards y Alertas (Repaso y Énfasis):** Estas
herramientas se alimentan de los datos recolectados por los sistemas de
logging estructurado, métricas y rastreo distribuido.

-   **Agregación de Logs y Visualización:**
    -   **ELK Stack (Elasticsearch, Logstash, Kibana):** Kibana es muy
        flexible para crear dashboards a partir de consultas sobre datos
        de logs indexados en Elasticsearch.
    -   **Grafana Loki:** Una solución de agregación de logs de Grafana
        Labs, diseñada para ser eficiente en costes y se integra
        nativamente con Grafana para la creación de dashboards.
    -   **Splunk, Sumo Logic, Loggly, SolarWinds Papertrail:**
        Soluciones comerciales con potentes capacidades de análisis y
        dashboarding de logs.
-   **Sistemas de Métricas y APM (Application Performance Monitoring):**
    -   **Prometheus y Grafana:**
        -   **Prometheus:** Para la recolección, almacenamiento y
            consulta (con PromQL) de series temporales de métricas. Los
            servicios FastAPI pueden exponer métricas en formato
            Prometheus usando bibliotecas como `starlette-prometheus` o
            instrumentación de OpenTelemetry que exporte a Prometheus.
        -   **Grafana:** Para la creación de dashboards altamente
            personalizables a partir de métricas de Prometheus (y muchas
            otras fuentes de datos, incluyendo Elasticsearch para logs,
            Loki, etc.).
        -   **Alertmanager:** (Parte del ecosistema Prometheus) Para
            definir y gestionar alertas basadas en reglas PromQL sobre
            las métricas.
    -   **Datadog, New Relic, Dynatrace, Instana, AppDynamics:**
        Soluciones APM comerciales que a menudo ofrecen dashboards y
        alertas de errores preconfigurados (\"out-of-the-box\"), además
        de capacidades de personalización profunda y correlación
        automática entre métricas, trazas y logs.
    -   **OpenTelemetry Collector:** Puede actuar como un intermediario
        para enviar métricas y trazas a varios de estos backends
        (Prometheus, Datadog, Jaeger, etc.), permitiendo flexibilidad en
        la elección de la herramienta de visualización y alerta.

**Diseño de un Dashboard de Errores Efectivo:**

-   **Orientado a la Audiencia y al Propósito:** ¿Quién usará el
    dashboard (desarrolladores, SREs, gestión de producto)? ¿Qué
    decisiones se tomarán basándose en él? Adaptar la información y el
    nivel de detalle.
-   **Claridad y Simplicidad Visual:** Usar visualizaciones que sean
    fáciles de entender a primera vista (gráficos de líneas para
    tendencias temporales, gráficos de barras para comparaciones,
    contadores grandes para KPIs clave, tablas para Top N). Evitar la
    sobrecarga de información en un solo dashboard; es mejor tener
    varios dashboards enfocados.
-   **Jerarquía y Capacidad de Desglose (Drill-Down):** Un buen
    dashboard permite empezar con una vista de alto nivel (ej. un
    \"semáforo\" de salud general, tasas de error clave por servicio).
    Desde allí, el usuario debería poder hacer clic para desglosar en
    detalles más específicos (ej. de una tasa de error de un servicio a
    los errores de un endpoint particular de ese servicio, y luego,
    idealmente, a ejemplos de logs o trazas correlacionados con esos
    errores).
-   **Accionable:** El dashboard no solo debe mostrar que algo está mal,
    sino también ayudar a identificar *dónde* está el problema y su
    posible impacto, para guiar la respuesta y la investigación.
-   **Alertas Proactivas y Significativas:** Configurar alertas
    automáticas para umbrales críticos (ej. tasa de error 5xx \> X%
    durante Y minutos, un Circuit Breaker específico abierto por más de
    Z minutos, aumento anómalo en un tipo de error 4xx que podría
    indicar un ataque o un cliente roto). Las alertas deben ser fiables
    y significativas para evitar la \"fatiga por alertas\" (alert
    fatigue) causada por demasiados falsos positivos o alertas no
    accionables.
-   **Contexto Temporal:** Mostrar datos históricos suficientes (ej.
    últimas horas, días, semanas) para identificar tendencias, comparar
    con períodos anteriores (ej. mismo día de la semana pasada, período
    anterior al último despliegue), y entender la estacionalidad si
    aplica.
-   **Anotaciones:** Poder anotar eventos importantes en los gráficos
    (ej. despliegues, mantenimientos, incidentes conocidos) ayuda a
    correlacionar cambios en las métricas de error con esos eventos.

## 4.10 Pruebas para simular fallos y degradación controlada 

La resiliencia de un sistema no se puede asumir ni garantizar solo por
diseño; debe ser probada de forma continua y rigurosa bajo condiciones
que simulen el mundo real. Las pruebas de fallos y la disciplina de la
Ingeniería del Caos (Chaos Engineering) son enfoques proactivos para
descubrir debilidades en el sistema antes de que los usuarios las
encuentren.

**Principios Fundamentales de Chaos Engineering:**

1.  **Definir un \"Estado Estable\" Medible:** Antes de inyectar fallos,
    es crucial establecer métricas observables (KPIs de negocio como
    finalización de pedidos, y KPIs técnicos como latencia p95, tasa de
    error, uso de CPU) que definan el comportamiento normal y aceptable
    del sistema. Este es la \"línea base\".
2.  **Plantear una Hipótesis:** Formular una hipótesis clara sobre cómo
    se comportará el sistema (y sus mecanismos de resiliencia) bajo
    ciertas condiciones de fallo. Por ejemplo: \"El sistema mantendrá
    una tasa de éxito de pedidos \> 99% y una latencia p95 \< 300ms
    incluso si el servicio de pagos experimenta una latencia adicional
    de 2 segundos durante 5 minutos, debido a los timeouts agresivos y
    la lógica de fallback a \'pago contra reembolso\' implementados en
    el servicio de checkout.\"
3.  **Introducir Fallos que Reflejen Eventos del Mundo Real:** Simular
    fallos que son comunes en sistemas distribuidos:
    -   Fallos de hardware (servidores, discos).
    -   Errores de red (alta latencia, pérdida de paquetes, particiones
        de red).
    -   Agotamiento de recursos (CPU, memoria, conexiones).
    -   Fallos de dependencias (bases de datos lentas o caídas, APIs de
        terceros no disponibles, Circuit Breakers que se abren).
    -   Errores de software (bugs que causan excepciones, consumo
        excesivo de recursos).
4.  **Intentar Refutar la Hipótesis:** Ejecutar los experimentos de caos
    e observar si el sistema se desvía significativamente del estado
    estable definido. El objetivo es encontrar debilidades (puntos donde
    la hipótesis de resiliencia no se cumple) proactivamente.
5.  **Minimizar el Radio de Impacto (Blast Radius):**
    -   **Empezar en Entornos de No Producción:** Siempre comenzar los
        experimentos de caos en entornos de desarrollo, prueba o
        staging.
    -   **Producción (Práctica Avanzada):** Si se realizan experimentos
        en producción (lo cual es el objetivo final de Chaos Engineering
        para máxima confianza), hacerlo con extremo cuidado:
        -   Sobre un subconjunto muy pequeño y controlado de tráfico o
            instancias (canary).
        -   Con mecanismos de parada de emergencia automáticos (basados
            en métricas que exceden umbrales de seguridad) y manuales
            (\"botón rojo\").
        -   Durante horas de bajo tráfico, si es posible.
        -   Con el conocimiento y la presencia de los equipos
            relevantes.

**Técnicas para Simulación de Fallos (Fault Injection):**

1.  **A Nivel de Red:**
    -   **Latencia:** Introducir retrasos artificiales en las respuestas
        de los servicios dependientes o en la comunicación entre
        servicios.
    -   **Pérdida de Paquetes:** Simular la pérdida de un porcentaje de
        paquetes de red.
    -   **Errores de DNS:** Hacer que la resolución de DNS para un
        servicio falle o devuelva IPs incorrectas.
    -   **Bloqueo de Puertos/IPs (Blackhole/Firewall):** Simular
        firewalls o fallos de conectividad completos a una dependencia.
    -   **Corrupción de Paquetes:** Modificar bits en los paquetes de
        red.
    -   **Ancho de Banda Limitado (Throttling).**
    -   **Herramientas:**
        -   **Linux:** `tc` (Traffic Control) para manipular colas de
            red, `iptables` para bloquear tráfico.
        -   **Toxiproxy:** Un proxy TCP programable para simular
            condiciones de red y sistema adversas (latencia, timeouts,
            conexiones cortadas, datos basura). Se puede usar un cliente
            Python (`toxiproxy-python`) para controlarlo en pruebas
            automatizadas.
        -   **Mountebank:** Herramienta para crear stubs y mocks de
            servicios HTTP/TCP con comportamiento programable,
            incluyendo la simulación de fallos.
        -   **Service Mesh:** Plataformas como Istio y Linkerd a menudo
            incluyen capacidades de inyección de fallos (retrasos HTTP,
            abortos HTTP) que se pueden configurar dinámicamente.
2.  **A Nivel de Servicio/Aplicación (Microservicio FastAPI):**
    -   **Caída de Instancias/Contenedores:** Apagar instancias de un
        microservicio para probar cómo reacciona el balanceador de
        carga, el descubrimiento de servicios, y los clientes que
        dependen de él.
    -   **Devolución de Errores Forzada:**
        -   Modificar un servicio (o un mock/stub que lo simule) para
            que devuelva errores HTTP específicos (500, 503, 429) o
            lance excepciones particulares bajo ciertas condiciones o
            para un porcentaje de las solicitudes. Esto puede hacerse
            con feature flags o endpoints de prueba especiales.
        -   En pruebas unitarias/integración, se pueden usar mocks (ej.
            `unittest.mock.patch` en Python) para simular que clientes
            HTTP (`httpx`) o bibliotecas de dependencias lanzan
            excepciones.
    -   **Consumo de Recursos (Stress Testing en el Contexto de Caos):**
        -   **CPU Spinning:** Introducir bucles que consuman
            intensivamente CPU en un servicio para ver cómo afecta su
            rendimiento, el de otros servicios en el mismo nodo, y cómo
            reaccionan los sistemas de autoescalado o límites de
            recursos (ej. en Kubernetes).
        -   **Memory Leaks Simulados:** Asignar y no liberar memoria
            para simular una fuga y observar el comportamiento del
            recolector de basura, el OOM killer, y la respuesta del
            servicio.
        -   **Agotamiento de Disco (si el servicio escribe a disco
            local).**
    -   **Degradación de Dependencias Clave:** Simular que una base de
        datos, una cola de mensajes, una caché compartida, o una API de
        un tercero crítico está lenta, no disponible, o devuelve
        errores.
    -   **Herramientas:**
        -   Mocks de servicios (ej. `pytest-httpx` para mockear
            respuestas de `httpx`, WireMock, MockServer).
        -   Proxies inyectores de fallos (como Toxiproxy).
        -   Bibliotecas de Chaos específicas del lenguaje (ej. `chaospy`
            para aspectos generales en Python, o bibliotecas para
            inyectar excepciones o retrasos en puntos específicos del
            código, a menudo usadas con AOP o monkeypatching).
        -   Feature Flags para habilitar/deshabilitar comportamiento de
            fallo.
3.  **A Nivel de Infraestructura (Plataforma Cloud/Kubernetes):**
    -   **Terminar VMs/Nodos de Kubernetes:** Simular fallos de hardware
        o mantenimiento de nodos.
    -   **Simular Fallos de Disco en Nodos.**
    -   **Interrumpir la Red a Nivel de Nodo, Rack, o Zona de
        Disponibilidad (en entornos cloud).**
    -   **Agotar Cuotas de Recursos de la Plataforma.**
    -   **Herramientas:**
        -   **Chaos Monkey (original de Netflix):** Aunque más antiguo,
            conceptualmente importante.
        -   **LitmusChaos:** Un framework de Chaos Engineering
            open-source, nativo de Kubernetes, con un amplio catálogo de
            experimentos de caos predefinidos y la capacidad de crear
            propios.
        -   **AWS Fault Injection Simulator (FIS):** Servicio gestionado
            de AWS para realizar experimentos de caos.
        -   **Azure Chaos Studio:** Servicio gestionado de Azure.
        -   **Google Cloud Chaos Toolkit (beta).**
        -   **Pumba:** Herramienta de línea de comandos para caos en
            contenedores Docker.

**Pruebas Específicas para Patrones de Resiliencia en Microservicios
FastAPI:**

-   **Timeouts:**
    -   **Test:** Usar Toxiproxy o un mock para inyectar latencia en una
        dependencia que exceda el timeout configurado en el cliente
        `httpx` de FastAPI.
    -   **Verificar:** Que la llamada del cliente FastAPI falla con la
        excepción de timeout esperada (ej. `httpx.TimeoutException` o la
        `HTTPException` 504 que la envuelve) dentro del plazo
        configurado, y no se queda bloqueada indefinidamente. Que los
        logs reflejan el timeout.
-   **Retries (con `tenacity` en FastAPI):**
    -   **Test:** Hacer que una dependencia (mockeada o a través de
        Toxiproxy) falle de forma intermitente (ej. devuelve 503 en los
        primeros N-1 intentos, y 200 en el N-ésimo).
    -   **Verificar:** Que el cliente (la lógica envuelta por
        `tenacity`) reintenta la operación. Que la estrategia de backoff
        exponencial y jitter se aplica (observable en los logs o tiempos
        entre intentos). Que se respeta el número máximo de reintentos.
        Que si la operación es idempotente, no causa efectos secundarios
        no deseados. Observar los logs para confirmar los intentos y el
        resultado final.
-   **Circuit Breakers (con `pybreaker` en FastAPI):**
    -   **Test (Abrir el circuito):** Inyectar fallos suficientes y
        persistentes en una dependencia (ej. forzar que devuelva 503
        consistentemente) para superar el `fail_max` del Circuit Breaker
        dentro de su ventana de tiempo.
    -   **Verificar:** Que el estado del Circuit Breaker
        (`cb.current_state`) transita a `OPEN`. Que las llamadas
        subsiguientes a la función protegida fallan inmediatamente con
        `pybreaker.CircuitBreakerError` (o son manejadas por la
        `fallback_function` si está definida).
    -   **Test (Transición a Semiabierto y Cerrado):** Esperar el
        `reset_timeout` del Circuit Breaker. Hacer que la dependencia
        vuelva a funcionar correctamente.
    -   **Verificar:** Que el circuito transita a `HALF_OPEN`. Que una o
        varias llamadas de prueba exitosas (según configuración) lo
        transitan de nuevo a `CLOSED`.
    -   **Test (Transición a Semiabierto y Re-apertura):** Esperar el
        `reset_timeout`. Hacer que la dependencia siga fallando.
    -   **Verificar:** Que el circuito transita a `HALF_OPEN`. Que una
        llamada de prueba fallida lo devuelve inmediatamente al estado
        `OPEN`.
-   **Bulkheads (Semáforos `asyncio.Semaphore` en FastAPI):**
    -   **Test:** Simular que una dependencia (protegida por un semáforo
        con límite N) se vuelve muy lenta o no responde. Realizar M \> N
        solicitudes concurrentes al endpoint de FastAPI que llama a esta
        dependencia, y también realizar solicitudes a otros endpoints o
        dependencias (con sus propios semáforos o sin ellos).
    -   **Verificar:** Que el número de tareas concurrentes esperando
        por la dependencia lenta no excede N. Que otras partes de la
        aplicación (otros endpoints, llamadas a otras dependencias)
        siguen respondiendo normalmente y no se ven afectadas por el
        agotamiento de recursos causado por la dependencia lenta.
-   **Fallbacks:**
    -   **Test:** Provocar un fallo en una dependencia de tal manera que
        se agoten los reintentos y/o el Circuit Breaker se abra (o la
        llamada protegida falle directamente).
    -   **Verificar:** Que la lógica de fallback del endpoint de FastAPI
        se activa correctamente. Que se devuelve la respuesta degradada
        esperada (datos de caché, valores por defecto, mensaje de error
        específico de degradación) en lugar de un error completo que
        rompa la experiencia del usuario.

**Integración de Pruebas de Caos en el Ciclo de Vida del Desarrollo
(SDLC):**

-   **Desarrollo Local:** Usar mocks y herramientas ligeras como
    Toxiproxy para pruebas tempranas.
-   **Entornos de Prueba/Staging:** Son los primeros lugares para
    realizar pruebas de caos más realistas y automatizadas como parte de
    los pipelines de CI/CD. Los resultados deben ser analizados antes de
    pasar a producción.
-   **CI/CD (con precaución y madurez):** Se pueden integrar
    experimentos de caos más pequeños, automatizados, y con un radio de
    impacto bien definido en el pipeline de CI/CD para validar
    continuamente la resiliencia de los cambios. Esto es una práctica
    avanzada.
-   **Game Days (Días de Juego / Simulacros):** Sesiones programadas
    (ej. una vez al mes o al trimestre) donde los equipos (desarrollo,
    SRE, operaciones, QA) simulan incidentes mayores de forma controlada
    (ej. fallo de una zona de disponibilidad completa, corrupción de una
    base de datos crítica, fallo de un servicio central). El objetivo es
    practicar los procedimientos de respuesta a incidentes (técnicos, de
    comunicación, de escalado/desescalado), identificar debilidades en
    el sistema y en los runbooks (guías de operación), y mejorar la
    preparación del equipo.

**Consideraciones Éticas y de Seguridad para Pruebas de Caos:**

-   **Permisos y Comunicación Clara:** Siempre obtener los permisos
    necesarios y comunicar claramente cuándo, dónde, y qué tipo de
    experimentos se realizarán, especialmente si podrían afectar a otros
    equipos o entornos compartidos.
-   **Minimizar el Radio de Impacto (Blast Radius):** Diseñar los
    experimentos para que el impacto potencial sea lo más pequeño
    posible y controlable. Usar \"grupos de control\" si es posible.
-   **Mecanismos de Parada de Emergencia (Stop Button / Kill Switch):**
    Tener siempre una forma clara, rápida y fiable de detener cualquier
    experimento de caos si las cosas van mal, si el impacto es mayor del
    esperado, o si se detecta una degradación inaceptable del estado
    estable del sistema. Esto puede ser manual o automatizado (basado en
    métricas que exceden umbrales de seguridad).
-   **Observabilidad Exhaustiva:** Asegurarse de que la observabilidad
    del sistema (métricas, logs, trazas) es suficiente para entender lo
    que está sucediendo durante un experimento de caos y para determinar
    si el sistema se está comportando como se esperaba o si la hipótesis
    de resiliencia se ha refutado. Sin buena observabilidad, Chaos
    Engineering es como volar a ciegas.

Al aplicar estas estrategias y patrones de prueba de forma sistemática,
los microservicios construidos con FastAPI pueden alcanzar un alto grado
de resiliencia, mejorando la experiencia del usuario y la fiabilidad
general del sistema frente a las inevitables turbulencias y fallos del
mundo real. \`\`\`
:::

::: {.cell .markdown id="ayFra4Un6evQ"}
```{=html}
<div class="md-recitation">
  Sources
  <ol>
  <li><a href="https://github.com/lmaran/kpistudio">https://github.com/lmaran/kpistudio</a></li>
  <li><a href="https://github.com/Balogunolalere/commerceApi">https://github.com/Balogunolalere/commerceApi</a></li>
  <li><a href="https://github.com/DennyKuo0809/Stock-Filter">https://github.com/DennyKuo0809/Stock-Filter</a></li>
  </ol>
</div>
```
:::
