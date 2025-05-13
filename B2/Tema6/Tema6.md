# **Tema 6. ARQUITECTURA HEXAGONAL Y APLICACIÓN DE DDD**

## Tabla de Contenidos

- [**Tema 6. ARQUITECTURA HEXAGONAL Y APLICACIÓN DE DDD**](#tema-6-arquitectura-hexagonal-y-aplicación-de-ddd)
  - [Tabla de Contenidos](#tabla-de-contenidos)
  - [**6.1 Comprender el patrón de puertos y adaptadores**](#61-comprender-el-patrón-de-puertos-y-adaptadores)
  - [**6.2 Identificar las capas: dominio, aplicación, infraestructura, interfaces**](#62-identificar-las-capas-dominio-aplicación-infraestructura-interfaces)
  - [**6.3 Diseñar interfaces para cada puerto (entrada y salida)**](#63-diseñar-interfaces-para-cada-puerto-entrada-y-salida)
  - [**6.4 Implementar adaptadores HTTP como controladores REST o WebSocket**](#64-implementar-adaptadores-http-como-controladores-rest-o-websocket)
  - [**6.5 Separar repositorios del dominio usando interfaces**](#65-separar-repositorios-del-dominio-usando-interfaces)
  - [**6.6 Diseñar pruebas para el núcleo sin depender de infraestructuras**](#66-diseñar-pruebas-para-el-núcleo-sin-depender-de-infraestructuras)
  - [**6.7 Integrar eventos de dominio desde la capa interna**](#67-integrar-eventos-de-dominio-desde-la-capa-interna)
  - [**6.8 Implementar casos de uso en la capa de aplicación**](#68-implementar-casos-de-uso-en-la-capa-de-aplicación)
  - [**6.9 Configurar inyecciones de dependencia de adaptadores externos**](#69-configurar-inyecciones-de-dependencia-de-adaptadores-externos)
  - [**6.10 Ejemplo de microservicio hexagonal completo con FastAPI**](#610-ejemplo-de-microservicio-hexagonal-completo-con-fastapi)




---



**Objetivo del Tema:** Aprender a diseñar y construir aplicaciones FastAPI siguiendo los principios de la Arquitectura Hexagonal y DDD, logrando un código desacoplado, enfocado en el dominio del negocio y fácilmente adaptable a cambios tecnológicos o de requisitos.

**Tecnologías Base:** Python 3.12, FastAPI, Docker, Docker Compose, MariaDB.

---

## **6.1 Comprender el patrón de puertos y adaptadores**


|!["figure"](img/image.png )|
|:--:|
| *Figura 1. Arquitectura Hexagonal* |



La Arquitectura Hexagonal, también conocida como "Puertos y Adaptadores", tiene como objetivo principal proteger el núcleo de la aplicación (la lógica de negocio o dominio) de las dependencias externas (frameworks, bases de datos, UI, etc.).

*   **El Hexágono (Núcleo):** Contiene la lógica de negocio pura. No sabe nada sobre el mundo exterior (HTTP, bases de datos específicas, etc.).
*   **Puertos:** Son las interfaces definidas por el hexágono. Representan los puntos de interacción.
    *   **Puertos de Entrada (Driving Ports):** APIs que el núcleo expone para ser "conducido" por el mundo exterior (ej. un servicio de aplicación que maneja un caso de uso).
    *   **Puertos de Salida (Driven Ports):** Interfaces que el núcleo necesita para obtener datos o realizar acciones en el mundo exterior (ej. una interfaz de repositorio para persistir datos).
*   **Adaptadores:** Son las implementaciones concretas de los puertos. Se encuentran fuera del hexágono.
    *   **Adaptadores de Entrada (Driving Adapters):** Convierten las solicitudes externas (ej. HTTP, CLI, gRPC) en llamadas a los puertos de entrada del núcleo (ej. un controlador FastAPI).
    *   **Adaptadores de Salida (Driven Adapters):** Implementan los puertos de salida, interactuando con herramientas externas (ej. un repositorio SQLAlchemy para MariaDB, un cliente HTTP para un servicio externo).

**Beneficios Clave:**
*   **Aislamiento del Dominio:** La lógica de negocio es independiente de la tecnología.
*   **Testabilidad:** El núcleo se puede probar de forma aislada, sin frameworks ni bases de datos.
*   **Intercambiabilidad:** Es más fácil cambiar de base de datos, framework web o cualquier otra dependencia externa sin afectar el núcleo.
*   **Mantenibilidad:** El código está mejor organizado y es más fácil de entender.

---

## **6.2 Identificar las capas: dominio, aplicación, infraestructura, interfaces**

![alt text](image.png)

Aunque la Arquitectura Hexagonal no prescribe capas estrictas como la arquitectura en capas tradicional, conceptualmente podemos identificar estas áreas:

1.  **Dominio (El Corazón del Hexágono):**
    *   Contiene la lógica de negocio, las reglas y el estado.
    *   **Entidades:** Objetos con identidad que persisten a lo largo del tiempo (ej. `Usuario`, `Producto`).
    *   **Objetos de Valor (Value Objects):** Objetos inmutables sin identidad conceptual, definidos por sus atributos (ej. `Direccion`, `Moneda`).
    *   **Agregados:** Clúster de entidades y objetos de valor tratados como una unidad (ej. `Pedido` con sus `LineasDePedido`).
    *   **Servicios de Dominio:** Lógica de negocio que no encaja naturalmente en una entidad u objeto de valor.
    *   **Eventos de Dominio:** Representan algo significativo que ocurrió en el dominio (ej. `PedidoCreado`).
    *   **Interfaces de Repositorio:** Definen cómo se persisten y recuperan los agregados (puertos de salida).
    *   *Dependencias: Ninguna hacia el exterior.*

2.  **Aplicación (Orquestación de Casos de Uso):**
    *   Contiene los casos de uso de la aplicación (servicios de aplicación).
    *   Orquesta la lógica del dominio para cumplir con las solicitudes.
    *   Utiliza las interfaces de repositorio para interactuar con la persistencia.
    *   Puede despachar eventos de dominio.
    *   Define los DTOs (Data Transfer Objects) para la comunicación con las interfaces de usuario, si es necesario.
    *   *Dependencias: Hacia el Dominio.*

3.  **Interfaces/Adaptadores (Interacción con el Mundo Exterior):**
    *   **Adaptadores de Entrada (Driving Adapters):**
        *   Controladores REST (FastAPI).
        *   Controladores WebSocket.
        *   Comandos CLI.
        *   Consumidores de colas de mensajes.
        *   *Llaman a los Servicios de Aplicación.*
    *   **Adaptadores de Salida (Driven Adapters):**
        *   Implementaciones de Repositorios (ej. para MariaDB con SQLAlchemy).
        *   Clientes para servicios externos (HTTP, gRPC).
        *   Productores de colas de mensajes.
        *   Implementaciones de servicios de notificación (email, SMS).
        *   *Implementan interfaces definidas en el Dominio o la Aplicación.*

4.  **Infraestructura (Detalles Técnicos):**
    *   Configuración de la base de datos, logging, frameworks, etc.
    *   Contiene la implementación concreta de los adaptadores de salida.
    *   Mecanismos de Inyección de Dependencias.
    *   *Aquí residen las implementaciones concretas de los adaptadores.*

**Regla de Dependencia:** Las dependencias siempre apuntan hacia el interior (hacia el Dominio). El Dominio no conoce las otras capas.

---

## **6.3 Diseñar interfaces para cada puerto (entrada y salida)**

Usaremos clases base abstractas (`abc.ABC`) de Python para definir nuestros puertos.

**Ejemplo:**

```python
# app/domain/ports/product_repository.py
from abc import ABC, abstractmethod
from typing import List, Optional
from ..entities.product import Product # Asumiendo que Product es una entidad

class ProductRepositoryPort(ABC): # Puerto de Salida

    @abstractmethod
    async def get_by_id(self, product_id: str) -> Optional[Product]:
        pass

    @abstractmethod
    async def get_all(self) -> List[Product]:
        pass

    @abstractmethod
    async def save(self, product: Product) -> Product:
        pass

    @abstractmethod
    async def delete(self, product_id: str) -> bool:
        pass

# app/application/ports/product_service.py
from abc import ABC, abstractmethod
from typing import List, Optional
from ..dtos.product_dto import ProductCreateDTO, ProductDTO # DTOs para la comunicación

class ProductServicePort(ABC): # Puerto de Entrada (para la capa de aplicación)

    @abstractmethod
    async def create_product(self, product_data: ProductCreateDTO) -> ProductDTO:
        pass

    @abstractmethod
    async def get_product(self, product_id: str) -> Optional[ProductDTO]:
        pass
```

---

## **6.4 Implementar adaptadores HTTP como controladores REST o WebSocket**

Estos adaptadores reciben peticiones externas y las traducen a llamadas a los servicios de aplicación.

**Ejemplo (Controlador REST con FastAPI):**

```python
# app/interfaces/api/product_routes.py
from fastapi import APIRouter, Depends, HTTPException, status
from typing import List

from app.application.ports.product_service import ProductServicePort
from app.application.dtos.product_dto import ProductCreateDTO, ProductDTO
from .dependencies import get_product_service # Asumimos un inyector de dependencias

router = APIRouter(prefix="/products", tags=["Products"])

@router.post("/", response_model=ProductDTO, status_code=status.HTTP_201_CREATED)
async def create_product_endpoint(
    product_data: ProductCreateDTO,
    product_service: ProductServicePort = Depends(get_product_service) # Inyecta el servicio de aplicación
):
    return await product_service.create_product(product_data)

@router.get("/{product_id}", response_model=ProductDTO)
async def get_product_endpoint(
    product_id: str,
    product_service: ProductServicePort = Depends(get_product_service)
):
    product = await product_service.get_product(product_id)
    if not product:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Product not found")
    return product

# ... otros endpoints
```

---

## **6.5 Separar repositorios del dominio usando interfaces**

Ya definimos `ProductRepositoryPort` en el dominio. Ahora, una implementación concreta en la capa de infraestructura.

**Ejemplo (Implementación con SQLAlchemy para MariaDB):**

```python
# app/infrastructure/repositories/mariadb_product_repository.py
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload # Si hay relaciones

from app.domain.entities.product import Product as DomainProduct
from app.domain.ports.product_repository import ProductRepositoryPort
from ..db_models.product_model import Product as DBProduct # Modelo SQLAlchemy

class MariaDBProductRepository(ProductRepositoryPort):
    def __init__(self, session: AsyncSession):
        self.session = session

    async def _map_to_domain(self, db_product: DBProduct) -> DomainProduct:
        # Mapeo de modelo de DB a entidad de dominio
        return DomainProduct(
            id=str(db_product.id), # Asumimos que el id en DB es int y en dominio str/UUID
            name=db_product.name,
            description=db_product.description,
            price=db_product.price
        )

    async def _map_to_db_model(self, domain_product: DomainProduct) -> DBProduct:
        # Mapeo de entidad de dominio a modelo de DB (para creación/actualización)
        data = {
            "name": domain_product.name,
            "description": domain_product.description,
            "price": domain_product.price
        }
        if domain_product.id and domain_product.id != "new": # Asumiendo un placeholder para nuevos
             # Para SQLAlchemy, si el ID es autoincremental, no lo pasamos al crear
             # Si es un UUID generado en el dominio, sí lo pasamos
             # Esto depende de cómo se manejen los IDs
            try:
                data["id"] = int(domain_product.id) # Si el ID de la DB es int
            except ValueError: # Si el ID es un UUID o string generado
                pass # No lo mapeamos directamente si la DB lo genera
        return DBProduct(**data)


    async def get_by_id(self, product_id: str) -> Optional[DomainProduct]:
        # Asumiendo que el ID en la DB es un entero para este ejemplo
        try:
            db_id = int(product_id)
        except ValueError:
            return None # o manejar error de ID inválido

        result = await self.session.execute(select(DBProduct).filter(DBProduct.id == db_id))
        db_product = result.scalars().first()
        return await self._map_to_domain(db_product) if db_product else None

    async def get_all(self) -> List[DomainProduct]:
        result = await self.session.execute(select(DBProduct))
        db_products = result.scalars().all()
        return [await self._map_to_domain(p) for p in db_products]

    async def save(self, product: DomainProduct) -> DomainProduct:
        if product.id and product.id != "new": # Actualización
            try:
                db_id = int(product.id)
                db_product_to_update = await self.session.get(DBProduct, db_id)
                if db_product_to_update:
                    db_product_to_update.name = product.name
                    db_product_to_update.description = product.description
                    db_product_to_update.price = product.price
                    self.session.add(db_product_to_update)
                    await self.session.commit()
                    await self.session.refresh(db_product_to_update)
                    return await self._map_to_domain(db_product_to_update)
                else: # No encontrado para actualizar, podría ser un error o crear uno nuevo
                    raise ValueError(f"Product with id {product.id} not found for update.")
            except ValueError: # ID no es un entero válido para la DB
                 raise ValueError(f"Invalid product ID format for database: {product.id}")

        else: # Creación
            db_product = await self._map_to_db_model(product)
            self.session.add(db_product)
            await self.session.commit()
            await self.session.refresh(db_product) # Para obtener el ID generado por la DB
            # Actualizar el id del objeto de dominio con el id generado
            product.id = str(db_product.id)
            return product # Devolver el objeto de dominio actualizado o el mapeado


    async def delete(self, product_id: str) -> bool:
        try:
            db_id = int(product_id)
        except ValueError:
            return False

        db_product = await self.session.get(DBProduct, db_id)
        if db_product:
            await self.session.delete(db_product)
            await self.session.commit()
            return True
        return False

```
**Nota:** El mapeo entre entidades de dominio y modelos de base de datos es crucial. A veces, se usan herramientas de automapeo, pero para control fino, el mapeo manual es común. Los IDs pueden ser un punto de atención (UUIDs generados en el dominio vs. autoincrementales en la DB).

---

## **6.6 Diseñar pruebas para el núcleo sin depender de infraestructuras**

Gracias al desacoplamiento, podemos probar el dominio y los servicios de aplicación usando mocks o fakes para los repositorios.

**Ejemplo (Prueba de un servicio de aplicación usando `pytest` y `unittest.mock`):**

```python
# tests/application/test_product_service.py
import pytest
from unittest.mock import AsyncMock # Para mocks de funciones async

from app.domain.entities.product import Product
from app.domain.ports.product_repository import ProductRepositoryPort
from app.application.services.product_app_service import ProductApplicationService # Implementación del servicio
from app.application.dtos.product_dto import ProductCreateDTO, ProductDTO

@pytest.fixture
def mock_product_repository() -> AsyncMock:
    return AsyncMock(spec=ProductRepositoryPort)

@pytest.fixture
def product_service(mock_product_repository: AsyncMock) -> ProductApplicationService:
    return ProductApplicationService(product_repository=mock_product_repository)

@pytest.mark.asyncio
async def test_create_product(product_service: ProductApplicationService, mock_product_repository: AsyncMock):
    product_data = ProductCreateDTO(name="Test Product", description="A testable product", price=99.99)
    
    # Mock del método save del repositorio
    # Asumimos que save devuelve la entidad Product con un ID asignado
    mock_saved_product = Product(id="prod_123", name=product_data.name, description=product_data.description, price=product_data.price)
    mock_product_repository.save.return_value = mock_saved_product

    created_product_dto = await product_service.create_product(product_data)

    # Verificar que el repositorio fue llamado correctamente
    # La aserción exacta aquí dependerá de cómo `ProductApplicationService` crea la entidad `Product`
    # Por simplicidad, asumimos que llama a save con un objeto Product que tiene los mismos atributos
    # que product_data, excepto el id que es asignado por el repositorio.
    # mock_product_repository.save.assert_called_once()
    # args, _ = mock_product_repository.save.call_args
    # called_with_product = args[0]
    # assert called_with_product.name == product_data.name
    # assert called_with_product.price == product_data.price
    
    # Versión simplificada de la aserción:
    assert mock_product_repository.save.call_count == 1
    saved_arg = mock_product_repository.save.call_args[0][0]
    assert isinstance(saved_arg, Product)
    assert saved_arg.name == product_data.name
    assert saved_arg.price == product_data.price


    # Verificar el DTO devuelto
    assert isinstance(created_product_dto, ProductDTO)
    assert created_product_dto.id == "prod_123"
    assert created_product_dto.name == "Test Product"

@pytest.mark.asyncio
async def test_get_product_found(product_service: ProductApplicationService, mock_product_repository: AsyncMock):
    product_id = "prod_123"
    mock_domain_product = Product(id=product_id, name="Existing Product", description="Desc", price=50.0)
    mock_product_repository.get_by_id.return_value = mock_domain_product

    product_dto = await product_service.get_product(product_id)

    mock_product_repository.get_by_id.assert_called_once_with(product_id)
    assert product_dto is not None
    assert product_dto.id == product_id
    assert product_dto.name == "Existing Product"

@pytest.mark.asyncio
async def test_get_product_not_found(product_service: ProductApplicationService, mock_product_repository: AsyncMock):
    product_id = "non_existent_id"
    mock_product_repository.get_by_id.return_value = None

    product_dto = await product_service.get_product(product_id)

    mock_product_repository.get_by_id.assert_called_once_with(product_id)
    assert product_dto is None
```

---

## **6.7 Integrar eventos de dominio desde la capa interna**

Los eventos de dominio comunican que algo importante ha sucedido. Pueden ser usados para desacoplar partes del sistema.

1.  **Definir el Evento (Dominio):**
    ```python
    # app/domain/events/product_events.py
    from dataclasses import dataclass
    from datetime import datetime

    @dataclass(frozen=True)
    class DomainEvent:
        timestamp: datetime = field(default_factory=datetime.utcnow)

    @dataclass(frozen=True)
    class ProductCreatedEvent(DomainEvent):
        product_id: str
        name: str
        price: float
    ```

2.  **Publicar Eventos (Dominio o Aplicación):**
    Las entidades pueden registrar eventos, y el servicio de aplicación (o un repositorio) los despacha.
    Una forma simple es tener una lista de eventos en la entidad raíz del agregado.

    ```python
    # app/domain/entities/product.py (modificado)
    from typing import List, Any
    from dataclasses import dataclass, field
    from ..events.product_events import ProductCreatedEvent, DomainEvent # Importar Eventos

    @dataclass
    class Product:
        id: str
        name: str
        description: Optional[str]
        price: float
        _events: List[DomainEvent] = field(default_factory=list, repr=False) # Lista para registrar eventos

        # ... otros métodos ...

        @classmethod
        def create(cls, name: str, description: Optional[str], price: float, product_id: str = "new") -> "Product":
            product = cls(id=product_id, name=name, description=description, price=price)
            # No registramos el evento aquí, sino cuando se confirma la creación (ej. al guardar)
            return product
        
        def register_creation_event(self):
            # Este método se llamaría después de que el producto se haya guardado y tenga un ID final
            if self.id and self.id != "new":
                self._events.append(ProductCreatedEvent(product_id=self.id, name=self.name, price=self.price))

        def pull_domain_events(self) -> List[DomainEvent]:
            """Devuelve y limpia los eventos de dominio registrados."""
            events = list(self._events)
            self._events.clear()
            return events
    ```

3.  **Despachador de Eventos (Infraestructura):**
    Un componente que toma los eventos y los envía a los manejadores.
    ```python
    # app/infrastructure/event_dispatcher.py
    from typing import List, Callable, Dict, Type
    from app.domain.events.product_events import DomainEvent

    Handler = Callable[[DomainEvent], None] # o Callable[[DomainEvent], Awaitable[None]] para async

    class EventDispatcher:
        def __init__(self):
            self._handlers: Dict[Type[DomainEvent], List[Handler]] = {}

        def register(self, event_type: Type[DomainEvent], handler: Handler):
            if event_type not in self._handlers:
                self._handlers[event_type] = []
            self._handlers[event_type].append(handler)

        async def dispatch(self, event: DomainEvent):
            print(f"Dispatching event: {event}") # Para depuración
            for handler in self._handlers.get(type(event), []):
                # Podría ser async si los handlers son async
                # await handler(event)
                handler(event) # Para handlers síncronos

        async def dispatch_batch(self, events: List[DomainEvent]):
            for event in events:
                await self.dispatch(event)
    
    # Crear una instancia global o inyectable del dispatcher
    event_dispatcher = EventDispatcher()
    ```

4.  **Manejadores de Eventos (Infraestructura o Aplicación):**
    ```python
    # app/infrastructure/event_handlers.py
    from app.domain.events.product_events import ProductCreatedEvent, DomainEvent

    def send_product_creation_notification(event: ProductCreatedEvent):
        # Lógica para enviar una notificación (email, Slack, etc.)
        # Este es un adaptador de salida implícito.
        print(f"HANDLED ProductCreatedEvent: New product created - ID: {event.product_id}, Name: {event.name}")

    # Registrar el handler en el dispatcher (esto se haría en la inicialización de la app)
    # from .event_dispatcher import event_dispatcher
    # event_dispatcher.register(ProductCreatedEvent, send_product_creation_notification)
    ```

5.  **Usar en el Servicio de Aplicación:**
    ```python
    # app/application/services/product_app_service.py (modificado)
    # ...
    from app.infrastructure.event_dispatcher import EventDispatcher # o inyectar
    # ...

    class ProductApplicationService(ProductServicePort):
        def __init__(self, product_repository: ProductRepositoryPort, event_dispatcher: EventDispatcher):
            self.product_repository = product_repository
            self.event_dispatcher = event_dispatcher # Inyectar dispatcher

        async def create_product(self, product_data: ProductCreateDTO) -> ProductDTO:
            product = DomainProduct.create(
                name=product_data.name,
                description=product_data.description,
                price=product_data.price
            )
            # Guardar en el repositorio (que asignará el ID si es nuevo)
            saved_product = await self.product_repository.save(product)
            
            # Registrar y despachar el evento DESPUÉS de que se haya guardado
            saved_product.register_creation_event() 
            domain_events = saved_product.pull_domain_events()
            await self.event_dispatcher.dispatch_batch(domain_events)

            return ProductDTO.from_domain(saved_product) # Asumiendo un método from_domain en DTO
    ```

---

## **6.8 Implementar casos de uso en la capa de aplicación**

Los servicios de aplicación implementan los casos de uso. Orquestan las entidades de dominio y usan los repositorios.

**Ejemplo (`ProductApplicationService`):**
Ya lo hemos visto en acción. Es la clase que implementa `ProductServicePort`.

```python
# app/application/services/product_app_service.py
from typing import List, Optional

from ..ports.product_service import ProductServicePort
from ..dtos.product_dto import ProductCreateDTO, ProductDTO
from app.domain.ports.product_repository import ProductRepositoryPort
from app.domain.entities.product import Product as DomainProduct
from app.infrastructure.event_dispatcher import EventDispatcher # Asumiendo que está disponible o inyectado

class ProductApplicationService(ProductServicePort):
    def __init__(self, product_repository: ProductRepositoryPort, event_dispatcher: EventDispatcher):
        self.product_repository: ProductRepositoryPort = product_repository
        self.event_dispatcher: EventDispatcher = event_dispatcher

    async def create_product(self, product_data: ProductCreateDTO) -> ProductDTO:
        # Validaciones de aplicación (si las hay, las de dominio están en la entidad)
        
        product_entity = DomainProduct.create(
            name=product_data.name,
            description=product_data.description,
            price=product_data.price
            # El ID se manejará internamente o por el repositorio al guardar
        )
        
        saved_product = await self.product_repository.save(product_entity)
        
        # Registrar y despachar evento después de guardar y tener el ID final
        saved_product.register_creation_event()
        domain_events = saved_product.pull_domain_events()
        if domain_events: # Solo despachar si hay eventos
            await self.event_dispatcher.dispatch_batch(domain_events)
            
        return ProductDTO.from_domain(saved_product) # Asumiendo DTO tiene un constructor from_domain

    async def get_product(self, product_id: str) -> Optional[ProductDTO]:
        product_entity = await self.product_repository.get_by_id(product_id)
        if product_entity:
            return ProductDTO.from_domain(product_entity)
        return None

    # ... otros métodos para get_all_products, update_product, delete_product
```

---

## **6.9 Configurar inyecciones de dependencia de adaptadores externos**

FastAPI facilita esto con su sistema de dependencias (`Depends`).

1.  **Crear factorías para los servicios y repositorios:**
    ```python
    # app/interfaces/api/dependencies.py
    from fastapi import Depends
    from sqlalchemy.ext.asyncio import AsyncSession

    from app.infrastructure.database import get_db_session # Función para obtener sesión de DB
    from app.domain.ports.product_repository import ProductRepositoryPort
    from app.infrastructure.repositories.mariadb_product_repository import MariaDBProductRepository
    from app.application.ports.product_service import ProductServicePort
    from app.application.services.product_app_service import ProductApplicationService
    from app.infrastructure.event_dispatcher import event_dispatcher, EventDispatcher # Instancia global o factoría

    # Factoría para el EventDispatcher (si no es global)
    def get_event_dispatcher() -> EventDispatcher:
        # Aquí podrías inicializarlo y configurarlo si fuera necesario
        return event_dispatcher # Usando la instancia global por simplicidad

    # Factoría para el repositorio
    def get_product_repository(session: AsyncSession = Depends(get_db_session)) -> ProductRepositoryPort:
        return MariaDBProductRepository(session=session)

    # Factoría para el servicio de aplicación
    def get_product_service(
        repository: ProductRepositoryPort = Depends(get_product_repository),
        dispatcher: EventDispatcher = Depends(get_event_dispatcher)
    ) -> ProductServicePort:
        return ProductApplicationService(product_repository=repository, event_dispatcher=dispatcher)
    ```

2.  **Usar en los endpoints (como ya se mostró en 6.4):**
    ```python
    # app/interfaces/api/product_routes.py
    # ...
    # product_service: ProductServicePort = Depends(get_product_service)
    # ...
    ```

3.  **Configuración de la sesión de base de datos (`get_db_session`):**
    ```python
    # app/infrastructure/database.py
    from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
    from sqlalchemy.orm import sessionmaker, declarative_base
    import os

    DATABASE_URL = os.getenv("DATABASE_URL", "mysql+aiomysql://user:password@mariadb_container/mydatabase")
    # Ejemplo: "mysql+aiomysql://testuser:testpass@localhost:3307/testdb"

    async_engine = create_async_engine(DATABASE_URL, echo=True)
    AsyncSessionLocal = sessionmaker(
        bind=async_engine,
        class_=AsyncSession,
        expire_on_commit=False,
        autoflush=False,
        autocommit=False
    )

    Base = declarative_base() # Para los modelos SQLAlchemy

    async def create_tables():
        async with async_engine.begin() as conn:
            # await conn.run_sync(Base.metadata.drop_all) # Opcional: para limpiar en desarrollo
            await conn.run_sync(Base.metadata.create_all)

    async def get_db_session() -> AsyncSession:
        async with AsyncSessionLocal() as session:
            try:
                yield session
                await session.commit() # Commit al final si todo fue bien
            except Exception:
                await session.rollback() # Rollback en caso de error
                raise
            finally:
                await session.close()
    ```

---

## **6.10 Ejemplo de microservicio hexagonal completo con FastAPI**

Ahora, juntemos todo en una estructura de proyecto.

**Estructura de Directorios (Simplificada):**

```
hexagonal_fastapi_ddd/
├── app/
│   ├── __init__.py
│   ├── application/                 # Casos de Uso, DTOs, Puertos de Entrada (Servicios App)
│   │   ├── __init__.py
│   │   ├── dtos/
│   │   │   └── product_dto.py
│   │   ├── ports/
│   │   │   └── product_service.py   # Interfaz ProductServicePort
│   │   └── services/
│   │       └── product_app_service.py # Implementación ProductApplicationService
│   ├── domain/                      # Lógica de Negocio Pura
│   │   ├── __init__.py
│   │   ├── entities/
│   │   │   └── product.py           # Entidad Product
│   │   ├── events/
│   │   │   └── product_events.py    # Eventos de Dominio
│   │   └── ports/
│   │       └── product_repository.py # Interfaz ProductRepositoryPort
│   ├── infrastructure/              # Implementaciones Concretas de Adaptadores de Salida y Config
│   │   ├── __init__.py
│   │   ├── database.py              # Configuración de DB (SQLAlchemy, get_session)
│   │   ├── db_models/
│   │   │   └── product_model.py     # Modelo SQLAlchemy para Product
│   │   ├── event_dispatcher.py
│   │   ├── event_handlers.py
│   │   └── repositories/
│   │       └── mariadb_product_repository.py # Implementación MariaDBProductRepository
│   └── interfaces/                  # Adaptadores de Entrada (API, CLI, etc.)
│       ├── __init__.py
│       └── api/
│           ├── __init__.py
│           ├── dependencies.py      # Factorías para Inyección de Dependencias
│           └── product_routes.py    # Endpoints FastAPI para Productos
├── tests/                           # Pruebas (unitarias, integración)
│   ├── __init__.py
│   ├── application/
│   │   └── test_product_service.py
│   └── domain/
│       └── test_product_entity.py
├── .env                             # Variables de entorno (ej. DATABASE_URL)
├── .gitignore
├── Dockerfile
├── docker-compose.yml
├── main.py                          # Punto de entrada de la aplicación FastAPI
└── requirements.txt
```

**`app/domain/entities/product.py`:** (Como se mostró antes, con `_events` y métodos)

**`app/domain/ports/product_repository.py`:** (Como se mostró antes)

**`app/domain/events/product_events.py`:** (Como se mostró antes)

**`app/application/dtos/product_dto.py`:**
```python
from pydantic import BaseModel, Field
from typing import Optional
from app.domain.entities.product import Product as DomainProduct

class ProductBaseDTO(BaseModel):
    name: str = Field(..., min_length=3, max_length=50)
    description: Optional[str] = Field(None, max_length=255)
    price: float = Field(..., gt=0)

class ProductCreateDTO(ProductBaseDTO):
    pass

class ProductDTO(ProductBaseDTO):
    id: str

    class Config:
        orm_mode = True # Pydantic v1
        # from_attributes = True # Pydantic v2

    @classmethod
    def from_domain(cls, product: DomainProduct) -> "ProductDTO":
        return cls(
            id=product.id,
            name=product.name,
            description=product.description,
            price=product.price
        )
```

**`app/application/ports/product_service.py`:** (Como se mostró antes)

**`app/application/services/product_app_service.py`:** (Como se mostró antes, con `EventDispatcher`)

**`app/infrastructure/database.py`:** (Como se mostró antes, con `Base`)

**`app/infrastructure/db_models/product_model.py`:**
```python
from sqlalchemy import Column, Integer, String, Float
from app.infrastructure.database import Base

class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String(50), index=True, nullable=False)
    description = Column(String(255), nullable=True)
    price = Column(Float, nullable=False)
```

**`app/infrastructure/repositories/mariadb_product_repository.py`:** (Como se mostró antes)

**`app/infrastructure/event_dispatcher.py`:** (Como se mostró antes)

**`app/infrastructure/event_handlers.py`:** (Como se mostró antes, pero registrar el handler se hace en `main.py`)

**`app/interfaces/api/dependencies.py`:** (Como se mostró antes)

**`app/interfaces/api/product_routes.py`:** (Como se mostró antes)

**`main.py`:**
```python
from fastapi import FastAPI
from contextlib import asynccontextmanager

from app.interfaces.api import product_routes
from app.infrastructure.database import create_tables
from app.infrastructure.event_dispatcher import event_dispatcher
from app.infrastructure.event_handlers import send_product_creation_notification # Import handler
from app.domain.events.product_events import ProductCreatedEvent # Import event type

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Código a ejecutar antes de que la aplicación empiece a aceptar peticiones
    print("Application startup: Creating database tables...")
    await create_tables() # Crear tablas al inicio
    print("Database tables created (if they didn't exist).")
    
    # Registrar manejadores de eventos
    print("Registering event handlers...")
    event_dispatcher.register(ProductCreatedEvent, send_product_creation_notification)
    print("Event handlers registered.")
    
    yield
    # Código a ejecutar después de que la aplicación termine
    print("Application shutdown...")

app = FastAPI(
    title="Hexagonal FastAPI DDD Service",
    description="Un ejemplo de microservicio con Arquitectura Hexagonal, DDD y FastAPI.",
    version="0.1.0",
    lifespan=lifespan # Usar el nuevo lifespan para startup/shutdown
)

app.include_router(product_routes.router, prefix="/api/v1")

@app.get("/health", tags=["Health"])
async def health_check():
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    # Para desarrollo, uvicorn puede manejar el reload.
    # Para producción, se usaría un gestor de procesos como Gunicorn + Uvicorn workers.
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
```

**`requirements.txt`:**
```
fastapi>=0.100.0
uvicorn[standard]>=0.23.0
pydantic>=1.10.0,<2.0.0 # O >=2.0.0 si ajustas los DTOs (orm_mode -> from_attributes)
sqlalchemy[asyncio]>=2.0.0
aiomysql>=0.2.0 # Driver para MariaDB/MySQL con asyncio
python-dotenv>=1.0.0 # Para .env
# Para pruebas
pytest
pytest-asyncio
httpx # Para cliente HTTP en pruebas de integración
# Opcional: para mocks
# unittest.mock # Ya viene con Python
```
*Ajusta las versiones de Pydantic si usas v2.*

**`.env` (ejemplo):**
```
DATABASE_URL="mysql+aiomysql://myuser:mypassword@mariadb_hexagonal_service:3306/mydatabase"
# Para desarrollo local sin Docker, podrías tener:
# DATABASE_URL="mysql+aiomysql://root:example@localhost:3306/hexagonal_db"
```
*Nota: `mariadb_hexagonal_service` es el nombre del servicio de MariaDB en `docker-compose.yml`.*

**`Dockerfile`:**
```dockerfile
FROM python:3.12-slim

WORKDIR /app

# Variables de entorno para Python
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Instalar dependencias del sistema si fueran necesarias
# RUN apt-get update && apt-get install -y --no-install-recommends some-package && rm -rf /var/lib/apt/lists/*

COPY ./requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY ./app /app/app
COPY ./main.py /app/

# Copiar .env si lo usas para configuración en el contenedor (mejor usar variables de entorno de Docker Compose)
# COPY ./.env /app/

EXPOSE 8000

# Comando para ejecutar la aplicación.
# Para producción, se recomienda Gunicorn con Uvicorn workers.
# CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
# Para desarrollo, uvicorn con reload es útil, pero el reload no funcionará bien dentro de Docker
# si los archivos no se montan como volumen.
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**`docker-compose.yml`:**
```yaml
version: '3.8'

services:
  app:
    build: .
    container_name: hexagonal_fastapi_app
    ports:
      - "8000:8000"
    volumes:
      - ./app:/app/app         # Montar código para desarrollo (permite hot-reloading con uvicorn --reload)
      - ./main.py:/app/main.py
      # - ./.env:/app/.env # Opcional si el .env se copia en Dockerfile
    environment:
      # Sobrescribir o definir variables de entorno aquí es preferible a copiar .env
      - DATABASE_URL=mysql+aiomysql://myuser:mypassword@mariadb_hexagonal_service:3306/mydatabase
      # - PYTHONUNBUFFERED=1 # Ya está en el Dockerfile
      # - PYTHONDONTWRITEBYTECODE=1 # Ya está en el Dockerfile
    depends_on:
      mariadb_hexagonal_service:
        condition: service_healthy # Espera a que MariaDB esté lista
    networks:
      - hexagonal_network

  mariadb_hexagonal_service:
    image: mariadb:10.11 # Usar una versión específica de MariaDB
    container_name: mariadb_hexagonal_db
    ports:
      - "3307:3306" # Exponer MariaDB en el puerto 3307 del host para acceso externo si es necesario
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword # No usar en producción
      MYSQL_DATABASE: mydatabase
      MYSQL_USER: myuser
      MYSQL_PASSWORD: mypassword
    volumes:
      - mariadb_data:/var/lib/mysql # Persistir datos de MariaDB
    healthcheck: # Para que 'depends_on' funcione mejor
      test: ["CMD", "mysqladmin" ,"ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - hexagonal_network

volumes:
  mariadb_data:

networks:
  hexagonal_network:
    driver: bridge
```

**Para ejecutar:**
1.  Crea los archivos y directorios como se describe.
2.  Asegúrate de tener Docker y Docker Compose instalados.
3.  Desde la raíz del proyecto `hexagonal_fastapi_ddd/`, ejecuta:
    ```bash
    docker-compose up --build
    ```
4.  Una vez levantado, podrás acceder a la API en `http://localhost:8000/docs`.

    Puedes probar a crear un producto con un POST a `http://localhost:8000/api/v1/products/` con un JSON como:
    ```json
    {
      "name": "Super Product",
      "description": "An amazing product from Hexagonal Arch",
      "price": 199.99
    }
    ```
    Deberías ver en la consola de Docker Compose los logs, incluyendo el mensaje del `ProductCreatedEvent` siendo manejado.

---

Este es un desarrollo exhaustivo del tema. Cubre los conceptos clave y proporciona ejemplos prácticos para construir un microservicio FastAPI robusto y bien arquitecturado. La clave es mantener la disciplina de las dependencias y pensar en términos de interfaces (puertos) y sus implementaciones (adaptadores).

---

