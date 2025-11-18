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

## - Presentado por: 
- Nicolas Alberto Cuellar Castrellón / 2220906
- Santiago Duque Valencia / 2215270


## Repositorio de la solución para el laboratorio de **Servicios Telemáticos**:

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

```
cd C:\Users\jpmor\ST\cloudnova
vagrant up
vagrant ssh

cd /vagrant/miniwebapp
docker compose up -d
```
Contenedores esperados:

- miniwebapp-web

- prometheus

- node-exporter

- grafana

Verificar:
```
docker ps
```

## 3.2 Acceso desde el navegador local

Con la VM y los contenedores arriba:

- Aplicación:

  - http://localhost:8080
    → redirige a
    https://localhost:8443 (certificado autofirmado).

- Prometheus:

  - http://localhost:9090

- Node Exporter:

  - http://localhost:9100/metrics

- Grafana:

  - http://localhost:3000
  Usuario: admin – Password: admin (por defecto)



## 4. Despliegue en AWS EC2
## 4.1 Creación de la instancia

  1. AWS → EC2 → Launch instance.

  2. AMI: Ubuntu Server 22.04 LTS.

3. Tipo: t2.micro (free tier).

4. Key pair: por ejemplo cloudnovaKeys.pem.

5. Security Group (Inbound):

  - HTTP (80) → 0.0.0.0/0

  - HTTPS (443) → 0.0.0.0/0

## 4.2 Instalación de Docker en la EC2

Desde el host (PowerShell):

```
cd "C:\Users\jpmor\ST\LlavesCloudnova"
ssh -i .\cloudnovaKeys.pem ubuntu@IP_PUBLICA
```

Dentro de la instancia:
```
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release git

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker ubuntu
sudo systemctl enable docker
sudo systemctl start docker
```

Cerrar sesión y volver a entrar para que el grupo docker surta efecto:
```
exit
ssh -i .\cloudnovaKeys.pem ubuntu@IP_PUBLICA
```

## 4.3 Despliegue de la aplicación en la EC2

Dentro de la EC2:
```
git clone https://github.com/BetoCuellar/cloudnova-miniwebapp.git
cd cloudnova-miniwebapp
docker compose up -d

docker ps
```
Probar desde el navegador (host):

- http://IP_PUBLICA
  → redirige a https://IP_PUBLICA.

Aceptar el warning del certificado y verificar que la MiniWebApp se muestra.

## 5. Monitoreo con Prometheus y Node Exporter
## 5.1 Configuración de Prometheus

Archivos principales:

- monitoring/prometheus.yml

- monitoring/alerts.yml

Prometheus se ejecuta en Docker y hace scrape de:

- prometheus:9090

- node-exporter:9100

Verificación en local (host, con VM arriba):

- http://localhost:9090/targets
  Targets prometheus y node-exporter en estado UP.

## 5.2 Métricas documentadas

1. CPU – node_cpu_seconds_total

    - Métrica base de segundos de CPU por modo (user, system, idle, etc.).

    - Permite calcular el porcentaje de uso de CPU aplicando rate() en una ventana de tiempo.

    - Útil para detectar picos de procesamiento y saturación del servidor.

2. Memoria – node_memory_MemAvailable_bytes

    - Cantidad de memoria disponible que puede usarse sin recurrir a swap.

    - Junto con node_memory_MemTotal_bytes se calcula el porcentaje de uso de memoria.

    - Permite ver si el servidor está cerca de quedarse sin RAM.

3. Disco – node_filesystem_avail_bytes

    - Espacio libre en bytes en un filesystem (por ejemplo mountpoint="/").

    - Junto con node_filesystem_size_bytes se obtiene el porcentaje de espacio libre.

    - Ayuda a evitar fallos por falta de espacio en disco (logs, bases de datos, etc.).

## 5.3 Reglas de alerta en Prometheus

Definidas en monitoring/alerts.yml, con ejemplos como:

- HighCPUUsage

  - Se dispara cuando el uso de CPU promedio supera el 80 % durante un intervalo de tiempo.

- HighMemoryUsage

  - Se dispara cuando el uso de memoria supera el 80 %.

- LowDiskSpace

  - Se dispara cuando el espacio libre en / es menor al 15 %.

Verificación:

- http://localhost:9090

  - Menú Status → Rules: grupo node_exporter_alerts.

  - Menú Alerts: mismas reglas en estado Inactive / Pending / Firing.

## 6. Visualización con Grafana
## 6.1 Integración Grafana–Prometheus

Grafana corre en Docker (definido en docker-compose.yml).

1. Acceder a http://localhost:3000.

2. Crear data source Prometheus:

  - URL: http://prometheus:9090 (dentro de la red de Docker).

3.Guardar y probar → “Data source is working”.

## 6.2 Dashboard personalizado

Dashboard con:

1. Panel de CPU y Memoria (Time series)

  - Métrica CPU (%):
  ```
  avg(rate(node_cpu_seconds_total{mode!="idle"}[5m])) * 100
  ```
  - Métrica Memoria (%):
  ```
  (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
  ```
2. Gauge de espacio en disco (%)
```
(node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100
```
Thresholds:
  
  - < 15 % → rojo

  - 15–30 % → amarillo

  - 30 % → verde
    
## 6.3 Dashboard importado

