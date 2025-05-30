# 🛠 Requerimientos 

Este manual describe cómo instalar y configurar todo el entorno necesario para trabajar en los laboratorios del curso de **Microservicios, FastAPI, DDD, Hexagonal, CQRS**.

---

## ✅ Requisitos

* Windows 10/11 
* Ubuntu WSL
* Docker/Docker Compose
* git
* Postman
* VScode
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
wsl --install -d Ubuntu-24.04
```

5. Verifica instalación:

```powershell
wsl --status
```

### 1.2 Instalar Docker Desktop

#### Windows 10/11

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

### 1.3 Ubuntu (WSL)


!!! info "Uso recomendado de Docker WSL Ubuntu"
    Se recomienda usar docker bajo WSL Ubuntu en Windows 10/11

```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo usermod -aG docker $USER

# Install docker and docker-compose
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

> Reinicia la sesión de WSL: `exit` y vuelve a entrar

!!! Info Iniciar el servicio de Docker Desktop 
    - Windows 10/11: Asegúrate que Docker Desktop esté iniciado
    - Ubuntu/WSL: `sudo service docker start`

### 1.4 Verificación

```bash
# Windows 10/11
docker version
docker compose version

## Ubuntu/WSL
sudo docker version
sudo docker compose version
```

---

## 2. Instalación de Git

### Windows 10/11

