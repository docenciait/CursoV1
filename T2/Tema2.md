## TEMA 2. FASTAPI COMO FRAMEWORK PARA MICROSERVICIOS

## Tabla de Contenidos

- [TEMA 2. FASTAPI COMO FRAMEWORK PARA MICROSERVICIOS](#tema-2-fastapi-como-framework-para-microservicios)
- [Tabla de Contenidos](#tabla-de-contenidos)
- [Objetivos](#objetivos)
- [Contenidos](#contenidos)
- [2.1. **Presentación de FastAPI y sus ventajas**](#21-presentación-de-fastapi-y-sus-ventajas)
- [2.2. **Entendimiento del uso de Pydantic**](#22-entendimiento-del-uso-de-pydantic)
- [2.3. **Creación de una estructura base escalable**](#23-creación-de-una-estructura-base-escalable)
- [2.4. **Gestión de rutas y controladores RESTful**](#24-gestión-de-rutas-y-controladores-restful)
- [2.5. **Implementación de middlewares personalizados**](#25-implementación-de-middlewares-personalizados)
- [2.6. **Aplicación de dependencias e inyecciones**](#26-aplicación-de-dependencias-e-inyecciones)
- [2.7. **Integración automática de OpenAPI**](#27-integración-automática-de-openapi)
- [2.8. **Utilización de BackgroundTasks**](#28-utilización-de-backgroundtasks)
- [2.9. **Manejo de excepciones personalizadas**](#29-manejo-de-excepciones-personalizadas)
- [2.10. **Configuración de entornos y variables**](#210-configuración-de-entornos-y-variables)
- [2.11. **Preparación de servicios para producción**](#211-preparación-de-servicios-para-producción)
- [**(0-5 minutos) 2.1. Presentación de FastAPI y sus ventajas para Microservicios**](#0-5-minutos-21-presentación-de-fastapi-y-sus-ventajas-para-microservicios)

---

## Objetivos

- Presentar FastAPI y sus ventajas frente a Flask o Django en microservicios
- Entender cómo FastAPI usa Pydantic para validación y tipado estricto
- Crear una estructura base escalable para un microservicio en FastAPI
- Gestionar rutas y controladores RESTful de manera limpia y desacoplada
- Implementar middlewares personalizados en FastAPI
- Aplicar dependencias y manejo de inyecciones con el sistema de FastAPI
- Integrar OpenAPI automáticamente para documentación de servicios
- Utilizar BackgroundTasks para tareas asincrónicas internas
- Manejar excepciones personalizadas con FastAPI
- Configurar entornos y variables con `pydantic.BaseSettings`
- Preparar servicios para producción con `uvicorn` y `gunicorn`

## Contenidos

## 2.1. **Presentación de FastAPI y sus ventajas**
## 2.2. **Entendimiento del uso de Pydantic**
## 2.3. **Creación de una estructura base escalable**
## 2.4. **Gestión de rutas y controladores RESTful**
## 2.5. **Implementación de middlewares personalizados**
## 2.6. **Aplicación de dependencias e inyecciones**
## 2.7. **Integración automática de OpenAPI**
## 2.8. **Utilización de BackgroundTasks**
## 2.9. **Manejo de excepciones personalizadas**
## 2.10. **Configuración de entornos y variables**
## 2.11. **Preparación de servicios para producción**



---

## **(0-5 minutos) 2.1. Presentación de FastAPI y sus ventajas para Microservicios**

* **Introducción Rápida:** FastAPI es un framework web moderno y rápido para construir APIs con Python 3.7+ basado en tipado estándar de Python. Se construye sobre Starlette (para manejo web asíncrono) y Pydantic (para validación y serialización de datos).
* **Ventajas Clave en el Contexto de Microservicios:**
    * **Alto Rendimiento:** Crucial para servicios que pueden recibir mucho tráfico en una arquitectura distribuida.
    * **Desarrollo Rápido:** Permite iterar y desplegar servicios de manera ágil.
    * **Tipado Estático y Validación (Pydantic):** Define contratos de datos claros (requests/responses), mejora la mantenibilidad y reduce errores en tiempo de ejecución – vital en sistemas con muchas integraciones.
    * **Documentación Automática (OpenAPI/Swagger UI):** Facilita la comunicación y la integración entre diferentes microservicios.
    * **Asincronía Nativa (`async def`, `await`):** Ideal para operaciones de I/O (llamadas a BD, HTTP a otros servicios) que son comunes en microservicios, evitando bloqueos.

---

**(5-10 minutos) 2.2. Entendimiento Profundo del Uso de Pydantic**

* **Más Allá de la Validación de Request Body:** Pydantic es el corazón de la validación y modelado de datos en FastAPI. Su uso va más allá de solo validar la entrada de un `POST`.
* **Aplicaciones Clave en Microservicios:**
    * **Modelado de Datos:** Definir estructuras claras para datos que se intercambian entre servicios o se almacenan.
    * **Validación de Salida (`response_model`):** Asegura que las respuestas de tu servicio cumplen un contrato definido.
    * **Settings Management (`BaseSettings`):** Cargar configuración desde el entorno de forma tipada y validada (ver 2.10).
    * **Serialización/Deserialización:** Convertir datos complejos (como objetos ORM) a diccionarios Python que Pydantic puede luego validar y convertir a JSON.
* **Ejemplo Práctico (Validación Avanzada/Anidada):**
    ```python
    from pydantic import BaseModel, Field, validator, EmailStr
    from typing import List, Optional
    from datetime import datetime

    class Address(BaseModel):
        street: str
        city: str
        zip_code: str = Field(pattern=r"^\d{5}$") # Ejemplo de regex

    class UserCreate(BaseModel):
        username: str = Field(..., min_length=3)
        email: EmailStr # Validación de formato de email
        password: str = Field(..., min_length=8)
        addresses: List[Address] = [] # Lista de modelos anidados

    class User(UserCreate): # Herencia de modelos
        id: int
        is_active: bool = True
        created_at: Optional[datetime] = None

        # Ejemplo de validador custom (no es el único método, pero ilustra)
        @validator('username')
        def username_cannot_be_admin(cls, value):
            if value.lower() == 'admin':
                raise ValueError('Username cannot be admin')
            return value

    # Explicar cómo UserCreate se usa para la entrada y User para la salida (response_model)
    # y cómo Address valida una estructura anidada.
    ```

---

**(10-18 minutos) 2.3. Creación de una Estructura Base Escalable**

* **Por Qué Estructurar:** Un microservicio, aunque pequeño, crece. Una buena estructura de proyecto es vital para la mantenibilidad, testabilidad y escalabilidad futura. Evita tener todo en un solo archivo.
* **Principios:** Separación de responsabilidades (endpoints, lógica de negocio/servicios, modelos de datos, acceso a base de datos, configuración).
* **Estructura de Directorios Recomendada:**
    ```
    my_microservice/
    ├── app/
    │   ├── api/               # Capa de la API (endpoints)
    │   │   ├── __init__.py
    │   │   └── endpoints/
    │   │       ├── __init__.py
    │   │       └── users.py   # Rutas específicas (ej: /users)
    │   │       └── items.py   # Rutas específicas (ej: /items)
    │   ├── core/              # Configuración, dependencias comunes
    │   │   ├── __init__.py
    │   │   ├── config.py      # Clases de configuración (Settings)
    │   │   └── dependencies.py # Funciones de dependencias comunes (ej: get_db)
    │   ├── db/                # Lógica de base de datos (sesión, modelos ORM)
    │   │   ├── __init__.py
    │   │   └── session.py     # Configuración y obtención de sesión de BD
    │   │   └── base.py        # Base declarativa para modelos ORM (si usas uno)
    │   ├── models/            # Modelos de datos (Pydantic, y/o ORM si no están en db)
    │   │   ├── __init__.py
    │   │   └── user.py        # Modelos Pydantic y/o ORM para usuarios
    │   ├── services/          # Lógica de negocio (opcional, pero recomendado)
    │   │   ├── __init__.py
    │   │   └── user_service.py # Funciones o clases con lógica de usuario
    │   └── main.py            # Punto de entrada principal (crea la app, incluye routers)
    ├── tests/                 # Tests unitarios/integración
    │   └── ...
    ├── .env                   # Variables de entorno (para desarrollo)
    ├── Dockerfile             # Definición del contenedor
    └── requirements.txt       # Dependencias del proyecto
    ```
* **Concepto Clave:** Esta organización facilita la navegación, el mantenimiento y la escritura de tests aislados para cada componente.

---

**(18-25 minutos) 2.4. Gestión de Rutas y Controladores RESTful**

* **`APIRouter` como Herramienta de Organización:** Re-enfatizamos el uso de `fastapi.APIRouter`. Permite agrupar "operaciones de ruta" (tus endpoints) en módulos lógicos. Esto evita que el archivo `main.py` se convierta en un monstruo. Cada archivo bajo `app/api/endpoints/` debería ser un `APIRouter`.
* **Diseño RESTful Básico:** Recordamos la importancia de usar los métodos HTTP correctos (`GET` para obtener, `POST` para crear, `PUT`/`PATCH` para actualizar, `DELETE` para eliminar) y URIs basadas en recursos (`/users`, `/items/{item_id}`).
* **Controladores en FastAPI:** En FastAPI, la "función de operación de ruta" (la función decorada con `@router.get`, `@app.post`, etc.) actúa como tu controlador. Recibe la petición (automáticamente validada por Pydantic/FastAPI), coordina la lógica de negocio (llamando a servicios o BD), y devuelve la respuesta.
* **Ejemplo Práctico (`APIRouter`):** Mostramos cómo se define un router y se incluye en la app principal.

    ```python
    # app/api/endpoints/users.py
    from fastapi import APIRouter, Depends, HTTPException, status
    from typing import List
    from ...models.user import User, UserCreate # Importamos modelos
    # from ...services.user_service import UserService # Importamos lógica de negocio (conceptual)
    # from ...dependencies import get_db # Importamos dependencia de BD (conceptual)
    # from sqlalchemy.orm import Session # Si usas SQLAlchemy

    router = APIRouter(
        prefix="/users", # Prefijo para todas las rutas de este router (/users)
        tags=["users"],  # Agrupa en la documentación
        responses={404: {"description": "User not found"}}, # Respuestas comunes para este router
    )

    @router.get("/", response_model=List[User])
    async def read_users():
        # users = await UserService.get_all_users(db) # Llamada a la lógica de negocio/BD
        # Simulación de datos de respuesta
        return [
            {"id": 1, "username": "foo", "email": "foo@example.com", "addresses": []},
            {"id": 2, "username": "bar", "email": "bar@example.com", "addresses": []}
        ]

    @router.post("/", response_model=User, status_code=status.HTTP_201_CREATED)
    async def create_user(user_data: UserCreate): # user_data es validado por Pydantic
        # new_user = await UserService.create_user(db, user_data) # Llamada a la lógica
        # Simulación de creación
        print(f"Creating user: {user_data.username}")
        return {"id": 3, **user_data.model_dump(), "is_active": True, "created_at": datetime.now()}

    # app/main.py (punto de entrada)
    from fastapi import FastAPI
    from .api.endpoints import users # Importamos el router de usuarios

    app = FastAPI(title="My Microservice API") # Metadata para la documentación

    app.include_router(users.router) # Incluimos el router

    # Puedes incluir más routers aquí...
    # from .api.endpoints import items
    # app.include_router(items.router)
    ```

---

**(25-32 minutos) 2.5. Implementación de Middlewares Personalizados**

* **¿Qué Son y Para Qué Sirven en Microservicios?:** Los middlewares son funciones que se ejecutan en el ciclo de vida de una petición: antes de que llegue a tu código de ruta y/o después de que tu código de ruta ha generado una respuesta, pero antes de que se envíe al cliente. Son perfectos para funcionalidades transversales que afectan a muchas (o todas) las peticiones.
* **Casos de Uso Típicos:**
    * Autenticación y Autorización (verificar headers, tokens).
    * Logging de peticiones y respuestas.
    * Añadir headers HTTP comunes (ej: CORS, seguridad).
    * Manejo de sesiones (menos común en APIs RESTless).
    * Rate Limiting (limitar número de peticiones por IP/usuario).
* **Creación de un Middleware (`@app.middleware("http")`):** Se define una función asíncrona que recibe la `Request` y una función `call_next`. `call_next(request)` llama a la siguiente pieza en la cadena (otro middleware o tu endpoint) y devuelve la `Response`. Puedes ejecutar código antes y después de `await call_next(request)`.
* **Ejemplo Práctico (Middleware de Logging Simple):**
    ```python
    from fastapi import FastAPI, Request
    import time

    app = FastAPI() # O usa tu instancia de app existente

    @app.middleware("http")
    async def log_requests(request: Request, call_next):
        start_time = time.time()
        # Código que se ejecuta ANTES de procesar la petición
        print(f"[{datetime.now().isoformat()}] Request: {request.method} {request.url}")

        response = await call_next(request) # Procesa la petición y obtiene la respuesta

        # Código que se ejecuta DESPUÉS de procesar la petición
        process_time = time.time() - start_time
        response.headers["X-Process-Time"] = str(process_time) # Ejemplo: añade un header

        print(f"[{datetime.now().isoformat()}] Response: {request.method} {request.url} - Status: {response.status_code} - Time: {process_time:.4f}s")

        return response

    # Incluye tus routers o define alguna ruta de prueba para ver el middleware en acción
    @app.get("/")
    async def read_root():
        return {"message": "Hello World"}

    # Explicar que si este middleware estuviera en main.py, afectaría a todas las rutas incluidas.
    ```

---

**(32-40 minutos) 2.6. Aplicación de Dependencias e Inyección**

* **Concepto Clave: Inyección de Dependencias (DI):** Es un patrón de diseño donde los componentes (tus funciones de ruta, servicios, etc.) no crean sus dependencias (ej: conexión a BD, configuración, instancias de otros servicios) sino que las reciben desde fuera. FastAPI implementa DI usando el sistema `Depends`.
* **`Depends` en FastAPI:** La función `Depends(callable)` le dice a FastAPI que ejecute `callable` (puede ser una función o una clase con `__call__`) y pase el resultado como argumento a la función de ruta (o a otra dependencia). FastAPI maneja la ejecución y la inyección automáticamente.
* **Beneficios Cruciales en Microservicios:**
    * **Reutilización de Lógica:** Define una dependencia una vez (ej: obtener sesión de BD, verificar autenticación) y úsala en múltiples rutas sin duplicar código.
    * **Testabilidad:** Puedes "inyectar" dependencias simuladas (mocks) fácilmente durante los tests.
    * **Organización:** Mantiene el código de las operaciones de ruta limpio y enfocado en su lógica principal.
    * **Gestión de Recursos:** Controla la vida útil de recursos (ej: cerrar sesión de BD al final de la petición usando `yield` en la dependencia).
* **Casos de Uso Típicos en Microservicios:**
    * Obtener una sesión de base de datos.
    * Obtener la configuración de la aplicación.
    * Inyectar una instancia de una clase de servicio (`UserService(db_session)`).
    * Implementar seguridad (ej: `current_user = Depends(get_current_active_user)`).
* **Ejemplo Práctico (Inyección de Configuración/BD - Revisado):**

    ```python
    # app/core/dependencies.py
    from fastapi import HTTPException, Header, status
    # Si usas BD, aquí iría la dependencia para obtener la sesión:
    # from ..db.session import SessionLocal # Suponiendo que tienes esto
    # def get_db():
    #     db = SessionLocal()
    #     try:
    #         yield db # 'yield' asegura que el código después del yield se ejecute (ej: db.close())
    #     finally:
    #         db.close()

    # Dependencia de ejemplo para requerir un header X-Service-Id
    async def verify_service_id(x_service_id: str = Header(...)):
        # En un caso real, validarías este ID contra una lista permitida o un sistema de auth
        if x_service_id != "known-service-123":
             raise HTTPException(
                 status_code=status.HTTP_403_FORBIDDEN,
                 detail="Invalid X-Service-Id header"
             )
        return x_service_id # La dependencia puede devolver un valor

    # Ejemplo de dependencia de configuración (ver 2.10)
    # from ..core.config import Settings
    # def get_settings():
    #     return Settings() # Pydantic Settings se encarga de cargar del entorno/archivo
    ```

    ```python
    # app/api/endpoints/items.py (ejemplo usando dependencias)
    from fastapi import APIRouter, Depends, HTTPException
    # from sqlalchemy.orm import Session
    # from ..dependencies import get_db, verify_service_id # Importamos dependencias
    # from ..models.item import Item # Modelo ORM o Pydantic
    # from ..schemas.item import ItemSchema # Esquema Pydantic para respuesta

    router = APIRouter(prefix="/items", tags=["items"])

    @router.get("/", # response_model=List[ItemSchema],
                # dependencies=[Depends(verify_service_id)] # Puedes añadir dependencias aquí también
               )
    # async def read_items(db: Session = Depends(get_db)): # Inyecta sesión de BD
    #    items = db.query(Item).all()
    #    return items # Pydantic response_model serializaría esto si fuera necesario

    # Ejemplo simple inyectando una dependencia dummy
    async def get_item_repository():
        # Esto simularía obtener una instancia de una clase Repository
        class ItemRepository:
            def get_all(self): return [{"name": "item1"}, {"name": "item2"}]
        return ItemRepository()

    @router.get("/simple")
    async def read_simple_items(repo: object = Depends(get_item_repository)): # Inyecta la instancia del repo
        return repo.get_all() # Llama a un método del repo

    # Explicar cómo Depends hace que el código sea modular y fácil de testear.
    ```

---

**(40-45 minutos) 2.7. Integración Automática de OpenAPI**

* **El Gran Regalo de FastAPI para Microservicios:** FastAPI genera automáticamente el esquema de la API en formato OpenAPI (anteriormente conocido como Swagger). Este esquema es el contrato formal de tu API.
* **Beneficios en un Entorno de Microservicios:**
    * **Documentación Interactiva:** Acceso inmediato a la documentación web interactiva (Swagger UI en `/docs` y ReDoc en `/redoc`). Es auto-generada a partir de tu código y tus modelos Pydantic. No necesitas escribirla a mano (¡y mantenerla sincronizada!).
    * **Facilita la Integración:** Otros equipos o servicios pueden entender exactamente cómo usar tu API leyendo la documentación.
    * **Generación de Clientes:** El esquema OpenAPI puede usarse para generar automáticamente código cliente en muchos lenguajes.
* **Personalización Básica:**
    * Añadir `title`, `description`, `version` a la instancia `FastAPI` mejora la página de documentación principal.
    * Usar el argumento `tags` en `APIRouter` y en las operaciones de ruta organiza visualmente la documentación.
    * Los `extra` en los modelos Pydantic (`example`, `description`) enriquecen la documentación del esquema.
* **No Práctico Detallado:** La magia ocurre automáticamente. La "práctica" es asegurarse de usar Pydantic, `response_model`, `tags`, etc., correctamente.

---

**(45-50 minutos) 2.8. Utilización de BackgroundTasks**

* **El Problema:** A veces, después de que un cliente ha hecho una petición, tu servicio necesita realizar una tarea que lleva tiempo (ej: enviar un email de confirmación, procesar una imagen, notificar a otro servicio). Si haces esto directamente en tu función de ruta, el cliente tendrá que esperar a que termine la tarea larga, lo que resulta en un tiempo de respuesta percibido muy lento.
* **La Solución (`BackgroundTasks`):** FastAPI proporciona `BackgroundTasks` para ejecutar código *después* de que la respuesta HTTP ha sido enviada al cliente. Esto libera al cliente inmediatamente y permite que la tarea se ejecute "en segundo plano" desde la perspectiva de la petición HTTP.
* **Uso:** Inyectas un objeto `BackgroundTasks` como parámetro en tu función de ruta y usas su método `.add_task()` para añadir la función que quieres ejecutar en segundo plano, junto con sus argumentos.
* **Ejemplo Práctico (Simular Envío de Email):**

    ```python
    from fastapi import BackgroundTasks, FastAPI, status

    app = FastAPI() # O tu app existente

    # Función que simula una tarea larga
    def send_email_simulation(to_email: str, message: str):
        import time
        print(f"--> Iniciando envío de email a {to_email}...")
        time.sleep(5) # Simula un proceso que tarda 5 segundos
        print(f"--> Email enviado a {to_email}.")

    @app.post("/send-notification/{email}", status_code=status.HTTP_202_ACCEPTED)
    async def send_notification(email: str, background_tasks: BackgroundTasks):
        # Añade la tarea a la lista de tareas en segundo plano
        background_tasks.add_task(send_email_simulation, email, "¡Bienvenido a nuestro servicio!")
        # La respuesta se envía inmediatamente después de este return,
        # sin esperar a que termine send_email_simulation.
        return {"message": "Notificación programada. El email se enviará en segundo plano."}

    # Explicar la diferencia con usar algo como Celery (BackgroundTasks es para tareas
    # simples y que no fallan, Celery para tareas distribuidas, con reintentos, etc.)
    ```

---

**(50-55 minutos) 2.9. Manejo de Excepciones Personalizadas**

* **Por Qué Es Importante:** En microservicios, las respuestas de error consistentes y claras son vitales para quienes consumen tu API. Manejar excepciones de forma controlada evita que tu servicio devuelva errores 500 genéricos y exponga detalles internos.
* **`HTTPException` para Errores Estándar:** FastAPI proporciona `fastapi.HTTPException` para devolver errores HTTP estándar (404 Not Found, 401 Unauthorized, 403 Forbidden, etc.) con un código de estado y un detalle (`detail`). FastAPI los maneja por defecto y los presenta correctamente en la respuesta JSON.
* **Manejadores de Excepciones Personalizados:** A veces, tu aplicación puede lanzar excepciones propias (ej: `UsuarioNoEncontradoError`, `SaldoInsuficiente`). Puedes crear manejadores de excepciones personalizados usando `@app.exception_handler(TuExcepcion)` para interceptar estas excepciones y devolver una respuesta HTTP controlada y significativa al cliente.
* **Ejemplo Práctico (Excepción Custom y Handler):**

    ```python
    from fastapi import FastAPI, HTTPException, Request, status
    from fastapi.responses import JSONResponse

    # 1. Define tu excepción personalizada
    class ItemUnavailableError(Exception):
        def __init__(self, item_id: int, detail: str = "Item is currently unavailable"):
            self.item_id = item_id
            self.detail = detail

    app = FastAPI() # O tu app existente

    # 2. Define un manejador para tu excepción personalizada
    @app.exception_handler(ItemUnavailableError)
    async def item_unavailable_exception_handler(request: Request, exc: ItemUnavailableError):
        # Este manejador se ejecuta cuando se lanza ItemUnavailableError
        print(f"ItemUnavailableError caught for item {exc.item_id}")
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST, # Elige un código HTTP adecuado
            content={"message": exc.detail, "item_id": exc.item_id},
        )

    # 3. Usa HTTPException o tu excepción personalizada en tus rutas
    @app.get("/items/{item_id}")
    async def read_item(item_id: int):
        if item_id == 1:
            # Lanza una excepción HTTP estándar
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Item not found")
        elif item_id == 2:
            # Lanza tu excepción personalizada
            raise ItemUnavailableError(item_id=item_id, detail="Este artículo está agotado")
        return {"item_id": item_id, "status": "available"}

    # Explicar cómo esto proporciona respuestas de error predecibles y profesionales.
    ```

---

**(55-58 minutos) 2.10. Configuración de Entornos y Variables**

* **Necesidad Crítica en Microservicios:** Un microservicio interactúa con muchos servicios externos (bases de datos, colas de mensajes, APIs de terceros). Sus credenciales, URLs y configuraciones (niveles de log, flags de features) cambian drásticamente entre entornos (desarrollo, staging, producción). Cambiar el código para cada entorno es insostenible y peligroso. La configuración debe ser **externa**.
* **El Patrón de las 12 Factores (Config):** Seguimos el principio de almacenar la configuración en el entorno de ejecución (variables de entorno), no en el código. Esto permite que la misma imagen de tu microservicio (Docker) se ejecute en cualquier entorno con solo cambiar su configuración externa.
* **`pydantic-settings` (`BaseSettings`) - La Solución Elegante y Tipada:** FastAPI (usando la librería `pydantic-settings`, que extiende Pydantic) ofrece `BaseSettings`.
    * Defines tu configuración como una clase que hereda de `BaseSettings`.
    * Defines los campos de configuración con tipado Pydantic (validación incluida).
    * `BaseSettings` **automáticamente** carga los valores primero de variables de entorno y, si configuras `env_file`, de un archivo `.env` (útil para desarrollo local).
    * Esto te da configuración tipada, validada y cargada externamente con mínimo esfuerzo.
* **Implementación Práctica (Clase Settings y Uso):** Mostramos la clase y cómo se usa `model_config` (antes `Config`) para cargar de `.env`. Recordamos cómo se inyecta con `Depends`.

    ```python
    # app/core/config.py
    from pydantic_settings import BaseSettings, SettingsConfigDict
    from typing import Optional

    class Settings(BaseSettings):
        # Variables de entorno comunes para microservicios
        database_url: str
        secret_key: str
        api_prefix: str = "/api/v1" # Valor por defecto si no se especifica en el entorno
        service_name: str = "MyAwesomeMicroservice"
        # Ejemplo de flag para activar/desactivar una feature
        enable_feature_x: bool = False

        # Configura Pydantic Settings para leer de un archivo .env en el root del proyecto
        model_config = SettingsConfigDict(env_file=".env", extra='ignore') # 'ignore' si hay vars extra en .env

    # Función para obtener la instancia de Settings (ideal para usar con Depends)
    # Se cachea automáticamente por Depends si no cambia.
    def get_settings():
        return Settings()

    # Ejemplo de .env file (para desarrollo local, NO en producción)
    # DATABASE_URL="postgresql://devuser:devpass@localhost/devdb"
    # SECRET_KEY="clave-secreta-desarrollo"
    # ENABLE_FEATURE_X="True" # Las variables de entorno son strings, Pydantic las convierte

    # Recordar cómo se inyecta:
    # from fastapi import Depends, FastAPI
    # from .core.config import Settings, get_settings
    #
    # app = FastAPI()
    # @app.get("/settings")
    # async def show_settings(settings: Settings = Depends(get_settings)):
    #     return {"service_name": settings.service_name, "feature_x_enabled": settings.enable_feature_x}
    ```
* **Beneficio Directo:** Facilita enormemente el despliegue en diferentes entornos sin modificar el código.

---

**(58-60 minutos) 2.11. Preparación de Servicios para Producción - El Salto Cuántico desde Desarrollo**

* **Introducción (El Cambio de Chip):** Hasta ahora, hemos visto cómo construir la lógica de nuestra API con FastAPI, genial para desarrollo. Pero un microservicio en producción enfrenta desafíos totalmente distintos: **alta concurrencia, fiabilidad 24/7, escalabilidad y visibilidad** de lo que está pasando. Ejecutar simplemente `uvicorn main:app --reload` **no** es suficiente para esto. Esto es un resumen de los temas CRÍTICOS que necesitas abordar.
* **El Servidor ASGI para Producción (Uvicorn + Gunicorn):** No usamos `uvicorn` solo. Lo combinamos típicamente con un **gestor de procesos** como **Gunicorn**. Gunicorn lanza múltiples workers (procesos) de Uvicorn (`gunicorn -w [número_workers] -k uvicorn.workers.UvicornWorker main:app`). Esto aprovecha mejor los núcleos de la CPU y añade resiliencia.
* **Empaquetado para la Consistencia (Containerización con Docker):** **Indispensable.** Empaquetamos nuestra app, dependencias y configuración en un **contenedor Docker**. Garantiza consistencia y simplifica el despliegue en orquestadores (Kubernetes, Docker Swarm, etc.). Se define en un **Dockerfile** (mostrar esquema rápido con `FROM`, `WORKDIR`, `COPY`, `RUN pip`, `EXPOSE`, `CMD`).
* **Saber Qué Demonios Pasa (Observabilidad):** Sin esto, estás ciego en producción.
    * **Logging:** Logging estructurado (JSON) recogido centralmente (ELK, Grafana Loki). Vital para depurar.
    * **Métricas:** Recolectar datos de rendimiento (Prometheus) y visualizarlos (Grafana). Monitorizar salud y carga.
    * *(Mención Rápida)* **Tracing Distribuido:** Para seguir peticiones a través de múltiples servicios.
* **Manejo Seguro de Secretos:** **Crítico.** Nunca credenciales hardcodeadas. Usar gestores de secretos dedicados (Vault, K8s Secrets, etc.).
* **Chequeos de Salud (Health Checks):** Implementar endpoints (`/healthz`) para que los orquestadores verifiquen si el servicio está vivo y respondiendo. Permite reinicios automáticos o redirección de tráfico.
* **Seguridad:** Continuar aplicando validación, autenticación/autorización robustas, configuración de CORS, etc.
* **Automatización (CI/CD):** Implementar pipelines automatizadas para construir, testear y desplegar tus imágenes Docker.

* **Cierre del Tema 2:** FastAPI te da una base fantástica de rendimiento, estructura y desarrollo rápido. Pero la **operación en producción** de un microservicio es otro desafío que requiere herramientas y prácticas adicionales (Docker, Gunicorn, Observabilidad, etc.). Han visto hoy las herramientas de FastAPI que los preparan muy bien para este siguiente paso.

---