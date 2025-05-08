# Tema 8. PATRÓN CQRS EN MICROSERVICIOS

## Tabla de Contenidos

- [Tema 8. PATRÓN CQRS EN MICROSERVICIOS](#tema-8-patrón-cqrs-en-microservicios)
  - [Tabla de Contenidos](#tabla-de-contenidos)
  - [8. Contenidos](#8-contenidos)
    - [8.1 Explicación del patrón CQRS y diferencias con CRUD tradicional](#81-explicación-del-patrón-cqrs-y-diferencias-con-crud-tradicional)
    - [8.2 Diseño de comandos y queries como elementos separados](#82-diseño-de-comandos-y-queries-como-elementos-separados)
    - [8.3 Implementación de CommandHandlers desacoplados de controladores](#83-implementación-de-commandhandlers-desacoplados-de-controladores)
    - [8.4 Creación de QueryHandlers para operaciones de lectura especializadas](#84-creación-de-queryhandlers-para-operaciones-de-lectura-especializadas)
    - [8.5 Introducción a la persistencia por evento (Event Sourcing)](#85-introducción-a-la-persistencia-por-evento-event-sourcing)
    - [8.6 Aplicación de validadores de comandos (Command Validators)](#86-aplicación-de-validadores-de-comandos-command-validators)
    - [8.7 Gestión de la separación entre modelo de escritura y lectura](#87-gestión-de-la-separación-entre-modelo-de-escritura-y-lectura)
    - [8.8 Uso de FastAPI como gateway para coordinar comandos y queries](#88-uso-de-fastapi-como-gateway-para-coordinar-comandos-y-queries)
    - [8.9 Desacoplamiento de servicios mediante colas o buses de eventos](#89-desacoplamiento-de-servicios-mediante-colas-o-buses-de-eventos)
    - [8.10 Análisis de pros y contras de CQRS en sistemas reales](#810-análisis-de-pros-y-contras-de-cqrs-en-sistemas-reales)

## 8. Contenidos

### 8.1 Explicación del patrón CQRS y diferencias con CRUD tradicional
### 8.2 Diseño de comandos y queries como elementos separados
### 8.3 Implementación de CommandHandlers desacoplados de controladores
### 8.4 Creación de QueryHandlers para operaciones de lectura especializadas
### 8.5 Introducción a la persistencia por evento (Event Sourcing)
### 8.6 Aplicación de validadores de comandos (Command Validators)
### 8.7 Gestión de la separación entre modelo de escritura y lectura
### 8.8 Uso de FastAPI como gateway para coordinar comandos y queries
### 8.9 Desacoplamiento de servicios mediante colas o buses de eventos
### 8.10 Análisis de pros y contras de CQRS en sistemas reales
