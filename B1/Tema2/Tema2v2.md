# TEMA 2. FASTAPI COMO FRAMEWORK PARA MICROSERVICIOS

- [TEMA 2. FASTAPI COMO FRAMEWORK PARA MICROSERVICIOS](#tema-2-fastapi-como-framework-para-microservicios)
  - [Objetivos](#objetivos)
  - [Contenidos](#contenidos)
  - [2.1. **Presentación de FastAPI y sus ventajas**](#21-presentación-de-fastapi-y-sus-ventajas)
  - [**Tabla Comparativa de Frameworks API**](#tabla-comparativa-de-frameworks-api)
  - [**Benchmarking de Frameworks API (TechEmpower)**](#benchmarking-de-frameworks-api-techempower)
  - [2.2. **Entendimiento del uso de Pydantic**](#22-entendimiento-del-uso-de-pydantic)
  - [2.3. **Creación de una estructura base escalable**](#23-creación-de-una-estructura-base-escalable)
  - [2.3. Estructura de Proyecto Escalable con FastAPI](#23-estructura-de-proyecto-escalable-con-fastapi)
    - [1. Estructura Mínima (Para Proyectos Pequeños o Prototipos)](#1-estructura-mínima-para-proyectos-pequeños-o-prototipos)
    - [2. Estructura Básica Modular (Separando Routers)](#2-estructura-básica-modular-separando-routers)
    - [3. Estructura Orientada a Servicios (Capa de Lógica de Negocio)](#3-estructura-orientada-a-servicios-capa-de-lógica-de-negocio)
    - [4. Estructura por Funcionalidad/Dominio (Feature-based)](#4-estructura-por-funcionalidaddominio-feature-based)
    - [5. Arquitectura Hexagonal (Puertos y Adaptadores)](#5-arquitectura-hexagonal-puertos-y-adaptadores)
    - [6. Clean Architecture](#6-clean-architecture)
    - [Consideraciones Adicionales](#consideraciones-adicionales)
  - [2.4. **Gestión de rutas y controladores RESTful**](#24-gestión-de-rutas-y-controladores-restful)
  - [2.4. Gestión de rutas y controladores RESTful](#24-gestión-de-rutas-y-controladores-restful-1)
    - [1. `FastAPI()` y `APIRouter()`](#1-fastapi-y-apirouter)
    - [2. Path Operations: Definiendo Endpoints](#2-path-operations-definiendo-endpoints)
    - [3. Modelo de Respuesta (`response_model`)](#3-modelo-de-respuesta-response_model)
    - [4. Inyección de Dependencias (`Depends`)](#4-inyección-de-dependencias-depends)
    - [5. Diseño de Controladores RESTful (Buenas Prácticas)](#5-diseño-de-controladores-restful-buenas-prácticas)
  - [**Referencias Bibliográficas y Recursos de Internet**](#referencias-bibliográficas-y-recursos-de-internet)

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

## 2.1. Presentación de FastAPI y sus ventajas

FastAPI se ha consolidado rápidamente como un framework web Python moderno y de alto rendimiento para construir APIs. Su diseño se centra en la velocidad, la facilidad de desarrollo y la robustez, aprovechando al máximo las características modernas de Python como los *type hints* (sugerencias de tipo) y la programación asíncrona.

**¿Qué es FastAPI?**

FastAPI es un framework web para construir APIs con Python 3.7+ basado en las anotaciones de tipo estándar de Python. Se apoya en dos pilares fundamentales:

* **Starlette:** Para toda la parte web de bajo nivel (enrutamiento, middleware, etc.). Starlette es un framework ASGI (Asynchronous Server Gateway Interface) ligero y de alto rendimiento.  
* **Pydantic:** Para la validación de datos, serialización y deserialización, y la generación automática de esquemas de datos (JSON Schema).

Esta combinación permite a FastAPI ofrecer un rendimiento comparable al de frameworks de Node.js y Go, al tiempo que mantiene la facilidad de uso y la expresividad de Python.

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

## **Tabla Comparativa de Frameworks API**

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

## **Benchmarking de Frameworks API (TechEmpower)**

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



## 2.2. Entendimiento del uso de Pydantic

Pydantic se ha establecido como la librería de facto en Python para la **validación de datos, serialización/deserialización y gestión de configuraciones utilizando anotaciones de tipo (type hints)**. Con el lanzamiento de Pydantic V2, reescrito en gran parte en Rust a través de `pydantic-core`, ha experimentado un salto significativo en rendimiento y ha introducido varias mejoras y cambios en su API, manteniendo su reconocida facilidad de uso.

Esta guía te llevará a través de todo lo que necesitas saber sobre Pydantic V2.

**¿Por qué Pydantic y qué ha cambiado en V2?**

Pydantic simplifica enormemente el trabajo con datos al:

1.  **Definir estructuras de datos claras:** Usando clases Python y *type hints*.
2.  **Validar datos automáticamente:** Comprobando tipos, restricciones y lógica personalizada.
3.  **Serializar y deserializar datos:** Convirtiendo objetos Python a/desde formatos como JSON de manera eficiente.
4.  **Generar esquemas JSON Schema:** Facilitando la documentación de APIs (clave en FastAPI).
5.  **Gestionar la configuración de aplicaciones:** De forma robusta y segura.

**Novedades y Enfoque de Pydantic V2:**

* **`pydantic-core`:** El corazón de Pydantic V2 está escrito en Rust. Esto se traduce en una **mejora drástica del rendimiento** (entre 4 y 50 veces más rápido que V1 en muchos benchmarks).
* **API más consistente y refinada:** Se han realizado cambios para hacer la API más intuitiva y potente. Por ejemplo, `.dict()` ahora es `model_dump()` y `.json()` es `model_dump_json()`. Para la creación de modelos desde datos, `parse_obj` es ahora `model_validate` y `parse_raw` es `model_validate_json`.
* **Strict Mode (Modo Estricto):** Mayor control sobre la coerción de tipos.
* **Mejoras en la personalización de la serialización y validación.**
* **`ConfigDict` para la configuración del modelo:** Reemplaza la clase interna `Config`.

**1. Fundamentos: Definiendo Modelos con `BaseModel`**

La base de Pydantic es la clase `BaseModel`. Defines tus estructuras de datos como clases que heredan de `BaseModel`, usando *type hints* para los campos.

```python
from datetime import datetime, date
from typing import List, Optional, Dict, Union
from pydantic import BaseModel, Field, EmailStr, HttpUrl, ValidationError

class UsuarioV2(BaseModel):
    id: int
    nombre: str = "Usuario Anónimo"  # Valor por defecto
    email: Optional[EmailStr] = None # Tipo específico de Pydantic para emails
    fecha_alta: date
    metadata: Dict[str, Union[str, int]] = {}
    amigos_ids: List[int] = Field(default_factory=list) # Usar default_factory para mutables
    perfil_url: Optional[HttpUrl] = None # Tipo para URLs HTTP/HTTPS

# Creación de una instancia
datos_usuario = {
    "id": 101,
    "email": "usuario@example.com",
    "fecha_alta": "2024-05-07", # Pydantic coaccionará la cadena a un objeto date
    "metadata": {"rol": "admin", "puntos": 100},
    "perfil_url": "[https://example.com/perfil/101](https://example.com/perfil/101)"
}

try:
    usuario = UsuarioV2(**datos_usuario)
    print(usuario)
    # >> id=101 nombre='Usuario Anónimo' email='usuario@example.com' fecha_alta=datetime.date(2024, 5, 7) metadata={'rol': 'admin', 'puntos': 100} amigos_ids=[] perfil_url=Url('[https://example.com/perfil/101](https://example.com/perfil/101)')
except ValidationError as e:
    print(e.errors())
```

**2. Validación de Datos**

La validación es automática al crear una instancia del modelo o al modificar campos (si `validate_assignment` está activado en la configuración).

* **Tipos Soportados:** Pydantic soporta todos los tipos estándar de Python, tipos de `typing` (como `List`, `Dict`, `Optional`, `Union`), y tipos propios más específicos (`EmailStr`, `HttpUrl`, `FilePath`, `DirectoryPath`, `PositiveInt`, `NegativeFloat`, etc.).
* **Coerción de Tipos:** Pydantic intenta convertir los datos de entrada al tipo esperado. Por ejemplo, `"123"` se convierte a `int(123)`, `"true"` a `bool(True)`.
* **Modo Estricto (`strict`):** Puedes habilitar el modo estricto a nivel de campo o modelo para deshabilitar la coerción de tipos y exigir tipos exactos.

```python
from pydantic import BaseModel, Field, ValidationError # Añadido ValidationError para el ejemplo

class ModeloEstricto(BaseModel):
    id_estricto: int = Field(strict=True)
    id_flexible: int

try:
    # Esto fallaría para id_estricto porque espera un int, no un str que necesite coerción.
    print(ModeloEstricto(id_estricto="123", id_flexible="456"))
except ValidationError as e:
    print("Error en ModeloEstricto con string para id_estricto:")
    print(e.errors())

try:
    # OK, id_flexible se coacciona desde "456" a 456. id_estricto recibe un int.
    obj_estricto = ModeloEstricto(id_estricto=123, id_flexible="456")
    print("ModeloEstricto creado con éxito:")
    print(obj_estricto)
except ValidationError as e:
    print("Error inesperado al crear ModeloEstricto:")
    print(e.errors())
```

**3. Campos (`Field`) y Restricciones**

`Field` permite configurar opciones adicionales para los campos: valores por defecto, alias, descripciones, y **restricciones de validación**.

```python
from pydantic import BaseModel, Field, ValidationError

class ProductoV2(BaseModel):
    nombre: str = Field(min_length=3, max_length=50)
    precio: float = Field(gt=0, le=1000.0) # Mayor que 0, menor o igual que 1000
    cantidad: Optional[int] = Field(default=0, ge=0) # Mayor o igual que 0
    codigo_barras: Optional[str] = Field(default=None, pattern=r"^[0-9]{12,13}$") # Expresión regular
    descripcion: Optional[str] = None

try:
    ProductoV2(nombre="P", precio=0) # Fallará por min_length y gt
except ValidationError as e:
    print(e.errors())
    """
    [
        {'type': 'string_too_short', 'loc': ('nombre',), 'msg': 'String should have at least 3 characters', 'input': 'P', 'ctx': {'min_length': 3}},
        {'type': 'greater_than', 'loc': ('precio',), 'msg': 'Input should be greater than 0', 'input': 0.0, 'ctx': {'gt': 0.0}}
    ]
    """
```

Otras restricciones comunes: `lt` (menor que), `multiple_of` (múltiplo de), `min_items`/`max_items` (para listas).

**4. Validadores Personalizados**

Pydantic V2 introduce nuevos decoradores para validadores, aunque los de V1 (`@validator`) aún funcionan por retrocompatibilidad (con *shims*).

* **`@field_validator`:** Para validar campos individuales. Se ejecuta *después* de la validación de tipo y las restricciones de `Field`.

```python 
from pydantic import BaseModel, field_validator, ValidationError

class PedidoV2(BaseModel):
    articulo_id: str
    cantidad: int

    @field_validator('articulo_id')
    @classmethod # Importante en V2
    def articulo_id_debe_empezar_con_item(cls, v: str) -> str:
        if not v.startswith('ITEM_'):
            raise ValueError('articulo_id debe empezar con "ITEM_"')
        return v.upper()

try:
    pedido = PedidoV2(articulo_id="producto_123", cantidad=1)
except ValidationError as e:
    print(e.errors()) # [{'type': 'value_error', 'loc': ('articulo_id',), 'msg': 'Value error, articulo_id debe empezar con "ITEM_"', ...}]

pedido_ok = PedidoV2(articulo_id="ITEM_abc", cantidad=2)
print(pedido_ok.articulo_id) # >> ITEM_ABC
```

El decorador puede tomar el modo (`'before'`, `'after'`, `'wrap'`, `'plain'`) para controlar cuándo se ejecuta la validación respecto a la validación del esquema central. `'after'` es el predeterminado.

* **`@model_validator`:** Para validaciones que involucran múltiples campos o todo el modelo. Reemplaza a `@root_validator` de V1.

```python
from datetime import date # Asegurarse que date está importado
from pydantic import BaseModel, model_validator, ValidationError

class RangoFechasV2(BaseModel):
    fecha_inicio: date
    fecha_fin: date

    @model_validator(mode='after') # 'before' o 'after'
    def validar_rango(self) -> 'RangoFechasV2':
        if self.fecha_inicio >= self.fecha_fin:
            raise ValueError('fecha_inicio debe ser anterior a fecha_fin')
        return self

try:
    RangoFechasV2(fecha_inicio='2024-01-15', fecha_fin='2024-01-10')
except ValidationError as e:
    print(e.errors()) # [{'type': 'value_error', 'loc': (), 'msg': 'Value error, fecha_inicio debe ser anterior a fecha_fin', ...}]
```

**5. Serialización: Convirtiendo Modelos a Diccionarios/JSON**

* **`model_dump()` (reemplaza a `.dict()`):** Devuelve una representación de diccionario del modelo.
    *(Se asume que `usuario` es una instancia de `UsuarioV2` creada previamente)

```python
# Suponiendo que 'usuario' es una instancia válida de UsuarioV2:
# Ejemplo de creación para que el código sea ejecutable:
from datetime import date
from typing import List, Optional, Dict, Union # Asegurar que todos los tipos están importados
from pydantic import BaseModel, Field, EmailStr, HttpUrl # Asegurar que todos los tipos están importados

class UsuarioV2(BaseModel): # Definición simplificada para el ejemplo
    id: int
    nombre: str = "Usuario Anónimo"
    email: Optional[EmailStr] = None
    fecha_alta: date
    metadata: Dict[str, Union[str, int]] = {}
    amigos_ids: List[int] = Field(default_factory=list)
    perfil_url: Optional[HttpUrl] = None
usuario = UsuarioV2(id=1, email="test@example.com", fecha_alta="2024-01-01")


usuario_dict = usuario.model_dump()
print(usuario_dict)

# Opciones:
# print(usuario.model_dump(include={'id', 'email'}))
# print(usuario.model_dump(exclude={'metadata', 'amigos_ids'}))
# print(usuario.model_dump(by_alias=True)) # Si se han definido alias para los campos
# print(usuario.model_dump(exclude_none=True)) # Excluir campos con valor None
```

**6. Deserialización/Parsing: Creando Modelos desde Datos**

* **`model_validate()` (reemplaza a `parse_obj()`):** Crea una instancia del modelo a partir de un diccionario Python, validando los datos.

```python
# Usando la definición completa de UsuarioV2 del inicio
from datetime import datetime, date
from typing import List, Optional, Dict, Union
from pydantic import BaseModel, Field, EmailStr, HttpUrl, ValidationError

class UsuarioV2(BaseModel):
    id: int
    nombre: str = "Usuario Anónimo"
    email: Optional[EmailStr] = None
    fecha_alta: date
    metadata: Dict[str, Union[str, int]] = {}
    amigos_ids: List[int] = Field(default_factory=list)
    perfil_url: Optional[HttpUrl] = None

datos_externos = {"id": 202, "email": "otro@example.com", "fecha_alta": "2023-11-20"}
try:
    usuario_nuevo = UsuarioV2.model_validate(datos_externos)
    print(usuario_nuevo)
except ValidationError as e:
    print(e.errors())
```

* **`model_validate_json()` (reemplaza a `parse_raw()`):** Crea una instancia del modelo a partir de una cadena JSON, validando los datos.

```python
# Usando la definición completa de UsuarioV2 del inicio
json_externo = '{"id": 303, "email": "json.user@example.com", "fecha_alta": "2022-10-10"}'
try:
    usuario_desde_json = UsuarioV2.model_validate_json(json_externo)
    print(usuario_desde_json)
except ValidationError as e:
    print(e.errors())
```

**7. Configuración del Modelo con `model_config` o `ConfigDict`**

Se usa un diccionario llamado `model_config` a nivel de clase o se importa y usa `ConfigDict`.

```python
from pydantic import BaseModel, ConfigDict, ValidationError

class ModeloConfigurado(BaseModel):
    model_config = ConfigDict(
        title="Mi Modelo Configurado",
        str_strip_whitespace=True, # Eliminar espacios en blanco al inicio/final de cadenas
        extra='forbid',           # No permitir campos extra no definidos en el modelo
        frozen=True,              # Hace el modelo inmutable después de la creación
        validate_assignment=True, # Validar campos al reasignarlos
        # from_attributes=True,   # Para crear modelos desde atributos de otros objetos (ej. ORM)
    )

    id_unico: int
    nombre_item: str

try:
    # Fallaría por 'otro_campo' no permitido debido a extra='forbid'
    # item_error = ModeloConfigurado(id_unico=1, nombre_item="  Objeto  ", otro_campo="extra_valor")
    # print(item_error)

    item_ok = ModeloConfigurado(id_unico=1, nombre_item="  Objeto  ")
    # Nota: str_strip_whitespace se aplica durante la validación de campos de tipo str.
    # Si el valor inicial ya es un str, la limpieza ocurre.
    print(f"Nombre item_ok: '{item_ok.nombre_item}'")


    # Para ver el efecto de str_strip_whitespace más claramente:
    class ModeloConStrip(BaseModel):
        model_config = ConfigDict(str_strip_whitespace=True)
        texto: str

    instancia_strip = ModeloConStrip(texto="   muchos espacios   ")
    print(f"Texto con strip: '{instancia_strip.texto}'") # >> 'muchos espacios'


    # item_ok.id_unico = 2 # Fallaría porque frozen=True
except ValidationError as e:
    print("Error en ModeloConfigurado:")
    print(e.errors())
except Exception as e_gen: # Captura otros errores como el de reasignación a un modelo frozen
    print(f"Otro error: {e_gen}")
```

**8. Modelos Anidados y Recursivos**

Pydantic maneja modelos anidados de forma natural. Para modelos que se referencian a sí mismos (recursivos), se usa `model_rebuild()` después de definir todas las clases involucradas si hay referencias hacia adelante (forward references) como strings.

```python
from typing import List, Optional
from pydantic import BaseModel, Field # Field importado para default_factory

class Empleado(BaseModel):
    id: int
    nombre: str
    jefe: Optional['Empleado'] = None # Referencia hacia adelante (Forward reference)
    subordinados: List['Empleado'] = Field(default_factory=list) # Usar default_factory

# Pydantic V2 maneja esto automáticamente en muchos casos,
# pero si se encuentran problemas, se puede llamar explícitamente:
# Empleado.model_rebuild() # Descomentar si es necesario

jefa = Empleado(id=1, nombre="Ana")
empleado1 = Empleado(id=2, nombre="Luis", jefe=jefa)
# Para que la serialización muestre la relación bidireccional correctamente,
# la jefa también debe conocer a sus subordinados.
jefa.subordinados.append(empleado1)


print(jefa.model_dump_json(indent=2))
```
**9. Modelos Genéricos (`GenericModel`)**

Permite crear modelos que pueden trabajar con diferentes tipos de datos de forma genérica.

```python
from typing import TypeVar, Generic, Optional # Asegurar Optional está importado
from pydantic import BaseModel # BaseModel necesario para DatosUsuario
from pydantic.generics import GenericModel

DataT = TypeVar('DataT')

class RespuestaAPI(GenericModel, Generic[DataT]):
    data: DataT
    error: Optional[str] = None

class DatosUsuario(BaseModel):
    id: int
    nombre: str

respuesta_usuario = RespuestaAPI[DatosUsuario](data=DatosUsuario(id=1, nombre="Eva"))
print(respuesta_usuario.model_dump_json(indent=2))
# {
#   "data": {
#     "id": 1,
#     "nombre": "Eva"
#   },
#   "error": null
# }
```

**10. Gestión de Configuración con `pydantic-settings`**

La funcionalidad de `BaseSettings` para cargar configuraciones desde variables de entorno, archivos `.env`, etc., se ha movido al paquete separado `pydantic-settings`.

```python

# pip install pydantic-settings
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import ValidationError # Para capturar errores de validación

class AjustesAppV2(BaseSettings):
    model_config = SettingsConfigDict(
        env_file='.env',
        env_file_encoding='utf-8',
        extra='ignore' # Ignorar variables de entorno extra
    )

    DATABASE_URL: str
    API_KEY: str
    DEBUG_MODE: bool = False

# Suponiendo que tienes un .env:
# DATABASE_URL="postgresql://user:pass@host:port/db"
# API_KEY="tu_super_secreta_api_key"

# Crear un archivo .env de ejemplo para que el código se ejecute:
with open(".env", "w") as f:
    f.write('DATABASE_URL="postgresql://user:pass@host:port/db"\n')
    f.write('API_KEY="tu_super_secreta_api_key_ejemplo"\n')
    f.write('DEBUG_MODE="True"\n')

try:
    ajustes = AjustesAppV2()
    print(f"Conectando a: {ajustes.DATABASE_URL}")
    print(f"API Key: {ajustes.API_KEY[:5]}...")
    print(f"Debug mode: {ajustes.DEBUG_MODE}")
except ValidationError as e:
    print("Error cargando la configuración:", e.errors())
```

---


## 2.3. Creación de una estructura base escalable

Una estructura de proyecto bien definida es crucial para la escalabilidad y mantenibilidad de cualquier aplicación, y las aplicaciones FastAPI no son una excepción. A medida que un proyecto crece, una organización lógica de archivos y directorios facilita la navegación, la colaboración entre desarrolladores, las pruebas y la adición de nuevas funcionalidades.

No existe una única "estructura perfecta" universal, ya que la ideal dependerá del tamaño y la complejidad del proyecto. Sin embargo, hay patrones y recomendaciones comunes que promueven la escalabilidad.

**Objetivos de una Buena Estructura de Proyecto:**

* **Claridad:** Fácil de entender dónde encontrar cada pieza de código.
* **Modularidad:** Componentes bien definidos y reutilizables.
* **Bajo Acoplamiento:** Minimizar las dependencias directas entre módulos no relacionados.
* **Alta Cohesión:** Agrupar código relacionado lógicamente.
* **Testeabilidad:** Facilitar la escritura de pruebas unitarias y de integración.
* **Escalabilidad:** Permitir que el proyecto crezca en funcionalidades y complejidad sin volverse caótico.

A continuación, exploraremos algunas estructuras de proyecto comunes para FastAPI, desde las más simples hasta las más completas.

### 1. Estructura Mínima (Para Proyectos Pequeños o Prototipos)

Para proyectos muy pequeños o cuando se está prototipando rápidamente, toda la aplicación puede residir en un solo archivo.

```text
.
├── main.py         # Aplicación FastAPI principal, modelos, endpoints
└── requirements.txt
```

* **`main.py`**:

```python
# Este código es para demostración.
# Para ejecutarlo, necesitarías FastAPI y Uvicorn instalados.
# Guarda este bloque como main.py y ejecuta: uvicorn main:app --reload

from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

class Item(BaseModel):
    name: str
    price: float
    is_offer: bool = None

@app.get("/")
async def read_root():
    return {"Hello": "World"}

@app.post("/items/")
async def create_item(item: Item):
    return item
```

* **Pros:** Simple, rápido para empezar.
* **Contras:** No escala bien. Se vuelve difícil de manejar a medida que se añaden más endpoints, modelos o lógica.
* **Cuándo usarlo:** Proyectos muy pequeños, tutoriales, pruebas de concepto.

### 2. Estructura Básica Modular (Separando Routers)

Un primer paso común para mejorar la organización es separar los *endpoints* en diferentes módulos usando `APIRouter`.

```text
.
├── app/
│   ├── __init__.py
│   ├── main.py             # Creación de la instancia FastAPI, inclusión de routers
│   ├── routers/
│   │   ├── __init__.py
│   │   ├── items.py        # Router para items
│   │   └── users.py        # Router para usuarios
│   ├── models/             # Modelos Pydantic (o schemas)
│   │   ├── __init__.py
│   │   ├── item.py
│   │   └── user.py
├── tests/
│   └── ...
├── .env
├── .gitignore
└── requirements.txt
```

**`app/main.py`** (Ejemplo):

```python
# Suponiendo que app/routers/items.py y app/routers/users.py existen
# from fastapi import FastAPI
# from .routers import items, users # Esta importación es relativa, funcionaría en el contexto del proyecto

# app = FastAPI()

# app.include_router(items.router)
# app.include_router(users.router)

# @app.get("/")
# async def root():
#     return {"message": "Hello Bigger Applications!"}
print("Contenido de app/main.py iría aquí.")
```

**`app/routers/items.py`** (Ejemplo):

```python
# from fastapi import APIRouter
# # Para que la siguiente importación funcione, app/models/item.py debe existir
# # from ..models.item import Item

# router = APIRouter(
#     prefix="/items",
#     tags=["items"],
#     responses={404: {"description": "Not found"}},
# )

# @router.post("/", response_model=Item)
# async def create_item(item: Item):
#     print(f"Item creado: {item.name}")
#     return item

# @router.get("/{item_id}", response_model=Item)
# async def read_item(item_id: str):
#     # Simulación:
#     return Item(name="Fake Item", price=10.0, is_offer=False)
print("Contenido de app/routers/items.py iría aquí.")
```

**`app/models/item.py`** (Ejemplo):

```python
from pydantic import BaseModel
from typing import Optional

class Item(BaseModel):
    name: str
    price: float
    is_offer: Optional[bool] = None

# item_ejemplo = Item(name="Cuaderno", price=2.50)
# print(item_ejemplo)
print("Definición de app/models/item.py cargada.")
```

* **Pros:** Mejor organización, más fácil de navegar, separación de responsabilidades por dominio/recurso.
* **Contras:** La lógica de negocio puede empezar a mezclarse con los routers si no se tiene cuidado.
* **Cuándo usarlo:** Proyectos pequeños a medianos.

### 3. Estructura Orientada a Servicios (Capa de Lógica de Negocio)

Para evitar que la lógica de negocio compleja sature los archivos de rutas, se introduce una capa de "servicios".

```text
.
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── core/                   # Configuración, dependencias comunes
│   │   ├── __init__.py
│   │   └── config.py
│   ├── db/                     # Módulos de base de datos (ej. sesión, ORM base)
│   │   ├── __init__.py
│   │   └── session.py          # (ej. para SQLAlchemy)
│   ├── models/                 # Modelos ORM (si se usa un ORM)
│   │   ├── __init__.py
│   │   ├── item.py
│   │   └── user.py
│   ├── schemas/                # Modelos Pydantic (para validación y serialización API)
│   │   ├── __init__.py
│   │   ├── item.py
│   │   └── user.py
│   ├── crud/                   # (Opcional) Funciones CRUD básicas reutilizables para ORM
│   │   ├── __init__.py
│   │   ├── crud_item.py
│   │   └── base.py
│   ├── services/               # Lógica de negocio
│   │   ├── __init__.py
│   │   ├── item_service.py
│   │   └── user_service.py
│   └── routers/                # Endpoints API (ahora más delgados)
│       ├── __init__.py
│       ├── items.py
│       └── users.py
├── tests/
│   └── ...
├── .env
├── .gitignore
└── requirements.txt
```

**`app/schemas/item.py`** (Ejemplo):

```python
from pydantic import BaseModel
from typing import Optional

class ItemBase(BaseModel):
    name: str
    price: float
    description: Optional[str] = None

class ItemCreate(ItemBase):
    pass

class ItemUpdate(ItemBase):
    pass

class ItemInDBBase(ItemBase):
    id: int

    class Config: # Para Pydantic V1, o model_config para V2
        orm_mode = True # Pydantic V1
        # from_attributes = True # Pydantic V2

class Item(ItemInDBBase): # Schema para respuestas API
    pass
print("Definición de app/schemas/item.py cargada.")
```

**`app/services/item_service.py`** (Ejemplo):

```python
# Para que este bloque funcione, necesitaríamos que app/schemas/item.py esté accesible
# from .. import schemas # Esto fallaría en un notebook directamente
# Por ahora, definimos los schemas necesarios aquí mismo para demostración:
from pydantic import BaseModel
from typing import Optional

class ItemBase(BaseModel): # Re-definición para el ejemplo autocontenido
    name: str
    price: float
    description: Optional[str] = None

class ItemCreate(ItemBase): # Re-definición
    pass

class Item(ItemBase): # Simplificado para el ejemplo de servicio, re-definición
    id: int

class ItemService:
    def get_item(self, item_id: int) -> Optional[Item]:
        print(f"Servicio: Obteniendo item con ID {item_id}")
        if item_id == 1: # Simulación
            return Item(id=item_id, name="Super Item", price=25.99, description="Un item de prueba")
        return None

    def create_item(self, item_in: ItemCreate) -> Item:
        print(f"Servicio: Creando item '{item_in.name}'")
        return Item(id=99, name=item_in.name, price=item_in.price, description=item_in.description)

svc = ItemService()
nuevo_item_data = ItemCreate(name="Libro de Python", price=30.0, description="Aprende Python ya!")
item_creado = svc.create_item(nuevo_item_data)
print(f"Item creado por servicio: {item_creado}")
item_obtenido = svc.get_item(1)
print(f"Item obtenido por servicio: {item_obtenido}")
```

**`app/routers/items.py`** (Ejemplo):

```python
# from fastapi import APIRouter, Depends, HTTPException
# from typing import List, Optional
# # Las siguientes importaciones son relativas y necesitarían la estructura de proyecto
# # from .. import schemas
# # from ..services.item_service import ItemService

# router = APIRouter(prefix="/items", tags=["items"])

# def get_item_service():
#     return ItemService()

# @router.post("/", response_model=schemas.Item)
# async def create_item_endpoint(
#     item_in: schemas.ItemCreate,
#     item_svc: ItemService = Depends(get_item_service)
# ):
#     return item_svc.create_item(item_in=item_in)

# @router.get("/{item_id}", response_model=Optional[schemas.Item])
# async def read_item_endpoint(
#     item_id: int,
#     item_svc: ItemService = Depends(get_item_service)
# ):
#     db_item = item_svc.get_item(item_id=item_id)
#     if db_item is None:
#         raise HTTPException(status_code=404, detail="Item not found")
#     return db_item
print("Contenido de app/routers/items.py (con servicio) iría aquí.")
```

* **Pros:** Separación clara de la lógica de API, negocio y datos. Más fácil de testear la lógica de negocio de forma aislada. Mayor mantenibilidad.
* **Contras:** Más archivos y directorios, puede parecer excesivo para proyectos pequeños.
* **Cuándo usarlo:** Proyectos medianos a grandes donde la lógica de negocio es significativa. Esta es una estructura muy popular y recomendada para la mayoría de las aplicaciones FastAPI serias.

### 4. Estructura por Funcionalidad/Dominio (Feature-based)

En lugar de agrupar por tipo de capa (routers, services, models), se agrupa por funcionalidad o dominio de negocio.

```text
.
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── core/
│   │   └── config.py
│   ├── common/                 # Componentes compartidos (ej. modelos Pydantic base, utils)
│   │   ├── __init__.py
│   │   └── schemas.py
│   ├── features/               # O 'domains', 'modules'
│   │   ├── __init__.py
│   │   ├── items/
│   │   │   ├── __init__.py
│   │   │   ├── item_router.py
│   │   │   ├── item_service.py
│   │   │   ├── item_crud.py
│   │   │   ├── item_schemas.py  # Pydantic schemas para items
│   │   │   └── item_models.py   # ORM models para items (si aplica)
│   │   ├── users/
│   │   │   ├── __init__.py
│   │   │   ├── user_router.py
│   │   │   ├── user_service.py
│   │   │   └── ...
│   │   └── orders/
│   │       └── ...
│   └── db/
│       └── session.py
├── tests/
│   └── ...
└── requirements.txt
```

* **Pros:** Muy alta cohesión dentro de cada feature. Fácil encontrar todo lo relacionado con una funcionalidad. Bueno para equipos grandes donde diferentes equipos trabajan en diferentes features.
* **Contras:** Puede haber cierta duplicación de lógica si no se gestionan bien los componentes comunes. Requiere disciplina para mantener los límites entre features.
* **Cuándo usarlo:** Proyectos grandes y complejos, especialmente con equipos distribuidos o cuando se quiere una clara delimitación por dominio de negocio.

### 5. Arquitectura Hexagonal (Puertos y Adaptadores)

Este patrón arquitectónico, también conocido como "Puertos y Adaptadores", se centra en aislar la lógica de negocio central (el "hexágono" o "dominio de la aplicación") de las preocupaciones externas como la UI, la base de datos, o servicios de terceros.

* **Núcleo de la Aplicación (Dominio):** Contiene la lógica de negocio pura, modelos de dominio (entidades) y casos de uso (servicios de aplicación). No depende de ninguna tecnología externa.
* **Puertos:** Definen interfaces (contratos) que el núcleo de la aplicación expone para interactuar con el exterior (ej. `ItemServicePort`) o que necesita para obtener datos o realizar acciones (ej. `ItemRepositoryPort`).
* **Adaptadores:** Implementaciones concretas de los puertos.
    * **Adaptadores Primarios/Conductores (Driving Adapters):** Invocan al núcleo de la aplicación. Ejemplos: controladores API (routers FastAPI), scripts CLI.
    * **Adaptadores Secundarios/Conducidos (Driven Adapters):** Son invocados por el núcleo de la aplicación (a través de puertos). Ejemplos: implementaciones de repositorios de base de datos (SQLAlchemy, MongoDB), clientes de servicios externos.

```text
.
├── app/
│   ├── __init__.py
│   ├── main.py                     # Configuración de FastAPI, montaje de adaptadores primarios
│   ├── core/
│   │   └── config.py
│   ├── domain/                     # Lógica de negocio pura, agnóstica al framework
│   │   ├── __init__.py
│   │   ├── items/
│   │   │   ├── item_entities.py    # Entidades de dominio (pueden ser Pydantic o dataclasses)
│   │   │   ├── item_services.py    # Casos de uso/servicios de aplicación (usan puertos)
│   │   │   └── item_ports.py       # Interfaces (puertos) para repositorios, etc.
│   │   └── users/
│   │       └── ...
│   ├── adapters/                   # Implementaciones de tecnologías externas
│   │   ├── __init__.py
│   │   ├── primary/                # O 'driving', 'api', 'entrypoints'
│   │   │   ├── __init__.py
│   │   │   ├── items_api.py        # Router FastAPI para items (adaptador primario)
│   │   │   └── users_api.py
│   │   └── secondary/              # O 'driven', 'infrastructure'
│   │       ├── __init__.py
│   │       ├── db/                 # Adaptadores de base de datos
│   │       │   ├── __init__.py
│   │       │   ├── item_sql_repository.py # Implementación de ItemRepositoryPort con SQL
│   │       │   └── db_utils.py
│   │       └── external_services/
│   │           └── ...
│   └── common/
│       └── ...
├── tests/
│   ├── domain/
│   │   └── items/
│   │       └── test_item_services.py # Tests unitarios del dominio, usando mocks para los puertos
│   ├── adapters/
│   │   └── ...
│   └── e2e/
│       └── test_items_flow.py
└── requirements.txt
```

**`app/domain/items/item_ports.py`** (Ejemplo):

```python
from abc import ABC, abstractmethod
from typing import List, Optional
# from .item_entities import Item # Asumiendo que Item es una entidad de dominio
# Para que este bloque sea autocontenido, definimos Item aquí:
from pydantic import BaseModel
class Item(BaseModel): # Re-definición para el ejemplo autocontenido
    id: str
    name: str
    price: float

class ItemRepositoryPort(ABC):
    @abstractmethod
    def get_by_id(self, item_id: str) -> Optional[Item]:
        pass

    @abstractmethod
    def save(self, item: Item) -> Item:
        pass
print("Definición de app/domain/items/item_ports.py cargada.")
```

* **Pros:** Máxima separación de la lógica de negocio de las preocupaciones externas. Alta testeabilidad del dominio (se pueden mockear los adaptadores). Flexibilidad para cambiar tecnologías (ej. base de datos, framework web).
* **Contras:** Mayor complejidad inicial y más *boilerplate* (código repetitivo para definir puertos y adaptadores). Puede ser excesivo para proyectos más simples.
* **Cuándo usarlo:** Aplicaciones complejas y de larga duración donde la mantenibilidad, testeabilidad y flexibilidad tecnológica son críticas.

### 6. Clean Architecture

Similar en espíritu a la Arquitectura Hexagonal, Clean Architecture (propuesta por Robert C. Martin - "Uncle Bob") también enfatiza la independencia del framework, la testeabilidad y la separación de responsabilidades, pero lo organiza en capas concéntricas:

* **Entities (Entidades):** Objetos de negocio centrales de la aplicación. Contienen la lógica de negocio más general y de alto nivel. No dependen de nada externo.
* **Use Cases (Casos de Uso / Interactors):** Orquestan el flujo de datos hacia y desde las entidades. Contienen la lógica de aplicación específica. Dependen de las Entidades, pero no de capas externas. Definen interfaces para los *gateways* (similares a los puertos).
* **Interface Adapters (Adaptadores de Interfaz):** Convierten datos del formato más conveniente para los Casos de Uso y Entidades al formato más conveniente para agencias externas como la Base de Datos, la Web, etc. (ej. Controladores, Presentadores, Gateways/Repositorios).
* **Frameworks & Drivers (Frameworks y Controladores):** La capa más externa. Detalles de implementación: Frameworks (FastAPI), Base de Datos, UI, dispositivos externos.

La regla de dependencia es clave: **las dependencias solo pueden apuntar hacia adentro**. El código de una capa interna no puede saber nada sobre una capa externa.

```text
.
├── app/
│   ├── __init__.py
│   ├── main.py                     # Punto de entrada, configuración, inyección de dependencias
│   ├── core/
│   │   └── config.py
│   ├── domain/                     # Equivalente a Entities + parte de Use Cases
│   │   ├── __init__.py
│   │   ├── entities/
│   │   │   └── item_entity.py
│   │   └── use_cases/              # O 'interactors'
│   │       ├── __init__.py
│   │       ├── create_item_use_case.py
│   │       └── _interfaces/        # Interfaces para gateways/repositorios
│   │           └── item_repository_interface.py
│   ├── interface_adapters/
│   │   ├── __init__.py
│   │   ├── controllers/            # Routers FastAPI
│   │   │   └── item_controller.py
│   │   ├── presenters/             # (Opcional, para transformar datos de salida)
│   │   └── gateways/               # Implementaciones de repositorios
│   │       └── item_sql_gateway.py
│   └── infrastructure/             # Frameworks & Drivers (configuración de DB, clientes HTTP externos)
│       ├── __init__.py
│       └── database/
│           └── setup.py
├── tests/
│   └── ...
└── requirements.txt
```

* **Pros y Contras:** Similares a la Arquitectura Hexagonal. Ofrece una guía muy estricta sobre las dependencias, lo que puede llevar a un diseño muy desacoplado y testeable.
* **Cuándo usarlo:** Similar a la Hexagonal, para aplicaciones grandes, complejas y de larga duración.

### Consideraciones Adicionales

* **`core`**: Suele contener la configuración de la aplicación (`config.py` cargando desde variables de entorno usando Pydantic Settings), y a veces dependencias globales o seguridad.
* **`db` / `infrastructure/database`**: Lógica de conexión a la base de datos, inicialización de ORM, definición de la sesión.
* **`models` (ORM) vs `schemas` (Pydantic)**:
    * `models`: Generalmente se refiere a los modelos ORM (ej. SQLAlchemy, Tortoise ORM) que interactúan directamente con la base de datos. En arquitecturas como Hexagonal o Clean, estos serían parte de los adaptadores de infraestructura o gateways.
    * `schemas`: Se refiere a los modelos Pydantic utilizados para la validación de datos de entrada/salida de la API y la serialización. También pueden usarse como DTOs (Data Transfer Objects) entre capas.
* **`crud`**: Operaciones genéricas de Crear, Leer, Actualizar, Eliminar para los modelos ORM. Ayuda a no repetir código. En arquitecturas más limpias, esto sería parte de los gateways/repositorios.
* **`dependencies.py`**: Un lugar común para definir dependencias reutilizables de FastAPI (ej. `get_current_user`, `get_db_session`, o inyectores para servicios/casos de uso).
* **`tests`**: Estructura los tests de forma paralela a tu aplicación (ej. `tests/routers/test_items.py` o `tests/domain/use_cases/test_create_item.py`).
* **Scripts y herramientas (`scripts/`, `tools/`)**: Para tareas de utilidad, migraciones, etc.

**¿Cómo Ayuda FastAPI a estas Estructuras?**

* **`APIRouter`**: Esencial para dividir los *endpoints* en módulos, que actuarían como adaptadores primarios o controladores.
* **Sistema de Inyección de Dependencias (`Depends`)**: Clave para implementar los patrones de Puertos y Adaptadores o Clean Architecture, permitiendo inyectar implementaciones concretas (adaptadores, gateways, repositorios) en los casos de uso o servicios de aplicación, y estos a su vez en los controladores/routers.
* **Modelos Pydantic**: Actúan como contratos de datos claros (DTOs) entre las capas, asegurando la validación y serialización.

**Conclusión Parcial:**

Elegir la estructura de proyecto adecuada es un paso importante hacia la construcción de una aplicación FastAPI escalable y mantenible. Comienza simple y evoluciona la estructura a medida que el proyecto crece en complejidad. La estructura orientada a servicios (punto 3) suele ser un excelente equilibrio para muchos proyectos. Para aplicaciones más grandes y complejas que requieren una alta mantenibilidad y flexibilidad a largo plazo, considerar patrones como la Arquitectura Hexagonal o Clean Architecture puede ser muy beneficioso, aunque conllevan una mayor sobrecarga inicial. La clave es la consistencia y la separación clara de responsabilidades.


---

## 2.4. Gestión de rutas y controladores RESTful


Una parte fundamental de la construcción de APIs robustas y fáciles de usar es una gestión de rutas clara y el diseño de controladores que sigan los principios RESTful. FastAPI proporciona herramientas excelentes para lograr esto de manera eficiente y elegante.

**Principios RESTful Clave:**

Antes de sumergirnos en FastAPI, recordemos brevemente algunos principios REST (Representational State Transfer):

1.  **Recursos:** Todo se considera un recurso (ej. un usuario, un producto, un pedido). Los recursos se identifican mediante URIs (Uniform Resource Identifiers), comúnmente URLs.
2.  **Métodos HTTP (Verbos):** Se utilizan los métodos estándar de HTTP para operar sobre los recursos:
    * `GET`: Recuperar un recurso o una colección de recursos.
    * `POST`: Crear un nuevo recurso.
    * `PUT`: Actualizar completamente un recurso existente (reemplazo).
    * `PATCH`: Actualizar parcialmente un recurso existente.
    * `DELETE`: Eliminar un recurso.
    * `OPTIONS`: Obtener las opciones de comunicación para el recurso de destino.
    * `HEAD`: Similar a `GET`, pero sin el cuerpo de la respuesta.
3.  **Representaciones:** Los recursos pueden tener múltiples representaciones (ej. JSON, XML). El cliente y el servidor negocian el formato del contenido (usando cabeceras como `Content-Type` y `Accept`). JSON es el formato más común para las APIs modernas.
4.  **Stateless (Sin estado):** Cada petición del cliente al servidor debe contener toda la información necesaria para entender la petición. El servidor no almacena ningún estado del cliente entre peticiones.
5.  **Interfaz Uniforme:** Un conjunto limitado y bien definido de operaciones y convenciones.
6.  **HATEOAS (Hypermedia as the Engine of Application State):** (Opcional pero recomendado para APIs muy maduras) Las respuestas del servidor pueden incluir enlaces a otras acciones o recursos relacionados, permitiendo al cliente navegar por la API.

**Gestión de Rutas en FastAPI**

FastAPI utiliza decoradores de *path operation* sobre funciones `async def` o `def` para definir las rutas y los métodos HTTP que manejan.

### 1. `FastAPI()` y `APIRouter()`

* **Instancia Principal `FastAPI()`:**
    ```python
    from fastapi import FastAPI

    app = FastAPI(
        title="Mi Súper API",
        description="Esta es una API de demostración con FastAPI.",
        version="1.0.0",
        # openapi_tags=[...] # Para metadatos de tags en Swagger UI
    )

    @app.get("/")
    async def read_root():
        return {"message": "Bienvenido a la API"}
    ```
    La instancia `app` es el punto de entrada principal.

* **`APIRouter()` para Modularidad:**
    Para organizar mejor las rutas, especialmente en aplicaciones grandes, se utiliza `APIRouter`. Cada router puede agrupar un conjunto de rutas relacionadas (por ejemplo, todas las rutas para la gestión de "usuarios").

    * **Ejemplo de un router (`app/routers/users.py`):**
        ```python
        from fastapi import APIRouter, HTTPException
        from pydantic import BaseModel
        from typing import List, Optional

        router = APIRouter(
            prefix="/users",  # Prefijo para todas las rutas en este router
            tags=["users"],   # Agrupa estas rutas bajo la etiqueta "users" en la documentación
            responses={404: {"description": "No encontrado"}} # Respuestas por defecto
        )

        class User(BaseModel):
            id: int
            username: str
            email: str

        class UserCreate(BaseModel):
            username: str
            email: str

        # Simulación de una base de datos en memoria
        fake_users_db = {
            1: {"id": 1, "username": "johndoe", "email": "john.doe@example.com"},
            2: {"id": 2, "username": "janedoe", "email": "jane.doe@example.com"},
        }
        next_user_id = 3

        @router.post("/", response_model=User, status_code=201) # Código de estado para creación exitosa
        async def create_user(user_in: UserCreate):
            global next_user_id
            # En Pydantic V2, se usaría model_dump() en lugar de dict()
            new_user_data = user_in.model_dump() if hasattr(user_in, 'model_dump') else user_in.dict()
            new_user = User(id=next_user_id, **new_user_data)
            fake_users_db[next_user_id] = new_user.model_dump() if hasattr(new_user, 'model_dump') else new_user.dict()
            next_user_id += 1
            return new_user

        @router.get("/", response_model=List[User])
        async def read_users(skip: int = 0, limit: int = 10):
            users_list = list(fake_users_db.values())
            return users_list[skip : skip + limit]

        @router.get("/{user_id}", response_model=User)
        async def read_user(user_id: int):
            if user_id not in fake_users_db:
                raise HTTPException(status_code=404, detail="Usuario no encontrado")
            return fake_users_db[user_id]
        ```

    * **Inclusión del router en la aplicación principal (`app/main.py`):**
        ```python
        from fastapi import FastAPI
        # from .routers import users # Si users.py está en el mismo directorio o subdirectorio app.routers

        # Para que este ejemplo sea autocontenido, definimos el router aquí mismo
        # En un proyecto real, esto estaría en app/routers/users.py
        from fastapi import APIRouter as UsersAPIRouter # Renombrado para evitar conflicto
        from pydantic import BaseModel as UsersBaseModel
        from typing import List as UsersList

        user_router_instance = UsersAPIRouter(prefix="/users", tags=["users"])
        class UserSchema(UsersBaseModel): id: int; username: str
        class UserCreateSchema(UsersBaseModel): username: str
        fake_db_users_example = {1: UserSchema(id=1, username="testuser")}
        
        @user_router_instance.post("/", response_model=UserSchema)
        async def create_user_example(user: UserCreateSchema): 
            # En Pydantic V2, se usaría model_dump()
            user_data = user.model_dump() if hasattr(user, 'model_dump') else user.dict()
            return UserSchema(id=2, **user_data)
            
        @user_router_instance.get("/", response_model=UsersList[UserSchema])
        async def get_users_example(): return list(fake_db_users_example.values())


        app = FastAPI(title="API Principal")
        app.include_router(user_router_instance) # Incluir el router de usuarios

        @app.get("/")
        async def main_root():
            return {"message": "API Principal"}
        ```

### 2. Path Operations: Definiendo Endpoints

FastAPI ofrece decoradores para todos los métodos HTTP estándar: `@app.get()`, `@app.post()`, `@app.put()`, `@app.patch()`, `@app.delete()`, `@app.options()`, `@app.head()`.

* **Parámetros de Ruta (Path Parameters):**
    Se definen usando la misma sintaxis que los *format strings* de Python en la ruta.
    ```python
    # Asumimos que 'router' está definido, ej: router = APIRouter()
    @router.get("/items/{item_id}")  # item_id es un parámetro de ruta
    async def read_item(item_id: int): # FastAPI valida y convierte el tipo
        return {"item_id": item_id}
    ```

* **Parámetros de Consulta (Query Parameters):**
    Son parámetros que no forman parte de la ruta y se declaran como argumentos de la función que no están en la ruta.
    ```python
    from typing import Optional # Necesario para Optional
    # Asumimos que 'router' está definido
    @router.get("/items/")
    async def read_items(skip: int = 0, limit: int = 10, q: Optional[str] = None):
        # skip y limit tienen valores por defecto, q es opcional
        results = {"skip": skip, "limit": limit}
        if q:
            results.update({"q": q})
        return results
    ```
    FastAPI también permite validaciones avanzadas para parámetros de consulta usando `Query` de `fastapi`.

* **Cuerpo de la Petición (Request Body):**
    Se define usando modelos Pydantic como anotaciones de tipo en los parámetros de la función. FastAPI automáticamente leerá, validará y parseará el cuerpo de la petición (generalmente JSON).
    ```python
    from pydantic import BaseModel
    from typing import Optional # Necesario para Optional

    class Item(BaseModel):
        name: str
        description: Optional[str] = None
        price: float
        tax: Optional[float] = None

    # Asumimos que 'router' está definido, ej: router = APIRouter()
    @router.post("/items/", status_code=201)
    async def create_item(item: Item): # 'item' se espera en el cuerpo de la petición
        return {"item_name": item.name, "item_price_with_tax": item.price + (item.tax or 0)}
    ```

### 3. Modelo de Respuesta (`response_model`)

Es una buena práctica definir explícitamente la estructura de la respuesta usando el parámetro `response_model` en el decorador del *path operation*. Esto:
    * Valida los datos de salida.
    * Filtra los datos para que solo se devuelvan los campos definidos en el modelo.
    * Documenta la estructura de la respuesta en el esquema OpenAPI.

```python
from pydantic import BaseModel # Necesario para BaseModel

# Asumimos que 'router' está definido y la clase 'Item' también
# class Item(BaseModel):
#     name: str
#     description: Optional[str] = None
#     price: float
#     tax: Optional[float] = None

class ItemResponse(BaseModel):
    name: str
    price: float
    # No incluimos 'tax' si no queremos exponerlo en la respuesta

@router.post("/items_v2/", response_model=ItemResponse)
async def create_item_v2(item: Item): # Item definido en la sección anterior
    # Aquí podríamos tener lógica para guardar el item completo (con tax)
    # pero solo devolvemos los campos de ItemResponse
    return item # FastAPI filtrará los campos según ItemResponse
```

* **Códigos de Estado HTTP (`status_code`):**
    Puedes especificar el código de estado HTTP por defecto para una respuesta exitosa.
    ```python
    from pydantic import BaseModel # Necesario para BaseModel
    # Asumimos que 'router' está definido
    @router.post("/create_resource/", status_code=201) # HTTP 201 Created
    async def create_resource(payload: BaseModel): # Un payload genérico Pydantic
        return payload
    ```

### 4. Inyección de Dependencias (`Depends`)

El sistema de inyección de dependencias de FastAPI es extremadamente potente y útil para la gestión de controladores. Permite:
    * Compartir lógica.
    * Compartir conexiones a bases de datos.
    * Implementar esquemas de seguridad (autenticación y autorización).

```python
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer # Ejemplo para oauth2_scheme

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token") # Ejemplo

async def get_current_active_user(token: str = Depends(oauth2_scheme)): # oauth2_scheme sería tu esquema de seguridad
    # Lógica para validar el token y obtener el usuario
    # user_data = get_user_from_token(token) # Esta función debería ser implementada
    # if not user_data:
    #     raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid authentication credentials", headers={"WWW-Authenticate": "Bearer"})
    # user = UserInDB(**user_data) # Asumiendo un modelo UserInDB
    # if not user.is_active: # Asumiendo un campo is_active en tu modelo de usuario
    #     raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Inactive user")
    # return user
    print(f"Simulando obtención de usuario con token: {token[:5]}...")
    # Simulación: En un caso real, aquí validarías el token y devolverías el usuario.
    if token == "fake-super-secret-token":
        return {"username": "fakeuser", "is_active": True, "email": "fake@example.com"}
    raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")


# Asumimos que 'router' está definido
@router.get("/users/me")
async def read_users_me(current_user: dict = Depends(get_current_active_user)):
    return current_user
```
En una estructura orientada a servicios, las clases de servicio se pueden inyectar en los *path operations*.

### 5. Diseño de Controladores RESTful (Buenas Prácticas)

* **Nombres de Rutas (Endpoints):**
    * Usar sustantivos en plural para colecciones de recursos (ej. `/users`, `/items`).
    * Usar identificadores para recursos específicos (ej. `/users/{user_id}`, `/items/{item_id}`).
    * Para acciones que no encajan en CRUD, considera sub-recursos o verbos específicos si es necesario, pero intenta mantenerlo simple (ej. `/users/{user_id}/activate`).
* **Consistencia:** Mantén la consistencia en el nombrado, la estructura de las respuestas y los códigos de estado.
* **Manejo de Errores:**
    * Usa `HTTPException` de FastAPI para devolver errores HTTP con códigos de estado y detalles apropiados.
    * Considera un manejador de excepciones global para errores no controlados o para estandarizar el formato de los errores.
    ```python
    from fastapi import Request, FastAPI # FastAPI para @app.exception_handler
    from fastapi.responses import JSONResponse

    # app = FastAPI() # Necesitarías una instancia de app para esto

    # @app.exception_handler(ValueError) # Ejemplo de manejador específico
    # async def value_error_exception_handler(request: Request, exc: ValueError):
    #     return JSONResponse(
    #         status_code=400,
    #         content={"message": f"Error de validación: {str(exc)}"},
    #     )
    ```
* **Versión de la API (Opcional pero recomendado para APIs públicas):**
    * En la URL (ej. `/v1/users`). FastAPI facilita esto anidando routers.
    * Mediante cabeceras HTTP (ej. `Accept: application/vnd.myapi.v1+json`).
* **Controladores "Delgados":** La lógica de negocio principal no debería residir directamente en las funciones de los *path operations*. Estas funciones deberían actuar como una capa delgada que:
    1.  Recibe la petición y los datos de entrada (validados por FastAPI y Pydantic).
    2.  Llama a servicios o funciones de lógica de negocio (posiblemente inyectados).
    3.  Devuelve la respuesta (formateada por FastAPI y Pydantic según `response_model`).

**Ejemplo de Controlador Delgado con Servicio:**

* **`app/services/product_service.py`**
    ```python
    # from ..schemas import ProductCreate, Product # Asumiendo estos schemas Pydantic
    # class ProductService:
    #     def create_product(self, product_data: ProductCreate) -> Product:
    #         print(f"Lógica de negocio para crear producto: {product_data.name}")
    #         # ... interactuar con base de datos, etc. ...
    #         # En Pydantic V2, se usaría model_dump()
    #         product_data_dict = product_data.model_dump() if hasattr(product_data, 'model_dump') else product_data.dict()
    #         return Product(id=123, **product_data_dict)
    print("Definición de ProductService (simulada) iría aquí.")
    ```

* **`app/routers/products.py`**
    ```python
    # from fastapi import APIRouter, Depends
    # from ..schemas import ProductCreate, Product
    # from ..services.product_service import ProductService

    # product_router = APIRouter(prefix="/products", tags=["products"])

    # def get_product_service(): # Dependencia para el servicio
    #     return ProductService()

    # @product_router.post("/", response_model=Product)
    # async def create_new_product(
    #     product_in: ProductCreate,
    #     service: ProductService = Depends(get_product_service)
    # ):
    #     return service.create_product(product_data=product_in)
    print("Definición del router de productos (simulada) iría aquí.")
    ```

**Conclusión Parcial:**

FastAPI ofrece un conjunto de herramientas muy completo y bien diseñado para la gestión de rutas y la creación de controladores RESTful. Al combinar `APIRouter` para la modularidad, modelos Pydantic para la validación y serialización, y el sistema de inyección de dependencias, puedes construir APIs limpias, robustas, bien documentadas y fáciles de mantener, siguiendo las mejores prácticas RESTful.


---

## **Referencias Bibliográficas y Recursos de Internet**

**FastAPI:**

1. [Documentación Oficial de FastAPI](https://fastapi.tiangolo.com/) \- La fuente más completa y actualizada. Creada por Sebastián Ramírez (Tiangolo).  
2. [Repositorio GitHub de FastAPI](https://github.com/tiangolo/fastapi) \- Código fuente, issues y discusiones.  
3. **Tutoriales y Artículos de Tiangolo:** El blog y las charlas del creador suelen ofrecer insights valiosos.  
4. [TestDriven.io \- FastAPI Courses & Tutorials](https://testdriven.io/blog/topics/fastapi/) \- Artículos y tutoriales de buena calidad sobre FastAPI.  
5. [Real Python](https://realpython.com/) \- Buscar "FastAPI" en Real Python suele arrojar tutoriales detallados y prácticos.

**Otros Frameworks y Tecnologías (Documentación Oficial):**

* [Django REST framework](https://www.django-rest-framework.org/)  
* [Flask](https://flask.palletsprojects.com/)  
* [Quart](https://pgjones.gitlab.io/quart/)  
* [Django Ninja](https://django-ninja.rest-framework.com/)  
* [Express.js](https://expressjs.com/)  
* [NestJS](https://nestjs.com/)  
* [ASP.NET Core](https://docs.microsoft.com/aspnet/core/)  
* [Spring Boot](https://spring.io/projects/spring-boot)  
* [Pydantic](https://pydantic-docs.helpmanual.io/) \- Fundamental para FastAPI.  
* [Starlette](https://www.starlette.io/) \- El framework ASGI sobre el que se construye FastAPI.  
* [Uvicorn](https://www.uvicorn.org/) \- El servidor ASGI recomendado para FastAPI.

**Benchmarking:**

* [TechEmpower Framework Benchmarks](https://www.techempower.com/benchmarks/) \- La fuente principal para datos de rendimiento comparativo de frameworks web.  
  * [Resultados de la Ronda 22 (Ejemplo)](https://www.techempower.com/benchmarks/#section=data-r22) \- *Siempre verifica la última ronda disponible.* (Nota: En el momento de esta actualización, la Ronda 22 es una referencia común, pero nuevas rondas pueden estar disponibles).

**Comunidades y Discusión:**

* **Stack Overflow:** Etiquetar preguntas con fastapi, python, y los nombres de otros frameworks relevantes.  
* **Reddit:** Subreddits como r/Python, r/FastAPI, r/django, r/flask, r/node, r/csharp, r/java.  
* **Gitter/Discord de FastAPI:** Canales de chat oficiales para FastAPI donde la comunidad y a veces el propio creador participan. (Buscar enlaces en la documentación oficial).

* **Código Mermaid:**
  
```mermaid
graph TD
    Client["Cliente HTTP (Navegador, Movil, u Otro Servicio)"]

    subgraph "Capa 1: Motor Asincrono"
      A["Python Asyncio - Event Loop"]
    end

    subgraph "Capa 2: Servidor ASGI"
      B["Uvicorn / Hypercorn / Daphne"]
    end

    subgraph "Capa 3: Toolkit ASGI Fundamental"
      C["Starlette"]
      C_Details["- Enrutamiento<br/>- Middlewares<br/>- Req/Res<br/>- Background Tasks<br/>- WebSockets"]
      C --> C_Details
    end

    subgraph "Capa 4: Validacion y Serializacion de Datos"
      D["Pydantic"]
      D_Details["- Modelos de Datos (Schemas)<br/>- Validacion de Tipos<br/>- Serializacion/Deserializacion"]
      D --> D_Details
    end

    subgraph "Capa 5: Tu Aplicacion con FastAPI"
      E["FastAPI App"]
      E_Details["- Path Operations (@app.get)<br/>- Inyeccion de Dependencias<br/>- Generacion OpenAPI<br/>- Seguridad Integrada<br/>- Tu Logica de Negocio"]
      E --> E_Details
    end

    Client -- "HTTP Request" --> B
    B -- "ASGI Request" --> E

    E -- "Utiliza o Extiende" --> C
    E -- "Integra o Utiliza" --> D

    C -- "Se ejecuta sobre" --> A
    B -- "Se ejecuta sobre o Gestiona" --> A

    E -- "ASGI Response" --> B
    B -- "HTTP Response" --> Client
```



* **Código Mermaid (versión simplificada para compatibilidad):**
```mermaid
graph TD
        Cliente["Usuarios Finales / Aplicaciones Cliente"]

        subgraph "Zona Externa / Perímetro"
            Gateway["API Gateway"]
        end

        subgraph "Red Interna de Microservicios"
            MS_A[("Microservicio A FastAPI expone OpenAPI")]
            MS_B[("Microservicio B FastAPI u Otro")]
            MS_C[("Microservicio C FastAPI u Otro")]

            DB_A[("Base de Datos A")]
            DB_B[("Base de Datos B")]

            Queue["Message Broker RabbitMQ o Kafka"]

            Cache[("Cache Distribuida Redis")]
        end

        subgraph "Infraestructura de Soporte"
            Logging["Sistema de Logging Centralizado"]
            Monitoring["Sistema de Monitorización y Alertas"]
            Discovery["Service Discovery Opcional Consul_etcd"]
        end

        Cliente --> Gateway

        Gateway -- "/api/servicioA" --> MS_A
        Gateway -- "/api/servicioB" --> MS_B

        MS_A -- "Síncrono (HTTP o gRPC)" --> MS_C
        MS_A --- DB_A
        MS_A --- Cache
        MS_A -- "Asíncrono (Publica)" --> Queue

        MS_B --- DB_B
        MS_B -- "Asíncrono (Consume)" --> Queue

        MS_A -- "Logs y Métricas" --> Logging
        MS_A -- "Logs y Métricas" --> Monitoring
        MS_B -- "Logs y Métricas" --> Logging
        MS_B -- "Logs y Métricas" --> Monitoring
        MS_C -- "Logs y Métricas" --> Logging
        MS_C -- "Logs y Métricas" --> Monitoring


        MS_A -. "Registra o Consulta" .-> Discovery
        MS_B -. "Registra o Consulta" .-> Discovery
        MS_C -. "Registra o Consulta" .-> Discovery
        Gateway -. "Consulta Rutas" .-> Discovery
```

---