1. Descargar desde: [https://git-scm.com/download/win](https://git-scm.com/download/win)
2. Instalar con todas las opciones por defecto.
3. Verificar:

```bash
git --version
```

### Ubuntu/WSL
```bash
sudo apt install git
```

### Configuración git

```bash
# Configurar nombre y correo
git config --global user.name "Tu Nombre Completo"
git config --global user.email "tu_correo@ejemplo.com"
```

---

## 3. Instalación de Python 3.12

### Windows 10/11

1. Descargar desde: [https://www.python.org/downloads/release/python-3120/](https://www.python.org/downloads/release/python-3120/)
2. Marcar:

   * ✅ "Add Python to PATH"
   * ✅ "Install for all users"
3. Verificar:

```bash
python --version
pip --version
pip install virtualenv # Instalar virtualenv
```


### Ubuntu WSL

!!! Info Normalmente Pyton 3.12 viene instalado en Ubuntu 24/WSL pero se realiza otra vez la instalación para verificarlo

```bash
sudo apt install python3.12 python3.12-pip python3.12-venv virtualenv -y
```

---

## 4. Instalación y Configuración VSCode

### 4.1 Instalación

- Instalar en Varias plataformas VSCode: [⬇️  Aquí ](https://code.visualstudio.com/docs/setup/setup-overview)

### 4.2 Descargar el archivo de perfil que te proporciona el formador:

⬇️ Perfil VSCode: [fastapi-course.code-profile](https://raw.githubusercontent.com/docenciait/imagina-assets/refs/heads/main/fastapi_arquitecture.profile.code-profile)


### 4.3 Importar el perfil

1. Abre Visual Studio Code
2. `Ctrl + Shift + P` > `Profiles: Import Profile`
3. Selecciona "Desde archivo"
4. Carga el archivo `.code-profile`
5. ¡¡¡Tarda un poco!!!


## 5 Instalación de make

- Herramienta para poder usar cómodamente los comandos docker, docker compose mediante Makefile

### Windows 10/11

1. Instalar choco como administrador en Windows [⬇️ Enlace](https://chocolatey.org/install)
2. Instalar make en un Terminal Administrador:
```bash
choco install make
make --version
```

### Ubuntu/WSL

```bash
sudo apt install make
sudo make --version
```


---

# 🧪 6. Laboratorio Test 




## 🎯 Objetivo

* Proveer un entorno completo de microservicio backend usando FastAPI y herramientas auxiliares para que el alumno experimente con un entorno similar a los usuados en los laboratorios.

* El alumno luego obtendrá los repositorios de los laboratorios con el tiempo adecuado para su previa instalación.



---

## 🚀 Tecnologías incluidas

| Componente       | Tecnología           |
| ---------------- | -------------------- |
| Backend API      | FastAPI              |
| ORM              | SQLAlchemy           |
| Base de datos    | MariaDB              |
| Cache            | Redis                |
| Mensajería       | RabbitMQ             |
| Observabilidad   | Prometheus + Grafana |
| Pruebas          | Pytest               |
| API Gateway      | NGINX                |
| Vault (Secretos) | HashiCorp Vault      |



---

## ⚙️ Instrucciones de uso

!!! Info Se recomienda no tener contenedores, imágenes, redes, volúmenes de docker previos para no eliminar accidentalmente otros items al realizar reseteos de la infraestructura


### 1. Descargar y Extraer

⬇️ Descargar zip: [Test Lab](https://github.com/docenciait/imagina-assets/blob/main/test-lab.zip)

1. Descomprimir zip 
2. `cd test-lab`

---

## 📁 Estructura del proyecto

```
test-lab/
├── app/
│   ├── main.py
├── tests/
│   └── test_health.py
├── Dockerfile
├── docker-compose.yml
├── Makefile
├── prometheus/
│   └── prometheus.yml
├── grafana/
│   └── provisioning/
├── nginx/
│   └── nginx.conf
└── requirements.txt
```

### 2. Comandos del Makefile

> Usar con sudo si estás en Ubuntu/WSL

| Comando           | Descripción                                                    |
| ----------------- | -------------------------------------------------------------- |
| `make build`      | Construir las imágenes Docker                                  |
| `make up`         | Levantar todos los servicios en segundo plano                  |
| `make down`       | Detener y eliminar los contenedores                            |
| `make restart`    | Reiniciar todo el entorno                                      |
| `make logs`       | Ver logs en tiempo real de los servicios                       |
| `make test`       | Ejecutar los tests unitarios definidos en `tests/`             |
| `make test-debug` | Ejecutar los tests con modo verbose y salida a consola         |
| `make clean`      | Limpiar contenedores, redes e imágenes no usados               |
| `make reset`      | Borrar volúmenes, redes, contenedores e imágenes completamente |
| `make prune`      | Apagar servicios y eliminar todos los recursos Docker          |

---

### 3. Levantar el entorno completo

```bash
make build  
make up
```



## 🔎 Cómo probar cada servicio manualmente

1. **FastAPI**

   * URL de prueba: `http://localhost:8000/health`
   * Respuesta esperada:

   ```json
   { "status": "ok" }
   ```

2. **MariaDB**

   ```bash
   docker compose exec mariadb mysql -uroot -ppassword -e "SHOW DATABASES;"
   ```

3. **Redis**

   ```bash
   docker compose exec redis redis-cli ping
   # PONG
   ```

4. **RabbitMQ**

   Accede vía navegador a: `http://localhost:15672` (guest/guest).


5. **Prometheus**

   Abre: `http://localhost:9090` 


6. **Grafana**

   Accede: `http://localhost:3000` → Login: `admin/admin` → Añadir datasource Prometheus.

7. **Vault**

   Accede: `http://localhost:8200`, Token root: `root`.

---

## 🧹 Cómo limpiar todo

Para dejar limpio el entorno:

```bash
make down    # Para detener
make prune   # Para eliminar contenedores, volúmenes, redes e imágenes
```

O limpieza forzada:

```bash
make reset
```

Esto elimina **todo** lo relacionado con los contenedores, imágenes, redes y volúmenes usados en este laboratorio.



!!! Info Este laboratorio es el punto de partida para entender cómo funcionan los diferentes componentes de un entorno de microservicios y su orquestación completa con Docker y FastAPI.


---

## 🏠 Listo

Aunque este entorno será un test, podrás conocer cómo son los laboratorios del curso sin conflictos entre dependencias, sin instalaciones manuales, y con control total sobre cada componente.

Así también te podrás familiarizar con los entornos de los laboratorios y poder ser resiliente ante cualquier fallo en la medida de lo posible.

!!! Note No obstante, cada sesión se proveerán los laboratorios correspondientes con suficiente tiempo de antelación.

**¡¡¡ Espero que todo hay ido bien y tengas tu entorno configurado y podamos aprender mucho de Arquitecturas con FastAPI!!!**