# Tema 4. MANEJO DE ERRORES Y CIRCUIT BREAKERS EN MICROSERVICIOS

## Tabla de Contenidos

- [Tema 4. MANEJO DE ERRORES Y CIRCUIT BREAKERS EN MICROSERVICIOS](#tema-4-manejo-de-errores-y-circuit-breakers-en-microservicios)
  - [Tabla de Contenidos](#tabla-de-contenidos)
  - [4. Contenidos](#4-contenidos)
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

## 4. Contenidos

### 4.1 Diseño de estrategia global de manejo de errores
### 4.2 Implementación de controladores de excepciones personalizados en FastAPI
### 4.3 Definición de errores de negocio vs errores técnicos
### 4.4 Aplicación del patrón Retry con backoff exponencial
### 4.5 Introducción a patrones Circuit Breaker y Bulkhead
### 4.6 Implementación de circuit breakers con `pybreaker`
### 4.7 Diseño de endpoints resilientes a fallos de servicios externos
### 4.8 Captura y log de trazas con contexto de peticiones
### 4.9 Visibilidad de errores mediante dashboards
### 4.10 Pruebas para simular fallos y degradación controlada
