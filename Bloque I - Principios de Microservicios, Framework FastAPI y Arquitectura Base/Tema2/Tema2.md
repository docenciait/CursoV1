# TEMA 2. FASTAPI COMO FRAMEWORK PARA MICROSERVICIOS


  - [Objetivos](#objetivos) 
  - [2.1. Presentación de FastAPI y ventajas frente a Flask o Django](#21-presentación-de-fastapi-y-ventajas-frente-a-flask-o-django)
  - [2.2. Uso de Pydantic para validación y tipado estricto](#22-uso-de-pydantic-para-validación-y-tipado-estricto)
  - [2.3. Creación de una estructura base escalable para un microservicio](#23-creación-de-una-estructura-base-escalable-para-un-microservicio)
  - [2.4. Gestión de rutas y controladores RESTful desacoplados](#24-gestión-de-rutas-y-controladores-restful-desacoplados)
  - [2.5. Implementación de middlewares personalizados](#25-implementación-de-middlewares-personalizados)
  - [2.6. Aplicación del sistema de dependencias e inyecciones](#26-aplicación-del-sistema-de-dependencias-e-inyecciones)
  - [2.7. Integración automática de documentación con OpenAPI](#27-integración-automática-de-documentación-con-openapi)
  - [2.8. Utilización de BackgroundTasks para tareas asincrónicas](#28-utilización-de-backgroundtasks-para-tareas-asincrónicas)
  - [2.9. Manejo de excepciones personalizadas](#29-manejo-de-excepciones-personalizadas)
  - [2.10. Configuración de entornos con `BaseSettings`](#210-configuración-de-entornos-con-basesettings)
  - [2.11. Preparación para despliegue en producción con `uvicorn` y `gunicorn`](#211-preparación-para-despliegue-en-producción-con-uvicorn-y-gunicorn)
  - [Referencias Bibliográficas](#referencias-bibliográficas)
---

## Objetivos

* Conocer FastAPI y sus ventajas como framework Python moderno para el desarrollo de microservicios.
* Dominar las características clave de FastAPI para la creación eficiente de APIs, como la validación con Pydantic, la inyección de dependencias y el enrutamiento.
* Aprender a estructurar y configurar un microservicio FastAPI de manera escalable, desde el desarrollo local hasta la preparación para producción.
* Utilizar funcionalidades avanzadas de FastAPI como middlewares, tareas en segundo plano y manejo de excepciones para construir servicios robustos.

---

## 2.1. Presentación de FastAPI y ventajas frente a Flask o Django

FastAPI se ha consolidado rápidamente como un framework web Python moderno y de alto rendimiento para construir APIs. Su diseño se centra en la velocidad, la facilidad de desarrollo y la robustez, aprovechando al máximo las características modernas de Python como los *type hints* (sugerencias de tipo) y la programación asíncrona.

**¿Qué es FastAPI?**

FastAPI es un framework web para construir APIs con Python 3.7+ basado en las anotaciones de tipo estándar de Python. Se apoya en dos pilares fundamentales:

* **Starlette:** Para toda la parte web de bajo nivel (enrutamiento, middleware, etc.). Starlette es un framework ASGI (Asynchronous Server Gateway Interface) ligero y de alto rendimiento.  
* **Pydantic:** Para la validación de datos, serialización y deserialización, y la generación automática de esquemas de datos (JSON Schema).

Esta combinación permite a FastAPI ofrecer un rendimiento comparable al de frameworks de Node.js y Go, al tiempo que mantiene la facilidad de uso y la expresividad de Python.

![alt text](img/image.png)

**Ventajas Clave de FastAPI:**

* **Alto Rendimiento:** Gracias a Starlette y al uso de async/await para operaciones concurrentes, FastAPI es uno de los frameworks Python más rápidos disponibles.  
* **Desarrollo Rápido:** Diseñado para reducir el tiempo de desarrollo con validación automática de datos, serialización/deserialización y documentación interactiva.  
* **Menos Errores:** El uso de *type hints* y Pydantic ayuda a detectar errores tempranamente.  
* **Intuitivo y Fácil de Usar:** Sintaxis clara y concisa.  
* **Editor Amigable (Autocompletado):** Excelente soporte de autocompletado gracias a los *type hints*.  
* **Documentación Automática Interactiva:** Genera documentación API con Swagger UI y ReDoc.  
* **Basado en Estándares Abiertos:** Compatible con OpenAPI y JSON Schema.  
* **Soporte Asíncrono Completo:** async nativo para operaciones de I/O intensivas.  
* **Inyección de Dependencias:** Sistema simple y potente.  
* **Excelente Compatibilidad:** Se integra con diversas bases de datos y herramientas.  
* **Seguridad y Autenticación:** Herramientas para OAuth2, JWT, etc.  
* **GraphQL (opcional):** Integración posible con librerías como Strawberry.

**Casos de Uso Típicos para FastAPI:**

* APIs RESTful de alto rendimiento.  
* Microservicios.  
* Aplicaciones web con operaciones asíncronas intensivas.  
* Servicios con validación de datos robusta y documentación automática.  
* Proyectos donde la velocidad de desarrollo y la reducción de errores son críticas.

**Tabla Comparativa de Frameworks API**

| Característica | FastAPI (Python) | DRF (Django REST framework) (Python) | Flask (Python) | Quart (Python) | Django Ninja (Python) | Express.js (Node.js) | NestJS (Node.js) | ASP.NET Core Web API (C\#) | Spring Boot (Java) |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| **Paradigma Principal** | API (ASGI) | API (sobre Django \- WSGI/ASGI) | Microframework (WSGI/ASGI opcional) | Microframework (ASGI, API Flask-like) | API (sobre Django \- ASGI/WSGI) | Microframework (Callbacks/Promises) | Framework completo (TypeScript, OOP, Modular) | Framework completo (Orientado a Objetos) | Framework completo (Orientado a Objetos, Inversión de Control) |
| **Rendimiento** | Muy Alto | Bueno a Alto (mejor con ASGI) | Moderado a Bueno | Alto (similar a FastAPI) | Bueno a Alto (similar a DRF) | Alto | Alto | Muy Alto | Alto a Muy Alto |
| **Facilidad de Uso** | Muy Alta | Moderada (curva de aprendizaje Django) | Muy Alta | Muy Alta (si conoces Flask) | Muy Alta (similar a FastAPI) | Alta | Moderada a Alta (TypeScript recomendado) | Moderada | Moderada (puede ser verboso) |
| **Asincronía (async/await)** | Nativo y Central | Soportado (Django 3.0+) | Limitado (Flask 2.0+ con ASGI) | Nativo y Central | Soportado | Nativo (Node.js) | Nativo y Central (TypeScript) | Nativo y Central | Soportado (Project Reactor, WebFlux) |
| **Validación de Datos** | Excelente (Pydantic integrado) | Robusta (Serializers de DRF) | Extensiones (ej. Marshmallow, Pydantic) | Extensiones (similar a Flask) | Excelente (Pydantic integrado) | Middleware/Librerías (ej. Joi, Yup) | Excelente (Pipes, Class Validator) | Robusta (Data Annotations, FluentValidation) | Robusta (Bean Validation) |
| **Documentación API Automática** | Excelente (OpenAPI, Swagger UI, ReDoc) | Buena (OpenAPI con librerías extra) | Extensiones (ej. Flask-RESTX, Flasgger) | Extensiones (similar a Flask) | Excelente (OpenAPI, Swagger UI, ReDoc) | Librerías (ej. swagger-jsdoc) | Excelente (OpenAPI/Swagger integrado) | Buena (Swagger/OpenAPI integrado) | Buena (Springfox, SpringDoc) |
| **Curva de Aprendizaje** | Baja | Media (depende de Django) | Muy Baja | Baja (si conoces Flask) | Baja | Baja | Media | Media | Media a Alta |
| **Tamaño del Framework** | Pequeño (micro \+ baterías incluidas) | Grande (parte de Django) | Micro | Micro | Pequeño (sobre Django) | Micro | Medio a Grande | Grande | Grande |
| **Ecosistema/Comunidad** | Creciente y Muy Activa | Muy Grande (Django) | Muy Grande | Creciente | Creciente | Enorme | Grande y Creciente | Muy Grande (Microsoft) | Enorme |
| **Opinión Generalizada** | Moderno, rápido, ideal para APIs nuevas | Estable, maduro, para proyectos Django | Flexible, simple, bueno para empezar | Flask asíncrono moderno | FastAPI para Django | Minimalista, flexible, muy popular | Estructurado, escalable, para empresas | Robusto, integrado con .NET | Robusto, para empresas, muy completo |
| **Tipado Fuerte** | Fomentado (*Type Hints*) | Opcional | Opcional | Fomentado (*Type Hints*) | Fomentado (*Type Hints*) | Opcional (JavaScript), Fuerte (TypeScript) | Fuerte (TypeScript por defecto) | Fuerte (C\#) | Fuerte (Java) |
| **Inyección de Dependencias** | Integrada y Sencilla | No nativa en DRF (Django sí tiene) | No nativa | No nativa | Integrada y Sencilla | No nativa | Integrada y Potente | Integrada y Potente | Integrada y Potente (Spring DI) |

**Benchmarking de Frameworks API (TechEmpower)**

Los benchmarks de TechEmpower son una referencia ampliamente utilizada para comparar el rendimiento de frameworks web. Es crucial entender que:

* Los resultados varían entre rondas y configuraciones.  
* El rendimiento no es el único factor; la facilidad de uso, el ecosistema y las características son igualmente importantes.  
* Las pruebas se realizan en configuraciones optimizadas.

A continuación, se presenta una tabla con datos numéricos representativos (Requests Per Second \- RPS) de algunas pruebas clave de TechEmpower (basados en tendencias generales observadas en rondas como la 21 o 22; **para datos exactos y actuales, consultar siempre el sitio oficial**). Se comparan FastAPI, Django, NestJS, ASP.NET Core y Spring Boot (WebFlux para la variante reactiva de Spring, que suele rendir mejor en estos benchmarks).

Resultados Numéricos Representativos de TechEmpower (RPS \- Requests Per Second)  
(Valores aproximados y pueden variar significativamente entre rondas y tipos de prueba específicos. Mayor RPS es mejor.)

**Resultados Numéricos Representativos de TechEmpower (RPS - Requests Per Second)**
*(Valores aproximados y pueden variar significativamente entre rondas y tipos de prueba específicos. Mayor RPS es mejor.)*

| Framework                 | Lenguaje   | Test: JSON Serialization (RPS) | Test: Single Query (DB - RPS) | Test: Multiple Queries (DB - RPS) | Test: Fortunes (Complex - RPS) |
| :------------------------ | :--------- | :----------------------------- | :---------------------------- | :-------------------------------- | :----------------------------- |
| **ASP.NET Core** | C#         | ~7,000,000 - 8,000,000+        | ~450,000 - 550,000+           | ~55,000 - 70,000+                 | ~300,000 - 400,000+            |
| **Spring Boot (WebFlux)** | Java       | ~5,000,000 - 7,000,000+        | ~350,000 - 450,000+           | ~40,000 - 60,000+                 | ~150,000 - 250,000+            |
| **Gin (Gonic)** | Go         | ~4,000,000 - 6,000,000+        | ~300,000 - 400,000+           | ~35,000 - 50,000+                 | ~120,000 - 200,000+            |
| **NestJS (Fastify)** | Node.js    | ~1,500,000 - 2,500,000+        | ~200,000 - 300,000+           | ~25,000 - 40,000+                 | ~100,000 - 180,000+            |
| **FastAPI (Uvicorn)** | **Python** | **~1,000,000 - 1,800,000+** | **~150,000 - 250,000+** | **~15,000 - 25,000+** | **~80,000 - 140,000+** |
| **Django (ASGI)** | Python     | ~250,000 - 400,000             | ~40,000 - 70,000              | ~3,000 - 6,000                    | ~20,000 - 35,000               |
| **Flask (ASGI)** | Python     | ~200,000 - 350,000             | ~30,000 - 60,000              | ~2,000 - 5,000                    | ~15,000 - 30,000               |

**Interpretación de los Datos Numéricos:**

* **ASP.NET Core (C\#):** Consistentemente muestra el rendimiento más alto en la mayoría de las pruebas, beneficiándose de las optimizaciones del runtime de .NET y la naturaleza compilada del lenguaje.  
* **Spring Boot (WebFlux, Java):** También se sitúa en los puestos altos, especialmente su variante reactiva (WebFlux) sobre servidores como Netty. La JVM es altamente optimizada.  
* **NestJS (Node.js, típicamente sobre Fastify):** Ofrece un excelente rendimiento dentro del ecosistema Node.js, superando a frameworks más tradicionales como Express.js en estas pruebas.  
* **FastAPI (Python, con Uvicorn):** Es, con diferencia, uno de los frameworks Python más rápidos. Aunque no alcanza las cifras de los frameworks C\# o Java de alto rendimiento en RPS absolutos, es significativamente más rápido que Django y Flask, cerrando la brecha de rendimiento para Python en el desarrollo de APIs. Su rendimiento es competitivo con muchos frameworks de Node.js.  
* **Django (Python, con Uvicorn/Daphne para ASGI):** Aunque ha mejorado con el soporte ASGI, Django es un framework más pesado y con más capas, lo que se traduce en un menor rendimiento en benchmarks crudos comparado con microframeworks o frameworks más especializados en APIs como FastAPI.

**Notas sobre el Benchmarking:**

* **Configuración:** Los resultados de TechEmpower usan configuraciones específicas (ej. FastAPI con Uvicorn y múltiples workers, NestJS sobre Fastify en lugar de Express, Spring Boot con WebFlux y Netty).  
* **Tipo de Prueba:** El rendimiento varía drásticamente según el tipo de prueba. Las pruebas de "Plaintext" o "JSON serialization" suelen dar números mucho más altos que las pruebas que involucran acceso a bases de datos o renderizado de plantillas ("Fortunes").  
* **No es la Única Métrica:** La velocidad de desarrollo, la madurez del ecosistema, la disponibilidad de talento y las características específicas del framework son tan importantes como el rendimiento crudo.  
* **Para Datos Precisos:** Visita [TechEmpower Framework Benchmarks](https://www.techempower.com/benchmarks/) para ver los resultados completos de la última ronda. Podrás filtrar por tipo de prueba, lenguaje, framework, etc.

---



## 2.2 Uso de Pydantic para Validación y Tipado Estricto

En el mundo de los microservicios, la comunicación clara y sin ambigüedades entre servicios es **vital**. Cada servicio expone una API, que es su **contrato** con el mundo exterior. Si los datos que fluyen a través de estas APIs no son correctos, pueden causar errores en cascada, comportamientos inesperados y ser una pesadilla para depurar. Aquí es donde **Pydantic** brilla ✨, actuando como el guardián de nuestros contratos de datos y una de las piedras angulares que hace de FastAPI una opción tan potente y robusta.

#### ¿Qué es Pydantic y Por Qué es Crucial?

Pydantic es una biblioteca Python para la **validación de datos** y la **gestión de configuraciones** utilizando **anotaciones de tipo (type hints)**. FastAPI la utiliza intensivamente. Su propósito principal es permitirnos definir **modelos de datos** como clases de Python. Estos modelos describen la *forma* que deben tener nuestros datos, incluyendo los tipos de cada campo y reglas de validación adicionales.

Lo crucial es que Pydantic **impone estos tipos y reglas en tiempo de ejecución**. Esto garantiza que nuestra lógica de negocio *siempre* reciba datos del tipo y la forma esperados, previniendo errores antes de que ocurran. Para los microservicios, esto significa:

  * **Contratos de API Robustos:** Define explícitamente qué datos acepta y devuelve cada servicio.
  * **Fiabilidad:** Reduce drásticamente los errores debidos a datos incorrectos.
  * **Claridad:** Mejora la comprensión de cómo interactúan los servicios.

Usaremos **Pydantic v2**, la versión moderna.

#### ¿Cómo Usar Pydantic? Modelando Nuestros Datos

Veamos cómo se "siente" trabajar con Pydantic, definiendo modelos y entendiendo cómo valida y transforma los datos.

**1. Definiendo Modelos Básicos (`BaseModel`)**

La forma más común es heredar de `pydantic.BaseModel`.

```python
# Concepto: Modelo Básico de Usuario
from pydantic import BaseModel
from typing import Optional

class UserBase(BaseModel):
    username: str  # Campo requerido de tipo string
    email: str     # Campo requerido de tipo string
    full_name: Optional[str] = None # Campo opcional, por defecto None
    age: int       # Campo requerido de tipo entero
```

  * **Clave:** Define la estructura esperada y sus tipos. Los campos sin valor por defecto son obligatorios. `Optional[str]` indica que puede ser un string o `None`.

**2. Validación Automática y Errores**

Pydantic valida los datos al crear una instancia. Si algo falla, lanza una `ValidationError`.

```python
# Concepto: Intento de Creación Inválida
invalid_data = { "username": "john.doe", "age": "treinta" }

# Al intentar: UserBase.model_validate(invalid_data)
# Se lanzaría 'ValidationError' indicando:
# - 'email': Falta (Field required)
# - 'age': No es un entero válido (Input should be a valid integer)
```

  * **En FastAPI:** Esto se traduce automáticamente en una respuesta **HTTP 422** detallando los errores, sin que tengamos que escribir código para ello.

**3. Usando `Field` para Validaciones Avanzadas**

Para más control (defaults, rangos, longitudes, descripciones), usamos `Field`.

```python
# Concepto: Modelo de Producto con Validaciones
from pydantic import BaseModel, Field, HttpUrl
from typing import List

class Product(BaseModel):
    name: str = Field(
        ..., min_length=3, max_length=50,
        description="Nombre del producto", examples=["Mi Super Producto"]
    )
    price: float = Field(..., gt=0, description="Precio > 0")
    tags: List[str] = Field(default=[], description="Etiquetas")
    image_url: Optional[HttpUrl] = Field(default=None, description="URL válida")
```

  * **Clave:** `...` marca un campo como obligatorio. `gt`, `min_length`, etc., definen reglas. `description` y `examples` alimentan la documentación OpenAPI. `HttpUrl` y `EmailStr` son tipos especiales de Pydantic para validaciones comunes.

**4. Modelos Anidados**

Pydantic maneja estructuras complejas anidando modelos, validando recursivamente.

```python
# Concepto: Modelo de Pedido Anidado
import datetime

class UserInOrder(BaseModel): username: str
class ProductInOrder(BaseModel): name: str; price: float

class Order(BaseModel):
    order_id: int
    timestamp: datetime.datetime
    customer: UserInOrder # <-- Modelo Anidado
    items: List[ProductInOrder] # <-- Lista de Modelos Anidados
```

**5. Serialización (`model_dump`) y Deserialización (`model_validate`)**

  * **Deserialización:** `MiModelo.model_validate(datos_json)` convierte la entrada en un objeto Python validado.
  * **Serialización:** `mi_objeto.model_dump()` convierte el objeto Python en un diccionario (listo para JSON).

<!-- end list -->

```python
# Concepto: (De)Serialización
product_data = {"name": "Laptop Pro", "price": 1200.50}
my_product = Product.model_validate(product_data) # Deserializa y valida
json_output = my_product.model_dump() # Serializa a dict
```

**6. Integración con Dataclasses de Python (`@pydantic.dataclasses.dataclass`)**

Si prefieres los `dataclasses` estándar, Pydantic te permite añadirles validación usando su decorador.

```python
# Concepto: Pydantic Dataclass
from pydantic.dataclasses import dataclass as pydantic_dataclass

@pydantic_dataclass
class PydanticItem:
    name: str = Field(min_length=3)
    price: float = Field(gt=0)
    item_id: int
```

  * **Clave:** Obtienes la sintaxis de `dataclasses` con la validación de Pydantic. FastAPI también entiende estos modelos.

**7. Settings Management (`BaseSettings`)**

Pydantic (a través de `pydantic-settings`) es también ideal para gestionar configuraciones desde variables de entorno o archivos `.env`.

```python
# Concepto: Configuración Básica
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str
    secret_key: str
    class Config: env_file = ".env"
```

#### La Magia de Pydantic y FastAPI Juntos

La verdadera potencia se libera gracias a la **integración nativa** de FastAPI con Pydantic:

1.  **Validación Automática de Peticiones:** Al declarar un modelo Pydantic como tipo en un endpoint (`def create_user(user: UserBase):`), FastAPI lee, valida y convierte el JSON entrante.
2.  **Serialización Automática de Respuestas:** Al declarar un `response_model`, FastAPI valida y convierte tu respuesta al formato correcto.
3.  **Documentación Automática (OpenAPI):** FastAPI inspecciona tus modelos Pydantic y genera automáticamente los esquemas de datos para tu documentación Swagger UI y ReDoc. ¡Tus contratos de API están siempre documentados y actualizados\!

#### Flujo de Datos con Pydantic en FastAPI

```mermaid
%%{init: {"themeVariables": {"fontSize": "42px"}}}%%
graph LR
    Cliente --> FastAPI
    FastAPI --> Pydantic_Model_Input
    Pydantic_Model_Input --> Objeto_Python
    FastAPI --> Logica
    Logica --> Pydantic_Model_Output
    Pydantic_Model_Output --> JSON_Respuesta
    FastAPI --> Cliente

    Pydantic_Model_Input --> OpenAPI
    Pydantic_Model_Output --> OpenAPI
    OpenAPI --> Documentacion

    style FastAPI fill:#f9f,stroke:#333,stroke-width:2px
    style Logica fill:#ccf,stroke:#333,stroke-width:2px
    style Cliente fill:#9cf,stroke:#333,stroke-width:2px
    style Documentacion fill:#9c9,stroke:#333,stroke-width:2px




```
#### Tabla Resumen: Pydantic `Field` Comunes

| Parámetro | Descripción | Ejemplo |
| :--- | :--- | :--- |
| `default` | Valor por defecto si no se proporciona. | `Field(default=10)` |
| `...` | Indica que el campo es obligatorio. | `Field(...)` |
| `gt`, `lt` | Mayor que, Menor que (exclusivo). | `Field(gt=0, lt=100)` |
| `ge`, `le` | Mayor o igual que, Menor o igual que. | `Field(ge=0, le=100)` |
| `min_length`| Longitud mínima para strings/listas. | `Field(min_length=5)` |
| `max_length`| Longitud máxima para strings/listas. | `Field(max_length=50)` |
| `pattern` | Patrón de expresión regular (v2). | `Field(pattern=r'^abc_')` |
| `description`| Texto descriptivo (para OpenAPI). | `Field(description="...")` |
| `examples` | Lista de ejemplos (para OpenAPI). | `Field(examples=["ej1", "ej2"])` |


Pydantic nos permite definir contratos de API claros y robustos, validarlos automáticamente y obtener documentación de alta calidad sin esfuerzo adicional. Al aprender a definir modelos Pydantic efectivos:

  * **Reducimos drásticamente el código *boilerplate*** de validación.
  * **Aumentamos la fiabilidad** de nuestros servicios al garantizar la integridad de los datos.
  * **Mejoras la comunicación** entre servicios y con los consumidores de tu API gracias a contratos claros y documentación automática.
  * **Facilitas el desarrollo y el mantenimiento** al trabajar con objetos Python bien definidos y tipados.

Dominar Pydantic es, en gran medida, dominar una de las partes más importantes y beneficiosas de trabajar con FastAPI, proporcionándonos las herramientas esenciales para construir microservicios fiables, mantenibles y bien documentados.



## 2.3 Creación de una Estructura Base Escalable para un Microservicio

Para construir microservicios con FastAPI que sean robustos, mantenibles y capaces de crecer, no basta con escribir código; necesitamos una **arquitectura bien definida** y una **estructura de proyecto coherente**. Esto implica entender los patrones comunes en el ecosistema de microservicios y elegir aquellos que mejor se alineen con nuestra filosofía de curso: **DDD, Microservicios, Hexagonal y CQRS**.

### 1. Patrones Clave en Microservicios

Existen muchos patrones, pero nos centraremos en aquellos que más impactan la **estructura y la transición**:

| Patrón | Descripción | Explicación |
| :--- | :--- | :--- |
| **Descomposición por Capacidad de Negocio** | Identificar las capacidades clave del negocio (Gestión de Pedidos, Facturación, etc.) y crear un microservicio por cada una. | Se enfoca en *qué* hace el negocio. Los servicios son estables, cohesivos y alineados con la organización. |
| **Descomposición por Subdominio (DDD)** | Usar Domain-Driven Design para identificar Subdominios y Bounded Contexts, que se convierten en microservicios. | Es una forma más rigurosa de la anterior, basada en el modelo de dominio y el lenguaje. Genera límites muy claros y modelos ricos. |
| **Database per Service** | Cada microservicio gestiona **exclusivamente** su propia base de datos. Otros servicios no pueden acceder directamente a ella. | Garantiza el **bajo acoplamiento** y la **autonomía**. Los servicios pueden elegir su BBDD y evolucionar su esquema independientemente. Requiere comunicación (API/Eventos) para datos compartidos. |
| **Strangler Fig (Higuera Estranguladora)** | Patrón de **migración gradual**. Se construye una fachada y se van extrayendo funcionalidades del monolito a nuevos servicios, redirigiendo el tráfico poco a poco. | Permite migrar sistemas legados con menor riesgo, obteniendo valor temprano y permitiendo aprender sobre la marcha. |
| **API Gateway** | Un **único punto de entrada** (o pocos) para los clientes. Enruta las peticiones, puede agregar respuestas y maneja tareas transversales (auth, log). | Simplifica los clientes, oculta la complejidad interna, centraliza políticas. Es esencial en cualquier arquitectura de microservicios. |
| **Arquitectura Hexagonal (Puertos y Adaptadores)** | Aísla el **núcleo** (lógica de negocio/DDD) de las dependencias externas (API, BBDD, etc.) usando **Interfaces (Puertos)** y **Adaptadores** (implementaciones). | Promueve el bajo acoplamiento, alta testabilidad y la independencia tecnológica del dominio. Se alinea perfectamente con DDD. |

### 2. Valoración: Monolítico -> Microservicio (Migración)

Al migrar un monolito, el **riesgo y la continuidad del negocio** son primordiales.

* **Mejores Patrones:**
    * **Strangler Fig:** Es el *proceso* de migración por excelencia. Permite ir paso a paso, reduciendo el riesgo. Es casi indispensable para migraciones complejas.
    * **Decomposición por Capacidad/Subdominio:** Son los *objetivos* de la descomposición. Nos ayudan a decidir *qué* funcionalidades extraer en cada paso del "estrangulamiento". Empezar por capacidades bien definidas y menos críticas suele ser una buena estrategia.
    * **API Gateway:** Se necesita desde el principio para actuar como la fachada que redirige el tráfico entre el monolito y los nuevos servicios.
    * **Arquitectura Hexagonal:** Aplicarla a los *nuevos* servicios que se extraen asegura que nazcan bien estructurados y no se conviertan en "mini-monolitos".
* **Desafíos:**
    * **Database per Service:** Es uno de los mayores retos en la migración. El monolito suele tener una BBDD única y muy acoplada. Extraer los datos requiere estrategias complejas (sincronización, vistas, etc.) durante la transición.

### 3. Valoración: Directo -> Microservicio (Greenfield)

Al empezar desde cero, tenemos la libertad de aplicar las mejores prácticas desde el día uno.

* **Mejores Patrones:**
    * **Decomposición por Subdominio (DDD):** Es el enfoque **ideal**. Nos permite realizar un análisis profundo del dominio y definir límites de microservicios robustos y significativos desde el inicio.
    * **Arquitectura Hexagonal:** Es la forma **natural** de estructurar cada microservicio (Bounded Context) para asegurar su calidad y desacoplamiento a largo plazo.
    * **Database per Service:** Es **fundamental** y más fácil de implementar desde cero.
    * **API Gateway:** Necesario para gestionar el acceso a los servicios.
* **Consideraciones:**
    * Aunque no migramos, es crucial invertir tiempo en **DDD Estratégico** al principio. Empezar a construir microservicios sin límites claros es una receta para el fracaso ("monolito distribuido").

### 4. Elección Objetivo: DDD + Hexagonal

Tanto para migración como para *greenfield*, nuestro objetivo es llegar a microservicios que representen **Bounded Contexts (DDD)** y estén estructurados internamente siguiendo la **Arquitectura Hexagonal**. Esta combinación nos da:

* **Sentido de Negocio:** Microservicios con un propósito claro.
* **Límites Fuertes:** Independencia y autonomía.
* **Calidad Interna:** Código testable, mantenible y desacoplado.

**FastAPI se adapta perfectamente** a este enfoque, actuando como un **Adaptador de Entrada HTTP** eficiente y moderno para nuestro núcleo hexagonal.

### 5. Seamos realistas: Estructura Base Escalable. Luego Hexagonal y Hexagonal/DDD

**Paso 1: Comencemos por una estructura inicial sin hexagonal ni DDD:**

¡Claro! Aquí tienes una estructura de proyecto para un microservicio FastAPI más **sencilla y directa**, sin aplicar explícitamente los patrones de DDD (Domain-Driven Design) ni la Arquitectura Hexagonal.

Esta estructura es muy común para microservicios pequeños o medianos donde la complejidad del dominio no justifica la sobrecarga de abstracciones de DDD/Hexagonal.



```
mi_microservicio/
├── app/
│   ├── __init__.py
│   ├── main.py           # 🚀 Punto de entrada y configuración de FastAPI
│   ├── api/              # 🌐 Endpoints/Routers de FastAPI
│   │   ├── __init__.py
│   │   └── v1/
│   │       ├── __init__.py
│   │       └── items.py      # 📦 Router para los 'items'
│   ├── schemas/          # 📝 Modelos Pydantic para validación y DTOs
│   │   ├── __init__.py
│   │   └── item.py       # Pydantic models para 'item'
│   ├── services/         # ⚙️ Lógica de negocio
│   │   ├── __init__.py
│   │   └── item_service.py # Lógica para gestionar 'items'
│   ├── db/               # 💾 Todo lo relacionado con la Base de Datos
│   │   ├── __init__.py
│   │   ├── database.py   # Configuración de conexión y sesión
│   │   ├── models.py     # Modelos del ORM (ej: SQLAlchemy)
│   │   └── crud_item.py  # Funciones CRUD para 'items'
│   └── core/             # 🛠️ Configuraciones, seguridad, utilidades
│       ├── __init__.py
│       └── config.py     # Carga de configuraciones (ej: BaseSettings)
├── tests/                # 🧪 Pruebas
│   ├── __init__.py
│   └── test_items.py
└── requirements.txt      # 📜 Dependencias del proyecto
```

---


### `app/`
Es la carpeta principal que contiene todo el código fuente de tu aplicación/microservicio.

### `app/main.py`
* **Propósito**: Este es el **punto de entrada** de tu aplicación FastAPI.
* **Responsabilidades**:
    * Crea la instancia principal de `FastAPI()`.
    * Configura *middlewares* (CORS, autenticación, logging, etc.).
    * **Incluye los routers** definidos en la capa `api/`.
    * Puede configurar eventos de *startup* y *shutdown* (como iniciar conexiones a la base de datos).
    * Configura la **inyección de dependencias** básica si es necesaria.

### `app/api/`
* **Propósito**: Define cómo el mundo exterior interactúa con tu servicio a través de **HTTP**.
* **Responsabilidades**:
    * Contiene los `APIRouter` de FastAPI. Es común agruparlos por *recurso* o *funcionalidad* (ej: `items.py`, `users.py`).
    * Cada *endpoint* (ruta) definido aquí:
        * Recibe las peticiones HTTP.
        * Utiliza los `schemas/` (Pydantic) para **validar** los datos de entrada y **serializar** los de salida.
        * **Llama a los `services/`** para ejecutar la lógica de negocio.
        * **No contiene lógica de negocio**. Su trabajo es traducir HTTP a llamadas de función y viceversa.

### `app/schemas/`
* **Propósito**: Define la **estructura de los datos** que entran y salen de tu API.
* **Responsabilidades**:
    * Contiene modelos **Pydantic** (`BaseModel`).
    * Actúan como DTOs (Data Transfer Objects).
    * Proporcionan validación automática de datos y generación de documentación OpenAPI (Swagger/ReDoc).

### `app/services/`
* **Propósito**: Contiene la **lógica de negocio** principal de tu aplicación. Es el "cerebro" del microservicio.
* **Responsabilidades**:
    * Implementa las operaciones o casos de uso que ofrece tu servicio (ej: `create_item`, `get_item_details`).
    * Recibe datos (a menudo validados por Pydantic desde la capa `api`).
    * **Orquesta las interacciones con la base de datos** (llamando a `db/crud_item.py`) y otros servicios externos si los hubiera.
    * Toma decisiones, aplica reglas y realiza cálculos.
    * En esta estructura simplificada, *reemplaza* la necesidad de las capas `application` y `domain` separadas.

### `app/db/`
* **Propósito**: Gestiona toda la **interacción con la base de datos**.
* **Responsabilidades**:
    * `database.py`: Configura la **conexión** a la base de datos (URL, engine) y gestiona las **sesiones** (ej: `get_db` para inyección de dependencias).
    * `models.py`: Define las **tablas de la base de datos** utilizando un ORM como SQLAlchemy. Estos son los modelos que se mapean directamente a la base de datos.
    * `crud_item.py` (o similar): Contiene funciones específicas para **operaciones CRUD** (Crear, Leer, Actualizar, Borrar) sobre los modelos de la base de datos. Estas funciones son llamadas por los `services/`. Esto es una forma simple de *separar* la lógica de acceso a datos sin llegar a definir interfaces formales como en Hexagonal.

### `app/core/`
* **Propósito**: Alberga código transversal que es útil en varias partes de la aplicación pero no es específico de la API, los servicios o la base de datos.
* **Responsabilidades**:
    * `config.py`: Manejo de **configuraciones** y variables de entorno (usando Pydantic `BaseSettings` es una buena práctica).
    * Puede contener módulos para **seguridad** (JWT, OAuth2), utilidades comunes, etc.

### `tests/`
* **Propósito**: Contiene todas las **pruebas** para asegurar que tu microservicio funciona correctamente.
* **Responsabilidades**:
    * **Pruebas unitarias**: Para `services/` y `db/crud_item.py`.
    * **Pruebas de integración/API**: Para `api/` (usando `TestClient` de FastAPI).

---

Esta estructura es más directa, tiene menos capas de abstracción y suele ser más rápida de desarrollar para proyectos más simples. La lógica de negocio vive en los `services`, que interactúan directamente con las funciones `crud` (o directamente con el ORM) y son expuestos por la `api`.

**Paso 2: Refactorizando a Hexagonal:**

Nos centraremos en la **Arquitectura Hexagonal (Puertos y Adaptadores)**, pero sin la carga conceptual específica de DDD (como Entidades, Agregados, Servicios de Dominio).

El objetivo sigue siendo aislar la lógica principal de la aplicación de los detalles externos (API, BBDD), pero el "núcleo" será la capa de aplicación/casos de uso, que define los contratos (puertos) que necesita.


```
mi_microservicio/
├── app/
│   ├── __init__.py
│   ├── main.py           # 🚀 Punto de entrada, Inyección de Dependencias y Routers
│   ├── api/              # 🔌 Adaptador de Entrada (HTTP/FastAPI)
│   │   ├── __init__.py
│   │   └── v1/
│   │       ├── __init__.py
│   │       ├── endpoints/
│   │       │   ├── __init__.py
│   │       │   └── items.py  # 📦 Router para 'items', llama a Application Services
│   │       └── schemas/
│   │           ├── __init__.py
│   │           └── item.py   # 📝 DTOs (Pydantic) para la API
│   ├── application/      # ❤️ El Hexágono: Casos de Uso y Puertos
│   │   ├── __init__.py
│   │   ├── services/
│   │   │   ├── __init__.py
│   │   │   └── item_service.py # Implementa casos de uso, usa Puertos de Salida
│   │   ├── ports/            # 📜 Puertos (Interfaces / Contratos)
│   │   │   ├── __init__.py
│   │   │   └── item_repository.py # Define la INTERFAZ para persistir Items
│   │   ├── models/           # (Opcional) Modelos internos si son necesarios
│   │   │   ├── __init__.py
│   │   │   └── item.py     # 💡 Modelos de datos simples, NO ORM, NO DDD Entities
│   │   └── exceptions.py   # ⚠️ Excepciones de la Aplicación
│   ├── infrastructure/   # 🔩 Adaptadores de Salida (Implementaciones Concretas)
│   │   ├── __init__.py
│   │   └── persistence/
│   │       ├── __init__.py
│   │       ├── sqlalchemy_adapter/ # 💾 Adaptador para SQLAlchemy
│   │       │   ├── __init__.py
│   │       │   ├── database.py   # Configuración de BBDD y Sesión
│   │       │   ├── db_models.py  # Modelos del ORM (mapeo a BBDD)
│   │       │   └── repository.py # 👈 Implementación CONCRETA del Puerto item_repository
│   │       └── ...         # (Otros adaptadores: MongoDB, Kafka, etc.)
│   └── core/             # 🛠️ Configuraciones, Seguridad, Dependencias Transversales
│       ├── __init__.py
│       └── config.py     # Carga de configuraciones
├── tests/                # 🧪 Pruebas
│   ├── __init__.py
│   ├── application/
│   └── infrastructure/
└── requirements.txt      # 📜 Dependencias del proyecto
```


### `app/main.py`
* **Propósito**: Igual que antes, es el punto de entrada y el **orquestador de la configuración**.
* **Responsabilidades**:
    * Crear `FastAPI()`.
    * Incluir routers de `app/api/`.
    * **Configurar la Inyección de Dependencias**: Aquí es donde *mapeas* los **puertos** (`application/ports/`) a sus **adaptadores** concretos (`infrastructure/persistence/`). Es el *pegamento* esencial de la Arquitectura Hexagonal.

### `app/api/` (Adaptador de Entrada)
* **Propósito**: Es el **adaptador de entrada principal** para las interacciones HTTP.
* **Responsabilidades**:
    * `endpoints/`: Define las rutas. Recibe peticiones, valida con `schemas`, y **llama a los servicios de `application/services/`**. No tiene lógica de negocio.
    * `schemas/`: DTOs Pydantic para la API. Siguen siendo el contrato con el cliente HTTP.

### `app/application/` (El Núcleo / El Hexágono)
* **Propósito**: Esta es la **parte central de tu hexágono**. Contiene la lógica de los casos de uso y, *crucialmente*, define las **interfaces (puertos)** que necesita para interactuar con el exterior, pero sin saber *cómo* se implementan.
* **Responsabilidades**:
    * `services/`: Contiene los servicios que implementan los casos de uso (ej: `crear_un_item`, `obtener_items`). **Esta es la lógica principal**.
    * `ports/`: **Define los Puertos de Salida**. Son **INTERFACES** (contratos abstractos). Especifican *qué* necesita hacer la aplicación con sistemas externos (como la base de datos), pero no *cómo*. Ejemplo: `ItemRepositoryPort` con métodos `save(item)`, `find_by_id(item_id)`.
    * `models/`: (Opcional) Si necesitas representar los datos *dentro* de la capa de aplicación de una forma específica, puedes tener modelos aquí. Serían clases de datos simples o Pydantic, pero **no deberían ser los modelos del ORM**. El objetivo es que esta capa no dependa de la BBDD.
    * `exceptions.py`: Excepciones específicas de los flujos de la aplicación.

### `app/infrastructure/` (Adaptadores de Salida)
* **Propósito**: Proporciona las **implementaciones concretas (adaptadores)** para los **puertos** definidos en `app/application/ports/`. Es el *cómo*.
* **Responsabilidades**:
    * `persistence/sqlalchemy_adapter/`: Un ejemplo de implementación para la persistencia.
        * `database.py`: Configura la BBDD.
        * `db_models.py`: **Modelos del ORM** (SQLAlchemy). Estos están ligados a la tecnología de BBDD.
        * `repository.py`: La clase `SQLAlchemyItemRepository` que **implementa** la interfaz `ItemRepositoryPort` definida en `application/ports/`. Contiene el código SQLAlchemy real para interactuar con la BBDD. Puede incluir mapeadores para convertir entre los `db_models` y los `application/models` (si los hay).
    * Aquí pondrías otros adaptadores: clientes HTTP para otras APIs, productores/consumidores de Kafka, etc. Cada uno implementaría un puerto definido en `application`.

### `app/core/` y `tests/`
* Mantienen sus roles anteriores: configuraciones transversales y pruebas (que ahora se enfocarían en probar la `application` con puertos *mockeados* y `infrastructure` con pruebas de integración).

---

### Diferencias Clave con la Versión DDD/Hexagonal

* **Ausencia de `app/domain/`**: No hay una capa explícita y rica para el dominio. La lógica de negocio principal reside en `app/application/services/`.
* **Puertos en `application/`**: Las interfaces (puertos) son definidas por la capa de aplicación, ya que es ella la que *necesita* estos servicios externos para cumplir sus casos de uso.
* **Modelos más Simples**: No hay un enfoque formal en Entidades, Agregados, VOs. Se usan estructuras de datos más simples, a menudo DTOs internos o modelos Pydantic básicos dentro de `application`.
* **Enfoque en Flujo**: La estructura se centra más en el flujo del caso de uso (API -> Servicio App -> Puerto -> Adaptador) que en modelar un dominio complejo.

Esta estructura **mantiene los beneficios clave de la Arquitectura Hexagonal** (testabilidad, flexibilidad, bajo acoplamiento) pero es **más ligera** al no requerir la inversión en el modelado profundo de DDD, siendo adecuada para muchos microservicios donde la lógica de negocio no es extremadamente compleja.


**Paso3: Estructura Hexagonal + DDD:**

¡Excelente! Ahora tomaremos la estructura simplificada y la refactorizaremos para aplicar los principios de la **Arquitectura Hexagonal** y **DDD (Domain-Driven Design)**, basándonos en la descripción inicial que proporcionaste.

El objetivo es lograr un **bajo acoplamiento** y una **alta cohesión**, aislando el núcleo del negocio (dominio) de las tecnologías externas (API, base de datos).


```
mi_microservicio/
├── app/
│   ├── __init__.py
│   ├── main.py           # 🚀 Punto de entrada, Inyección de Dependencias y Routers
│   ├── api/              # 🔌 Adaptador de Entrada (HTTP/FastAPI)
│   │   ├── __init__.py
│   │   └── v1/
│   │       ├── __init__.py
│   │       ├── endpoints/
│   │       │   ├── __init__.py
│   │       │   └── items.py  # 📦 Router para 'items', llama a Application Services
│   │       └── schemas/
│   │           ├── __init__.py
│   │           └── item.py   # 📝 DTOs (Pydantic) para la API
│   ├── application/      # ⚙️ Orquestación y Casos de Uso
│   │   ├── __init__.py
│   │   └── services/
│   │       ├── __init__.py
│   │       └── item_service.py # Implementa casos de uso, usa Repositorios (Interfaces)
│   ├── domain/           # ❤️ Núcleo del Negocio (Agnóstico a la tecnología)
│   │   ├── __init__.py
│   │   ├── model/
│   │   │   ├── __init__.py
│   │   │   └── item.py     # 👑 Entidades, Agregados, VOs del Dominio
│   │   ├── services/
│   │   │   ├── __init__.py
│   │   │   └── ...         # (Opcional) Servicios de Dominio
│   │   ├── repositories.py # 📜 Interfaces/Puertos de Salida (Contratos)
│   │   └── exceptions.py   # ⚠️ Excepciones del Dominio
│   ├── infrastructure/   # 🔩 Adaptadores de Salida (Implementaciones Concretas)
│   │   ├── __init__.py
│   │   └── persistence/
│   │       ├── __init__.py
│   │       ├── sqlalchemy/ # 💾 Implementación con SQLAlchemy
│   │       │   ├── __init__.py
│   │       │   ├── database.py   # Configuración de BBDD y Sesión
│   │       │   ├── models.py     # Modelos del ORM (mapeo a BBDD)
│   │       │   └── repositories.py # 👈 Implementación del Repositorio de Items
│   │       └── ...         # (Otras implementaciones: MongoDB, Kafka, etc.)
│   └── core/             # 🛠️ Configuraciones, Seguridad, Dependencias Transversales
│       ├── __init__.py
│       └── config.py     # Carga de configuraciones
├── tests/                # 🧪 Pruebas (Unitarias, Integración)
│   ├── __init__.py
│   ├── domain/
│   ├── application/
│   └── api/
└── requirements.txt      # 📜 Dependencias del proyecto
```

---


### `app/main.py`
* **Propósito**: Punto de entrada. Su rol principal ahora es **configurar y conectar** las diferentes capas.
* **Responsabilidades**:
    * Crea la instancia de `FastAPI()`.
    * Configura middlewares.
    * **Incluye los routers** de `app/api/v1/endpoints/`.
    * **Configura la Inyección de Dependencias**: Aquí es donde *conectas* las interfaces (puertos) definidas en `domain/repositories.py` con sus implementaciones concretas de `infrastructure/persistence/`. FastAPI facilita esto enormemente.

### `app/api/` (Adaptador de Entrada)
* **Propósito**: Actúa como un **adaptador de entrada**, traduciendo las peticiones HTTP externas en llamadas a la capa de aplicación.
* **Responsabilidades**:
    * `endpoints/`: Contiene los `APIRouter` que definen las rutas HTTP. **No contienen lógica**. Reciben datos HTTP, usan `schemas` para validar/serializar y **llaman a los servicios de la capa `application`**.
    * `schemas/`: Contiene los modelos Pydantic (DTOs). Son el **contrato de datos** de la API, no necesariamente iguales a los modelos del dominio.

### `app/application/` (Capa de Aplicación / Casos de Uso)
* **Propósito**: Orquesta los pasos necesarios para llevar a cabo un **caso de uso** o una acción del negocio.
* **Responsabilidades**:
    * `services/`: Contiene los *Application Services*.
        * **No contienen lógica de negocio** (esa está en el dominio).
        * **Dependen de las *interfaces*** (`domain/repositories.py`), no de implementaciones concretas.
        * Obtienen entidades del dominio a través de los repositorios.
        * **Llaman a métodos de las entidades o servicios del dominio** para ejecutar la lógica.
        * Utilizan los repositorios para persistir los cambios.
        * Pueden manejar transacciones, autorización a nivel de caso de uso, etc.

### `app/domain/` (El Núcleo / El Hexágono)
* **Propósito**: Es el **corazón de tu aplicación**. Contiene toda la lógica y las reglas de negocio, y es **totalmente independiente** de cualquier tecnología externa (FastAPI, SQLAlchemy, etc.).
* **Responsabilidades**:
    * `model/`: Contiene las **Entidades**, **Agregados** y **Value Objects** de DDD. Representan los conceptos del negocio y encapsulan su lógica y estado. Son "Plain Old Python Objects" (o clases con comportamiento).
    * `services/`: (Opcional) Lógica de dominio que no encaja naturalmente en una entidad (ej: cálculos que involucran varias entidades).
    * `repositories.py`: **Define los Puertos de Salida**. Son **INTERFACES** (usando `abc.ABC` o `typing.Protocol` en Python). Definen *qué* se necesita hacer con la persistencia (u otros sistemas externos), pero no *cómo*. Ejemplo: `ItemRepositoryInterface` con métodos como `get_by_id`, `save`.
    * `exceptions.py`: Define excepciones personalizadas que reflejan problemas del negocio.

### `app/infrastructure/` (Adaptadores de Salida)
* **Propósito**: Proporciona las **implementaciones concretas** de los puertos definidos en `app/domain/repositories.py`. También maneja la comunicación con *cualquier* sistema externo.
* **Responsabilidades**:
    * `persistence/sqlalchemy/`: Un ejemplo de implementación para persistencia.
        * `database.py`: Configura SQLAlchemy (conexión, sesión).
        * `models.py`: Define los **modelos de SQLAlchemy**. *Importante*: Estos son modelos de persistencia, pueden ser diferentes a los modelos de dominio. A menudo se necesita un **mapeador** para convertir entre modelos de dominio y modelos de persistencia.
        * `repositories.py`: **Implementa las interfaces** de `domain/repositories.py`. Por ejemplo, `SQLAlchemyItemRepository` implementa `ItemRepositoryInterface` usando SQLAlchemy para hablar con la base de datos.

### `app/core/`
* **Propósito**: Mantiene su rol de configuraciones y utilidades transversales.
* **Responsabilidades**: Configuración (`BaseSettings`), seguridad, dependencias comunes.

### `tests/`
* **Propósito**: Pruebas, ahora idealmente estructuradas por capa.
* **Responsabilidades**:
    * **Unitarias**: Para `domain` (muy importantes) y `application` (usando mocks para los repositorios).
    * **Integración**: Para `infrastructure` (probando la conexión real a BBDD) y `api` (probando los endpoints de punta a punta, a menudo con una BBDD de prueba).


### Beneficios Clave de esta Refactorización

1.  **Aislamiento del Dominio**: La lógica de negocio está protegida de cambios en la tecnología (cambiar FastAPI por Flask, o SQLAlchemy por MongoDB, afecta principalmente a `api` e `infrastructure`).
2.  **Testabilidad**: El dominio y la aplicación se pueden probar de forma aislada y rápida, sin necesidad de BBDD o frameworks web.
3.  **Flexibilidad**: Es más fácil añadir nuevos adaptadores (ej: una CLI como entrada, o un bus de eventos como salida) sin tocar el núcleo.
4.  **Mantenibilidad**: La separación clara de responsabilidades hace que el código sea más fácil de entender, modificar y mantener a medida que crece.

> El *pegamento* que une todo esto es la **Inyección de Dependencias**, gestionada típicamente en `app/main.py`, donde le dices a FastAPI (o a un contenedor de dependencias) qué implementación concreta (`SQLAlchemyItemRepository`) debe usar cuando una clase (`ItemService`) pide una interfaz (`ItemRepositoryInterface`).


## 2.4. Gestión de Rutas y Controladores RESTful Desacoplados

Imagina nuestro microservicio como una fortaleza medieval (nuestro Dominio Hexagonal). La API REST es su **puente levadizo y su cuerpo de guardia**: el punto de entrada controlado. Si los guardias (nuestros controladores) empiezan a tomar decisiones estratégicas o a cultivar sus propios campos (lógica de negocio), ¡tendremos un caos! Su misión es **verificar, traducir y dirigir** el tráfico hacia el interior del castillo, manteniéndose **delgados, eficientes y estrictamente enfocados** en su rol.

Este punto trata sobre cómo construir esa fachada con FastAPI, usando `APIRouter` y diseñando controladores que sean **guardianes ejemplares**, no señores feudales, asegurando un **desacoplamiento total** con nuestro núcleo.

#### 1. REST: El Protocolo Diplomático de Nuestras APIs 

Para que nuestros microservicios hablen un idioma universal en la web, nos apoyamos en los principios REST (Representational State Transfer). Es como el latín de las APIs: aunque no siempre se hable puro, entender sus bases nos permite comunicarnos eficazmente.

| Principio | Verbo HTTP | Propósito Típico (CRUD) | Ejemplo URI | Códigos Comunes |
| :--- | :--- | :--- | :--- | :--- |
| **Recursos** | - | Identifica "cosas" (Pedidos, Usuarios) | `/orders`, `/users/123` | - |
| **Acciones** | `GET` | **Leer** (Read) | `/orders/123` | 200 (OK), 404 (Not Found) |
| | `POST` | **Crear** (Create) | `/orders` | 201 (Created), 400 (Bad Request) |
| | `PUT` | **Actualizar/Reemplazar** (Update) | `/orders/123` | 200 (OK), 404, 400 |
| | `PATCH` | **Actualizar Parcialmente** (Update) | `/orders/123` | 200 (OK), 404, 400 |
| | `DELETE` | **Eliminar** (Delete) | `/orders/123` | 204 (No Content), 404 |
| **Stateless** | - | Cada petición es independiente. | - | - |

Usar REST nos da **previsibilidad** y nos permite aprovechar la infraestructura web (caches, proxies).

#### 2. `APIRouter`

Un castillo no tiene una sola puerta gigante; tiene varias, cada una para un propósito. `APIRouter` es la herramienta de FastAPI para **organizar nuestras rutas** en módulos lógicos, evitando un `main.py` monstruoso.

* **Función:** Permite agrupar rutas relacionadas (ej: todas las de `/orders`), asignarles prefijos (`/api/v1/orders`), etiquetas para la documentación (`tags=["Orders"]`), e incluso dependencias específicas.
* **Implementación:** En nuestra estructura (`app/api/v1/endpoints/`), cada archivo (ej: `orders.py`, `users.py`) define un `APIRouter`.

**Visualizando la Estructura de Routers:**

```mermaid
    graph TD
        subgraph "Archivo: app/main.py"
            A["FastAPI"]
        end

        subgraph "Módulos: app/api/v1/endpoints/"
            B["orders.py<br/>prefix '/orders'"]
            C["users.py<br/>prefix '/users'"]
            D["products.py<br/>prefix '/products'"]
        end

        A --> B
        A --> C
        A --> D

        B --> B1["@post '/'"]
        B --> B2["@get '/{id}'"]
        C --> C1["@post '/'"]
        C --> C2["@get '/{id}'"]
        D --> D1["@get '/'"]

        style A fill:#f9f,stroke:#333
        style B fill:#ccf,stroke:#333
        style C fill:#ccf,stroke:#333
        style D fill:#ccf,stroke:#333


```

Esto nos da **modularidad y claridad**. Cada `APIRouter` es un "puesto de guardia" especializado.

#### 3. El Controlador Ideal

El **"Controlador"** en nuestro contexto es la **función Python decorada** con `@router.get`, `@router.post`, etc. Su *única* misión es:

1.  **Recibir y Validar:** Aceptar la petición HTTP y dejar que FastAPI y Pydantic hagan su magia validando tipos, formatos y reglas de los `schemas` (DTOs) de entrada.
2.  **Obtener Dependencias:** Usar `Depends` para solicitar "ayuda" (instancias de Servicios de Aplicación). **¡Esta es la clave del desacoplamiento!**
3.  **Delegar:** Llamar al método apropiado del Servicio de Aplicación, pasándole los datos limpios y validados.
4.  **Formatear y Devolver:** Recibir el resultado del servicio y dejar que FastAPI y Pydantic (usando `response_model`) lo conviertan en una respuesta HTTP_ **correcta y consistente.**

**Flujo Interno de un Controlador:**

```mermaid
graph LR
    A[Petición HTTP Entrante] --> B["FastAPI y Pydantic"]
    B -->|Valida body, query, path| C["Datos validados (DTOs)"]
    B -->|Resuelve Depends| D["Servicio de aplicación"]
    E["Función Endpoint"] -->|Usa| C
    E -->|Llama| D
    D --> F["Resultado (Dominio o DTO)"]
    E -->|Recibe| F
    E --> G["FastAPI y Pydantic"]
    G -->|Serializa con response_model| H["Respuesta HTTP Saliente"]

    subgraph "Controlador: Función Endpoint"
        E
    end

    subgraph "Magia de FastAPI"
        B
        G
    end

    subgraph "Capa de Aplicación"
        D
    end

    style E fill:#f9f,stroke:#333

```

**¡El Controlador NUNCA debe contener lógica de negocio!** No debe hacer cálculos complejos, ni hablar con la BBDD, ni saber *cómo* funciona realmente el Dominio. Es un **pasamanos inteligente**.

#### 4. Logrando el Desacoplamiento Real

Al seguir este patrón, nuestra capa `api` (`Controladores` y `Schemas`) se convierte en un **Adaptador de Entrada** perfectamente definido:

* **Depende Hacia Adentro:** Solo depende de la capa de `application` (a través de `Depends` y las llamadas a servicios) y de sus propios `schemas`.
* **Ignora el Interior:** No tiene idea de si la `application` usa `domain`, ni cómo `infrastructure` implementa la persistencia.
* **Intercambiable:** Podríamos cambiar FastAPI por otro framework (con esfuerzo, claro) modificando solo la capa `api`, sin tocar `application` ni `domain`.



#### 5. Beneficios Inapelables 

* **Flexibilidad:** Cambia tu API sin romper el núcleo.
* **Mantenibilidad:** Código fácil de encontrar, entender y modificar.
* **Testabilidad Suprema:** Testea la API *mockeando* la aplicación. Testea la aplicación *mockeando* los repos. Testea el dominio ¡sin mocks!
* **Claridad Arquitectónica:** Cada pieza tiene su sitio y su misión.


La gestión de rutas y controladores en FastAPI, cuando se hace con una **mentalidad de desacoplamiento** y siguiendo los principios **Hexagonales**, transforma nuestra capa API de un posible monolito en sí misma a una **interfaz elegante, organizada y reemplazable**. Usando `APIRouter` para la estructura y diseñando controladores como **traductores delgados** que delegan en la capa de aplicación, sentamos las bases para microservicios que no solo son funcionales, sino también **arquitectónicamente sólidos y preparados para el futuro**.


---


## 2.5. Implementación de Middlewares Personalizados

> Un **middleware** es un componente de software que se sitúa "en medio" de otros dos componentes, interceptando y procesando la comunicación entre ellos. Piensa en él como una serie de "peajes" o "estaciones de procesamiento" por las que una solicitud (request) y su respuesta (response) deben pasar.

En un entorno de **microservicios real** necesitamos middlewares que resuelvan:

* **Logs detallados** de cada request/response.
* **Medición precisa** de tiempos de respuesta.
* **Headers de seguridad** estándar (XSS, HSTS, etc.).
* **Prevalidación de tokens** antes del router.
* **Control de CORS** centralizado.
* **Modificación de respuestas** (e.g., añadir metadatos a la respuesta).

Aquí vamos a crear **middlewares personalizados** para cada uno de esos aspectos, **sin depender de librerías externas** salvo lo estrictamente necesario, como `pydantic` y `fastapi`.

### Estructura

```
app/
├── main.py
├── middlewares/
│   ├── __init__.py
│   ├── logging_middleware.py
│   ├── timer_middleware.py
│   ├── security_headers_middleware.py
│   ├── auth_middleware.py
│   ├── cors_middleware.py
│   └── response_middleware.py
└── routers/
    ├── __init__.py
    └── health.py
```


### Logs de peticiones/respuestas

**middlewares/logging\_middleware.py**

```python
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
import logging

logger = logging.getLogger("uvicorn.access")

class LoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        logger.info(f"Request: {request.method} {request.url.path}")
        response = await call_next(request)
        logger.info(f"Response status: {response.status_code} for {request.url.path}")
        return response
```

---

### Medición de tiempos de respuesta

**middlewares/timer\_middleware.py**

```python
import time
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

class TimerMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start_time = time.perf_counter()
        response = await call_next(request)
        duration = time.perf_counter() - start_time
        response.headers["X-Process-Time"] = f"{duration:.5f}s"
        return response
```

Esto añade un **header** `X-Process-Time` en cada respuesta.

---

### Aplicar headers de seguridad

**middlewares/security\_headers\_middleware.py**

```python
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)
        # Headers anti ataques comunes
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        return response
```

Estos headers mejoran la **seguridad** de la app contra clickjacking, XSS y otras vulnerabilidades básicas.

---

### Autenticaciones preliminares (token parsing simple)

**middlewares/auth\_middleware.py**

```python
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from fastapi import HTTPException

class AuthMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        if request.url.path.startswith("/health"):  # Permitimos health check sin auth
            return await call_next(request)

        token = request.headers.get("Authorization")
        if not token or not token.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Missing or invalid Authorization header")
        
        # Simular parseo simple (sin validar el JWT entero aquí)
        payload = token.split(" ")[1]
        request.state.user_token = payload  # Guardamos token en state para el endpoint

        response = await call_next(request)
        return response
```

---

### Control de CORS (Cross-Origin Resource Sharing)

**middlewares/cors\_middleware.py**

Aunque FastAPI tiene su propio CORS middleware, **personalizamos** uno propio para control detallado:

```python
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response

class CustomCORSMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        if request.method == "OPTIONS":
            response = Response()
        else:
            response = await call_next(request)

        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
        response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type"
        return response
```

✅ Permite CORS básico para todas las rutas. Ideal para desarrollo o ajustable a dominios específicos en producción.



### Modificación de la respuesta global

**middlewares/response\_middleware.py**

Añadimos un wrapper al body de la respuesta:

```python
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse
import json

class ResponseModifierMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        response = await call_next(request)

        if response.headers.get("content-type") == "application/json":
            body = b""
            async for chunk in response.body_iterator:
                body += chunk

            data = json.loads(body)
            modified_data = {
                "success": True,
                "data": data,
                "metadata": {
                    "path": str(request.url.path),
                    "method": request.method,
                }
            }

            return JSONResponse(content=modified_data, status_code=response.status_code)
        
        return response
```

🔎 Esto garantiza que **todas** las respuestas JSON devuelvan un formato homogéneo con:

* `success: true`
* `data: <contenido original>`
* `metadata: path + method`



### Integración en `main.py`

```python
from fastapi import FastAPI
from app.middlewares.logging_middleware import LoggingMiddleware
from app.middlewares.timer_middleware import TimerMiddleware
from app.middlewares.security_headers_middleware import SecurityHeadersMiddleware
from app.middlewares.auth_middleware import AuthMiddleware
from app.middlewares.cors_middleware import CustomCORSMiddleware
from app.middlewares.response_middleware import ResponseModifierMiddleware
from app.routers import health

app = FastAPI()

# Registro de middlewares personalizados
app.add_middleware(LoggingMiddleware)
app.add_middleware(TimerMiddleware)
app.add_middleware(SecurityHeadersMiddleware)
app.add_middleware(AuthMiddleware)
app.add_middleware(CustomCORSMiddleware)
app.add_middleware(ResponseModifierMiddleware)

app.include_router(health.router)
```

**Orden de middlewares** importa:

1. Logging primero para capturar toda la petición.
2. Timing segundo para capturar tiempos reales.
3. Seguridad después.
4. Autenticación previa a cualquier lógica.
5. CORS para manejar preflights.
6. Modificación de respuesta al final.


### Resultado esperado

✅ **Request Log:**

```
INFO:     Request: GET /health
INFO:     Response status: 200 for /health
```

✅ **Headers en respuesta:**

```
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Process-Time: 0.00123s
```

✅ **CORS en todas las respuestas:**

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Authorization, Content-Type
```

✅ **Formato homogéneo de respuestas JSON:**

```json
{
  "success": true,
  "data": {
    "status": "ok"
  },
  "metadata": {
    "path": "/health",
    "method": "GET"
  }
}
```

✅ **401 Unauthorized** si no envías Authorization:

```json
{
  "detail": "Missing or invalid Authorization header"
}
```



## 2.6. Aplicación del Sistema de Dependencias e Inyecciones


La **Inyección de Dependencias (DI)** es un **patrón de diseño** en el que un objeto recibe ("se le inyectan") sus **dependencias** en lugar de crearlas internamente.

* **Dependencia**: Cualquier objeto del que otra clase depende para funcionar (por ejemplo: conexión a base de datos, cliente API, configuración).
* **Inyección**: No es la clase quien crea sus dependencias. Se las pasan desde fuera, normalmente el framework.

###  **¿Qué problema resuelve?**

* **Acoplamiento fuerte**: Si una clase crea su propio `Database()`, depende **directamente** de esa implementación.
* **Testabilidad**: Si la dependencia está "pegada" internamente, no puedes **simular (mockear)** en un test.
* **Mantenibilidad**: Difícil cambiar la implementación (`Database` -> `MockDatabase`) sin tocar muchas líneas.

👉 **DI** elimina estos problemas porque la dependencia es inyectada externamente, el objeto solo espera recibir lo que necesita.


### ¿Cómo maneja FastAPI la Inyección de Dependencias?

FastAPI implementa un **sistema de dependencias ligero** que:

1. Usa funciones o clases declaradas como dependencias.
2. Llama automáticamente a esas funciones para **resolver** los objetos requeridos.
3. Maneja el **ciclo de vida** (lifetime) de las dependencias.
4. Permite **overrides** de dependencias fácilmente (especialmente útil en testing).

Se basa en:

* **`Depends`**: Declaras que un parámetro se debe resolver con una función.
* **Resolución automática**: FastAPI resuelve la jerarquía completa de dependencias.
* **Alcances (scopes)**: Puedes controlar si una dependencia vive por **petición** o **globalmente**.

---

### Cómo funciona técnicamente

Cuando defines:

```python
def get_settings():
    return Settings()
```

y luego en un endpoint:

```python
@app.get("/items")
def read_items(settings: Settings = Depends(get_settings)):
    return settings.app_name
```

FastAPI:

1. **Detecta** que `read_items` necesita un parámetro `settings`.
2. **Ejecuta** `get_settings()` para obtener el `Settings`.
3. **Inyecta** ese objeto **automáticamente** en el endpoint.

⚡️ **El endpoint no sabe de dónde viene `Settings`. Solo sabe que lo recibe**.

### Además:

* Si `get_settings` tuviera a su vez dependencias (por ejemplo, leer de un SecretManager), FastAPI resolvería también esa cadena.

---

### ¿Qué podemos inyectar?

* **Configuraciones** (`Settings` de Pydantic).
* **Instancias de base de datos**.
* **Servicios de negocio** (por ejemplo, `UserService`).
* **Cliente HTTP externo** (`HTTPX.AsyncClient`).
* **Usuario autenticado actual**.
* **Objetos de caché** (`Redis`, `Memcached`).
* **Conexiones de mensajería** (`RabbitMQ`, `Kafka`).

Todo **por petición** (scoped) o **global**.




La **Inyección de Dependencias** (Dependency Injection) es un **patrón de diseño** en el que un objeto recibe ("se le inyecta") las instancias que necesita para funcionar, en lugar de crearlas él mismo.

> **Objetivo:** reducir el **acoplamiento** entre componentes, hacer el sistema más **flexible**, **escalable** y **testable**.

✅ **En lugar de**:
Una clase creándose sus propias dependencias:

```python
class UserService:
    def __init__(self):
        self.db = DatabaseConnection()  # ❌ Mal, acoplado
```

✅ **Con DI**:
La clase **recibe** la dependencia:

```python
class UserService:
    def __init__(self, db):
        self.db = db  # ✅ Bien, inyectado externamente
```

---

### **¿Cómo funciona la DI en FastAPI?**

FastAPI proporciona un sistema de **resolución automática de dependencias** mediante la función `Depends`.

* **Declaras** funciones o clases que proporcionan objetos como dependencias.
* **FastAPI resuelve automáticamente** estas dependencias cuando recibe una petición.
* El sistema es **asíncrono** y soporta dependencias **anidadas**.

> FastAPI llama a las funciones declaradas en `Depends`, resuelve el objeto y lo pasa al endpoint.

### **Ejemplo Básico**

```python
from fastapi import FastAPI, Depends

app = FastAPI()

def get_db():
    return "Database Connection"

@app.get("/items/")
def read_items(db=Depends(get_db)):
    return {"db_connection": db}
```

Cuando FastAPI recibe una petición:

* **Invoca** `get_db()`.
* **Obtiene** el valor retornado.
* **Lo inyecta** como parámetro `db` en el endpoint.



### **¿Qué se puede inyectar en FastAPI?**

| Tipo de dependencia                          | Ejemplo                                             |
| -------------------------------------------- | --------------------------------------------------- |
| **Configuración** (`BaseSettings`)           | Variables de entorno, configuración global          |
| **Base de datos** (`Database Session`)       | Conexiones SQLAlchemy, Redis, MongoDB               |
| **Servicios** (`UserService`, `AuthService`) | Lógica de negocio desacoplada                       |
| **Clientes externos** (`HTTP Clients`)       | Integraciones con APIs externas usando `httpx`      |
| **Usuario autenticado** (`Security`)         | Validación de tokens, JWTs, autorización por scopes |
| **Background Tasks**                         | Tareas asincrónicas inyectadas                      |

**Importante**: FastAPI también soporta dependencias **anidadas** y **context managers** (`yield`) para manejo de recursos.


Un proyecto FastAPI **bien estructurado** guarda las dependencias en un módulo propio:

```
app/
├── api/
│   ├── deps/                # <--- 📦 Dependencias aquí
│   │   ├── config_deps.py
│   │   ├── db_deps.py
│   │   ├── services_deps.py
│   │   ├── auth_deps.py
│   │   └── external_deps.py
```



### 1 **Inyección de Configuración Global**

**`config_deps.py`**

```python
from pydantic import BaseSettings

class Settings(BaseSettings):
    database_url: str = "sqlite:///./test.db"
    secret_key: str = "supersecret"

    class Config:
        env_file = ".env"

def get_settings():
    return Settings()
```

**Uso en ruta:**

```python
from fastapi import FastAPI, Depends
from app.api.deps.config_deps import get_settings

app = FastAPI()

@app.get("/config")
def read_config(settings=Depends(get_settings)):
    return {"db_url": settings.database_url}
```

---

### 2 **Inyección de Conexión a Base de Datos**

**`db_deps.py`**

```python
from app.api.deps.config_deps import get_settings
from fastapi import Depends

class Database:
    def __init__(self, url):
        self.url = url

def get_db(settings=Depends(get_settings)):
    return Database(settings.database_url)
```

**Uso en ruta:**

```python
@app.get("/db")
def read_db(db=Depends(get_db)):
    return {"connected_to": db.url}
```

---

### 3 **Inyección de Servicio de Negocio**

**`services_deps.py`**

```python
from app.api.deps.db_deps import get_db
from fastapi import Depends

class UserService:
    def __init__(self, db):
        self.db = db

    def get_user(self, user_id):
        return {"user_id": user_id, "db_url": self.db.url}

def get_user_service(db=Depends(get_db)):
    return UserService(db)
```

**Uso en ruta:**

```python
@app.get("/users/{user_id}")
def get_user(user_id: int, user_service=Depends(get_user_service)):
    return user_service.get_user(user_id)
```

---

### 4 **Inyección de Usuario Autenticado**

**`auth_deps.py`**

```python
from fastapi import Request, HTTPException

def get_current_user(request: Request):
    token = request.headers.get("Authorization")
    if not token or not token.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Unauthorized")
    
    user_id = token.split(" ")[1]  # Simulación sencilla
    return {"user_id": user_id}
```

**Uso en ruta:**

```python
@app.get("/me")
def read_me(current_user=Depends(get_current_user)):
    return {"user": current_user}
```

---

### 5 **Inyección de Cliente HTTP Externo**

**`external_deps.py`**

```python
import httpx

async def get_http_client():
    async with httpx.AsyncClient() as client:
        yield client
```

**Uso en ruta:**

```python
@app.get("/external")
async def external_api(client=Depends(get_http_client)):
    response = await client.get("https://jsonplaceholder.typicode.com/todos/1")
    return response.json()
```



## 2.7. Integración Automática de Documentación con OpenAPI


### **¿Qué es OpenAPI?**

> **OpenAPI** es un estándar que define un formato para describir APIs RESTful de forma clara y estructurada.

Con OpenAPI:

* Los **clientes** (frontend, móviles, integradores) saben **cómo consumir** tu API.
* Puedes **generar documentación interactiva** (Swagger UI, Redoc).
* Facilitas la **integración** entre sistemas (por ejemplo, generación automática de SDKs).

**Antes:** API mal documentadas con Postman y correos.
**Ahora:** OpenAPI genera **auto-documentación** confiable y siempre sincronizada con el código.

**FastAPI** tiene integración **nativa y automática** con OpenAPI — **sin escribir código extra**.



### **¿Cómo integra FastAPI la documentación?**

Cada vez que defines un endpoint:

```python
@app.get("/items/{item_id}")
def read_item(item_id: int):
    return {"item_id": item_id}
```

FastAPI **genera** automáticamente:

* El método HTTP (`GET`).
* La URL (`/items/{item_id}`).
* Los parámetros (`item_id`).
* El schema de la respuesta (basado en los tipos de retorno).

✅ Esta información es convertida en un **documento OpenAPI** en JSON:

```
GET /items/{item_id}
  - parameters: item_id (path)
  - response: 200 OK { "item_id": int }
```

Y automáticamente expone:

* **Swagger UI** en `/docs`
* **Redoc** en `/redoc`
* **OpenAPI JSON** en `/openapi.json`

---

### **Interfaces Generadas Automáticamente**

| UI           | URL             | Descripción                             |
| ------------ | --------------- | --------------------------------------- |
| Swagger UI   | `/docs`         | Interfaz interactiva para probar la API |
| Redoc        | `/redoc`        | Documentación estructurada estilo Redoc |
| OpenAPI JSON | `/openapi.json` | Documento OpenAPI en JSON exportable    |

---

### **Personalización de la Documentación**

FastAPI permite personalizar:

* **Título**, **descripción**, **versión** de la API.
* **Tags** para organizar endpoints.
* **Descripción de endpoints**, **parámetros**, **códigos de estado**, **modelos de respuesta**.

### Definir Metadata General

```python
from fastapi import FastAPI

app = FastAPI(
    title="My Microservice API",
    description="API de ejemplo para el microservicio de usuarios",
    version="1.0.0",
    contact={
        "name": "Equipo Backend",
        "email": "backend@empresa.com",
    },
    license_info={
        "name": "MIT",
        "url": "https://opensource.org/licenses/MIT",
    },
)
```

---

### Documentar Endpoints con Tags

**Uso de tags** para categorizar operaciones:

```python
from fastapi import APIRouter

router = APIRouter()

@router.get("/users/{user_id}", tags=["Usuarios"])
def get_user(user_id: int):
    return {"user_id": user_id}
```

### Descripción de Endpoints y Parámetros

Añadir descripción legible:

```python
from fastapi import Path

@router.get("/items/{item_id}", tags=["Items"], summary="Obtener un ítem por ID", description="Devuelve un ítem específico basado en el ID.")
def read_item(
    item_id: int = Path(..., title="ID del Ítem", description="El ID debe ser un entero positivo.", gt=0)
):
    return {"item_id": item_id}
```

* **`summary`**: aparece como título corto.
* **`description`**: explicación detallada.
* **`Path` metadata**: documenta los parámetros.

---

### Documentar Respuestas Personalizadas

```python
from fastapi import status
from fastapi.responses import JSONResponse

@router.get("/users/{user_id}", responses={
    200: {"description": "Usuario encontrado exitosamente"},
    404: {"description": "Usuario no encontrado"},
})
def get_user(user_id: int):
    fake_db = {1: "Alice", 2: "Bob"}
    if user_id in fake_db:
        return {"name": fake_db[user_id]}
    return JSONResponse(status_code=404, content={"detail": "User not found"})
```

> FastAPI **extiende automáticamente** el OpenAPI con esta información.

---

### Documentar Request Body y Response Model

Uso de **Pydantic models** para describir el cuerpo de las peticiones y respuestas:

```python
from pydantic import BaseModel

class Item(BaseModel):
    name: str
    price: float

@app.post("/items/", response_model=Item, tags=["Items"])
def create_item(item: Item):
    return item
```

* **`response_model`**: indica qué retorna el endpoint.
* FastAPI usa los **modelos de Pydantic** para generar el schema OpenAPI automáticamente.

---

### **Ejemplo Profesional de Documentación Completa**

```python
from fastapi import FastAPI, Path
from pydantic import BaseModel

app = FastAPI(
    title="User Microservice",
    description="API para gestión de usuarios en el sistema.",
    version="2.1.0",
    contact={"name": "Equipo de Ingeniería", "email": "soporte@empresa.com"},
    license_info={"name": "Apache 2.0", "url": "https://www.apache.org/licenses/LICENSE-2.0.html"}
)

class User(BaseModel):
    id: int
    name: str
    email: str

@app.get("/users/{user_id}", response_model=User, tags=["Usuarios"], summary="Obtener información de usuario", description="Este endpoint devuelve la información detallada de un usuario por su ID.", responses={404: {"description": "Usuario no encontrado"}})
def get_user(user_id: int = Path(..., description="ID único del usuario", gt=0)):
    fake_user_db = {1: User(id=1, name="Alice", email="alice@example.com")}
    user = fake_user_db.get(user_id)
    if user:
        return user
    return {"detail": "Usuario no encontrado"}
```


### **¿Dónde Documentar en un Proyecto Real?**

En un proyecto profesional, puedes organizar así:

```
app/
├── main.py                 # Configuración general de la API
├── api/
│   ├── routes/
│   │   ├── user_routes.py   # Documentación por endpoint
├── models/
│   ├── user.py              # Modelos Pydantic bien documentados
```

Cada **router** (`user_routes.py`) define sus **tags**, **respuestas** y **modelos**.

**En `main.py`** defines la **metadata general** de OpenAPI (`title`, `description`, `contact`...).


### **Buenas Prácticas**

| Práctica                                  | Por qué es importante                                         |
| ----------------------------------------- | ------------------------------------------------------------- |
| Usar **tags**                             | Agrupa endpoints y mejora la navegación en Swagger            |
| Definir **summary** y **description**     | Clarifica rápidamente qué hace cada endpoint                  |
| Documentar **parámetros**                 | Evita malentendidos en las integraciones                      |
| Usar **response\_model**                  | Asegura contratos de salida, evita cambios no documentados    |
| Versionar la API (`version="1.0.0"`)      | Permite mantener compatibilidad hacia atrás                   |
| Añadir **responses** personalizadas       | Documenta posibles errores y sus códigos HTTP                 |
| Mantener la documentación **actualizada** | La doc debe reflejar siempre el comportamiento real de la API |



## 2.8. Utilización de BackgroundTasks para tareas asincrónicas

Imagina que un cliente hace un pedido en tu E-Commerce. Quieres enviarle la confirmación (`201 Created`) lo más rápido posible. Pero, además, necesitas enviar un email de bienvenida, actualizar unas estadísticas internas y quizás notificar al almacén. ¿Debe el cliente esperar a que todo eso termine? ¡Por supuesto que no!

Aquí es donde entra en juego `BackgroundTasks`: es el mecanismo de FastAPI (heredado de Starlette) que te permite **programar la ejecución de una o más funciones *después* de haber enviado la respuesta al cliente**. Es como decirle a un asistente: "En cuanto le dé el 'OK' al cliente, encárgate de estas tareas secundarias".

#### 1. ¿Por Qué y Cuándo Usar `BackgroundTasks`?

Se utilizan para tareas **"Fire and Forget"** (dispara y olvida) o **no críticas** que no deben bloquear la respuesta principal. Su principal ventaja es **mejorar la latencia percibida** por el cliente.

**Casos de Uso Ideales:**

* **Notificaciones :** Enviar emails (bienvenida, confirmación) o SMS.
* **Logging Extendido :** Registrar eventos detallados que no son críticos para la respuesta.
* **Limpieza Simple :** Eliminar archivos temporales.
* **Actualizaciones Menores :** Incrementar un contador en Redis, actualizar estadísticas no vitales.
* **Llamadas a Webhooks :** Notificar a otros sistemas sin esperar su respuesta.

#### 2. ¡La Advertencia Crucial!

`BackgroundTasks` tiene una característica fundamental que **debes entender perfectamente**:

**¡Se ejecutan en el MISMO proceso y Bucle de Eventos (Event Loop) que tu aplicación FastAPI!**

Esto implica:

* **No son para Tareas Pesadas:** Si tu tarea consume mucha CPU o I/O durante mucho tiempo, **bloqueará el Event Loop**, ¡y toda tu aplicación dejará de responder a nuevas peticiones!
* **No son para Tareas Críticas:** Si tu servidor se reinicia o crashea *antes* de que la tarea se ejecute, **se perderá**. No hay reintentos ni persistencia incorporados.
* **Comparten Recursos:** Compiten por CPU, memoria y conexiones con tus endpoints principales.

**`BackgroundTasks` vs. Colas de Tareas Dedicadas (Celery, RQ, ARQ):**

| Característica | `BackgroundTasks` (FastAPI) | Colas Dedicadas (Celery, RQ, ARQ) |
| :--- | :--- | :--- |
| **Infraestructura** | **Ninguna extra**. Integrado. | **Requerida** (Broker: Redis/RabbitMQ, Workers). |
| **Complejidad** | **Muy Baja**. Fácil de usar. | **Media/Alta**. Configuración, workers, monitorización. |
| **Garantías** | **Bajas**. "Best Effort", se pierden si crashea. | **Altas**. Persistencia, reintentos, colas, prioridades. |
| **Casos de Uso** | Tareas ligeras, rápidas, no críticas. | Tareas pesadas, largas, críticas, procesamiento por lotes. |
| **Escalabilidad** | Limitada al proceso principal. | **Alta**. Puedes escalar workers independientemente. |
| **Rendimiento App** | **Puede impactar** si la tarea es pesada. | **No impacta** (se ejecuta en procesos/máquinas separadas). |

**Conclusión:** Usa `BackgroundTasks` con **sabiduría y precaución**. Si dudas, ¡probablemente necesites una cola dedicada!

#### 3. Implementación Práctica

Usarlas es sorprendentemente sencillo:

1.  Importa `BackgroundTasks` de `fastapi`.
2.  Añádelo como un **parámetro** a tu *path operation function*. FastAPI lo **inyectará** automáticamente (¡hola, DI!).
3.  Usa el método `background_tasks.add_task(func, arg1, arg2, kwarg1="valor")`.

**Conceptualización (Enviar Email de Bienvenida):**

```python
# Concepto: app/api/v1/endpoints/users.py

from fastapi import FastAPI, Depends, BackgroundTasks
from pydantic import BaseModel, EmailStr
# from app.utils.email import send_welcome_email # Tu función de email

# --- Tu función (puede ser sync o async) ---
def send_welcome_email_task(email: EmailStr, name: str):
    print(f"INFO: Enviando email de bienvenida a {email}...")
    # Lógica real de envío (send_welcome_email(email, name))
    # ¡Simulamos que tarda un poco!
    import time
    time.sleep(3) # ¡OJO! En una app real, esto bloquearía si fuera sync.
                  # ¡La función de envío real debería ser async o correr en un threadpool!
    print(f"INFO: Email enviado a {email}.")

# --- Tu Schema Pydantic ---
class UserCreate(BaseModel):
    email: EmailStr
    password: str
    name: str

class UserOut(BaseModel):
    email: EmailStr
    name: str

# --- Tu Endpoint ---
@router.post("/users/", status_code=201, response_model=UserOut)
async def create_user(
    user_in: UserCreate,
    background_tasks: BackgroundTasks # <-- ¡Inyección Mágica!
):
    """Crea un nuevo usuario y envía un email de bienvenida en segundo plano."""

    # 1. Lógica principal (Crear usuario en BBDD, etc.)
    print(f"INFO: Creando usuario {user_in.email}...")
    user_created = UserOut(email=user_in.email, name=user_in.name) # Simulación
    print(f"INFO: Usuario {user_in.email} creado.")

    # 2. ¡Añadir la tarea!
    background_tasks.add_task(
        send_welcome_email_task, # La función a llamar
        user_in.email,           # Argumento posicional 1
        user_in.name             # Argumento posicional 2
    )
    print("INFO: Tarea de email añadida. Devolviendo respuesta...")

    # 3. Devolver la respuesta INMEDIATAMENTE
    return user_created
```

#### 4. Visualizando el Flujo Asíncrono

```mermaid
sequenceDiagram
    participant C as Cliente
    participant F as FastAPI / Endpoint
    participant B as BackgroundTasks
    participant T as Tarea (Email)

    C->>F: POST /users/ (Petición)
    F->>F: Procesa Petición (Crea Usuario)
    F->>B: background_tasks.add_task(...)
    B-->>F: Tarea Añadida OK
    F-->>C: 201 Created (Respuesta Rápida)
    Note right of C: ¡Cliente Feliz! Ya tiene respuesta.
    B->>T: Ejecuta send_welcome_email_task(...)
    Note over T: ...enviando email (tarda 3s)...
    T-->>B: Tarea Completada
```

Este diagrama muestra claramente que la **respuesta al cliente (`201 Created`) se envía *antes*** de que la tarea en segundo plano (`send_welcome_email_task`) siquiera comience o termine.

`BackgroundTasks` es una herramienta **útil y conveniente** en el arsenal de FastAPI para mejorar la experiencia del usuario al **diferir tareas no esenciales** y devolver respuestas más rápidamente. Sin embargo, su poder viene con la **gran responsabilidad** de entender sus limitaciones: funcionan dentro del mismo proceso y están diseñadas para **operaciones ligeras y no críticas**. Usarlas con **rigor**, sabiendo cuándo son apropiadas y cuándo es imperativo escalar a un sistema de colas dedicado, es una marca de madurez en el desarrollo de microservicios con FastAPI.

---



## 2.9. Manejo de Excepciones Personalizadas

En un mundo ideal, nuestras APIs siempre funcionarían perfectamente. Pero en el mundo real, los errores ocurren: datos no encontrados, reglas de negocio violadas, sistemas externos caídos. Un **manejo de excepciones robusto** no consiste solo en evitar que la aplicación se caiga; consiste en **comunicar esos errores** de forma clara y estandarizada al cliente.

FastAPI ofrece un manejo básico, pero su verdadero poder reside en permitirnos crear un **sistema de excepciones personalizado**, alineado con nuestro **Dominio (DDD)** y que se traduce en **respuestas HTTP significativas**.

#### 1. La Base: El Manejo por Defecto de FastAPI

FastAPI ya nos da una red de seguridad:

* **`HTTPException`**: Puedes lanzarla manualmente (`raise HTTPException(status_code=404, detail="Item not found")`) para devolver respuestas HTTP de error estándar. Es útil, pero **acopla tu lógica a HTTP**.
* **`RequestValidationError`**: Se lanza automáticamente cuando Pydantic falla al validar la entrada. Devuelve un **HTTP 422** con detalles sobre los campos erróneos.

Si bien son útiles, a menudo necesitamos más: queremos que nuestro **Dominio** lance errores que reflejen **problemas de negocio**, sin saber nada de HTTP, y que la capa API los traduzca adecuadamente.

#### 2. El Poder: ¿Por Qué Excepciones Personalizadas?

* **Semántica del Dominio:** Permiten expresar errores en términos de negocio (`PedidoNoEncontradoError`, `StockInsuficienteError`).
* **Desacoplamiento (Hexagonal):** Tu núcleo (`domain`, `application`) lanza excepciones de dominio. La capa API (`api`) se encarga de traducirlas a HTTP. ¡El Dominio permanece puro!
* **Respuestas Estandarizadas:** Garantizas que *todos* los errores (esperados e inesperados) devuelvan un JSON con una estructura consistente.
* **Códigos HTTP Precisos:** Puedes mapear cada error de negocio al código HTTP más apropiado (404, 409, 400, 403, etc.).
* **Depuración y Logging:** Facilita el registro y la identificación de problemas específicos.

#### 3. El Diseño: Creando Nuestra Jerarquía de Excepciones

Lo ideal es crear una clase base para nuestras excepciones de aplicación/dominio y luego heredar de ella. Esto nos permite capturarlas de forma más genérica si es necesario.

```python
# Concepto: app/domain/exceptions.py

class BaseAppError(Exception):
    """Clase base para excepciones personalizadas."""
    def __init__(self, detail: str = "Error de aplicación"):
        self.detail = detail
        super().__init__(self.detail)

class ResourceNotFoundError(BaseAppError):
    """Lanzada cuando un recurso no se encuentra."""
    def __init__(self, resource_name: str, resource_id: any):
        detail = f"Recurso '{resource_name}' con ID '{resource_id}' no encontrado."
        super().__init__(detail)

class BusinessRuleViolationError(BaseAppError):
    """Lanzada cuando se viola una regla de negocio."""
    def __init__(self, detail: str):
        super().__init__(detail)

class EmailAlreadyExistsError(BusinessRuleViolationError):
    """Ejemplo específico de violación de regla."""
    def __init__(self, email: str):
        detail = f"El email '{email}' ya está registrado."
        super().__init__(detail)
```

**Lanzándolas desde el Dominio/Aplicación:**

```python
# Concepto: app/application/services/user_service.py
# from app.domain.exceptions import EmailAlreadyExistsError

def create_user(email: str, ...):
    if user_exists_in_db(email):
        raise EmailAlreadyExistsError(email) # <-- ¡Lanzamos nuestra excepción!
    # ... (crear usuario) ...
```

#### 4. La Traducción: `app.exception_handler`

Aquí ocurre la magia. Usamos el decorador `@app.exception_handler(MiExcepcion)` para registrar una función que **interceptará** nuestra excepción personalizada y la **transformará** en una respuesta HTTP.

```python
# Concepto: app/api/exception_handlers.py o main.py

from fastapi import Request, status
from fastapi.responses import JSONResponse
from app.domain.exceptions import (
    ResourceNotFoundError,
    BusinessRuleViolationError,
    EmailAlreadyExistsError
)

async def resource_not_found_handler(request: Request, exc: ResourceNotFoundError):
    return JSONResponse(
        status_code=status.HTTP_404_NOT_FOUND,
        content={"error_code": "RESOURCE_NOT_FOUND", "detail": exc.detail},
    )

async def email_exists_handler(request: Request, exc: EmailAlreadyExistsError):
    return JSONResponse(
        status_code=status.HTTP_409_CONFLICT, # <-- 409 Conflict es apropiado aquí
        content={"error_code": "EMAIL_EXISTS", "detail": exc.detail},
    )

async def business_rule_handler(request: Request, exc: BusinessRuleViolationError):
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST, # <-- 400 o 409 suelen ser opciones
        content={"error_code": "BUSINESS_RULE_VIOLATION", "detail": exc.detail},
    )

# --- Registro en main.py ---
# from fastapi import FastAPI
# from .api import exception_handlers
# from .domain.exceptions import ...

# app = FastAPI()
# app.add_exception_handler(ResourceNotFoundError, exception_handlers.resource_not_found_handler)
# app.add_exception_handler(EmailAlreadyExistsError, exception_handlers.email_exists_handler)
# app.add_exception_handler(BusinessRuleViolationError, exception_handlers.business_rule_handler)
```

**Importante:** El orden de registro puede importar si tienes jerarquías. FastAPI usará el manejador más específico que encuentre.

#### 5. Visualizando el Flujo de la Excepción

```mermaid
sequenceDiagram
    participant API as Capa API (Endpoint)
    participant APP as Capa Aplicación
    participant DOM as Dominio / Infra (Repo)
    participant FAPI as FastAPI Core
    participant EH as Exception Handlers
    participant C as Cliente

    API->>APP: Llama a create_user(email="a@b.com")
    APP->>DOM: Verifica si user_exists("a@b.com")
    DOM-->>APP: True (Usuario existe)
    APP->>APP: raise EmailAlreadyExistsError("a@b.com")
    Note over APP: ¡Lanza Excepción Personalizada!
    APP-->>FAPI: Propaga Excepción
    FAPI->>FAPI: Busca Handler para 'EmailAlreadyExistsError'
    FAPI->>EH: Llama a email_exists_handler(...)
    EH->>EH: Crea JSONResponse(status=409, content=...)
    EH-->>FAPI: Devuelve JSONResponse
    FAPI-->>C: Envía Respuesta HTTP 409
```

Este diagrama muestra cómo una excepción nacida en la lógica de negocio se transforma elegantemente en una respuesta HTTP específica, sin que la capa de negocio sepa nada de HTTP 409.

#### 6. Tabla de Mapeo (Ejemplos)

| Excepción de Dominio | Código HTTP Sugerido | Significado |
| :--- | :--- | :--- |
| `ResourceNotFoundError` | 404 | No se encontró lo que se buscaba. |
| `EmailAlreadyExistsError` | 409 | Conflicto, el recurso ya existe. |
| `InvalidInputError` | 400 | La petición del cliente es incorrecta (no sintaxis, sino lógica). |
| `StockInsuficienteError` | 409 / 400 | Conflicto o petición inválida. |
| `AuthenticationError` | 401 | El cliente no está autenticado. |
| `AuthorizationError` | 403 | El cliente está autenticado pero no tiene permisos. |
| `PaymentFailedError` | 402 / 400 | Fallo en el pago (raro 402, a menudo 400). |


El manejo de excepciones personalizadas no es un lujo, es una **necesidad** para construir APIs de alta calidad. En FastAPI, gracias a su sistema de *exception handlers*, podemos implementar un **puente robusto y semántico** entre los errores detectados en nuestro **Dominio** y las respuestas HTTP que enviamos a nuestros clientes. Esto nos permite crear APIs que no solo funcionan, sino que también **comunican eficazmente** cuando las cosas no salen como se esperaba, respetando el **desacoplamiento** y la **claridad** que promueve nuestra arquitectura DDD y Hexagonal. ¡Esto no es "flojear", es construir como profesionales!

---




## 2.10. Configuración de Entornos con `BaseSettings`

Un microservicio no vive aislado. Necesita hablar con bases de datos, APIs externas, sistemas de mensajería; necesita saber en qué entorno se ejecuta (desarrollo, staging, producción); y debe manejar datos sensibles como claves de API o credenciales. Gestionar toda esta **configuración** puede convertirse rápidamente en un nido de hardcodeo, ficheros dispersos y errores tontos. ¡Es inaceptable\!

Aquí es donde **Pydantic**, a través de su biblioteca hermana `pydantic-settings` y su clase estrella `BaseSettings`, nos ofrece una solución **elegante, robusta y centralizada**. Transforma la gestión de la configuración de un arte oscuro a una ciencia exacta, basada en la validación y el tipado.

#### 1\. El Caos de la Configuración Tradicional vs. La Solución Pydantic

| Problema Tradicional | Solución con `BaseSettings` |
| :--- | :--- |
| **Valores Hardcodeados:** Riesgo de seguridad, difícil cambiar. | **Configuración Externa:** Lee de variables de entorno, `.env`, etc. |
| **Ficheros Múltiples:** Inconsistencias, difícil saber qué se usa. | **Modelo Único:** Define *toda* la configuración en una clase Pydantic. |
| **Tipos Implícitos:** `os.getenv("PORT")` devuelve `str`, ¡incluso si es un número\! | **Validación y Tipado:** `port: int` asegura que el puerto sea un entero. |
| **Falta de Claridad:** ¿Qué es opcional? ¿Qué es requerido? | **Definición Explícita:** Los campos sin default son requeridos. |
| **Entornos Dispares:** Lógica `if/else` para cargar config. | **Carga Jerárquica:** Define fuentes y `pydantic-settings` las busca en orden. |

#### 2\. `pydantic-settings`: La Magia de `BaseSettings`

`pydantic-settings` (que era parte de Pydantic v1 y se separó en v2) nos permite definir nuestras configuraciones como un modelo Pydantic.

**Características Clave:**

  * **Lectura Automática:** Lee variables de entorno (insensible a mayúsculas/minúsculas) y de archivos `.env`.
  * **Validación Pydantic:** Aplica todas las reglas de Pydantic (tipos, `Field`, `HttpUrl`, `SecretStr`, etc.).
  * **Jerarquía de Fuentes:** Busca valores en un orden predefinido, permitiendo sobrescribir valores.
  * **Soporte `.env`:** Integra `python-dotenv` para cargar archivos `.env` fácilmente.

**El Flujo de Carga (Prioridad): ¡El que Gana es el Primero\!**

`pydantic-settings` busca valores para tus campos en este orden. En cuanto encuentra uno, ¡deja de buscar para ese campo\!


Esto significa que una variable de entorno **siempre** sobrescribirá un valor en tu `.env`, lo cual es ideal (`.env` para desarrollo local, variables de entorno para producción).

#### 3\. Implementación Práctica y Rigurosa

**1. Instalar:** `pip install pydantic-settings`

**2. Crear el Fichero `.env` (Para Desarrollo):**

```dotenv
# .env
DATABASE_URL="postgresql+asyncpg://user:password@localhost:5432/my_db"
SECRET_KEY="un_secreto_muy_secreto_para_dev"
API_V1_PREFIX="/api/v1"
DEBUG_MODE=True
# DEFAULT_ITEMS_PER_PAGE=25 # <-- Lo dejamos sin definir para usar el default
```

**3. Definir el Modelo `BaseSettings`:**

```python
# Concepto: app/core/config.py
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import HttpUrl, SecretStr
from typing import List, Optional

class Settings(BaseSettings):
    # Variables de Entorno / .env
    database_url: str  # Requerido (debe estar en .env o env var)
    secret_key: SecretStr # <-- Usa SecretStr para datos sensibles
    api_v1_prefix: str = "/api/v1" # Con valor por defecto
    debug_mode: bool = False # Default a False (más seguro)
    default_items_per_page: int = 50

    # Pydantic puede validar URLs, emails, etc.
    admin_email: Optional[str] = None # Opcional
    allowed_origins: List[str] = ["http://localhost:3000"]

    # Configuración para pydantic-settings (Pydantic v2)
    model_config = SettingsConfigDict(
        env_file=".env",              # Fichero a cargar
        env_file_encoding='utf-8',    # Encoding
        case_sensitive=False,         # Ignora mayúsculas/minúsculas en env vars
        env_prefix=''                 # Si quieres que todas tus vars empiecen con 'APP_'
    )

# --- Crear una instancia Singleton ---
# La creamos aquí para que se lea una sola vez al iniciar la app.
settings = Settings()
```

  * **`SecretStr`**: Un tipo especial que oculta su valor en `print()` y `repr()`, ¡vital para no loggear secretos\!
  * **`SettingsConfigDict`**: La forma moderna (Pydantic v2) de configurar el comportamiento de `BaseSettings`.

**4. Usando la Configuración (Inyección de Dependencias)**

La forma más limpia de usar `settings` es inyectarla donde la necesites usando el sistema DI de FastAPI.

```python
# Concepto: app/core/dependencies.py
from .config import settings

def get_settings() -> Settings:
    # Simplemente devuelve la instancia global.
    # Podrías usar @lru_cache(maxsize=1) para asegurar que sea singleton,
    # aunque si la creas una vez en config.py, ya lo es.
    return settings

# Concepto: app/api/v1/endpoints/some_endpoint.py
from fastapi import APIRouter, Depends
from app.core.config import Settings
from app.core.dependencies import get_settings

router = APIRouter()

@router.get("/info")
async def get_app_info(cfg: Settings = Depends(get_settings)):
    return {
        "debug_mode": cfg.debug_mode,
        "prefix": cfg.api_v1_prefix,
        "admin": cfg.admin_email,
        # ¡OJO! No devuelvas 'secret_key' directamente en una API.
        # cfg.secret_key.get_secret_value() te da el valor real.
        "db_url_type": str(type(cfg.database_url))
    }
```

**Visualizando la Inyección de `Settings`:**

```mermaid
graph TD
    A["Inicio App: main.py"] --> B["Importa app.core.config"]
    B --> C["Crea settings = Settings()"]
    C --> D["Lee .env o variables de entorno"]
    D --> E["Instancia global de settings"]

    F["Petición a /info"] --> G["Endpoint: /info"]
    G -->|Pide Depends → get_settings| H["Sistema DI de FastAPI"]
    H --> I["Ejecuta get_settings"]
    I -->|Devuelve instancia| E
    H -->|Inyecta cfg| G
    G --> J["Usa cfg.debug_mode"]
    J --> K["Devuelve respuesta"]

    style E fill:#e74c3c,stroke:#333


```

La configuración es la columna vertebral invisible de cualquier aplicación. Usar `pydantic-settings` con FastAPI no es solo una "buena práctica", es una **declaración de intenciones**: apostamos por la **robustez, la seguridad y la claridad**. Al definir nuestras configuraciones como modelos Pydantic, ganamos **validación automática, tipado estricto y una gestión de entornos flexible y centralizada**. Integrado con el sistema de Inyección de Dependencias, nos permite acceder a la configuración de forma limpia y desacoplada, asegurando que nuestros microservicios sean **predecibles y fáciles de desplegar** en cualquier entorno. ¡Esto es construir con calidad altísima\!

-----


## 2.11. Preparación para Despliegue en Producción con `uvicorn` y `gunicorn` 

**Uvicorn vs Gunicorn: Comparativa Profesional**


| |**Uvicorn**                   | **Gunicorn + Uvicorn Worker** |                                               
| ----------------------------- | ----------------------------- | --------------------------------------------- |
| **¿Qué es?**                  | Servidor ASGI ligero.         | Orquestador multiproceso WSGI/ASGI.           |
| **Procesos**                  | 1 proceso, 1 core.            | N procesos, múltiples cores.                  |
| **Concurrencia**              | Asíncrono, event loop único.  | Multiproceso + event loop por worker.         |
| **Escalabilidad**             | Limitado a un core.           | Escalabilidad horizontal (multiproceso).      |
| **Manejo de señales**         | Básico.                       | Correcto y controlado.                        |
| **Uso ideal**                 | Desarrollo (`--reload`).      | Producción estable y escalable.               |
| **Reinicio automático**       | Solo en `--reload`.           | `max_requests`, `timeout`, graceful shutdown. |
| **Configuraciones avanzadas** | Limitadas.                    | Avanzadas (`preload_app`, `socket`, etc.).    |


Gunicorn es un servidor HTTP **prefork**:

* Crea un **proceso maestro** que lanza varios **workers**.
* Cada worker maneja peticiones usando un event loop de Uvicorn.

➞️ **Opciones Clave de Gunicorn**

| Opcion                       | Descripción                                                | Recomendación            |
| ---------------------------- | ---------------------------------------------------------- | ------------------------ |
| `-k`, `--worker-class`       | Tipo de worker (`uvicorn.workers.UvicornWorker`).          | Obligatorio para FastAPI |
| `-w`, `--workers`            | Número de procesos worker.                                 | `2 * CPU_CORES + 1`      |
| `--threads`                  | Hilos por worker (no recomendado en ASGI).                 | No usar.                 |
| `--bind`                     | IP\:puerto o socket Unix.                                  | `0.0.0.0:8000`           |
| `--timeout`                  | Tiempo máximo de respuesta antes de matar el worker.       | 60 s                     |
| `--graceful-timeout`         | Tiempo de shutdown controlado.                             | 30 s                     |
| `--keep-alive`               | Tiempo de keep-alive en conexiones HTTP.                   | 5 s                      |
| `--max-requests`             | Reinicio tras N peticiones (prevención memory leaks).      | 1000                     |
| `--max-requests-jitter`      | Variabilidad en reinicios para evitar parones simultáneos. | 50                       |
| `--preload`                  | Precargar app antes de fork (cuidado con conexiones).      | `False` normalmente.     |
| `--access-logfile`           | Log de accesos (`-` para stdout).                          | `-`                      |
| `--error-logfile`            | Log de errores (`-` para stderr).                          | `-`                      |
| `--log-level`                | Nivel de log (`info`, `warning`, `error`).                 | `info`                   |
| `--reload`                   | Hot reload dev (NO usar en producción).                    | ❌                        |
| `--limit-request-line`       | Tamaño máximo de línea HTTP (bytes).                       | 4094                     |
| `--limit-request-field_size` | Tamaño máximo de cabeceras HTTP.                           | 8190                     |

---

####  Lanzamientos de Gunicorn

➞️ **Lanzamiento rápido**

```bash
gunicorn -k uvicorn.workers.UvicornWorker app.main:app
```

➞️ **Lanzamiento de producción recomendado**

```bash
gunicorn -k uvicorn.workers.UvicornWorker app.main:app \
  --workers 9 \
  --bind 0.0.0.0:8000 \
  --timeout 60 \
  --keep-alive 5 \
  --max-requests 1000 \
  --max-requests-jitter 50 \
  --access-logfile - \
  --error-logfile - \
  --log-level info
```

---

####  Gunicorn con `config_gunicorn.py`



```python
import multiprocessing

bind = "0.0.0.0:8000"
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "uvicorn.workers.UvicornWorker"
timeout = 60
graceful_timeout = 30
keepalive = 5
max_requests = 1000
max_requests_jitter = 50
accesslog = "-"
errorlog = "-"
loglevel = "info"
preload_app = False
```

➞️ **Lanzarlo usando config**

```bash
gunicorn -c config_gunicorn.py app.main:app
```

---

#### Despliegue con Docker

##### Dockerfile Multistage (Producción)

```Dockerfile
# Build Stage
FROM python:3.12-slim AS build

WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Runtime Stage
FROM python:3.12-slim

WORKDIR /app

COPY --from=build /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH

COPY . .

COPY config_gunicorn.py .

CMD ["gunicorn", "-c", "config_gunicorn.py", "app.main:app"]
```

---

#### Dockerfile.dev (Desarrollo)

```Dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
```

---

#### docker-compose.yml (Producción)

```yaml
version: "3.9"

services:
  fastapi-app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    restart: always
    environment:
      - WORKERS=9
      - TIMEOUT=60
    networks:
      - app-network
    depends_on:
      - db

  db:
    image: mariadb:10.11
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: supersecret
      MYSQL_DATABASE: mydb
      MYSQL_USER: dbuser
      MYSQL_PASSWORD: dbpassword
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

volumes:
  db_data:
```

---

#### docker-compose.override.yml (Desarrollo)

```yaml
version: "3.9"

services:
  fastapi-app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    volumes:
      - .:/app
    ports:
      - "8000:8000"
    environment:
      - ENVIRONMENT=development
```

---

#### Healthcheck en docker-compose (opcional)

```yaml
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

---

#### Buenas Prácticas

* **Separar entornos**: Dockerfile y compose distintos para **dev** y **prod**.
* **Gunicorn + UvicornWorker**: siempre en producción.
* **Hot Reload** (`--reload`) solo en desarrollo.
* **Multistage build**: reduce tamaño de imagen en producción.
* **Healthchecks**: permiten detectar y reparar fallos automáticamente.
* **Preload con precaución**: usar `preload_app = False` salvo que esté controlado.
* **Max Requests + Jitter**: evita memory leaks y reinicios masivos simultáneos.

---



## Referencias Bibliográficas

* **[1] FastAPI Official Documentation.** (s.f.). Tiangolo.
    * Recuperado de [https://fastapi.tiangolo.com/](https://fastapi.tiangolo.com/)
    * *Referencia principal para todos los aspectos de FastAPI, incluyendo Pydantic, inyección de dependencias, BackgroundTasks, OpenAPI, etc.*

* **[2] Pydantic Documentation.** (s.f.). Pydantic.
    * Recuperado de [https://docs.pydantic.dev/](https://docs.pydantic.dev/)
    * *Documentación oficial para la validación de datos, serialización y configuración con Pydantic, incluyendo `BaseModel` y `Field`.*

* **[3] Pydantic-Settings Documentation.** (s.f.). Pydantic.
    * Recuperado de [https://docs.pydantic.dev/latest/api/pydantic_settings/](https://docs.pydantic.dev/latest/api/pydantic_settings/)
    * *Para la gestión de configuraciones con `BaseSettings`, como se describe en la sección 2.10.*

* **[4] Starlette Official Documentation.** (s.f.). Encode.
    * Recuperado de [https://www.starlette.io/](https://www.starlette.io/)
    * *El framework ASGI de bajo nivel sobre el cual se construye FastAPI, relevante para entender los middlewares y `BackgroundTasks`.*

### Estándares y Especificaciones

* **[5] OpenAPI Specification.** (s.f.). OpenAPI Initiative.
    * Recuperado de [https://spec.openapis.org/oas/latest.html](https://spec.openapis.org/oas/latest.html)
    * *El estándar en el que FastAPI basa su generación automática de documentación API, como se detalla en la sección 2.7.*

* **[6] JSON Schema Organization.** (s.f.).
    * Recuperado de [https://json-schema.org/](https://json-schema.org/)
    * *El estándar utilizado por OpenAPI (y Pydantic) para definir la estructura de los datos JSON.*

### Servidores ASGI y WSGI

* **[7] Uvicorn Official Documentation.** (s.f.). Encode.
    * Recuperado de [https://www.uvicorn.org/](https://www.uvicorn.org/)
    * *El servidor ASGI de alto rendimiento recomendado para FastAPI en desarrollo y como worker en producción, mencionado en la sección 2.11.*

* **[8] Gunicorn Official Documentation.** (s.f.). Gunicorn.
    * Recuperado de [https://gunicorn.org/](https://gunicorn.org/)
    * *El servidor WSGI HTTP de Python para UNIX, comúnmente usado como gestor de procesos para workers Uvicorn en producción (sección 2.11).*
