# CURSO: Arquitectura de Microservicios, Hexagonal, DDD y CQRS en FastAPI 

BLoque I:

1. Introducción a la Arquitectura de Microservicios
2. FastAPI como Framework para Microservicios
3. Introducción a la Comunicación entre Microservicios Síncrona y Asíncrona
4. Manejo de Errores y Circuit Breakers en Microservicios
5. Seguridad y Buenas Prácticas en Microservicios

Bloque II:

6. Arquitectura Hexagonal y Aplicación de DDD
7. Introducción a Domain-Driven Design (DDD)
8. Patrón CQRS en Microservicios

Bloque III:

9. Introducción a la Mensajería con Kafka, RabbitMQ
10. Introducción a los WebSockets y Pub/Sub en Sistemas Distribuidos
11. Diseño de APIs REST y WebSockets en FastAPI

Bloque IV: 
12. Escalabilidad y Optimización de Microservicios
13. Persistencia de Datos en Microservicios
14. Breve Introducción al Testing con Pytest
15. Buenas Prácticas y Automatización de Despliegues

16. Proyecto Final: Aplicación Completa Basada en Microservicios con FastAPI

---

# TEMA 1. INTRODUCCIÓN A LA ARQUITECTURA DE MICROSERVICIOS


  * [Objetivos](Tema1.md#objetivos)
  * [1.0 Conceptos Previos](Tema1.md#10-conceptos-previos)
  * [1.1 Evolución de la arquitectura monolítica hacia los microservicios](Tema1.md#11-evolución-de-la-arquitectura-monolítica-hacia-los-microservicios)
  * [1.2 Ventajas y Desventajas Clave de los Microservicios](Tema1.md#12-ventajas-y-desventajas-clave-de-los-microservicios)
  * [1.3 Principios Fundamentales de la Arquitectura de Microservicios](Tema1.md#13-principios-fundamentales-de-la-arquitectura-de-microservicios)
  * [1.4 Casos de Uso Reales donde los Microservicios Aportan Valor](Tema1.md#14-casos-de-uso-reales-donde-los-microservicios-aportan-valor)
  * [1.5 Distinción entre Microservicios y SOA (Service-Oriented Architecture)](Tema1.md#15-distinción-entre-microservicios-y-soa-service-oriented-architecture)
  * [1.6 La Importancia del Diseño Orientado a Dominio (DDD) en este Contexto](Tema1.md#16-la-importancia-del-diseño-orientado-a-dominio-ddd-en-este-contexto)
  * [1.7 Bounded Context y Separación de Responsabilidades](Tema1.md#17-bounded-context-y-separación-de-responsabilidades)
  * [1.8 Distribución de los Equipos en torno a Microservicios](Tema1.md#18-distribución-de-los-equipos-en-torno-a-microservicios)
  * [1.9 Evaluación del Impacto de los Microservicios en la Gestión del Ciclo de Vida del Software (SDLC)](Tema1.md#19-evaluación-del-impacto-de-los-microservicios-en-la-gestión-del-ciclo-de-vida-del-software-sdlc)
  * [1.10 Herramientas Modernas para la Gestión de Arquitecturas Distribuidas](Tema1.md#110-herramientas-modernas-para-la-gestión-de-arquitecturas-distribuidas)
  * [1.11 Introducción a Patrones Clave: API Gateway, Service Registry y Service Discovery](Tema1.md#111-introducción-a-patrones-clave)
  * [Referencias](Tema1.md#referencias)

# TEMA 2. FASTAPI COMO FRAMEWORK PARA MICROSERVICIOS


  - [Objetivos](#objetivos)
  - [Contenidos](#contenidos)
  - [2.1. Presentación de FastAPI y ventajas frente a Flask o Django](#21-presentación-de-fastapi-y-ventajas-frente-a-flask-o-django)
  - [2.2. Uso de Pydantic para validación y tipado estricto](#22-uso-de-pydantic-para-validación-y-tipado-estricto)
  - [2.3. Creación de una estructura base escalable para un microservicio](#23-creación-de-una-estructura-base-escalable-para-un-microservicio)
  - [2.4. Gestión de rutas y controladores RESTful desacoplados](#24-gestión-de-rutas-y-controladores-restful-desacoplados-el-arte-de-la-fachada-perfecta)
  - [2.5. Implementación de middlewares personalizados](#25-implementación-de-middlewares-personalizados)
  - [2.6. Aplicación del sistema de dependencias e inyecciones](#26-aplicación-del-sistema-de-dependencias-e-inyecciones)
  - [2.7. Integración automática de documentación con OpenAPI](#27-integración-automática-de-documentación-con-openapi)
  - [2.8. Utilización de BackgroundTasks para tareas asincrónicas](#28-utilización-de-backgroundtasks-para-tareas-asincrónicas)
  - [2.9. Manejo de excepciones personalizadas](#29-manejo-de-excepciones-personalizadas)
  - [2.10. Configuración de entornos con `BaseSettings`](#210-configuración-de-entornos-con-basesettings)
  - [2.11. Preparación para despliegue en producción con `uvicorn` y `gunicorn`](#211-preparación-para-despliegue-en-producción-con-uvicorn-y-gunicorn)

  # Tema 3. INTRODUCCIÓN A LA COMUNICACIÓN ENTRE MICROSERVICIOS SÍNCRONA Y ASÍNCRONA 
  
    - [3.1. Distinción entre comunicación síncrona y asíncrona](#31-distinción-entre-comunicación-síncrona-y-asíncrona)
    - [3.2. Análisis del uso de REST, gRPC o mensajería por eventos](#32-análisis-del-uso-de-rest-grpc-o-mensajería-por-eventos)
    - [3.3. Implementación de APIs REST entre microservicios con FastAPI](#33-implementación-de-apis-rest-entre-microservicios-con-fastapi)
    - [3.4. Utilización de gRPC como alternativa eficiente y tipada](#34-utilización-de-grpc-como-alternativa-eficiente-y-tipada)
    - [3.5. Diseño de contratos API con Protobuf o JSON Schema](#35-diseño-de-contratos-api-con-protobuf-o-json-schema)
    - [3.6. Introducción a conceptos de Service Mesh](#36-introducción-a-conceptos-de-service-mesh)
    - [3.7. Manejo de timeouts, retries y latencias en comunicación síncrona](#37-manejo-de-timeouts-retries-y-latencias-en-comunicación-síncrona)
    - [3.8. Introducción de colas para integración asíncrona](#38-introducción-de-colas-para-integración-asíncrona)
    - [3.9. Uso de mecanismos de pub/sub para desacoplamiento extremo](#39-uso-de-mecanismos-de-pubsub-para-desacoplamiento-extremo)
    - [3.10. Manejo del versionado de contratos en microservicios independientes](#310-manejo-del-versionado-de-contratos-en-microservicios-independientes)
  
  # Tema 4. MANEJO DE ERRORES Y CIRCUIT BREAKERS EN MICROSERVICIOS
  
  
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
  
  # Tema 5. SEGURIDAD Y BUENAS PRÁCTICAS EN MICROSERVICIOS
  
    * [5.1 Autenticación basada en JWT con FastAPI](Tema5.md#51-autenticación-basada-en-jwt-con-fastapi)
    * [5.2 Autorización por roles y scopes (RBAC)](Tema5.md#52-autorización-por-roles-y-scopes-rbac)
    * [5.3 Comunicación segura con HTTPS y certificados](Tema5.md#53-comunicación-segura-con-https-y-certificados)
    * [5.4 Validación de inputs y outputs](Tema5.md#54-validación-de-inputs-y-outputs)
    * [5.5 Políticas de CORS estrictas](Tema5.md#55-políticas-de-cors-estrictas)
    * [5.6 Protección de endpoints WebSocket y REST](Tema5.md#56-protección-de-endpoints-websocket-y-rest)
    * [5.7 Rotación de claves y secretos](Tema5.md#57-rotación-de-claves-y-secretos-57-rotación-de-claves-y-secretos)
    * [5.8 Gestión de credenciales con Vault o AWS Secrets Manager](Tema5.md#58-gestión-de-credenciales-con-vault-o-aws-secrets-manager)
    * [5.9 Análisis de vulnerabilidades OWASP](Tema5.md#59-análisis-de-vulnerabilidades-owasp)
    * [5.10 Auditoría y trazabilidad de usuarios](Tema5.md#510-auditoría-y-trazabilidad-de-usuarios)
    * [5.11 Configuración de rate limiting](Tema5.md#511-configuración-de-rate-limiting)
    * [Referencias](Tema5.md#referencias)
  
  # Tema 6. ARQUITECTURA HEXAGONAL Y APLICACIÓN DE DDD
  
    
  
    - [6.1 Comprender el patrón de puertos y adaptadores](#61-comprender-el-patrón-de-puertos-y-adaptadores)
    - [6.2 Identificar las capas: dominio, aplicación, infraestructura, interfaces](#62-identificar-las-capas-dominio-aplicación-infraestructura-interfaces)
    - [6.3 Diseñar interfaces para cada puerto (entrada y salida)](#63-diseñar-interfaces-para-cada-puerto-entrada-y-salida)
    - [6.4 Implementar adaptadores HTTP como controladores REST o WebSocket](#64-implementar-adaptadores-http-como-controladores-rest-o-websocket)
    - [6.5 Separar repositorios del dominio usando interfaces](#65-separar-repositorios-del-dominio-usando-interfaces)
    - [6.6 Diseñar pruebas para el núcleo sin depender de infraestructuras](#66-diseñar-pruebas-para-el-núcleo-sin-depender-de-infraestructuras)
    - [6.7 Integrar eventos de dominio desde la capa interna](#67-integrar-eventos-de-dominio-desde-la-capa-interna)
    - [6.8 Implementar casos de uso en la capa de aplicación](#68-implementar-casos-de-uso-en-la-capa-de-aplicación)   
    - [6.9 Configurar inyecciones de dependencia de adaptadores externos](#69-configurar-inyecciones-de-dependencia-de-adaptadores-externos)
    - [6.10 Ejemplo de microservicio hexagonal completo con FastAPI](#610-ejemplo-de-microservicio-hexagonal-completo-con-fastapi)
  

  # Tema 7. INTRODUCCIÓN A DOMAIN-DRIVEN DESIGN (DDD)
  
    * [7.1 Bloques tácticos y estratégicos del DDD](Tema7.md#71-bloques-tácticos-y-estratégicos-del-ddd)
    * [7.2 Rol de Aggregates, Entities y Value Objects](Tema7.md#72-rol-de-aggregates-entities-y-value-objects)
    * [7.3 Definición de Bounded Contexts y sus fronteras](Tema7.md#73-definición-de-bounded-contexts-y-sus-fronteras)
    * [7.4 Diseño de Domain Services](Tema7.md#74-diseño-de-domain-services)
    * [7.5 Repositorios como abstracción de persistencia](Tema7.md#75-repositorios-como-abstracción-de-persistencia)
    * [7.6 Integración de DDD con FastAPI y Pydantic](Tema7.md#76-integración-de-ddd-con-fastapi-y-pydantic)
    * [7.7 Creación de factories para entidades complejas](Tema7.md#77-creación-de-factories-para-entidades-complejas)
    * [7.8 Desarrollo de Ubiquitous Language](Tema7.md#78-desarrollo-de-ubiquitous-language)
    * [7.9 Capa de aplicación sobre la lógica de dominio](Tema7.md#79-capa-de-aplicación-sobre-la-lógica-de-dominio)
    * [7.10 Refactorización de dominio en capas desacopladas](Tema7.md#710-refactorización-de-dominio-en-capas-desacopladas)
    * [Bibliografía](Tema7.md#bibliografía)
  
  # Tema 8. PATRÓN CQRS EN MICROSERVICIOS
  
    - [8.1 Explicación del patrón CQRS y diferencias con CRUD tradicional](#81-explicación-del-patrón-cqrs-y-diferencias-con-crud-tradicional)
    - [8.2 Diseño de Comandos y Queries como Elementos Separados: Formalización de la Interacción](#82-diseño-de-comandos-y-queries-como-elementos-separados-formalización-de-la-interacción)
    - [8.3 Implementación de CommandHandlers desacoplados de controladores](#83-implementación-de-commandhandlers-desacoplados-de-controladores)
    - [8.4 Creación de QueryHandlers para operaciones de lectura especializadas](#84-creación-de-queryhandlers-para-operaciones-de-lectura-especializadas)
    - [8.5 Introducción a la persistencia por evento (Event Sourcing)](#85-introducción-a-la-persistencia-por-evento-event-sourcing)
    - [8.6 Aplicación de Validadores de Comandos (Command Validators)](#86-aplicación-de-validadores-de-comandos-command-validators)
    - [8.7 Gestión de la separación entre modelo de escritura y lectura](#87-gestión-de-la-separación-entre-modelo-de-escritura-y-lectura)
    - [8.8 Uso de FastAPI como gateway para coordinar comandos y queries](#88-uso-de-fastapi-como-gateway-para-coordinar-comandos-y-queries)
    - [8.9 Desacoplamiento de Servicios Mediante Colas o Buses de Eventos](#89-desacoplamiento-de-servicios-mediante-colas-o-buses-de-eventos)
    - [8.10 Análisis de Pros y Contras de CQRS en Sistemas Reales](#810-análisis-de-pros-y-contras-de-cqrs-en-sistemas-reales)
    - [Bibliografía](#bibliografía)
    
    # Tema 9. INTRODUCCIÓN A LA MENSAJERÍA CON KAFKA, RABBITMQ
    
      * [9.1 Comparar Kafka vs RabbitMQ: casos de uso y diferencias clave](Tema9.md#91-comparar-kafka-vs-rabbitmq-casos-de-uso-y-diferencias-clave)
      * [9.2 Instalación y configuración de un broker básico](Tema9.md#92-instalación-y-configuración-de-un-broker-básico)
      * [9.3 Conceptos de topic, exchange, queue y binding](Tema9.md#93-conceptos-de-topic-exchange-queue-y-binding)
      * [9.4 Publicación de mensajes desde un microservicio productor](Tema9.md#94-publicación-de-mensajes-desde-un-microservicio-productor)
      * [9.5 Procesamiento de eventos en consumidores desacoplados](Tema9.md#95-procesamiento-de-eventos-en-consumidores-desacoplados)
      * [9.6 Diseño de mensajes idempotentes y trazables](Tema9.md#96-diseño-de-mensajes-idempotentes-y-trazables)
      * [9.7 Patrones de eventos: Event Notification y Event Carried State](Tema9.md#97-patrones-de-eventos-event-notification-y-event-carried-state)
      * [9.8 Manejo de Errores y Reintentos en Colas: Navegando la Tormenta de la Mensajería](Tema9.md#98-manejo-de-errores-y-reintentos-en-colas-navegando-la-tormenta-de-la-mensajería)
      * [9.9 Uso de `aiokafka`, `kombu` o `pika`](Tema9.md#99-uso-de-aiokafka-kombu-o-pika)
      * [9.10 Integración con lógica de dominio en arquitectura hexagonal](Tema9.md#910-integración-con-lógica-de-dominio-en-arquitectura-hexagonal)
    
    # Tema 10. INTRODUCCIÓN A LOS WEBSOCKETS Y PUB/SUB EN SISTEMAS DISTRIBUIDOS
    
      * [10.1 Casos de uso reales para WebSockets](Tema10.md#101-casos-de-uso-reales-para-websockets)
      * [10.2 Servidor WebSocket con FastAPI](Tema10.md#102-servidor-websocket-con-fastapi)
      * [10.3 Gestión de clientes conectados y salas lógicas](Tema10.md#103-gestión-de-clientes-conectados-y-salas-lógicas)
      * [10.4 Pub/Sub con Redis o Kafka como Backend](Tema10.md#104-pubsub-con-redis-o-kafka-como-backend)
      * [10.5 Push de eventos desde backend a clientes](Tema10.md#105-push-de-eventos-desde-backend-a-clientes)
      * [10.6 Microservicio de notificaciones dedicado](Tema10.md#106-microservicio-de-notificaciones-dedicado)
      * [10.7 Consistencia eventual en eventos enviados](Tema10.md#107-consistencia-eventual-en-eventos-enviados)
      * [10.8 Reconexiones, heartbeats y expiración](Tema10.md#108-reconexiones-heartbeats-y-expiración)
      * [10.9 Seguridad de canales con JWT o API Keys](Tema10.md#109-seguridad-de-canales-con-jwt-o-api-keys)
      * [10.10 Patrones reactivos para tiempo real](Tema10.md#1010-patrones-reactivos-para-tiempo-real)
    
    # Tema 11. DISEÑO DE APIS REST Y WEBSOCKETS EN FASTAPI
    
      * [11.1 Buenas prácticas para endpoints RESTful](Tema11.md#111-buenas-prácticas-para-endpoints-restful)
      * [11.2 Versionado y organización de APIs](Tema11.md#112-versionado-y-organización-de-apis)
      * [11.3 Validación con Pydantic y modelos anidados](Tema11.md#113-validación-con-pydantic-y-modelos-anidados)
      * [11.4 Documentación con Swagger y Redoc](Tema11.md#114-documentación-con-swagger-y-redoc)
      * [11.5 CRUD con dependencias en FastAPI](Tema11.md#115-crud-con-dependencias-en-fastapi)
      * [11.6 Respuestas personalizadas y status codes](Tema11.md#116-respuestas-personalizadas-y-status-codes)
      * [11.7 Configuración de CORS y headers](Tema11.md#117-configuración-de-cors-y-headers)
      * [11.8 Autenticación en endpoints (JWT/OAuth2)](Tema11.md#118-autenticación-en-endpoints-jwtoauth2)
      * [11.9 Canales WebSocket nativos en FastAPI](Tema11.md#119-canales-websocket-nativos-en-fastapi)
      * [11.10 Handlers WebSocket y gestión de clientes](Tema11.md#1110-handlers-websocket-y-gestión-de-clientes)
      * [11.11 Integración WebSockets con lógica de dominio](Tema11.md#1111-integración-websockets-con-lógica-de-dominio)
    
    # Tema 12. ESCALABILIDAD Y OPTIMIZACIÓN DE MICROSERVICIOS
    
    
      * [12.1 Escalado horizontal vs vertical](Tema12.md#121-escalado-horizontal-vs-vertical)
      * [12.1 Escalado Horizontal vs. Vertical: El Dilema del Crecimiento – ¿Más Músculo o Más Manos?](Tema12.md#121-escalado-horizontal-vs-vertical-el-dilema-del-crecimiento--más-músculo-o-más-manos)
      * [12.2 Caching con Redis para endpoints críticos](Tema12.md#122-caching-con-redis-para-endpoints-críticos)
      * [12.2 `Caching` con Redis para `Endpoints` Críticos: El Turbo de Tu API a la Velocidad de la Luz](Tema12.md#122-caching-con-redis-para-endpoints-críticos-el-turbo-de-tu-api-a-la-velocidad-de-la-luz)
      * [12.3 Balanceo de carga con NGINX o Traefik](Tema12.md#123-balanceo-de-carga-con-nginx-o-traefik)
      * [12.4 Desacoplamiento con colas para paralelo](Tema12.md#124-desacoplamiento-con-colas-para-paralelo)
      * [12.5 `Workers` Asincrónicos y Uso de Recursos: La Danza Eficiente del Procesamiento en Segundo Plano](Tema12.md#125-workers-asincrónicos-y-uso-de-recursos-la-danza-eficiente-del-procesamiento-en-segundo-plano)
      * [12.5 Workers asincrónicos y uso de recursos](Tema12.md#125-workers-asincrónicos-y-uso-de-recursos)
      * [12.6 Profiling y detección de cuellos de botella](Tema12.md#126-profiling-y-detección-de-cuellos-de-botella)
      * [12.7 Throttling para prevenir sobrecarga](Tema12.md#127-throttling-para-prevenir-sobrecarga)
      * [12.7 `Throttling` y `Rate Limiting` para Prevenir Sobrecarga: El Guardián del Flujo de Tu API](Tema12.md#127-throttling-y-rate-limiting-para-prevenir-sobrecarga-el-guardián-del-flujo-de-tu-api)
      * [12.8 Kubernetes HPA (Horizontal Pod Autoscaler)](Tema12.md#128-kubernetes-hpa-horizontal-pod-autoscaler)
      * [12.9 Afinidad y políticas de tolerancia](Tema12.md#129-afinidad-y-políticas-de-tolerancia)
      * [12.10 Batching y Debouncing en concurrencia](Tema12.md#1210-batching-y-debouncing-en-concurrencia)
      * [Referencias Bibliográficas y Recursos Adicionales Recomendados](Tema12.md#referencias-bibliográficas-y-recursos-adicionales-recomendados)
    

    # Tema 13. PERSISTENCIA DE DATOS EN MICROSERVICIOS
    
    
      * [13.1 Integración de SQLAlchemy ORM](Tema13.md#131-integración-de-sqlalchemy-orm)
      * [13.2 Modelos desacoplados del dominio (DTO vs Entity)](Tema13.md#132-modelos-desacoplados-del-dominio-dto-vs-entity)
      * [13.3 Patrones de Repositorio con SQLAlchemy: Guardianes Elegantes de Tu Persistencia](Tema13.md#133-patrones-de-repositorio-con-sqlalchemy-guardianes-elegantes-de-tu-persistencia)
      * [13.4 Gestión de Transacciones Locales: Asegurando la Atomicidad en Tus Operaciones de Datos](Tema13.md#134-gestión-de-transacciones-locales-asegurando-la-atomicidad-en-tus-operaciones-de-datos)
      * [13.5 Transacciones distribuidas: sagas y outbox](Tema13.md#135-transacciones-distribuidas-sagas-y-outbox)
      * [13.6 Rollback coordinado con eventos](Tema13.md#136-rollback-coordinado-con-eventos)
      * [13.7 Conexión a MongoDB con `motor`](Tema13.md#137-conexión-a-mongodb-con-motor)
      * [13.8 Esquemas flexibles en MongoDB](Tema13.md#138-esquemas-flexibles-en-mongodb)
      * [13.9 Bases de datos por servicio y separación](Tema13.md#139-bases-de-datos-por-servicio-y-separación)
      * [13.9 Bases de Datos por Servicio y Separación de Datos: Autonomía y Desacoplamiento en la Persistencia de `Microservices`](Tema13.md#139-bases-de-datos-por-servicio-y-separación-de-datos-autonomía-y-desacoplamiento-en-la-persistencia-de-microservices)
      * [13.10 Pools de conexión y timeouts](Tema13.md#1310-pools-de-conexión-y-timeouts)
      * [13.10 `Pools` de Conexión y `Timeouts`: Optimizando el Flujo Ininterrumpido de Datos](Tema13.md#1310-pools-de-conexión-y-timeouts-optimizando-el-flujo-ininterrumpido-de-datos)
      * [Bibliografía](Tema13.md#bibliografía)

      # Tema 14. BREVE INTRODUCCIÓN AL TESTING
      
          * [14.1 Entorno de pruebas con Pytest en FastAPI](Tema14.md#141-entorno-de-pruebas-con-pytest-en-fastapi)
          * [14.2 Pruebas unitarias para servicios de dominio](Tema14.md#142-pruebas-unitarias-para-servicios-de-dominio)
          * [14.3 Simulación de dependencias con `unittest.mock`](Tema14.md#143-simulación-de-dependencias-con-unittestmock)
          * [14.4 `TestClient` para REST y WebSocket](Tema14.md#144-testclient-para-rest-y-websocket)
          * [14.5 Pruebas de integración con DB temporal](Tema14.md#145-pruebas-de-integración-con-db-temporal)
          * [14.6 Pruebas E2E entre microservicios](Tema14.md#146-pruebas-e2e-entre-microservicios)
          * [14.7 Validación de eventos y colas en tests async](Tema14.md#147-validación-de-eventos-y-colas-en-tests-async)
          * [14.8 Cobertura y calidad con `coverage.py`](Tema14.md#148-cobertura-y-calidad-con-coveragepy)
          * [14.9 Estructura de carpetas y fixtures](Tema14.md#149-estructura-de-carpetas-y-fixtures)
          * [14.10 Automatización en pipelines CI/CD](Tema14.md#1410-automatización-en-pipelines-cicd)
        * [Bibliografía](Tema14.md#bibliografía)

    # Tema 15. BUENAS PRÁCTICAS Y AUTOMATIZACIÓN DE DESPLIEGUES
    
    
        * [15.1 Dockerfiles eficientes para microservicios](Tema15.md#151-dockerfiles-eficientes-para-microservicios)
        * [15.2 Imágenes versionadas semánticamente](Tema15.md#152-imágenes-versionadas-semánticamente)
        * [15.3 `docker-compose` para entorno local](Tema15.md#153-docker-compose-para-entorno-local)
        * [15.4 Despliegue en Kubernetes con Helm/Kustomize](Tema15.md#154-despliegue-en-kubernetes-con-helmkustomize)
        * [15.5 Pipelines CI/CD en GitHub Actions/GitLab CI](Tema15.md#155-pipelines-cicd-en-github-actionsgitlab-ci)
        * [15.6 GitOps con ArgoCD o FluxCD](Tema15.md#156-gitops-con-argocd-o-fluxcd)
        * [15.7 Trazabilidad y logging con `structlog`/`loguru`](Tema15.md#157-trazabilidad-y-logging-con-structlogloguru)
        * [15.8 Métricas con Prometheus y Grafana](Tema15.md#158-métricas-con-prometheus-y-grafana)
        * [15.9 Logs centralizados con ELK o Loki](Tema15.md#159-logs-centralizados-con-elk-o-loki)
        * [15.10 Rollout y rollback automático](Tema15.md#1510-rollout-y-rollback-automático)
      * [Bibliografía](Tema15.md#bibliografía)
    