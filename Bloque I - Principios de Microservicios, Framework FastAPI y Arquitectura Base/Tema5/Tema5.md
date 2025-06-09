# Tema 5. Seguridad y buenas prácticas en Microservicios

  * [Objetivos](#objetivos)
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
  * [Referencias](#referencias)

***
## Objetivos

* Comprender los principios fundamentales de seguridad aplicables a arquitecturas de microservicios.

* Implementar mecanismos de autenticación y autorización robustos, como JWT y RBAC, en aplicaciones FastAPI.

* Aplicar buenas prácticas para asegurar la comunicación, la validación de datos y la gestión de secretos en microservicios.

* Identificar y mitigar vulnerabilidades comunes en APIs, tomando como referencia el Top 10 de OWASP.

* Establecer estrategias para la auditoría, trazabilidad y limitación de tasa en los servicios.

***

!!! Info La seguridad en arquitecturas de microservicios es un desafío multifacético pero crítico. La naturaleza distribuida de los microservicios introduce nuevas superficies de ataque y complejidades en comparación con los monolitos. Adoptar un enfoque de "defensa en profundidad", donde múltiples capas de seguridad se complementan, es esencial. Este tema cubre los aspectos fundamentales de la seguridad y las buenas prácticas para construir microservicios robustos y protegidos, con ejemplos y consideraciones para FastAPI.

## 5.1 Autenticación basada en JWT con FastAPI

La autenticación es el proceso de verificar la identidad de un usuario, cliente o servicio. JSON Web Tokens (JWT) son un estándar abierto (RFC 7519) que define una forma compacta y autónoma para transmitir información de forma segura entre partes como un objeto JSON. Son especialmente adecuados para escenarios de microservicios debido a su naturaleza stateless.

**Estructura de un JWT:** Un JWT consta de tres partes separadas porpuntos (`.`):

1. **Header (Cabecera):** Típicamente consiste en dos partes: el tipo de token (`typ`, que es JWT) y el algoritmo de firma utilizado (`alg`, como HMAC SHA256 o RSA SHA256).`json { "alg": "HS256", "typ": "JWT" }` Esta parte se codifica en Base64Url.
2.  **Payload (Carga Útil):** Contiene las "claims" (afirmaciones), que son declaraciones sobre una entidad (normalmente el usuario) y datos adicionales. Hay tres tipos de claims:

    * **Registered claims (Registradas):** Un conjunto de claims\
      predefinidas no obligatorias pero recomendadas, como `iss`\
      (issuer/emisor), `exp` (expiration time/tiempo de expiración),`sub` (subject/sujeto, el ID del usuario), `aud`\
      (audience/audiencia, el destinatario del token).
    * **Public claims (Públicas):** Definidas por quienes usan JWTs,\
      pero deben ser globalmente únicas (registradas en el IANA JSON\
      Web Token Registry o usar URIs resistentes a colisiones).
    * **Private claims (Privadas):** Claims personalizadas creadas\
      para compartir información entre partes que acuerdan usarlas\
      (ej. roles, permisos).

    ```json
    {
      "sub": "user123",
      "name": "Alice Wonderland",
      "roles": ["user", "reader"],
      "exp": 1715289000 // Ejemplo: Timestamp de expiración
    }
    ```

    Esta parte también se codifica en Base64Url.
3. **Signature (Firma):** Para crear la firma, se toman el header\
   codificado, el payload codificado, un secreto (para HMAC) o una\
   clave privada (para RSA/ECDSA), y se firman con el algoritmo\
   especificado en el header.`HMACSHA256( base64UrlEncode(header) + "." + base64UrlEncode(payload), secret )`\
   La firma se utiliza para verificar que el remitente del JWT es quien\
   dice ser y para asegurar que el mensaje no ha sido alterado en\
   tránsito.

**Ventajas de JWT en Microservicios:**

* **Stateless:** El servidor no necesita almacenar el estado de la\
  sesión del token. Toda la información necesaria está en el propio\
  token (aunque se puede verificar contra una lista de revocación si\
  es necesario). Esto es ideal para la escalabilidad horizontal de los\
  microservicios.
* **Distribuible:** Los tokens pueden ser generados por un servicio de\
  autenticación y luego validados por múltiples microservicios (si\
  comparten el secreto o la clave pública).
* **Seguridad (si se usa correctamente):** La firma asegura la\
  integridad y autenticidad del token.

**Flujo Típico (OAuth2 Password Flow con Bearer Tokens):**

1. El usuario envía sus credenciales (username/password) a un endpoint\
   de autenticación (ej. `/token` o `/login`).
2. El servicio de autenticación verifica las credenciales.
3. Si son válidas, genera un JWT (access token) y opcionalmente un\
   refresh token.
4. El cliente almacena el access token (ej. en `localStorage`,`sessionStorage`, o memoria) y lo envía en la cabecera`Authorization` con el esquema `Bearer` en cada solicitud a los\
   endpoints protegidos. `Authorization: Bearer <token>`



#### **Ejemplo Práctico** 

Vamos a construir una API con dos endpoints:
* `/token`: Un endpoint público donde el usuario envía su nombre y contraseña para recibir un JWT.
* `/users/me`: Un endpoint protegido que solo devuelve información si se presenta un JWT válido.

**1. Preparación (Instalación de librerías):**
Abre tu terminal e instala todo lo necesario:
```bash
pip install "fastapi[all]" "python-jose[cryptography]" "passlib[bcrypt]" bcrypt==3.2.0
```

**2. Código de la Aplicación:**
Guarda este código en un fichero llamado `main_sec_5_1.py`:

```python
# main_sec_5_1.py
from datetime import datetime, timedelta, timezone
from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from passlib.context import CryptContext

# --- 1. Configuración de Seguridad ---
# ¡IMPORTANTE! En un proyecto real, esta clave debe ser mucho más compleja y
# cargada desde un lugar seguro (variables de entorno, gestor de secretos), NUNCA en el código.
SECRET_KEY = "mi-clave-secreta-para-el-ejemplo-de-jwt"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# --- 2. Utilidades para Contraseñas y Tokens ---
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token") # Le dice a FastAPI dónde está el endpoint de login

# --- 3. Base de Datos Ficticia de Usuarios ---
# En un caso real, esto vendría de una base de datos.
fake_users_db = {
    "user1": {
        "username": "user1",
        "full_name": "Usuario Uno",
        "email": "user1@example.com",
        "hashed_password": pwd_context.hash("pass123"), # La contraseña "pass123" hasheada
    }
}

# --- 4. Funciones de Creación y Verificación de JWT ---
def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def get_current_user(token: str = Depends(oauth2_scheme)):
    """
    Esta es la dependencia "guardián". Se encarga de:
    1. Extraer el token de la cabecera 'Authorization'.
    2. Decodificarlo y validar su firma y expiración.
    3. Devolver los datos del usuario si todo es correcto.
    4. Lanzar una excepción si algo falla.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="No se pudieron validar las credenciales",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    user = fake_users_db.get(username)
    if user is None:
        raise credentials_exception
    return user

# --- 5. La Aplicación FastAPI ---
app = FastAPI()

@app.post("/token", summary="Iniciar sesión y obtener un token")
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends()):
    user_in_db = fake_users_db.get(form_data.username)
    if not user_in_db or not pwd_context.verify(form_data.password, user_in_db["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario o contraseña incorrectos",
        )
    # El "sub" (subject) es el identificador único del usuario en el token.
    access_token = create_access_token(data={"sub": user_in_db["username"]})
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/users/me", summary="Obtener perfil del usuario actual (protegido)")
async def read_users_me(current_user: dict = Depends(get_current_user)):
    # Gracias a `Depends(get_current_user)`, este código solo se ejecuta
    # si el token es válido. `current_user` contendrá los datos del usuario.
    # Eliminamos el hash de la contraseña antes de devolver los datos.
    user_info = current_user.copy()
    user_info.pop("hashed_password")
    return user_info
```

**3. Ejecuta la Aplicación:**
```bash
uvicorn main_sec_5_1:app --reload
```

#### **Pruebas con `curl`** ✅

Ahora, vamos a probar que nuestra autenticación funciona.

**1. Intenta acceder al endpoint protegido SIN token (debe fallar):**
```bash
curl -X GET "http://localhost:8000/users/me"
```
*Respuesta esperada (401 Unauthorized):*
```json
{"detail":"Not authenticated"}
```
¡Perfecto! El guardián está haciendo su trabajo.

**2. Inicia sesión para obtener un token:**
```bash
curl -X POST "http://localhost:8000/token" \
-H "Content-Type: application/x-www-form-urlencoded" \
-d "username=user1&password=pass123"
```
*Respuesta esperada:*
```json
{"access_token":"eyJhbGciOi...","token_type":"bearer"}
```
**Copia el valor del `access_token`**. Lo necesitaremos para el siguiente paso.

**3. Accede al endpoint protegido CON el token (debe funcionar):**

Reemplaza `TU_TOKEN_COPIADO_AQUI` con el token que acabas de obtener.

```bash
TOKEN="TU_TOKEN_COPIADO_AQUI"

curl -X GET "http://localhost:8000/users/me" \
-H "Authorization: Bearer $TOKEN"
```
*Respuesta esperada (200 OK):*
```json
{"username":"user1","full_name":"Usuario Uno","email":"user1@example.com"}
```



---
**Consideraciones de Seguridad para JWT:**

* **HTTPS Siempre:** Los JWTs solo deben transmitirse sobre HTTPS para\
  protegerlos de la interceptación.
* **Algoritmo de Firma (`alg`):**
  * `HS256` (HMAC con SHA-256) usa un único secreto compartido entre\
    el emisor y el validador. Es más simple pero requiere compartir\
    el secreto.
  * `RS256` (RSA con SHA-256) usa un par de claves pública/privada.\
    El emisor firma con la clave privada, y los validadores\
    verifican con la clave pública. Esto es más seguro para\
    microservicios, ya que la clave privada no necesita ser\
    compartida con todos los servicios.
  * Evitar el algoritmo `none` (deshabilítalo en tu biblioteca de\
    validación).
* **Gestión de Secretos/Claves:** El `SECRET_KEY` (para HS256) o la\
  clave privada (para RS256) deben ser fuertes, únicos y gestionados\
  de forma segura (ver secciones 5.7 y 5.8).
* **Expiración (`exp`):** Los access tokens deben tener una vida corta\
  (ej. 15-60 minutos) para limitar el impacto si son robados.
* **Refresh Tokens:** Para obtener nuevos access tokens sin que el\
  usuario tenga que volver a ingresar credenciales, se usan refresh\
  tokens. Estos son tokens de larga duración, almacenados de forma\
  segura por el cliente, y se envían a un endpoint especial para\
  obtener un nuevo access token. Los refresh tokens pueden ser\
  revocados.
* **Revocación de Tokens:** Aunque los JWT son stateless, a veces es\
  necesario revocar un token antes de su expiración (ej. si el usuario\
  cierra sesión, cambia contraseña, o se detecta compromiso). Esto\
  requiere una solución stateful, como una lista negra de IDs de token\
  (claim `jti`) o una lista blanca de sesiones activas, consultada\
  durante la validación.
* **Sensibilidad del Payload:** No incluyas información altamente\
  sensible directamente en el payload del JWT si este puede ser leído\
  por el cliente. Aunque firmado, el payload es solo Base64Url\
  codificado, no cifrado. Si se necesita cifrado, usar JWE (JSON Web\
  Encryption).

## 5.2 Autorización por roles y scopes (RBAC)




> La **autorización** es el proceso que ocurre *después* de la autenticación. Responde a la pregunta: **"¿Tiene este usuario permiso para realizar esta acción?"**.

Existen varios modelos para gestionar permisos, pero uno muy común y flexible es una combinación de **roles** y **scopes**:

* **Rol**: Es una etiqueta que agrupa a un tipo de usuario. Define *quién* es el usuario en un sentido funcional.
    * *Ejemplos*: `admin`, `editor`, `viewer`, `premium_user`.

* **Scope (Ámbito o Permiso)**: Es una autorización granular para realizar una acción muy específica. Define *qué puede hacer* el usuario.
    * *Ejemplos*: `items:read`, `items:write`, `users:delete`, `billing:view`.

La práctica habitual es asignar uno o más roles a un usuario, y que cada rol lleve asociados un conjunto de scopes. Para mantener nuestros microservicios rápidos y autónomos, la mejor estrategia es **incluir los roles y scopes del usuario directamente en el payload del JWT** al iniciar sesión.

#### **Ejemplo Práctico** 

Vamos a ampliar nuestro ejemplo anterior. Ahora, al iniciar sesión, el token JWT contendrá los permisos del usuario. Crearemos endpoints que requieran scopes específicos para poder ser accedidos.

**1. Preparación:**
Continuaremos con el fichero del punto anterior. No se necesitan nuevas librerías.

**2. Código de la Aplicación:**
Guarda este código como `main_sec_5_2.py`. Fíjate en los cambios marcados con comentarios.

```python
# main_sec_5_2.py
from datetime import datetime, timedelta, timezone
from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from passlib.context import CryptContext

# --- Configuración (sin cambios) ---
SECRET_KEY = "mi-clave-secreta-para-el-ejemplo-de-jwt"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# --- Base de Datos Ficticia (¡Ahora con roles y scopes!) ---
fake_users_db = {
    "user_viewer": {
        "username": "user_viewer",
        "full_name": "Usuario Lector",
        "email": "viewer@example.com",
        "hashed_password": pwd_context.hash("pass123"),
        "roles": ["viewer"],
        "scopes": ["items:read"], # Solo puede leer
    },
    "user_editor": {
        "username": "user_editor",
        "full_name": "Usuario Editor",
        "email": "editor@example.com",
        "hashed_password": pwd_context.hash("pass456"),
        "roles": ["editor"],
        "scopes": ["items:read", "items:write"], # Puede leer y escribir
    }
}

# --- Funciones de JWT (create_access_token sin cambios) ---
def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

# --- Dependencias de Seguridad (get_current_user ahora extrae más claims) ---
async def get_current_user_from_token(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="No se pudieron validar las credenciales",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
        
        # Extraemos los scopes del payload del token
        scopes = payload.get("scopes", [])
        
    except JWTError:
        raise credentials_exception
    
    # Devolvemos un diccionario con los datos del usuario del token
    return {"username": username, "scopes": scopes}


# --- NUEVA Dependencia de AUTORIZACIÓN ---
def require_scope(required_scope: str):
    """
    Esta es una factoría de dependencias. Devuelve una función 'checker'
    que verifica si el scope requerido está en la lista de scopes del usuario.
    """
    async def scope_checker(current_user: dict = Depends(get_current_user_from_token)):
        if required_scope not in current_user.get("scopes", []):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Permisos insuficientes. Se requiere el scope: '{required_scope}'"
            )
        return current_user
    return scope_checker

# --- Aplicación FastAPI ---
app = FastAPI()

# El endpoint de login ahora debe incluir los scopes en el token
@app.post("/token", summary="Iniciar sesión para obtener un token con scopes")
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends()):
    user_in_db = fake_users_db.get(form_data.username)
    if not user_in_db or not pwd_context.verify(form_data.password, user_in_db["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario o contraseña incorrectos",
        )
    
    # Creamos el token incluyendo el username (sub) y sus scopes
    access_token = create_access_token(
        data={"sub": user_in_db["username"], "scopes": user_in_db["scopes"]}
    )
    return {"access_token": access_token, "token_type": "bearer"}


# --- Endpoints Protegidos por Scopes ---
@app.get("/items", summary="Leer lista de items (requiere scope 'items:read')")
async def read_items(current_user: dict = Depends(require_scope("items:read"))):
    return [{"id": 1, "name": "Poción de Salud"}, {"id": 2, "name": "Espada Mágica"}]

@app.post("/items", summary="Crear un item (requiere scope 'items:write')")
async def create_item(current_user: dict = Depends(require_scope("items:write"))):
    return {"status": "success", "message": f"Item creado por el usuario '{current_user['username']}'"}

```

**3. Ejecuta la Aplicación:**
```bash
uvicorn main_sec_5_2:app --reload
```

#### **Pruebas con `curl`** ✅

Vamos a probar los permisos de nuestros dos usuarios.

**Escenario 1: El Lector (`user_viewer`)**

1.  **Obtén el token para `user_viewer`:**
    ```bash
    curl -X POST "http://localhost:8000/token" -H "Content-Type: application/x-www-form-urlencoded" -d "username=user_viewer&password=pass123"
    ```
    Copia el `access_token` que te devuelve.

2.  **Intenta LEER items (debería funcionar):**
    ```bash
    TOKEN_VIEWER="TU_TOKEN_DE_VIEWER_AQUI"
    curl -X GET "http://localhost:8000/items" -H "Authorization: Bearer $TOKEN_VIEWER"
    ```
    *Respuesta esperada (200 OK):* Un JSON con la lista de items.

3.  **Intenta CREAR un item (debería fallar):**
    ```bash
    TOKEN_VIEWER="TU_TOKEN_DE_VIEWER_AQUI"
    curl -X POST "http://localhost:8000/items" -H "Authorization: Bearer $TOKEN_VIEWER"
    ```
    *Respuesta esperada (403 Forbidden):*
    ```json
    {"detail":"Permisos insuficientes. Se requiere el scope: 'items:write'"}
    ```

**Escenario 2: El Editor (`user_editor`)**

1.  **Obtén el token para `user_editor`:**
    ```bash
    curl -X POST "http://localhost:8000/token" -H "Content-Type: application/x-www-form-urlencoded" -d "username=user_editor&password=pass456"
    ```
    Copia este nuevo `access_token`.

2.  **Intenta CREAR un item (debería funcionar):**
    ```bash
    TOKEN_EDITOR="TU_TOKEN_DE_EDITOR_AQUI"
    curl -X POST "http://localhost:8000/items" -H "Authorization: Bearer $TOKEN_EDITOR"
    ```
    *Respuesta esperada (200 OK):*
    ```json
    {"status":"success","message":"Item creado por el usuario 'user_editor'"}
    ```

---
Hemos implementado con éxito un sistema de autorización granular. El token ahora no solo dice *quién* es el usuario, sino también *qué puede hacer*.

Cuando quieras, continuamos con el punto **5.3 Comunicación segura con HTTPS y certificados**.

## 5.3 Comunicación segura con HTTPS y certificados

La definición de HTTPS, TLS y certificados es la misma que la anterior. La diferencia radica en la implementación.

HTTPS cifra el tráfico para protegerlo de espionaje y manipulación. En una arquitectura de producción, un servidor web como Nginx actúa como "terminador TLS", gestionando la conexión segura con el cliente y comunicándose con nuestra aplicación FastAPI a través de una red interna más simple y rápida.

`Cliente <--- (Tráfico Cifrado HTTPS) ---> Nginx <--- (Tráfico sin cifrar HTTP) ---> Aplicación FastAPI`

#### Ejemplo Práctico 

La forma más sencilla y reproducible de montar este entorno es con Docker y Docker Compose. Así definimos nuestros dos servicios (la app y el proxy) y cómo se conectan.


**Paso 1: La Aplicación FastAPI (Sin Cambios en el Código)**

Usaremos exactamente el mismo fichero `main_sec_5_2.py` de la sección anterior. Lo importante es que **nuestra app no sabrá nada de SSL**. Ella correrá en HTTP normal.

**Paso 2: Generar los Certificados (Igual que Antes)**

En la raíz de tu proyecto, ejecuta el comando para crear tu certificado y clave auto-firmados:
```bash
openssl req -x509 -newkey rsa:4096 -nodes -out cert.pem -keyout key.pem -days 365
```
(Recuerda que puedes pulsar Enter a todas las preguntas para desarrollo local).

**Paso 3: Crear la Configuración de Nginx**

Crea un fichero llamado `nginx.conf`. Este le dice a Nginx cómo comportarse.

**Fichero: `nginx.conf`**
```nginx
server {
    # Nginx escuchará en el puerto 443 para tráfico HTTPS
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name localhost;

    # Le indicamos dónde están el certificado y la clave privada
    ssl_certificate /etc/nginx/certs/cert.pem;
    ssl_certificate_key /etc/nginx/certs/key.pem;

    # La raíz de la web, aunque no la usaremos mucho para la API
    root /usr/share/nginx/html;

    # La configuración principal: todo lo que llegue se reenvía a la API
    location / {
        # 'fastapi_app' es el nombre del servicio de nuestra API en docker-compose
        # El puerto 8000 es donde escucha Uvicorn dentro de la red de Docker
        proxy_pass http://fastapi_app:8000;
        
        # Cabeceras importantes para que la app FastAPI sepa
        # de dónde vino la petición original
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Paso 4: Crear los Ficheros de Docker**

Necesitaremos tres ficheros más para orquestar todo: `requirements.txt`, `Dockerfile` para nuestra app, y `docker-compose.yml` para unirlos.

**Fichero: `requirements.txt`**
```txt
fastapi[all]
python-jose[cryptography]
passlib[bcrypt]
```

**Fichero: `Dockerfile`**
```dockerfile
# Usamos una imagen oficial de Python
FROM python:3.11-slim

# Establecemos el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiamos el fichero de requisitos e instalamos las dependencias
COPY ./requirements.txt .
RUN pip install --no-cache-dir --upgrade -r requirements.txt

# Copiamos el código de nuestra aplicación
COPY ./main_sec_5_2.py .

# El comando que se ejecutará cuando el contenedor arranque
# --host 0.0.0.0 es crucial para que sea accesible desde otros contenedores
CMD ["uvicorn", "main_sec_5_2:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Fichero: `docker-compose.yml`**
```yaml
version: '3.8'

services:
  fastapi_app:
    build: . # Construye la imagen usando el Dockerfile en la carpeta actual
    container_name: mi_fastapi_app
    # No exponemos el puerto 8000 al exterior, solo Nginx necesita verlo.

  nginx:
    image: nginx:latest
    container_name: mi_nginx_proxy
    ports:
      # Mapeamos el puerto 443 del host al 443 del contenedor
      - "443:443"
    volumes:
      # Montamos nuestra configuración de Nginx dentro del contenedor
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
      # Montamos nuestros certificados dentro del contenedor
      - ./cert.pem:/etc/nginx/certs/cert.pem
      - ./key.pem:/etc/nginx/certs/key.pem
    depends_on:
      - fastapi_app # Nginx no arrancará hasta que la app esté lista
```

**Estructura final de tu carpeta:**
```
.
├── cert.pem
├── key.pem
├── main_sec_5_2.py
├── requirements.txt
├── Dockerfile
├── nginx.conf
└── docker-compose.yml
```

#### **Pruebas con el Entorno Completo** ✅

**1. Levantar todo el sistema:**
Con todos los ficheros en su sitio, abre una terminal en esa carpeta y ejecuta:
```bash
docker-compose up --build
```
Docker construirá la imagen de tu aplicación y arrancará ambos contenedores.

**2. Prueba con el Navegador:**
* Abre tu navegador y ve a `https://localhost/docs` (ya no necesitas especificar el puerto, porque usamos el 443 estándar de HTTPS).
* Verás la misma advertencia de seguridad que antes. Acéptala.
* ¡La documentación de FastAPI cargará! Has accedido de forma segura a través de Nginx.

**3. Prueba con `curl`:**
`curl` ahora hablará directamente con Nginx en el puerto 443.
```bash
# Obtén un token (recuerda que ahora es a través de https://localhost)
curl https://localhost/token --insecure \
-H "Content-Type: application/x-www-form-urlencoded" \
-d "username=user_viewer&password=pass123"
```
Copia el token y úsalo para acceder a un endpoint protegido:
```bash
TOKEN="TU_TOKEN_AQUI"
curl https://localhost/items --insecure -H "Authorization: Bearer $TOKEN"
```
La respuesta debería ser un `200 OK` con la lista de items. Has completado el flujo profesional: tu petición `curl` viaja cifrada hasta Nginx, y Nginx la reenvía de forma segura a tu aplicación FastAPI.

---

## 5.4 Validación de inputs y outputs

La validación de todos los datos que entran y salen de un servicio es\
una práctica de seguridad fundamental. Ayuda a prevenir una amplia gama\
de vulnerabilidades y errores.

* **Importancia:**
  * **"Nunca confíes en la entrada del usuario" (o de cualquier**\
    **cliente, incluso otro servicio):** Los datos externos pueden ser\
    maliciosos, malformados o inesperados.
  * **Prevenir Vulnerabilidades de Inyección:** Como SQL Injection\
    (SQLi), Cross-Site Scripting (XSS), Command Injection. Aunque\
    los ORMs y plantillas modernas ayudan, la validación en la capa\
    de entrada es la primera línea de defensa.
  * **Asegurar la Integridad de los Datos:** Evitar que datos\
    incorrectos o corruptos se almacenen en bases de datos o se\
    propaguen a otros servicios.
  * **Prevenir Errores Inesperados:** Datos con tipos o formatos\
    incorrectos pueden causar excepciones no manejadas en la lógica\
    de negocio.
  * **Cumplir Contratos API:** Asegurar que el servicio consume y\
    produce datos que se adhieren a su contrato API definido.
* **Validación de Inputs (Entradas):** FastAPI utiliza **Pydantic**\
  extensivamente para la validación automática de datos de entrada, lo\
  cual es una de sus características de seguridad más potentes.
  1. **Cuerpo de la Solicitud (Request Body):**
     * Definir modelos Pydantic para el cuerpo de las solicitudes\
       POST, PUT, PATCH.
     * FastAPI automáticamente parsea el JSON entrante, lo valida\
       contra el modelo Pydantic, y convierte los tipos.
     * Si la validación falla (ej. falta un campo requerido, un\
       tipo es incorrecto, una restricción no se cumple), FastAPI\
       lanza automáticamente una `RequestValidationError` y\
       devuelve una respuesta HTTP `422 Unprocessable Entity` con\
       detalles de los errores.

```python
from fastapi import FastAPI
        from pydantic import BaseModel, Field, EmailStr

        app = FastAPI()

        class UserCreate(BaseModel):
            username: str = Field(..., min_length=3, max_length=50, pattern=r"^[a-zA-Z0-9_]+$")
            email: EmailStr # Valida formato de email
            full_name: str | None = None
            age: int = Field(..., gt=0, le=120) # Mayor que 0, menor o igual a 120

        @app.post("/users/")
        async def create_user(user: UserCreate):
            # Si llegamos aquí, 'user' es una instancia válida de UserCreate
            return {"message": "User created successfully", "user_data": user}
```

1. **Parámetros de Ruta (Path Parameters) y Consulta (Query**\
   **Parameters):** \* También se pueden anotar con tipos y usar\
   validaciones de Pydantic (a través de `Query`, `Path` de FastAPI,\
   que usan `Field` de Pydantic internamente).

```python
from fastapi import FastAPI, Query, Path

        @app.get("/items_query/")
        async def read_items_query(
            q: str | None = Query(None, min_length=3, max_length=50, description="Query string"),
            limit: int = Query(10, gt=0, le=100, description="Max number of items to return")
        ):
            return {"q": q, "limit": limit}

        @app.get("/items_path/{item_id}")
        async def read_item_path(
            item_id: int = Path(..., gt=0, description="The ID of the item to get")
        ):
            return {"item_id": item_id}
```

1. **Cabeceras (Headers):** \* Similar a Query y Path, se pueden\
   validar cabeceras con `Header`.

```python
from fastapi import FastAPI, Header

        @app.get("/headers_test/")
        async def read_headers(user_agent: str | None = Header(None, description="User agent string")):
            return {"User-Agent": user_agent}
```

1. **Validadores Personalizados en Pydantic:** \* Para lógica de\
   validación más compleja que no cubren las restricciones estándar,\
   Pydantic permite definir validadores personalizados a nivel de campo\
   o de modelo.

```python
from pydantic import BaseModel, field_validator, validator # field_validator para Pydantic v2, validator para v1

        class Event(BaseModel):
            start_date: datetime
            end_date: datetime

            # Para Pydantic V2+
            @field_validator("end_date")
            @classmethod
            def end_date_must_be_after_start_date_v2(cls, v, values):
                # 'values' es un FieldValidationInfo object en Pydantic v2, se accede a data con values.data
                if 'start_date' in values.data and v <= values.data['start_date']:
                    raise ValueError("End date must be after start date")
                return v

            # Para Pydantic V1
            # @validator("end_date")
            # def end_date_must_be_after_start_date_v1(cls, v, values, **kwargs):
            #     if 'start_date' in values and v <= values['start_date']:
            #         raise ValueError("End date must be after start date")
            #     return v
```

1. **Sanitización vs. Validación:** \* **Validación:** Rechazar datos\
   que no cumplen los criterios. Es la estrategia preferida. \***Sanitización:** Intentar "limpiar" o transformar datos de\
   entrada para hacerlos seguros (ej. eliminando tags HTML, escapando\
   caracteres SQL). **La sanitización es peligrosa si no se hace**\
   **perfectamente** y puede ser eludida. Es mejor validar estrictamente\
   y rechazar lo inválido. Si se necesita transformar datos, hacerlo\
   después de la validación y de forma explícita.

* **Validación de Outputs (Salidas / Response Models):**
  * **Propósito:**
    * Asegurar que el servicio devuelve datos que se adhieren al\
      contrato API prometido.
    * Prevenir la fuga accidental de datos sensibles que podrían\
      estar en los objetos internos pero no deberían exponerse en\
      la API (ej. hashes de contraseñas, datos internos de\
      auditoría).
  * **Implementación en FastAPI:**
    * Usar el parámetro `response_model` en los decoradores de\
      ruta (`@app.get`, `@app.post`, etc.).
    * FastAPI tomará el objeto devuelto por la función de ruta, lo\
      validará contra el `response_model` de Pydantic, y filtrará\
      cualquier campo que no esté definido en el `response_model`.\
      Si hay un error de tipo o un campo requerido en el`response_model` falta en el objeto devuelto (y no tiene\
      default/es opcional), FastAPI lanzará un error en el\
      servidor (ya que es un problema del código del servidor, no\
      del cliente).

```python
from pydantic import BaseModel

        class UserInDB(BaseModel): # Modelo interno, podría tener hashed_password
            username: str
            email: EmailStr
            hashed_password: str
            full_name: str | None = None

        class UserPublic(BaseModel): # Modelo para la respuesta pública
            username: str
            email: EmailStr
            full_name: str | None = None
            # No incluye hashed_password

        @app.get("/users/{username}", response_model=UserPublic)
        async def get_user_public_info(username: str):
            # Simular carga de usuario de la BD
            # user_from_db = UserInDB(username=username, email="user@example.com", hashed_password="verysecret", full_name="A User")
            user_from_db_dict = {"username": username, "email": f"{username}@example.com", "hashed_password": "verysecret", "full_name": f"User {username}"}

            # FastAPI/Pydantic automáticamente filtrará los campos según UserPublic
            return user_from_db_dict # O return UserInDB(**user_from_db_dict)
```

* **Validar Datos de Otros Servicios:**
  * Incluso si un servicio interno es "de confianza", es una buena\
    práctica validar los datos recibidos de él, especialmente si ese\
    servicio podría obtener datos de fuentes menos fiables o tener\
    sus propios bugs. Usar modelos Pydantic para deserializar y\
    validar las respuestas de otros microservicios.

## 5.5 Políticas de CORS estrictas

¡Sin problema! Saltamos al 5.5. Este es un punto que causa muchos dolores de cabeza en el desarrollo frontend, así que es muy importante entenderlo bien.

---

### **5.5 Políticas de CORS Estrictas**

#### **Definición** 🌐

Por defecto, los navegadores web aplican una regla de seguridad fundamental llamada **"Política del Mismo Origen" (Same-Origin Policy o SOP)**. Esta política impide que un script cargado en una página web (por ejemplo, `https://mi-frontend.com`) pueda hacer peticiones a una API que se encuentra en un origen diferente (por ejemplo, `https://api.mi-empresa.com`). Un "origen" es la combinación de protocolo (http/https), dominio y puerto.

**CORS (Cross-Origin Resource Sharing)** es el mecanismo que permite **relajar esta restricción de forma segura**. Es un sistema basado en cabeceras HTTP que el **servidor** utiliza para decirle al **navegador** qué orígenes externos tienen permiso para acceder a sus recursos.

Una **política de CORS estricta** significa que, en lugar de permitir el acceso desde cualquier sitio (usando un comodín `*`), tú defines una lista explícita y limitada de los orígenes en los que confías (tu aplicación frontend, por ejemplo).

#### **Ejemplo Práctico** 🚦

FastAPI hace que configurar CORS sea muy sencillo a través de un middleware. Vamos a configurar nuestra API para que solo acepte peticiones de nuestro frontend oficial y de nuestro entorno de desarrollo local.

**1. Código de la Aplicación:**
Añade este bloque de código al principio de tu fichero (`main_sec_5_2.py` o uno nuevo).

```python
# ... (importaciones existentes)
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI() # Asumiendo que esta es la inicialización de tu app

# --- Lista de orígenes permitidos ---
# En producción, aquí solo debería estar el dominio de tu frontend.
origins = [
    "https://mi-frontend-oficial.com",
    "http://localhost:3000", # Origen común para desarrollo con React/Vue/Angular
]

# --- Añadir el Middleware de CORS ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,       # Especifica los orígenes permitidos
    allow_credentials=True,      # Permite cookies (importante para sesiones)
    allow_methods=["GET", "POST", "PUT", "DELETE"], # Métodos HTTP permitidos
    allow_headers=["Authorization", "Content-Type"], # Cabeceras HTTP permitidas
)

# ... (El resto de tus endpoints, como /token, /items, etc.)
```

**2. Ejecuta la Aplicación:**
```bash
uvicorn tu_fichero_de_app:app --reload
```

#### **Pruebas (Cómo Verificarlo)** ✅

Probar CORS es diferente a probar otros endpoints, porque la restricción la aplica **el navegador**, no el servidor. `curl` no tiene una política de mismo origen, por lo que siempre funcionará. La clave es simular lo que hace un navegador.

**Prueba 1: Simular la Petición "Preflight" con `curl`**

Para peticiones "complejas" (como `POST` con `Content-Type: application/json` o que incluyen la cabecera `Authorization`), el navegador primero envía una petición `OPTIONS` llamada "preflight" para pedir permiso al servidor. Podemos simular esto.

* **Simulando una petición desde un origen PERMITIDO:**
    ```bash
    curl -X OPTIONS "http://localhost:8000/items" \
    -H "Origin: http://localhost:3000" \
    -H "Access-Control-Request-Method: POST" \
    -H "Access-Control-Request-Headers: Authorization" \
    -v 
    ```
    * **Respuesta esperada:** Verás un `HTTP/1.1 200 OK` y, lo más importante, las cabeceras de respuesta que dan permiso:
        ```
        < access-control-allow-origin: http://localhost:3000
        < access-control-allow-credentials: true
        ...
        ```
        Esto le dice al navegador: "Adelante, puedes enviar la petición POST real".

* **Simulando una petición desde un origen NO PERMITIDO:**
    ```bash
    curl -X OPTIONS "http://localhost:8000/items" \
    -H "Origin: https://un-sitio-raro.com" \
    -H "Access-Control-Request-Method: POST" \
    -v
    ```
    * **Respuesta esperada:** Aunque podrías recibir un `200 OK`, **NO verás las cabeceras `access-control-allow-origin`**. La ausencia de esta cabecera le indica al navegador que el permiso ha sido denegado y que debe bloquear la petición real.

**Prueba 2: El Escenario Real en el Navegador**

Esta es la prueba definitiva.

1.  Crea un fichero en tu ordenador llamado `test_cors.html`.
2.  Pega el siguiente código en él. Este script intentará crear un item usando el token de tu usuario editor.

    ```html
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>Test CORS</title>
    </head>
    <body>
        <h1>Prueba de CORS a FastAPI</h1>
        <button onclick="realizarPeticion()">Intentar Crear Item</button>
        <p>Abre la consola del desarrollador (F12) para ver el resultado.</p>

        <script>
            function realizarPeticion() {
                // Pega aquí un token válido de tu usuario editor
                const token = "TU_TOKEN_DE_EDITOR_AQUI"; 

                fetch('http://localhost:8000/items', {
                    method: 'POST',
                    headers: {
                        'Authorization': `Bearer ${token}`,
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ "item": "nuevo desde la web" })
                })
                .then(response => {
                    if (!response.ok) {
                        throw new Error('La respuesta de red no fue OK');
                    }
                    return response.json();
                })
                .then(data => {
                    console.log('¡Éxito! Respuesta:', data);
                    alert('¡Petición exitosa!');
                })
                .catch(error => {
                    console.error('Error en la petición fetch:', error);
                    alert('¡La petición falló! Revisa la consola para ver el error de CORS.');
                });
            }
        </script>
    </body>
    </html>
    ```

3.  Abre el fichero `test_cors.html` directamente en tu navegador (haciendo doble clic en él).
4.  Abre la consola de desarrollador (normalmente con `F12`).
5.  Haz clic en el botón "Intentar Crear Item".

* **Resultado esperado:** La petición **fallará**. En la consola, verás un error muy claro que dice algo como:
    > Access to fetch at 'http://localhost:8000/items' from origin 'null' has been blocked by CORS policy...

Esto ocurre porque el origen de un fichero local es `null`, y `null` no está en nuestra lista de orígenes permitidos. Has probado que tu política de CORS estricta funciona perfectamente.

---
Configurar CORS correctamente es una de las defensas más importantes para una API que será consumida por una aplicación web.

Cuando estés listo, podemos seguir con el **5.4 Validación de inputs y outputs**, o el que prefieras.

## 5.6 Protección de endpoints WebSocket y REST

Tanto los endpoints RESTful tradicionales como los endpoints WebSocket\
requieren estrategias de protección adecuadas, aunque con algunas\
diferencias.

* **Protección de Endpoints REST (HTTP):**
  1. **Autenticación:**
     * **JWT (Bearer Tokens):** Como se vio en 5.1. El cliente\
       envía el JWT en la cabecera `Authorization`. Es el método\
       preferido para APIs consumidas por frontends SPA o\
       servicios.
     * **API Keys:** Para acceso programático por parte de otros\
       servicios o scripts. La API key se puede enviar en una\
       cabecera personalizada (ej. `X-API-Key`) o como un query\
       parameter (menos seguro). Deben ser gestionadas como\
       secretos.
     * **OAuth2:** Un framework de autorización más completo, a\
       menudo usado para delegar acceso a APIs de terceros en\
       nombre de un usuario. JWT es comúnmente usado como el\
       formato del access token en flujos OAuth2.
     * FastAPI `Security` y dependencias para implementar estos\
       mecanismos.
  2. **Autorización:**
     * RBAC y scopes (ver 5.2) para controlar qué puede hacer un\
       usuario/cliente autenticado.
     * Implementado mediante dependencias en FastAPI.
  3. **Validación de Entradas:**
     * Uso riguroso de Pydantic para validar path/query parameters,\
       cabeceras y cuerpos de solicitud (ver 5.4). Previene muchos\
       tipos de ataques de inyección y errores de datos.
  4. **Validación de Salidas (`response_model`):**
     * Para evitar fuga de datos sensibles y asegurar el contrato\
       API (ver 5.4).
  5. **HTTPS:**
     * Toda la comunicación debe ser sobre HTTPS (ver 5.3).
  6. **Rate Limiting:**
     * Para prevenir abuso y DoS (ver 5.11).
  7. **Políticas CORS Estrictas:**
     * Si la API es consumida por navegadores desde diferentes\
       orígenes (ver 5.5).
  8. **Protección contra Ataques Comunes (OWASP Top 10):**
     * **Inyección (SQLi, NoSQLi, Command Inj.):** Pydantic ayuda\
       con la validación de tipos. Usar ORMs parametrizados (como\
       SQLAlchemy con FastAPI) o bibliotecas de base de datos que\
       manejen el escapado. Nunca construir queries concatenando\
       strings con input del usuario.
     * **Cross-Site Scripting (XSS):** Si FastAPI devuelve HTML (lo\
       cual es menos común para APIs de microservicios, pero\
       posible), usar plantillas que auto-escapen (Jinja2 lo hace).\
       Para APIs JSON, el riesgo de XSS se traslada al frontend que\
       consume el JSON y lo renderiza. Validar salidas si es\
       necesario. `Content-Security-Policy` (CSP) header.
     * **Server-Side Request Forgery (SSRF):** Si el servicio hace\
       peticiones a URLs proporcionadas por el usuario o derivadas\
       de la entrada del usuario, validar y sanitizar\
       cuidadosamente esas URLs. Usar listas blancas de\
       dominios/IPs permitidos.
     * FastAPI, por defecto, con Pydantic y buenas prácticas, ya\
       mitiga varios riesgos, pero la concienciación y pruebas son\
       clave.
* **Protección de Endpoints WebSocket:** Los WebSockets proporcionan\
  comunicación bidireccional y persistente, lo que introduce desafíos\
  de seguridad adicionales.
  1. **Autenticación:**
     * **No se pueden usar cabeceras `Authorization` directamente**\
       en la conexión WebSocket inicial de la misma manera que en\
       HTTP después del handshake.
     * **Opciones Comunes:**
       * **Token en Query Parameter durante el Handshake:**`ws://example.com/ws?token=YOUR_JWT_HERE` Menos seguro\
         porque el token puede quedar en logs del servidor,\
         proxies, o historial del navegador. Usar solo sobre WSS\
         (WebSocket Secure).
       * **Token en Cookie durante el Handshake:** Si el\
         WebSocket se origina desde una página web en el mismo\
         dominio (o con `SameSite` bien configurado), el\
         navegador podría enviar cookies. El servidor puede leer\
         la cookie durante el handshake.
       * **Autenticación HTTP Inicial y luego Upgrade:** El\
         cliente primero se autentica a través de un endpoint\
         HTTP normal (obteniendo un ticket/token de sesión de\
         corta duración específico para WebSocket) y luego usa\
         ese ticket para la conexión WebSocket.
       * **Autenticación a Nivel de Subprotocolo:** Enviar un\
         mensaje de autenticación (con el token) como el primer\
         mensaje después de establecer la conexión WebSocket,\
         usando un subprotocolo acordado. El servidor valida el\
         token y solo entonces permite más comunicación.
     * **FastAPI y Autenticación WebSocket:** Se puede usar una\
       dependencia en la función de endpoint WebSocket para manejar\
       la autenticación.

```python
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Depends, status, HTTPException
            # from .auth import get_current_user_from_token_in_query_or_cookie # Función de autenticación adaptada

            app = FastAPI()

            async def get_current_user_ws(
                websocket: WebSocket,
                token: str | None = Query(None, alias="jwt_token"), # Desde query param
                # session: str | None = Cookie(None) # O desde cookie
            ) -> dict: # Devuelve payload del usuario
                if not token: # y no session
                    await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Missing token")
                    # Nota: cerrar el websocket desde la dependencia puede no ser ideal en todos los escenarios.
                    # Podrías devolver un valor especial y que el endpoint lo maneje,
                    # o lanzar una excepción que un manejador de excepciones de websocket capture.
                    # Para este ejemplo, cerramos y lanzamos para detener.
                    raise WebSocketDisconnect(code=status.WS_1008_POLICY_VIOLATION, reason="Missing token")

                # Aquí iría la lógica para validar el 'token' (ej. JWT)
                # similar a `get_current_user` para HTTP, pero adaptada.
                # Por simplicidad, simulamos:
                if token == "valid_jwt_for_user123":
                    return {"sub": "user123", "roles": ["chat_user"]}

                await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Invalid token")
                raise WebSocketDisconnect(code=status.WS_1008_POLICY_VIOLATION, reason="Invalid token")


            @app.websocket("/ws/{chat_room}")
            async def websocket_endpoint(
                websocket: WebSocket,
                chat_room: str,
                # La dependencia se ejecuta cuando se acepta la conexión
                user_payload: dict = Depends(get_current_user_ws)
            ):
                await websocket.accept()
                username = user_payload.get("sub")
                print(f"User {username} connected to chat room {chat_room}")
                try:
                    while True:
                        data = await websocket.receive_text()
                        # Validar y procesar 'data' aquí
                        # Aplicar autorización si es necesario para acciones específicas
                        await websocket.send_text(f"User {username} in room {chat_room} says: {data}")
                except WebSocketDisconnect:
                    print(f"User {username} disconnected from chat room {chat_room}")
                except Exception as e:
                    print(f"Error in websocket for user {username}: {e}")
                    await websocket.close(code=status.WS_1011_INTERNAL_ERROR, reason=f"Server error: {type(e).__name__}")
```

1. **Autorización:** \* Una vez autenticado, aplicar lógica de RBAC o\
   scopes para las acciones que el usuario intenta realizar a través\
   del WebSocket. \* El payload del usuario (con roles/scopes) obtenido\
   durante la autenticación se puede usar para esto.
   1. **Validación de Mensajes (Input/Output):**
      * Los mensajes recibidos del cliente a través del WebSocket\
        deben ser validados rigurosamente (contenido, tipo, tamaño)\
        antes de ser procesados, similar a los cuerpos de solicitud\
        HTTP. Se pueden usar modelos Pydantic.
      * Igualmente, validar los mensajes enviados al cliente.
   2. **WSS (WebSocket Secure):**
      * Siempre usar `wss://` en producción. Esto es WebSocket sobre\
        TLS, proporcionando cifrado. La configuración es similar a\
        HTTPS (mismo certificado y clave).
   3. **Validación de Origen (Origin Validation):**
      * Durante el handshake WebSocket, el navegador envía una\
        cabecera `Origin`. El servidor debe validar esta cabecera\
        para asegurar que la conexión proviene de un origen\
        permitido, similar a CORS para HTTP, pero las políticas de\
        WebSocket son un poco diferentes y no usan todas las\
        cabeceras CORS. FastAPI puede acceder a`websocket.headers.get("origin")`.
   4. **Gestión de Estado de Conexión Segura:**
      * Manejar cuidadosamente la creación y destrucción de recursos\
        asociados a una conexión WebSocket.
      * Asegurar la limpieza adecuada cuando una conexión se cierra\
        (normal o anormalmente).
   5. **Protección contra DoS/DDoS:**
      * **Límites de Tamaño de Mensaje:** Imponer límites al tamaño\
        de los mensajes que se pueden enviar/recibir.
      * **Límites de Conexión:** Limitar el número de conexiones\
        WebSocket concurrentes por IP o por usuario autenticado.
      * **Rate Limiting de Mensajes:** Limitar la frecuencia con la\
        que un cliente puede enviar mensajes.
      * Herramientas a nivel de infraestructura (WAFs, CDNs) pueden\
        ayudar.

## 5.7 Rotación de claves y secretos

Las claves y secretos (API keys, contraseñas de bases de datos, claves\
de firma de JWT, claves de cifrado, etc.) son fundamentales para la\
seguridad. Si un secreto se compromete y no se rota, un atacante puede\
tener acceso persistente. La rotación regular de secretos es una\
práctica de seguridad crítica.

* **Importancia:**
  * **Limita la Ventana de Exposición:** Si una clave es\
    comprometida (ej. por una fuga de datos, un empleado deshonesto,\
    un error de configuración), la rotación asegura que la clave\
    robada solo sea válida por un tiempo limitado.
  * **Cumplimiento Normativo:** Algunas regulaciones (ej. PCI DSS)\
    exigen la rotación periódica de claves.
  * **Reduce el Riesgo de Claves Débiles o Antiguas:** Fuerza la\
    regeneración con algoritmos o longitudes potencialmente más\
    fuertes.
  * **Parte de "Defense in Depth":** Es una capa adicional de\
    seguridad.
* **Tipos de Secretos a Rotar:**
  * Claves de firma de JWT (el `SECRET_KEY` para HS256, o el par de\
    claves para RS256).
  * Contraseñas de bases de datos y otros servicios backend.
  * API keys (tanto las que tu servicio consume de terceros, como\
    las que tu servicio emite).
  * Claves de cifrado simétricas y asimétricas usadas para proteger\
    datos en reposo.
  * Credenciales de acceso a servicios cloud (aunque aquí se\
    prefiere usar roles IAM con permisos temporales si es posible).
  * Secretos de configuración (ej. tokens de acceso para\
    integraciones).
* **Políticas de Rotación:**
  * **Frecuencia:** Debe basarse en el riesgo y la sensibilidad del\
    secreto.
    * Secretos muy críticos (ej. clave de firma de JWT raíz): cada\
      3-12 meses.
    * Contraseñas de BD: cada 3-6 meses.
    * API keys: según la política del proveedor o internamente\
      cada 6-12 meses.
  * **Automatización:** Siempre que sea posible, automatizar el\
    proceso de rotación para reducir el error humano y asegurar la\
    consistencia. Los sistemas de gestión de secretos (ver 5.8) a\
    menudo ayudan con esto.
  * **Responsabilidad:** Definir claramente quién es responsable de\
    la rotación de cada tipo de secreto.
* **Proceso General de Rotación (con Período de Transición):** El\
  objetivo es rotar sin causar tiempo de inactividad (zero-downtime\
  rotation).
  1. **Generación de la Nueva Clave/Secreto:**
     * Crear una nueva clave/secreto fuerte.
  2. **Distribución/Despliegue de la Nueva Clave:**
     * Distribuir la nueva clave a todas las aplicaciones,\
       servicios o instancias que la necesiten.
     * Las aplicaciones deben ser capaces de usar la nueva clave _y_\
       _también seguir reconociendo la clave antigua_ durante un\
       período de transición.
  3. **Período de Transición (Coexistencia de Claves):**
     * **Para Firmas (ej. JWT):**
       * El servicio de autenticación comienza a firmar lo&#x73;_&#x6E;uevos_ JWTs con la _nueva_ clave privada (para RS256)\
         o nuevo secreto (para HS256).
       * Los servicios de recursos (validadores de JWT) deben ser\
         capaces de verificar firmas hechas con la _nueva_ clave\
         Y con la _clave antigua_ (la inmediatamente anterior).\
         Esto se puede lograr teniendo una lista de\
         claves/secretos de validación activos.
     * **Para Contraseñas de BD / API Keys Consumidas:**
       * Actualizar la configuración de la aplicación para usar\
         la nueva contraseña/API key.
       * El servicio externo (BD, API de tercero) debe permitir\
         que la nueva credencial funcione.
  4. **Activación Completa de la Nueva Clave:**
     * Después de que todas las aplicaciones estén usando la nueva\
       clave para generar nuevas firmas/tokens o para autenticarse,\
       y que los tokens/sesiones firmados con la clave antigua\
       hayan expirado o se considere seguro invalidarlos.
  5. **Desaprovisionamiento/Revocación de la Clave Antigua:**
     * Eliminar la clave antigua de la lista de claves de\
       validación activas.
     * Revocar la contraseña/API key antigua en el sistema externo.
     * Archivar de forma segura la clave antigua si es necesario\
       para descifrar datos históricos (si aplica y si no se\
       re-cifraron los datos).
  6. **Monitorización:** Monitorizar errores de\
     autenticación/autorización después de la rotación para detectar\
     problemas.
* **Consideraciones para JWT:**
  * **`kid` (Key ID) en el Header del JWT:** Para algoritmos\
    asimétricos (RS256), es útil incluir un `kid` en el header del\
    JWT. El `kid` identifica qué clave pública se debe usar para\
    verificar la firma. El servicio validador puede tener un\
    conjunto de claves públicas activas (JWKS - JSON Web Key Set), y\
    usa el `kid` del token para seleccionar la correcta. Esto\
    facilita la rotación de claves de firma sin problemas.
  * Los servicios pueden obtener el JWKS de un endpoint bien\
    conocido del servidor de autenticación (ej.`/.well-known/jwks.json`).

## 5.8 Gestión de credenciales con Vault o AWS Secrets Manager

Almacenar secretos (contraseñas, API keys, certificados, claves de\
cifrado, etc.) directamente en archivos de configuración, código fuente,\
o variables de entorno no seguras es una mala práctica y un riesgo de\
seguridad significativo. Los Sistemas de Gestión de Secretos (Secrets\
Management Systems) proporcionan una solución centralizada y segura.

* **Problemas con la Gestión de Secretos Tradicional:**
  * **Exposición en Repositorios de Código:** Si se cometen\
    accidentalmente al control de versiones.
  * **Dispersión de Secretos:** Secretos esparcidos en múltiples\
    lugares, difíciles de auditar y rotar.
  * **Acceso No Controlado:** Difícil restringir quién o qué puede\
    acceder a los secretos.
  * **Rotación Manual y Propensa a Errores.**
* **Propósito de un Sistema de Gestión de Secretos:**
  * **Almacenamiento Seguro:** Cifrado de secretos en reposo.
  * **Control de Acceso Estricto:** Políticas granulares para\
    definir qué aplicaciones, usuarios o roles pueden acceder a qué\
    secretos. Autenticación y autorización para el acceso a los\
    secretos.
  * **Auditoría Detallada:** Logs de quién accedió a qué secreto y\
    cuándo.
  * **Gestión Centralizada:** Un único lugar para gestionar y rotar\
    secretos.
  * **Secretos Dinámicos (en algunos sistemas):** Capacidad de\
    generar credenciales temporales y de corto plazo bajo demanda\
    (ej. para bases de datos).
  * **Automatización de la Rotación:** Algunos sistemas pueden\
    integrarse con servicios backend (ej. bases de datos) para rotar\
    sus credenciales automáticamente.
* **HashiCorp Vault:**
  * **Descripción:** Una herramienta de gestión de secretos muy\
    popular y potente, open-source con una versión enterprise.
  * **Características Clave:**
    * **Secret Engines (Motores de Secretos):** Diferentes\
      backends para almacenar y generar secretos (ej. Key/Value,\
      Databases para secretos dinámicos, AWS, PKI para\
      certificados).
    * **Authentication Methods (Métodos de Autenticación):**\
      Múltiples formas para que las aplicaciones y usuarios se\
      autentiquen en Vault y obtengan un token de Vault (ej.\
      Tokens, AppRole, AWS EC2/IAM, Kubernetes, LDAP).
    * **Policies (Políticas):** Definen qué rutas (secretos) puede\
      acceder una identidad autenticada y con qué permisos (crear,\
      leer, actualizar, eliminar, listar).
    * **Cifrado:** Vault cifra los secretos en reposo y requiere\
      un proceso de "unseal" (desellado) al iniciarse para\
      cargar la clave maestra de cifrado.
    * **Leasing y Renovación:** Los secretos (especialmente los\
      dinámicos) tienen un "lease" (tiempo de vida) y pueden ser\
      renovados o revocados.
  * **Cómo las Aplicaciones Recuperan Secretos de Vault:**
    1. La aplicación se autentica en Vault usando un método\
       configurado (ej. rol de AppRole, token de Kubernetes Service\
       Account).
    2. Vault devuelve un token de cliente de Vault (con un lease).
    3. La aplicación usa este token de cliente para leer los\
       secretos que necesita de las rutas permitidas por su\
       política.
    4. La aplicación debe renovar su token de cliente de Vault\
       antes de que expire.
    5. Bibliotecas cliente de Vault (ej. `hvac` para Python)\
       facilitan esta interacción.
    6. **Agent de Vault:** Un proceso que puede ejecutarse junto a\
       la aplicación para facilitar la autenticación y la\
       recuperación/cacheo de secretos, exponiéndolos a la\
       aplicación a través de un archivo o una interfaz local.
* **AWS Secrets Manager:**
  * **Descripción:** Un servicio gestionado de AWS para la gestión\
    de secretos.
  * **Características Clave:**
    * **Integración con AWS IAM:** El acceso a los secretos se\
      controla mediante políticas de IAM. Las aplicaciones que\
      corren en AWS (EC2, ECS, Lambda) pueden usar roles IAM para\
      autenticarse y acceder a los secretos.
    * **Cifrado Automático:** Los secretos se cifran en reposo\
      usando AWS KMS (Key Management Service).
    * **Rotación Automática de Secretos:** Para ciertos tipos de\
      secretos (ej. credenciales de Amazon RDS, Redshift,\
      DocumentDB), Secrets Manager puede rotar las contraseñas\
      automáticamente usando funciones Lambda de rotación\
      predefinidas o personalizadas.
    * **Versionado de Secretos:** Mantiene versiones de los\
      secretos, permitiendo la recuperación de versiones\
      anteriores si es necesario.
    * **Replicación Multi-Región (opcional).**
  * **Cómo las Aplicaciones Recuperan Secretos de AWS Secrets**\
    **Manager:**
    1. La aplicación (ej. un servicio FastAPI en ECS o Lambda)\
       asume un rol IAM que tiene permisos para leer secretos\
       específicos de Secrets Manager.
    2. Usando el SDK de AWS (ej. `boto3` para Python), la\
       aplicación llama a la API de Secrets Manager (ej.`get_secret_value`) para recuperar el valor del secreto.
    3. Se recomienda cachear los secretos recuperados en la\
       aplicación (con un TTL) para reducir la latencia y el coste\
       de las llamadas a la API, refrescándolos periódicamente o\
       cuando la caché expire.
* **Otras Alternativas Populares:**
  * **Azure Key Vault:** Servicio gestionado de Microsoft Azure.
  * **Google Cloud Secret Manager:** Servicio gestionado de Google\
    Cloud.
  * **SOPS (Secrets OPerationS):** Herramienta open-source de\
    Mozilla para cifrar archivos de secretos (JSON, YAML) usando\
    KMS, GPG, PGP, etc., y cometerlos al repositorio de código de\
    forma segura (solo el archivo cifrado). La clave de descifrado\
    se gestiona por separado.
* **Integración de FastAPI con Sistemas de Gestión de Secretos:**
  * **Al Inicio de la Aplicación:** La estrategia más común es que\
    la aplicación FastAPI, durante su secuencia de inicio (ej. en un\
    evento `startup` o antes de que Uvicorn inicie completamente la\
    app), se conecte al sistema de gestión de secretos y recupere\
    todas las credenciales necesarias, almacenándolas en su\
    configuración en memoria.
  * **Recuperación Dinámica (menos común para todos los secretos):**\
    Para secretos que rotan muy frecuentemente o para escenarios de\
    "just-in-time access", se podrían recuperar por solicitud,\
    pero esto añade latencia y complejidad (se necesitaría un cacheo\
    agresivo).
  * **Variables de Entorno Inyectadas (en PaaS/CaaS):** Plataformas\
    como Kubernetes pueden integrar sistemas de secretos (ej. Vault,\
    Kubernetes Secrets) para montar secretos como archivos o\
    inyectarlos como variables de entorno en los contenedores de la\
    aplicación. La aplicación FastAPI luego lee estos archivos o\
    variables de entorno. Esta es una abstracción común.

```python
# Ejemplo conceptual de carga de secretos al inicio en FastAPI (usando variables de entorno que podrían ser inyectadas por un sistema de secretos)
    import os
    from fastapi import FastAPI
    from pydantic_settings import BaseSettings # Para cargar configuración

    class AppSettings(BaseSettings):
        app_name: str = "My Secure FastAPI App"
        database_url: str # Ej: "postgresql://user:password@host:port/db"
        api_key_external_service: str
        jwt_secret_key: str

        class Config:
            env_file = ".env" # Opcional, para desarrollo local
            # En producción, estas variables serían inyectadas por el entorno (Kubernetes, Docker Compose, etc.)
            # que a su vez podría obtenerlas de Vault, AWS Secrets Manager, etc.

    settings = AppSettings() # Carga la configuración (y los secretos) al inicio
    app = FastAPI()

    @app.on_event("startup")
    async def startup_event():
        print(f"Aplicación iniciada. Usando BD: {settings.database_url[:20]}...") # No loggear el secreto completo
        print(f"JWT Secret Key cargado (longitud): {len(settings.jwt_secret_key)}")
        # Aquí podrías inicializar conexiones a BD usando settings.database_url, etc.

    @app.get("/config_check")
    async def config_check():
        # ¡NUNCA exponer secretos en un endpoint así en producción! Solo para demo.
        return {
            "db_url_prefix": settings.database_url.split('@')[0] if '@' in settings.database_url else "N/A",
            "api_key_loaded": bool(settings.api_key_external_service),
            "jwt_secret_loaded": bool(settings.jwt_secret_key)
        }
```

## 5.9 Análisis de vulnerabilidades OWASP

El Open Web Application Security Project (OWASP) es una comunidad online\
sin ánimo de lucro que produce artículos, metodologías, documentación,\
herramientas y tecnologías en el campo de la seguridad de aplicaciones\
web. Su proyecto más conocido es el **OWASP Top 10**.

*   **OWASP Top 10:** Es un documento de concienciación estándar para\
    desarrolladores y seguridad de aplicaciones web. Representa un\
    amplio consenso sobre los riesgos de seguridad más críticos para las\
    aplicaciones web (y, por extensión, APIs). La lista se actualiza\
    periódicamente. Aunque se centra en "aplicaciones web", muchos de\
    los riesgos son directamente aplicables a microservicios y APIs\
    REST/WebSocket.

    **Algunas Categorías del OWASP Top 10 (ej. de la lista 2021) y su**\
    **Relevancia para Microservicios/APIs:**

    1. **A01:2021 - Broken Access Control (Control de Acceso Roto):**
       * **Descripción:** Restricciones sobre lo que los usuarios\
         autenticados pueden hacer no se aplican correctamente. Los\
         atacantes pueden explotar estos fallos para acceder a\
         funcionalidades y/o datos no autorizados.
       * **Relevancia en Microservicios:** Fallos en la\
         implementación de RBAC (roles), scopes, o validaciones de\
         propiedad de recursos. Endpoints que no verifican\
         adecuadamente si el usuario autenticado tiene permiso para\
         la acción o el recurso específico.
       * **Mitigación con FastAPI:** Implementar autorización robusta\
         (ver 5.2), usar dependencias para verificar permisos en cada\
         endpoint relevante, pruebas exhaustivas de los flujos de\
         autorización.
    2. **A02:2021 - Cryptographic Failures (Fallos Criptográficos):**
       * **Descripción:** Fallos relacionados con la criptografía (o\
         su ausencia) que pueden llevar a la exposición de datos\
         sensibles. Esto incluye la transmisión de datos en texto\
         plano, uso de algoritmos débiles, mala gestión de claves.
       * **Relevancia en Microservicios:** No usar HTTPS para toda la\
         comunicación (externa e interna si es posible), uso de\
         algoritmos de firma de JWT débiles (ej. `alg: none` o HS256\
         con secretos débiles), almacenamiento inseguro de secretos,\
         cifrado incorrecto de datos en reposo.
       * **Mitigación:** Usar HTTPS/mTLS (5.3), algoritmos de firma\
         JWT fuertes (RS256/ES256), gestión segura de claves (5.7,\
         5.8), cifrado de datos sensibles en BBDD.
    3. **A03:2021 - Injection (Inyección):**
       * **Descripción:** Fallos que permiten a un atacante enviar\
         datos hostiles a un intérprete (SQL, OS, NoSQL, LDAP, XSS,\
         etc.) como parte de un comando o consulta.
       * **Relevancia en Microservicios:**
         * **SQL Injection:** Si se construyen queries SQL\
           concatenando strings con input del usuario.
         * **NoSQL Injection:** Similar, para bases de datos NoSQL.
         * **OS Command Injection:** Si se usan inputs del usuario\
           para construir comandos del sistema operativo.
         * **Cross-Site Scripting (XSS Reflejado/Almacenado):** Más\
           relevante si la API devuelve HTML o si los datos\
           almacenados por la API se renderizan sin escapar en un\
           frontend. Para APIs JSON, el riesgo principal es que el\
           frontend sea vulnerable.
       * **Mitigación con FastAPI:**
         * **Pydantic para validación de tipos y formatos:** Ayuda\
           a asegurar que los datos tienen la forma esperada antes\
           de usarlos.
         * **Usar ORMs parametrizados (SQLAlchemy):** Previenen\
           SQLi al separar los datos de las queries.
         * **Validación de entrada estricta (5.4).**
         * Evitar ejecutar comandos del sistema operativo con input\
           del usuario.
         * Para XSS en APIs JSON: Asegurar que los frontends que\
           consumen la API escapen correctamente los datos antes de\
           renderizarlos. `response_model` puede ayudar a no\
           filtrar datos inesperados.
    4. **A04:2021 - Insecure Design (Diseño Inseguro):**
       * **Descripción:** Una categoría más amplia que se enfoca en\
         las debilidades resultantes de un diseño de seguridad\
         deficiente o ausente. Falta de modelado de amenazas,\
         requisitos de seguridad no considerados, etc.
       * **Relevancia en Microservicios:** No tener una estrategia de\
         seguridad global, flujos de autenticación/autorización\
         débiles, falta de aislamiento entre servicios, confianza\
         implícita en la red interna.
       * **Mitigación:** Modelado de amenazas, "security by\
         design", aplicar principios de seguridad (mínimo\
         privilegio, defensa en profundidad), revisiones de diseño de\
         seguridad.
    5. **A05:2021 - Security Misconfiguration (Configuración Incorrecta**\
       **de Seguridad):**
       * **Descripción:** Configuraciones de seguridad por defecto\
         inseguras, configuraciones incompletas o ad-hoc, mensajes de\
         error verbosos que revelan información, servicios o\
         funcionalidades innecesarias habilitadas.
       * **Relevancia en Microservicios:** CORS demasiado permisivo\
         (5.5), no deshabilitar modos DEBUG en producción, puertos\
         innecesarios abiertos, permisos de ficheros/directorios\
         incorrectos, gestión de errores que expone stack traces\
         (4.1, 4.2).
       * **Mitigación:** Hardening de la configuración de todos los\
         componentes (servidor web/ASGI, base de datos, sistema\
         operativo, cloud), infraestructura como código (IaC) con\
         linters de seguridad, auditorías de configuración.
    6. **A06:2021 - Vulnerable and Outdated Components (Componentes**\
       **Vulnerables y Desactualizados):**
       * **Descripción:** Usar software (frameworks, bibliotecas, SO,\
         aplicaciones) con vulnerabilidades conocidas.
       * **Relevancia en Microservicios:** Dependencias de Python\
         desactualizadas (`requirements.txt`), imágenes base de\
         Docker obsoletas, versiones antiguas de bases de datos o\
         proxies.
       * **Mitigación:** Gestión de parches, análisis de composición\
         de software (SCA) para identificar dependencias vulnerables\
         (ej. `pip-audit`, `safety`, Snyk, Dependabot/GitHub Advanced\
         Security), actualizar regularmente las dependencias y la\
         infraestructura.
    7. **A07:2021 - Identification and Authentication Failures (Fallos**\
       **de Identificación y Autenticación):**
       * **Descripción:** Funciones de aplicación relacionadas con la\
         autenticación y gestión de sesión implementadas\
         incorrectamente, permitiendo a los atacantes comprometer\
         contraseñas, claves, tokens de sesión, o explotar fallos de\
         implementación para asumir identidades de otros usuarios.
       * **Relevancia en Microservicios:** Políticas de contraseñas\
         débiles (si se gestionan usuarios), JWTs sin expiración o\
         con expiración muy larga, gestión insegura de refresh\
         tokens, endpoints de login vulnerables a enumeración de\
         usuarios o ataques de fuerza bruta, falta de multi-factor\
         authentication (MFA).
       * **Mitigación:** Implementación robusta de JWT (5.1), MFA,\
         políticas de contraseñas fuertes, protección contra fuerza\
         bruta (rate limiting en login - 5.11), gestión segura de\
         sesiones/tokens.
    8. **A08:2021 - Software and Data Integrity Failures (Fallos de**\
       **Integridad de Software y Datos):**
       * **Descripción:** Código y infraestructura que no protegen\
         contra violaciones de integridad. Por ejemplo, confiar en\
         plugins o bibliotecas de fuentes no seguras, o la\
         deserialización insegura de datos.
       * **Relevancia en Microservicios:** Descargar dependencias de\
         Python de repositorios no confiables, deserialización de\
         datos no validados (aunque Pydantic ayuda mucho aquí), falta\
         de verificación de firmas en actualizaciones de software.
       * **Mitigación:** Usar fuentes de confianza para dependencias,\
         verificar hashes/firmas, validación estricta de cualquier\
         dato serializado antes de procesarlo.
    9. **A09:2021 - Security Logging and Monitoring Failures (Fallos de**\
       **Registro y Monitorización de Seguridad):**
       * **Descripción:** Registro y monitorización insuficientes de\
         eventos de seguridad, lo que dificulta la detección de\
         brechas, la respuesta a incidentes y el análisis forense.
       * **Relevancia en Microservicios:** Falta de auditoría (5.10),\
         logs sin suficiente contexto o sin correlation IDs (4.8),\
         alertas no configuradas para actividades sospechosas o\
         fallos críticos.
       * **Mitigación:** Implementar logging y auditoría exhaustivos,\
         monitorización de seguridad y alertas (SIEM), practicar la\
         respuesta a incidentes.
    10. **A10:2021 - Server-Side Request Forgery (SSRF):**
        * **Descripción:** Un fallo que permite a un atacante inducir\
          a una aplicación del lado del servidor a realizar peticiones\
          HTTP a un dominio elegido por el atacante. Puede usarse para\
          escanear redes internas, acceder a metadatos de instancia en\
          la nube, o interactuar con servicios internos no expuestos.
        * **Relevancia en Microservicios:** Si un microservicio toma\
          una URL (o parte de ella) de la entrada del usuario (o de\
          otro servicio) y luego realiza una petición a esa URL sin la\
          validación adecuada.
        * **Mitigación:**
          * Nunca confiar en URLs proporcionadas por el usuario.
          * Validar estrictamente cualquier URL contra una lista\
            blanca de dominios, IPs, y puertos permitidos.
          * Evitar que las respuestas de las peticiones inducidas\
            por SSRF se devuelvan directamente al cliente.
          * Usar firewalls de red y de aplicación para restringir\
            las capacidades de red saliente de los microservicios al\
            mínimo necesario.
* **Cómo FastAPI Ayuda y Dónde se Requiere Cuidado Adicional:**
  * **Fortalezas de FastAPI:**
    * **Validación de Tipos y Datos con Pydantic:** Mitiga\
      enormemente los riesgos de inyección y errores de\
      procesamiento de datos (A03, A08).
    * **Utilidades de Seguridad Integradas:** Para OAuth2, JWT,\
      API keys, facilitando la implementación de autenticación\
      (A07).
    * **Generación Automática de Esquemas OpenAPI:** Promueve\
      contratos API claros, lo que indirectamente ayuda a la\
      seguridad al definir claramente las interfaces.
  * **Áreas de Cuidado Adicional (Responsabilidad del**\
    **Desarrollador):**
    * **Lógica de Autorización (Control de Acceso):** FastAPI\
      proporciona las herramientas, pero la lógica correcta de\
      RBAC/scopes debe ser implementada por el desarrollador\
      (A01).
    * **Gestión de Secretos y Configuración Segura:** (A02, A05,\
      A07).
    * **HTTPS y Seguridad de Red:** (A02).
    * **Manejo de Dependencias y Componentes:** (A06).
    * **Logging y Monitorización:** (A09).
    * **Lógica de Negocio Específica:** Prevenir SSRF si se\
      manejan URLs, lógica de negocio segura.
* **Pruebas de Seguridad Continuas:**
  * **SAST (Static Application Security Testing):** Analizar el\
    código fuente en busca de patrones de vulnerabilidades\
    conocidos. Herramientas como SonarQube, Bandit (para Python).
  * **DAST (Dynamic Application Security Testing):** Probar la\
    aplicación en ejecución enviando peticiones maliciosas\
    simuladas. Herramientas como OWASP ZAP, Burp Suite.
  * **SCA (Software Composition Analysis):** Analizar dependencias\
    para identificar vulnerabilidades conocidas (ver A06).
  * **Penetration Testing (Pruebas de Penetración):** Contratar a\
    expertos para que intenten explotar vulnerabilidades de forma\
    manual y creativa.
  * **Revisiones de Código con Enfoque en Seguridad.**

## 5.10 Auditoría y trazabilidad de usuarios

La auditoría y la trazabilidad de las acciones de los usuarios (y de los\
servicios) son cruciales para la seguridad, el cumplimiento normativo y\
la resolución de problemas. Un registro de auditoría (audit trail) es un\
registro cronológico y seguro de eventos.

* **Importancia:**
  * **Rendición de Cuentas (Accountability):** Saber quién hizo qué\
    y cuándo.
  * **Detección de Incidentes y Análisis Forense:** Si ocurre una\
    brecha de seguridad o un incidente, los logs de auditoría son\
    vitales para entender cómo ocurrió, qué se vio afectado y el\
    alcance del daño.
  * **Cumplimiento Normativo:** Muchas regulaciones (GDPR, HIPAA,\
    SOX, PCI DSS) exigen registros de auditoría para ciertas\
    actividades y acceso a datos.
  * **Detección de Actividad Sospechosa o Maliciosa:** Patrones\
    anómalos en los logs de auditoría pueden indicar un ataque en\
    curso o un abuso interno.
  * **Resolución de Disputas:** Proporcionar evidencia de las\
    acciones realizadas.
* **Qué Auditar (Eventos Clave):**
  1. **Eventos de Autenticación:**
     * Intentos de login exitosos y fallidos.
     * Cierres de sesión (logouts).
     * Cambios de contraseña, reseteos de contraseña.
     * Uso y fallo de Multi-Factor Authentication (MFA).
     * Creación, modificación, eliminación de cuentas de usuario.
  2. **Eventos de Autorización (Control de Acceso):**
     * Intentos de acceso a recursos o funcionalidades (tanto\
       concedidos como denegados).
     * Cambios en roles, permisos o políticas de acceso.
  3. **Operaciones de Negocio Críticas o Sensibles:**
     * Creación, modificación, eliminación de datos importantes\
       (ej. creación de un pedido, transferencia de fondos,\
       modificación de un registro de paciente).
     * Acceso a datos especialmente sensibles.
     * Transacciones financieras.
  4. **Acciones Administrativas:**
     * Cambios en la configuración del sistema o de la aplicación.
     * Inicio/parada de servicios.
     * Despliegues.
     * Acceso de administradores a datos de usuario.
  5. **Eventos de Seguridad:**
     * Alertas de seguridad generadas por otros sistemas (WAF,\
       IDS/IPS).
     * Apertura/cierre de Circuit Breakers.
     * Detección de rate limiting excesivo.
* **Contenido de una Entrada de Log de Auditoría:** Cada entrada debe\
  ser lo más completa y autocontenida posible.
  * **Timestamp:** Fecha y hora exactas del evento (con UTC y\
    timezone).
  * **Identidad del Actor:** Quién realizó la acción.
    * ID de Usuario, nombre de usuario.
    * ID de Servicio (si la acción fue realizada por otro\
      servicio).
    * Dirección IP de origen (con cuidado de la privacidad si es\
      de usuarios finales).
  * **Acción Realizada (Evento):** Qué se hizo (ej. `user_login`,`create_order`, `delete_product`,`access_denied_to_admin_panel`). Usar nombres de evento\
    consistentes y descriptivos.
  * **Recurso Afectado:** Sobre qué entidad o recurso se realizó la\
    acción (ej. `order_id=123`, `product_id=xyz`,`user_account=abc`).
  * **Resultado/Estado de la Acción:** Éxito o fracaso. Si fracasó,\
    el motivo del fallo.
  * **Correlation ID / Trace ID:** Para vincular la auditoría con\
    otros logs y trazas del sistema.
  * **Información de Contexto Adicional:** Cualquier otro dato\
    relevante para entender el evento (ej. valores antiguos y nuevos\
    de un campo modificado, si es seguro loguearlo).
* **Características de un Sistema de Log de Auditoría Seguro:**
  * **Inmutabilidad/Tamper-Evidence:** Los logs de auditoría, una\
    vez escritos, no deben poder ser modificados o eliminados por\
    usuarios no autorizados (incluyendo administradores del sistema\
    si es posible). Usar técnicas como append-only, firmas digitales\
    de logs, o servicios de logging especializados.
  * **Integridad:** Asegurar que no se pierdan mensajes de log.
  * **Disponibilidad:** Los logs deben estar disponibles para\
    análisis cuando se necesiten.
  * **Confidencialidad:** Proteger los logs de auditoría contra\
    acceso no autorizado, ya que pueden contener información\
    sensible.
  * **Retención:** Definir políticas claras de cuánto tiempo se\
    deben conservar los logs de auditoría, según los requisitos de\
    negocio y cumplimiento.
  * **Sincronización de Tiempo:** Todos los servicios deben tener\
    sus relojes sincronizados (usando NTP) para que los timestamps\
    en los logs sean consistentes y correlacionables.
* **Herramientas para Auditoría y Trazabilidad:**
  * **Sistemas de Agregación de Logs:** (ELK Stack, Splunk, Loki)\
    pueden usarse para recolectar y analizar logs de auditoría, pero\
    pueden necesitar configuración adicional para asegurar la\
    inmutabilidad.
  * **SIEM (Security Information and Event Management):** Sistemas\
    especializados en la recolección, análisis, correlación y alerta\
    de eventos de seguridad y logs de auditoría (ej. Splunk\
    Enterprise Security, QRadar, Azure Sentinel, Elastic SIEM).
  * **Bases de Datos con Capacidades de Auditoría:** Algunas bases\
    de datos ofrecen funcionalidades de auditoría integradas.
  * **Tecnología Blockchain/Libro Mayor Distribuido (DLT):** Para\
    casos que requieren una inmutabilidad y transparencia\
    extremadamente altas, aunque es más complejo.
* **Integración de Auditoría en Aplicaciones FastAPI:**
  1. **Middleware:** Un middleware de FastAPI puede interceptar todas\
     las solicitudes y respuestas para loguear automáticamente\
     ciertos eventos de acceso (quién accedió a qué endpoint, con qué\
     resultado).
  2. **Decoradores:** Se pueden crear decoradores para aplicarlos a\
     funciones de ruta o métodos de servicio específicos que realizan\
     operaciones críticas, para loguear la acción antes y después de\
     su ejecución.
  3. **Llamadas Explícitas a un Servicio de Auditoría/Logging:** En\
     la lógica de negocio, después de realizar una acción auditable,\
     llamar explícitamente a una función o servicio que registre el\
     evento de auditoría. Esto permite el máximo control sobre el\
     contenido del log.
  4. **Hooks de Eventos de Framework/ORM:** Si se usa un ORM como\
     SQLAlchemy, se pueden usar sus hooks de eventos para auditar\
     cambios en los datos a nivel de base de datos.

```python
# Ejemplo conceptual de logging de auditoría en FastAPI
    import logging
    from fastapi import FastAPI, Request, Depends, HTTPException
    from pydantic import BaseModel
    from datetime import datetime, timezone
    # from .auth import get_current_user_payload # Asumiendo una dependencia de autenticación

    # Configurar un logger específico para auditoría
    audit_logger = logging.getLogger("audit")
    audit_logger.setLevel(logging.INFO)
    # Configurar handlers para el audit_logger para que escriba a un archivo separado o a un sistema de logs
    # (ej. un FileHandler que escriba JSON) - omitido por brevedad.
    # Si no se configura, usará la configuración del logger raíz.
    # Para el ejemplo, imprimirá a consola si el logger raíz está configurado.
    if not audit_logger.handlers: # Asegurar que tenga al menos un handler para la demo
        handler = logging.StreamHandler()
        formatter = logging.Formatter('%(asctime)s - AUDIT - %(levelname)s - %(message)s')
        handler.setFormatter(formatter)
        audit_logger.addHandler(handler)


    app = FastAPI()

    # Simulación de get_current_user para el ejemplo
    async def get_current_user_payload_audit_sim(request: Request) -> dict | None:
        # En un caso real, esto validaría un token JWT de la cabecera Authorization
        auth_header = request.headers.get("Authorization")
        if auth_header and auth_header.startswith("Bearer test_token_"):
            user_id = auth_header.split("test_token_")[1]
            return {"sub": user_id, "roles": ["user"]}
        return None # O lanzar HTTPException si se requiere autenticación para todas las rutas auditadas

    def log_audit_event(
        actor_id: str | None,
        action: str,
        resource: str | None = None,
        status: str = "SUCCESS",
        details: dict | None = None,
        request: Request | None = None
    ):
        log_entry = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "actor_id": actor_id or "anonymous",
            "action": action,
            "resource": resource,
            "status": status,
            "source_ip": request.client.host if request else "N/A",
            "endpoint": str(request.url) if request else "N/A",
            "details": details or {}
        }
        audit_logger.info(log_entry) # Enviar como un diccionario para logging estructurado


    class ItemCreate(BaseModel):
        name: str
        description: str | None = None

    @app.post("/items_audited/")
    async def create_item_audited(
        item: ItemCreate,
        request: Request, # Inyectar Request para acceder a IP, URL
        current_user: dict | None = Depends(get_current_user_payload_audit_sim) # Usuario autenticado
    ):
        actor = current_user.get("sub") if current_user else None

        # Simular creación de ítem
        item_id = str(uuid.uuid4())
        print(f"Item '{item.name}' created with ID {item_id} by {actor}")

        log_audit_event(
            actor_id=actor,
            action="CREATE_ITEM",
            resource=f"item:{item_id}",
            status="SUCCESS",
            details={"item_name": item.name, "description": item.description},
            request=request
        )
        return {"item_id": item_id, "name": item.name}

    @app.get("/admin_action_audited")
    async def admin_action(request: Request, current_user: dict | None = Depends(get_current_user_payload_audit_sim)):
        actor = current_user.get("sub") if current_user else None
        if not actor or "admin" not in current_user.get("roles", []): # Simulación de chequeo de rol
            log_audit_event(actor, "ACCESS_ADMIN_ACTION", status="FAILURE_FORBIDDEN", request=request, details={"reason": "Not an admin"})
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not an admin")

        log_audit_event(actor, "ACCESS_ADMIN_ACTION", status="SUCCESS", request=request)
        return {"message": f"Admin action performed by {actor}"}
```

## 5.11 Configuración de rate limiting

El Rate Limiting (limitación de tasa o frecuencia) es una técnica de\
control que restringe el número de solicitudes que un cliente\
(identificado por IP, usuario, API key, etc.) puede realizar a una API\
dentro de un período de tiempo específico.

* **Propósito e Importancia:**
  1. **Protección contra Abuso:** Evita que clientes maliciosos o\
     scripts fuera de control sobrecarguen el servicio con un número\
     excesivo de solicitudes.
  2. **Prevención de Ataques de Denegación de Servicio (DoS/DDoS):**\
     Ayuda a mitigar el impacto de ataques que intentan agotar los\
     recursos del servidor mediante un alto volumen de tráfico.
  3. **Asegurar la Disponibilidad y Calidad del Servicio (Fair**\
     **Usage):** Garantiza que el servicio permanezca disponible y con\
     buen rendimiento para todos los usuarios legítimos, evitando que\
     unos pocos clientes monopolicen los recursos.
  4. **Control de Costes:** En APIs que consumen recursos costosos\
     (ej. llamadas a APIs de IA de terceros, cómputo intensivo), el\
     rate limiting puede ayudar a controlar los costes.
  5. **Cumplimiento de Cuotas de Servicio:** Para APIs públicas que\
     ofrecen diferentes niveles de servicio con cuotas.
* **Tipos de Rate Limiting (Identificación del Cliente):**
  * **Por Dirección IP:** Limitar el número de solicitudes desde una\
    misma IP. Es el más básico y puede afectar a múltiples usuarios\
    detrás de un NAT, pero es útil como primera línea de defensa.
  * **Por Usuario Autenticado / ID de Cliente:** Una vez que el\
    usuario está autenticado, se pueden aplicar límites más\
    específicos a su ID de usuario o ID de cliente. Más preciso que\
    por IP.
  * **Por API Key:** Si la API usa claves para el acceso\
    programático, cada clave puede tener su propia cuota.
  * **Por Endpoint o Grupo de Endpoints:** Aplicar límites\
    diferentes a diferentes partes de la API (ej. endpoints de login\
    pueden tener límites más estrictos, endpoints de lectura pueden\
    ser más permisivos que los de escritura).
  * **Global:** Un límite general para todo el servicio.
* **Algoritmos Comunes de Rate Limiting:**
  1. **Fixed Window Counter (Contador de Ventana Fija):**
     * Se cuenta el número de solicitudes en una ventana de tiempo\
       fija (ej. 100 solicitudes por minuto).
     * Si el contador excede el límite, se rechazan más solicitudes\
       hasta que la ventana se reinicia.
     * **Problema:** Puede permitir ráfagas de tráfico al inicio de\
       cada ventana que superen el límite promedio si todas las\
       solicitudes llegan justo cuando se reinicia la ventana.
  2. **Sliding Window Log (Registro de Ventana Deslizante):**
     * Se almacenan los timestamps de las solicitudes recibidas en\
       la última ventana de tiempo (ej. último minuto).
     * Al llegar una nueva solicitud, se descartan los timestamps\
       más antiguos que la ventana y se cuenta el número de\
       timestamps restantes. Si el conteo excede el límite, se\
       rechaza la solicitud.
     * Más preciso que la ventana fija, pero consume más memoria\
       para almacenar los timestamps.
  3. **Sliding Window Counter (Contador de Ventana Deslizante):**
     * Un híbrido que ofrece un buen compromiso. Usa contadores\
       para la ventana actual y la anterior, y estima el conteo en\
       la ventana deslizante basándose en la posición actual dentro\
       de la ventana. Menos intensivo en memoria que el log.
  4. **Token Bucket (Cubo de Fichas):**
     * Un cubo tiene una capacidad fija de "fichas" (tokens). Las\
       fichas se añaden al cubo a una tasa constante.
     * Cada solicitud entrante consume una ficha. Si no hay fichas,\
       la solicitud se rechaza (o se encola, menos común para APIs\
       síncronas).
     * Permite ráfagas de tráfico hasta la capacidad del cubo,\
       mientras que la tasa promedio a largo plazo está limitada\
       por la tasa de reposición de fichas.
  5. **Leaky Bucket (Cubo Agujereado):**
     * Las solicitudes entrantes se añaden a una cola (el cubo). El\
       cubo "gotea" (procesa solicitudes) a una tasa constante.
     * Si el cubo se llena (la cola excede su capacidad), las\
       nuevas solicitudes se descartan.
     * Suaviza las ráfagas de tráfico, forzando una tasa de salida\
       constante.
* **Implementación de Rate Limiting en FastAPI:**
  1. **A Nivel de API Gateway / Reverse Proxy:**
     * Es una ubicación común y eficiente para implementar el rate\
       limiting, ya que puede proteger múltiples instancias del\
       servicio FastAPI y aplicar políticas globales.
     * **Nginx:** Módulo `ngx_http_limit_req_module`.
     * **Traefik:** Middleware de RateLimit.
     * **Cloud Gateways:** AWS API Gateway, Azure API Management,\
       Google Cloud API Gateway, todos ofrecen funcionalidades de\
       rate limiting.
  2. **Middleware en FastAPI:**
     * Se pueden usar bibliotecas de Python como `slowapi` que se\
       integran con FastAPI como middleware.
     * `slowapi` permite definir límites basados en diferentes\
       criterios (IP, ruta, etc.) y usa un almacén (en memoria o\
       Redis) para los contadores.

```python
from fastapi import FastAPI, Request, HTTPException
        from slowapi import Limiter, _rate_limit_exceeded_handler # _rate_limit_exceeded_handler para manejar la excepción
        from slowapi.util import get_remote_address
        from slowapi.errors import RateLimitExceeded
        from starlette.status import HTTP_429_TOO_MANY_REQUESTS

        # Inicializar el limitador (usa get_remote_address para identificar por IP)
        limiter = Limiter(key_func=get_remote_address, default_limits=["100/minute"])
        # default_limits se aplica a todas las rutas no decoradas explícitamente.
        # Se puede usar un backend de Redis:
        # from slowapi.extension import RedisStore
        # limiter = Limiter(key_func=get_remote_address, storage_uri="redis://localhost:6379/0")


        app = FastAPI()

        # Registrar el estado del limitador con la app y los manejadores de excepción
        app.state.limiter = limiter
        app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
        # O un manejador personalizado:
        # @app.exception_handler(RateLimitExceeded)
        # async def custom_rate_limit_exceeded_handler(request: Request, exc: RateLimitExceeded):
        #     return JSONResponse(
        #         status_code=HTTP_429_TOO_MANY_REQUESTS,
        #         content={"detail": f"Rate limit exceeded: {exc.detail}"},
        #         headers={"Retry-After": str(exc.retry_after)} if exc.retry_after else None
        #     )


        @app.get("/limited_route")
        @limiter.limit("5/minute") # Límite específico para esta ruta: 5 por minuto por IP
        async def limited_endpoint(request: Request): # Necesitas Request para que slowapi acceda a la IP
            return {"message": "This endpoint is rate-limited (5 per minute)."}

        @app.get("/unlimited_route") # Usará el default_limits si está configurado, o sin límite si no
        async def unlimited_endpoint():
            return {"message": "This endpoint might have default rate limits or none."}

        # Ejemplo de límite basado en un identificador de usuario (si está autenticado)
        # async def get_user_identifier(request: Request) -> str:
        #     # Aquí obtendrías el ID del usuario autenticado (ej. del token JWT)
        #     # Si no está autenticado, podrías devolver la IP o un identificador de sesión anónima
        #     user = getattr(request.state, "user", None) # Asumiendo que un middleware de auth pone el user en request.state
        #     if user and hasattr(user, "username"):
        #         return user.username
        #     return get_remote_address(request)

        # user_limiter = Limiter(key_func=get_user_identifier, default_limits=["200/hour"])
        # app.state.user_limiter = user_limiter

        # @app.post("/user_specific_action")
        # @user_limiter.limit("10/hour") # Límite por usuario autenticado
        # async def user_action(request: Request):
        #     # ...
        #     return {"message": "Action performed."}
```

**Nota:** `slowapi` usa `request.state` para adjuntar información.\
Asegúrate de que tu aplicación FastAPI esté configurada para permitir\
esto si usas otros middlewares que también interactúan con`request.state`.

* **Comunicación de Límites al Cliente:**
  * **Código de Estado HTTP `429 Too Many Requests`:** Cuando se\
    excede un límite, el servidor debe devolver este código.
  * **Cabecera `Retry-After`:** Es muy recomendable incluir esta\
    cabecera en la respuesta 429. Indica cuánto tiempo (en segundos)\
    el cliente debe esperar antes de reintentar la solicitud.
  * **Cabeceras `X-RateLimit-*` (informativas, no estándar pero**\
    **comunes):**
    * `X-RateLimit-Limit`: El número total de solicitudes\
      permitidas en la ventana actual.
    * `X-RateLimit-Remaining`: El número de solicitudes restantes\
      en la ventana actual.
    * `X-RateLimit-Reset`: El tiempo (timestamp Unix o segundos\
      restantes) hasta que la ventana se reinicia y el límite se\
      restablece. Estas cabeceras ayudan a los clientes API a\
      auto-regularse y evitar ser bloqueados.
* **Políticas y Umbrales Configurables:**
  * Los límites de tasa no deben estar hardcodeados. Deben ser\
    configurables (ej. a través de variables de entorno, archivos de\
    configuración, o un panel de control) para poder ajustarlos\
    según las necesidades del servicio, el tráfico observado, y\
    diferentes planes de usuario si aplica.
  * Considerar tener límites diferentes para peticiones autenticadas\
    vs. anónimas, o para diferentes niveles de API keys.

La implementación efectiva de rate limiting es una combinación de elegir\
el algoritmo y el punto de aplicación correctos (gateway vs.\
aplicación), y comunicar claramente los límites a los consumidores de la\
API. 

---

## Reto práctico Blindando la API con SSL y CORS

#### **El Objetivo** 🎯

El objetivo es tomar la configuración del proxy inverso Nginx con SSL del punto 5.3 y añadirle una capa de seguridad adicional: una política de CORS estricta.

Al final, tu sistema deberá:
1.  Servir todo el tráfico exclusivamente a través de **HTTPS**. Cualquier intento de conectar por HTTP deberá ser redirigido automáticamente a HTTPS.
2.  Permitir que la API sea llamada únicamente desde un dominio frontend específico y seguro: `https://mi-app.com`.

#### **El Escenario** 🎬

Imagina que ya tienes tu API funcionando detrás de Nginx con un certificado auto-firmado, como vimos en el punto 5.3. El equipo de frontend acaba de desplegar su aplicación en `https://mi-app.com` y te reportan que, al intentar hacer login o llamar a cualquier endpoint, el navegador les muestra un error de CORS en la consola y la aplicación no funciona. Tu misión es solucionar este problema.

#### **Punto de Partida** 🏁

Comienza con la configuración completa del **punto 5.3 con Nginx y Docker**. Deberías tener en tu carpeta los siguientes ficheros:
* `main_sec_5_2.py` (nuestra app FastAPI con autenticación y autorización)
* `requirements.txt`
* `Dockerfile`
* `nginx.conf`
* `docker-compose.yml`
* `cert.pem` y `key.pem`

#### **El Reto: Tus Tareas** 🚀

**Tarea 1: Forzar HTTPS en Nginx**

Actualmente, nuestro Nginx escucha en el puerto 443 (HTTPS), pero no hace nada si alguien intenta acceder por el puerto 80 (HTTP). Debes modificar tu fichero `nginx.conf` para que cualquier petición que llegue al puerto 80 sea **redirigida permanentemente (código 301)** a su equivalente en HTTPS.

* **Pista:** Necesitarás añadir un nuevo bloque `server` que escuche en el `listen 80;` y use la directiva `return 301 https://$host$request_uri;`.

**Tarea 2: Configurar la Política de CORS en FastAPI**

Ahora, debes modificar tu aplicación FastAPI (`main_sec_5_2.py`) para que le diga al navegador que solo confía en las peticiones que vienen de `https://mi-app.com`.

* **Pista:** Añade el `CORSMiddleware` a tu aplicación. La configuración debe ser estricta:
    * `allow_origins`: Solo debe contener `["https://mi-app.com"]`.
    * `allow_methods`: Permite solo los métodos que tu API realmente necesita (ej: `["GET", "POST"]`).
    * `allow_headers`: Permite solo las cabeceras necesarias, como `["Authorization", "Content-Type"]`.
    * `allow_credentials`: Debe ser `True`.

**Tarea 3: Reconstruir y Probar**

Una vez hechos los cambios en `nginx.conf` y `main_sec_5_2.py`, necesitas reconstruir tu imagen de Docker para que los cambios en el código Python surtan efecto.

* **Pista:** Detén los contenedores si están corriendo (`docker-compose down`) y luego levántalos de nuevo con el comando `docker-compose up --build`.

#### **Cómo Comprobar tu Solución** ✅

Debes verificar que ambas tareas se han completado con éxito.

**1. Verificar la Redirección a HTTPS:**
Usa `curl` para hacer una petición a la versión HTTP de tu servidor. El flag `-I` solo muestra las cabeceras de la respuesta.
```bash
curl -I http://localhost
```
* **Resultado Esperado:** Debes recibir una respuesta `301 Moved Permanently` que te redirige a la versión HTTPS.
    ```
    HTTP/1.1 301 Moved Permanently
    Server: nginx/1.27.0
    Date: ...
    Content-Type: text/html
    Content-Length: 169
    Connection: keep-alive
    Location: https://localhost/
    ```

**2. Verificar la Política de CORS (Simulando un Navegador):**
Usaremos `curl` para enviar una petición de "preflight" (`OPTIONS`), como haría un navegador antes de un POST.

* **Caso 1: Origen PERMITIDO (debe funcionar)**
    ```bash
    curl -X OPTIONS https://localhost/token --insecure \
    -H "Origin: https://mi-app.com" \
    -H "Access-Control-Request-Method: POST" \
    -v
    ```
    * **Resultado Esperado:** La respuesta del servidor debe incluir las cabeceras CORS que dan permiso, reflejando el origen que enviaste.
        ```
        < HTTP/1.1 200 OK
        ...
        < access-control-allow-origin: https://mi-app.com
        < access-control-allow-credentials: true
        ```

* **Caso 2: Origen DENEGADO (debe ser bloqueado)**
    ```bash
    curl -X OPTIONS https://localhost/token --insecure \
    -H "Origin: https://sitio-malicioso.com" \
    -v
    ```
    * **Resultado Esperado:** La respuesta del servidor **NO debe incluir** la cabecera `access-control-allow-origin`. Su ausencia es la señal para el navegador de que la petición está prohibida.

#### **Punto Extra (Bonus)** 🌟

Modifica tu `nginx.conf` para añadir una cabecera de seguridad adicional que mejore tu puntuación en los tests de seguridad web: `Strict-Transport-Security (HSTS)`.

* **Pista:** Añade esta línea dentro de tu bloque `server` de HTTPS:
    `add_header Strict-Transport-Security 'max-age=31536000; includeSubDomains' always;`
* **Investiga:** ¿Qué hace exactamente esta cabecera y por qué es una buena práctica de seguridad?



## Referencias 



1.  **Guía sobre JWT (JSON Web Tokens):**
    * `https://www.machinet.net/tutorial-es/jwtdecoder-comprehensive-guide-java-developers` (Aunque enfocado a Java, explica los conceptos de JWT que son universales y aplicables a la autenticación en microservicios).
2.  **Ejemplo de Autenticación en FastAPI (FastMongoAuth):**
    * `https://github.com/Craxti/FastMongoAuth` (Un proyecto que implementa autenticación, útil para ver un ejemplo práctico con FastAPI).
3.  **Discusión sobre Refresh Tokens en FastAPI:**
    * `https://stackoverflow.com/questions/75534277/fastapi-grant-type-refresh-token` (Pregunta específica en Stack Overflow sobre un aspecto importante de la autenticación con tokens).
4.  **Configuración de SSL/TLS con Nginx y Let's Encrypt (Comunidad Let's Encrypt):**
    * `https://community.letsencrypt.org/t/update-request-for-etc-letsencrypt-options-ssl-nginx-conf/160859` (Relevante para la sección de comunicación segura con HTTPS y certificados).
5.  **Tutorial sobre Balanceo de Carga HTTPS con Nginx (Google Cloud):**
    * `https://cloud.google.com/community/tutorials/https-load-balancing-nginx?hl=es` (Útil para entender la configuración de HTTPS en un entorno de producción con un reverse proxy).
6.  **Artículo sobre el Top 10 de Seguridad de OWASP (Inforc.lat):**
    * `https://www.inforc.lat/post/top10-seguridad-apps-owasp` (Referencia clave para el análisis de vulnerabilidades OWASP).
7.  **Discusión sobre un aspecto de FastAPI (GitHub Issue):**
    * `https://github.com/tiangolo/fastapi/issues/5219` (Podría contener información específica sobre la implementación o problemas de seguridad en FastAPI, dependiendo del contenido del issue).
8.  **Ejemplo de Aplicación FastAPI con Arquitectura Hexagonal:**
    * `https://github.com/ShahriyarR/hexagonal-fastapi-jobboard` (Un proyecto más completo que puede servir de ejemplo para la estructura general y la implementación de buenas prácticas de seguridad en FastAPI).
9.  **Ejemplo General de Proyecto con FastAPI (tasks):**
    * `https://github.com/JorgeRomeroC/tasks` (Uno de los proyectos base referenciados, podría ilustrar configuraciones iniciales o algunos de los conceptos de forma simple).
10. **Plantilla de FastAPI con Piccolo ORM:**
    * `https://github.com/AliSayyah/FastAPI-Piccolo-Template` (Las plantillas de proyecto suelen incluir configuraciones básicas de seguridad o una estructura que facilita su implementación).