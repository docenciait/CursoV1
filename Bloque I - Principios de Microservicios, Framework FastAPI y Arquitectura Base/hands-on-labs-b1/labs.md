# BLOQUE 1 – Hands-on Labs

> ⏱️ **Duración total estimada:** 7 horas\
> 🧱 **Proyecto base:** App de e-commerce (usuarios, productos, pedidos) en FastAPI + MariaDB

***
## Repositorio Base

- Aquí estarán todos los labs del Bloque 1: [Repo Base](https://github.com/docenciait/fa-training-labs-alumnos)


## 🔹 LAB 1 – Monolito Base: FastAPI + MariaDB



| Item            | Detalles                                                                          |
| --------------- | --------------------------------------------------------------------------------- |
| 🕒 Duración     | 1.5 h                                                                             |
| 🎯 Objetivo     | Partir de una app monolítica realista con routers separados                       |
| 🧠 Temas        | Tema 1 (1.1 a 1.7), Tema 2.1 a 2.4                                                |
| ⚙️ Tecnologías  | FastAPI, Docker Compose, Pydantic, SQL Alchemy básico                                      |
| 📁 Entregable   | Monolito completo: `/users`, `/products`, `/orders`, `payments`                               |
| 🧪 Tareas clave | <p>- Clonar<br> - Explicación de todo el monolito <br>- Entender capas<br>- Ejecutar API REST y testarlos <br>- Analizar dominios</p> |
| 🧩 Repositorios | `lab01-inicial`                                                |

***

## 🔹 LAB 2 – Refactor: Microservicios + Gateway

| Item            | Detalles                                                                    |
| --------------- | --------------------------------------------------------------------------- |
| 🕒 Duración     | 1.5 h                                                                       |
| 🎯 Objetivo     | Separar dominios en microservicios y exponerlos a través de un API Gateway  |
| 🧠 Temas        | Tema 1.7 a 1.11, Tema 2.5, 2.10, Tema 3.1 a 3.3                             |
| ⚙️ Tecnologías  | httpx, routers FastAPI, Docker Compose avanzado                             |
| 📁 Entregable   | 4 servicios (`users`, `products`, `orders`, `payments`) + 1 gateway (`api`)             |
| 🧪 Tareas clave | <p> - Identificar los Bounded Contexts. <br> - Separar en `auth-service`, `product-service`, `order-service`, `payment-service`.  <br> - Definir APIs REST independientes para cada microservicio. <br> - Reverse Proxy hacia los microservicios. <br> - HTTPS con certificados SSL. <br> - Redirección de tráfico por rutas. <br> - Aplicar patrones de comunicación síncrona y asíncrona. <br> - Patrón **Strangler Fig** para migración progresiva. </p>
|
| 🧩 Repositorios | `lab02-microservicios-ecommerce` (fase intermedia)                    |

***

## 🔹 LAB 3 – Gestión de Errores y Resiliencia

| Item            | Detalles                                                            |
| --------------- | ------------------------------------------------------------------- |
| 🕒 Duración     | 1.5 h                                                               |
| 🎯 Objetivo     | Añadir manejo de errores resiliente y Circuit Breaker básico        |
| 🧠 Temas        | Tema 4 completo                                                     |
| ⚙️ Tecnologías  | pybreaker, logging, fallback handlers                               |
| 📁 Entregable   | API Gateway con retry y tolerancia a fallos de servicios caídos     |
| 🧪 Tareas clave | <p>- Simular fallos<br>- Implementar retry<br>- Circuit breaker</p> |
| 🧩 Repositorios | `lab03-resilience-gateway`                                          |

***

## 🔹 LAB 4 – Seguridad Básica con JWT y CORS

| Item            | Detalles                                                                    |
| --------------- | --------------------------------------------------------------------------- |
| 🕒 Duración     | 1.5 h                                                                       |
| 🎯 Objetivo     | Añadir autenticación JWT y configuración segura de endpoints                |
| 🧠 Temas        | Tema 5 completo                                                             |
| ⚙️ Tecnologías  | FastAPI JWT Auth, CORS, validación con Pydantic                             |
| 📁 Entregable   | Sistema protegido con login, tokens y autorización por scope                |
| 🧪 Tareas clave | <p>- Generar y validar JWT<br>- Proteger endpoints<br>- Configurar CORS y CORS Policies <br> - BaseSettings y gestión de entornos <br> - Gunicorn como servidor WSGI <br> - Documentación OpenAPI 3.0</p> |
| 🧩 Repositorios | `lab04-secure-microservices`                                                |

***

## 📦 Resultado final tras Bloque 1

Un sistema distribuido con:

* 🔐 Seguridad básica
* 🛡️ Resiliencia básica
* 🌐 Comunicación REST
* 📦 Despliegue profesional en Docker Compose

***

