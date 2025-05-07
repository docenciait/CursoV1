## 4 MANEJO DE ERRORES Y CIRCUIT BREAKERS EN MICROSERVICIOS

 

## Tabla de Contenidos

- [Objetivos](#objetivos)
    - Distinguir comunicación síncrona vs asíncrona
    
    - Analizar cuándo usar REST, gRPC o mensajería por eventos
    
    - Implementar APIs REST entre microservicios con FastAPI
    
    - Utilizar gRPC como alternativa eficiente y tipada
    
    - Diseñar contratos API con Protobuf o JSON Schema
    
    - Introducir conceptos de Service Mesh (como Istio o Linkerd)
    
    - Manejar timeouts, retries y latencias en comunicación síncrona
    
    - Introducir colas como RabbitMQ y Kafka para integración asíncrona
    
    - Usar mecanismos de pub/sub para desacoplamiento extremo
    
    - Manejar el versionado de contratos en microservicios independientes
- [Contenidos](#contenidos)
    * 3.1. [Distinción entre comunicación síncrona y asíncrona](#31-distinción-entre-comunicación-síncrona-y-asíncrona)
    * 3.2. [Análisis del uso de REST, gRPC o mensajería por eventos](#22-análisis-del-uso-de-rest-grpc-o-mensajería-por-eventos)
    * 3.3. [Implementación de APIs REST entre microservicios con FastAPI](#23-implementación-de-apis-rest-entre-microservicios-con-fastapi)
    * 3.4. [Utilización de gRPC como alternativa eficiente y tipada](#24-utilización-de-grpc-como-alternativa-eficiente-y-tipada)
    * 3.5. [Diseño de contratos API con Protobuf o JSON Schema](#25-diseño-de-contratos-api-con-protobuf-o-json-schema)
    * 3.6. [Introducción a conceptos de Service Mesh](#26-introducción-a-conceptos-de-service-mesh)
    * 3.7. [Manejo de timeouts, retries y latencias en comunicación síncrona](#27-manejo-de-timeouts-retries-y-latencias-en-comunicación-síncrona)
    * 3.8. [Introducción de colas para integración asíncrona](#28-introducción-de-colas-para-integración-asíncrona)
    * 3.9. [Uso de mecanismos de pub/sub para desacoplamiento extremo](#29-uso-de-mecanismos-de-pubsub-para-desacoplamiento-extremo)
    * 3.10. [Manejo del versionado de contratos en microservicios independientes](#210-manejo-del-versionado-de-contratos-en-microservicios-independientes)




## 3. Contenidos

### 3.1 Distinción entre comunicación síncrona y asíncrona