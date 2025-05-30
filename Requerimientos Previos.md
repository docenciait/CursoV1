# 🛠 Requerimientos 

Este manual describe cómo instalar y configurar todo el entorno necesario para trabajar en los laboratorios del curso de **Microservicios, FastAPI, DDD, Hexagonal, CQRS**.

---

## ✅ Requisitos

* Windows 10/11 
* Conexión a internet estable
* Permisos de administrador

---

## 1. Instalación de Docker Desktop con WSL 2

### 1.1 Instalar WSL 2

1. Abrir PowerShell como administrador:

```powershell
wsl --install
```

2. Reiniciar el sistema cuando se solicite.
3. Verificar:

```powershell
wsl --list --online
```

4. Instalar Ubuntu:

```powershell
wsl --install -d Ubuntu
```

5. Verifica instalación:

```powershell
wsl --status
```

### 1.2 Instalar Docker Desktop

1. Descargar desde: [https://www.docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop)
2. Instalar con:

   * ✅ Integración con WSL2 activada
   * ✅ Uso de contenedores Linux
3. Reiniciar y verificar:

```powershell
docker --version
docker info
```

---

## 2. Docker tanto en Windows como en Ubuntu WSL

### 2.1 Ubuntu (WSL)

```bash
sudo apt update && sudo apt install docker.io docker-compose -y
sudo usermod -aG docker $USER
```

> Reinicia la sesión de WSL: `exit` y vuelve a entrar

### 2.2 Verificación

```bash
docker version
docker-compose version
```

---

## 3. Instalación de Git

1. Descargar desde: [https://git-scm.com/download/win](https://git-scm.com/download/win)
2. Instalar con todas las opciones por defecto.
3. Verificar:

```bash
git --version
```

---

## 4. Instalación de Python 3.12

1. Descargar desde: [https://www.python.org/downloads/release/python-3120/](https://www.python.org/downloads/release/python-3120/)
2. Marcar:

   * ✅ "Add Python to PATH"
   * ✅ "Install for all users"
3. Verificar:

```bash
python --version
pip --version
```

---

## 5. Importar perfil de VS Code

### 5.1 Descargar el archivo de perfil que te proporciona el formador:

Archivo: [fastapi-course.code-profile](fastapi_arquitecture.profile)

### 5.2 Importar el perfil

1. Abre Visual Studio Code
2. `Ctrl + Shift + P` > `Profiles: Import Profile`
3. Selecciona "Desde archivo"
4. Carga el archivo `.code-profile`

---

## 6. Test Lab

Proyecto que incluyen varias configuraciones que tiene como objetivo 


### 6.2 Makefile de ejemplo

```makefile
.PHONY: build up down restart logs test

build:
	docker compose build

up:
	docker compose up -d

down:
	docker compose down

restart:
	make down && make up

logs:
	docker compose logs -f

test:
	docker compose exec app pytest
```

### 6.3 Ejecutar el proyecto

```bash
git clone https://github.com/tu-org/fastapi-lab.git
cd fastapi-lab
make build
make up
```

> El servicio estará disponible en: `http://localhost:8000/docs`

---

### 6.4 Verificar servicios

* **MariaDB**: puerto 3306
* **Redis**: puerto 6379
* **RabbitMQ**: [http://localhost:15672](http://localhost:15672)
* **Prometheus**: [http://localhost:9090](http://localhost:9090)
* **Grafana**: [http://localhost:3000](http://localhost:3000) (user: admin / pass: admin)
* **FastAPI**: [http://localhost:8000](http://localhost:8000)
* **gRPC**: puerto 50051
* **WebSockets**: vía `/ws` endpoint
* **Tests**: ejecutar con `make test`

---

## 🏠 Listo

Con este entorno puedes realizar todos los laboratorios del curso sin conflictos entre dependencias, sin instalaciones manuales, y con control total sobre cada componente.
