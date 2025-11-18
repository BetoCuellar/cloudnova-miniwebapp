# To Run application

## Start and SSH into Vagrant VM 

```
vagrant up
vagrant ssh servidorWeb
```

## Run the webApp

```
cd /home/vagrant/webapp
export FLASK_APP=run.py
/usr/local/bin/flask run --host=0.0.0.0
```

# CloudNova MiniWebApp

Repositorio de la solución para el laboratorio de **Servicios Telemáticos**:

- Empaquetado de la MiniWebApp en Docker.
- Despliegue local con Vagrant + Docker.
- Despliegue en la nube con AWS EC2.
- Monitoreo con **Prometheus + Node Exporter**.
- Visualización con **Grafana**.

Repositorio: https://github.com/BetoCuellar/cloudnova-miniwebapp  

---

## 1. Arquitectura de la solución

Componentes principales:

- **Nginx** (contenedor `miniwebapp-web`):
  - Sirve la aplicación estática.
  - Termina TLS con un certificado autofirmado.
  - Redirige automáticamente HTTP → HTTPS.
- **Prometheus**:
  - Recolecta sus propias métricas y las de Node Exporter.
  - Usa `prometheus.yml` y `alerts.yml` del directorio `monitoring/`.
- **Node Exporter**:
  - Expone métricas de CPU, memoria y disco de la VM.
- **Grafana**:
  - Se conecta a Prometheus como data source.
  - Muestra dashboards personalizados y uno importado (ID 1860).

Todo se orquesta con **Docker Compose** a partir del archivo `docker-compose.yml`.

---

## 2. Requisitos

En el **host (máquina local)**:

- VirtualBox  
- Vagrant  
- Git  

Dentro de la **VM** (se instalan automáticamente mediante el `Vagrantfile`):

- Docker  
- Docker Compose plugin  

En la **nube**:

- Cuenta en AWS.
- Instancia **EC2 Ubuntu 22.04**.
- Llave `.pem` para acceso SSH.
- Security Group con puertos:
  - 80 (HTTP)
  - 443 (HTTPS)

---

## 3. Despliegue local con Vagrant + Docker

### 3.1 Levantar la VM y los contenedores

En el host (Windows):

```bash
cd C:\Users\jpmor\ST\cloudnova
vagrant up
vagrant ssh

cd /vagrant/miniwebapp
docker compose up -d
