# BLOQUE 1 – Hands-on Labs

> ⏱️ **Duración total estimada:** 7 horas\
> 🧱 **Proyecto base:** App de e-commerce (usuarios, productos, pedidos) en FastAPI + MariaDB

***

## 🔹 LAB 1 – Monolito Base: FastAPI + MariaDB

| Item            | Detalles                                                                          |
| --------------- | --------------------------------------------------------------------------------- |
| 🕒 Duración     | 1.5 h                                                                             |
| 🎯 Objetivo     | Partir de una app monolítica realista con routers separados                       |
| 🧠 Temas        | Tema 1 (1.1 a 1.7), Tema 2.1 a 2.4                                                |
| ⚙️ Tecnologías  | FastAPI, Docker Compose, Pydantic, SQL crudo                                      |
| 📁 Entregable   | Monolito completo: `/users`, `/products`, `/orders`                               |
| 🧪 Tareas clave | <p>- Clonar<br>- Entender capas<br>- Ejecutar API REST<br>- Analizar dominios</p> |
| 🧩 Repositorios | `lab01-monolito-ecommerce-inicial`                                                |

***

## 🔹 LAB 2 – Refactor: Microservicios + Gateway

| Item            | Detalles                                                                    |
| --------------- | --------------------------------------------------------------------------- |
| 🕒 Duración     | 1.5 h                                                                       |
| 🎯 Objetivo     | Separar dominios en microservicios y exponerlos a través de un API Gateway  |
| 🧠 Temas        | Tema 1.7 a 1.11, Tema 2.5, 2.10, Tema 3.1 a 3.3                             |
| ⚙️ Tecnologías  | httpx, routers FastAPI, Docker Compose avanzado                             |
| 📁 Entregable   | 3 servicios (`users`, `products`, `orders`) + 1 gateway (`api`)             |
| 🧪 Tareas clave | <p>- Crear microservicios<br>- Configurar red interna<br>- Gateway REST</p> |
| 🧩 Repositorios | `lab01-microservicios-ecommerce-final` (fase intermedia)                    |

***

## 🔹 LAB 3 – Desarollo Servicio gRPC
| Item            | Detalles                                                            |
| --------------- | ------------------------------------------------------------------- |
| 🕒 Duración     | 1.5 h                                                               |
| 🎯 Objetivo     | Implementar servicio gRPC
| 🧠 Temas        | Tema 3 completo                                                     |
| ⚙️ Tecnologías  | gRPCs                               |
| 📁 Entregable   | Proyecto docker   |
| 🧪 Tareas Crear servicio API REST que llame a gRPC |
| 🧩 Repositorios | `lab01-grpc-todo`                                          |

***

## 🔹 LAB 4 – Seguridad Básica con JWT, CORS y Resilencia

| Item            | Detalles                                                                    |
| --------------- | --------------------------------------------------------------------------- |
| 🕒 Duración     | 1.5 h                                                                       |
| 🎯 Objetivo     | Añadir autenticación JWT y configuración segura de endpoints                |
| 🧠 Temas        | Tema 5 completo                                                             |
| ⚙️ Tecnologías  | FastAPI JWT Auth, CORS, validación con Pydantic, circuit breaker                             |
| 📁 Entregable   | Sistema protegido con login, tokens y autorización por scope y circuite breaker               |
| 🧪 Tareas clave | <p>- Generar y validar JWT<br>- Proteger endpoints<br>- Configurar CORS</p> <br> - Circuit breaker |
| 🧩 Repositorios | `lab04-seguridad`   |

***
