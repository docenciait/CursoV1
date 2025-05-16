```mermaid
graph LR
    I[Interfaces<br>(FastAPI Endpoints)] --> A[Aplicación<br>(Casos de Uso, Puertos Conducidos)]
    A --> D[Dominio<br>(Entidades, VOs, Reglas)]
    Infra[Infraestructura<br>(Repo Impls, DB, External Services)] --> A
    Infra --> D

```