Se importó un dashboard preconfigurado desde la librería oficial de Grafana:

  - ID: 1860 – Node Exporter Full

  - Data source: prometheus

Pasos:

1. Grafana → Dashboards → Import.

2. Ingresar ID 1860.

3. Seleccionar data source prometheus.

4. Guardar e inspeccionar los paneles con datos.

## 7. Evidencias
## - 1. Empaquetado y despliegue local con Docker (1.5 puntos)


  - Estado del Docker

  
<img width="1186" height="277" alt="imagen" src="https://github.com/user-attachments/assets/3ed30df0-4517-49cd-bd58-f80a42213a7b" />


  - Pruebas con Curl (HTTP y HTTPS)

  
<img width="911" height="455" alt="imagen" src="https://github.com/user-attachments/assets/1f603bc2-2252-45fe-bc47-b5e47c06ddc0" />


  - Certificado en el host

  
<img width="1331" height="416" alt="imagen" src="https://github.com/user-attachments/assets/abb3711c-15cc-4f16-9ff0-1a84875c02d8" />


<img width="1044" height="1026" alt="imagen" src="https://github.com/user-attachments/assets/7aa781ec-c2e4-441d-bee9-969a2194ad60" />


## - 2. Despliegue en la nube con AWS EC2 (1.0 punto)


  - Despligue de la instancia en AWS

  
<img width="1075" height="301" alt="imagen" src="https://github.com/user-attachments/assets/dd491657-6428-463a-bbf2-5433a8b167ac" />


  - Prueba de docker dentro de la EC2

  
<img width="1480" height="293" alt="imagen" src="https://github.com/user-attachments/assets/e5972de5-6837-4ab7-b208-1b6bbe67ed65" />


  - Probar acceso en el host desde la instancia

  
<img width="1238" height="368" alt="imagen" src="https://github.com/user-attachments/assets/b5f9583f-30a7-4a50-b0ab-a030320b840f" />


## - 3. Monitoreo con Prometheus y Node Exporter (1.5 puntos)


  - Ver que Prometheus y Node Exporter están corriendo

  
<img width="2551" height="664" alt="imagen" src="https://github.com/user-attachments/assets/f4f12b06-a013-4155-8104-d035f0b46f40" />


<img width="980" height="519" alt="imagen" src="https://github.com/user-attachments/assets/615f8a37-4f43-4661-a8c4-b30988c23657" />


<img width="820" height="531" alt="imagen" src="https://github.com/user-attachments/assets/23efb142-0f20-42dd-b63a-9b2a56114324" />

  ## - Revisión de metricas
  - node_cpu_seconds_total


<img width="2556" height="1274" alt="imagen" src="https://github.com/user-attachments/assets/bdae803e-6596-4ac0-a054-a7d554427fa4" />


  - node_memory_MemAvailable_bytes


<img width="2553" height="1144" alt="imagen" src="https://github.com/user-attachments/assets/64e5e844-6347-4a59-bf54-5d981f30bb16" />


  - node_filesystem_avail_bytes


<img width="2552" height="1264" alt="imagen" src="https://github.com/user-attachments/assets/d260f464-db07-4a4f-99d0-f4e70ab1e854" />


## - 4. Visualización con Grafana (1.0 puntos)


  - Dashboard propio con 2 paneles (CPU y Memoria %, y Gauge de disco)


<img width="1112" height="940" alt="imagen" src="https://github.com/user-attachments/assets/1cde64b0-b7c3-454a-bb1d-b97ac4bb9e2e" />


  - Panel oficial importado (1860)


<img width="2181" height="1262" alt="imagen" src="https://github.com/user-attachments/assets/5b96371e-ceec-428b-9cd5-cbec14d4df1b" />


## 8. Conclusión técnica

- ¿Qué aprendí al integrar Docker, AWS y Prometheus?
  
Aprendí a empaquetar una aplicación en contenedores Docker de forma reproducible y a desplegar el mismo stack tanto en un entorno local (Vagrant) como en la nube (AWS EC2) sin cambiar el código de la aplicación. También entendí cómo Prometheus y Node Exporter permiten observar el estado real del servidor (CPU, memoria, disco) y cómo Grafana facilita la visualización de estas métricas mediante dashboards.

- ¿Qué fue lo más desafiante y cómo lo resolvería en un entorno real?
  
Lo más desafiante fue coordinar varios servicios (Nginx, Prometheus, Node Exporter y Grafana) en un solo docker-compose.yml, junto con la configuración de TLS y la redirección HTTP→HTTPS. En un entorno real usaría certificados válidos emitidos por Let’s Encrypt, automatizaría el despliegue con pipelines CI/CD y manejaría la configuración mediante herramientas de infraestructura como código (por ejemplo, Terraform y Ansible) para reducir errores manuales y hacer el proceso repetible.

- ¿Qué beneficio aporta la observabilidad en el ciclo DevOps?
  
La observabilidad permite detectar problemas de rendimiento y capacidad antes de que afecten al usuario final. Tener métricas, alertas y dashboards hace posible reaccionar rápido ante incidentes, optimizar recursos y tomar decisiones basadas en datos. Esto cierra el ciclo DevOps porque el feedback de producción vuelve al equipo de desarrollo y operaciones de forma continua, mejorando la calidad y la confiabilidad del sistema.
