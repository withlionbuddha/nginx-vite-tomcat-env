# React Web Server와 Tomcat Front WAS 개발 환경

[![Docker Compose](https://img.shields.io/badge/Ref%20Doc-Docker%20Compose-2496ED?logo=docker&logoColor=white)](https://docs.docker.com/compose/) [![Docker bind mounts](https://img.shields.io/badge/Ref%20Doc-Docker%20bind%20mounts-2496ED?logo=docker&logoColor=white)](https://docs.docker.com/engine/storage/bind-mounts/) [![Docker volumes](https://img.shields.io/badge/Ref%20Doc-Docker%20volumes-2496ED?logo=docker&logoColor=white)](https://docs.docker.com/engine/storage/volumes/) [![Apache Tomcat 10.1](https://img.shields.io/badge/Ref%20Doc-Apache%20Tomcat%2010.1-F8DC75?logo=apachetomcat&logoColor=black)](https://tomcat.apache.org/tomcat-10.1-doc/) [![Vite server options](https://img.shields.io/badge/Ref%20Doc-Vite%20server%20options-646CFF?logo=vite&logoColor=white)](https://vite.dev/config/server-options)

&emsp;이 저장소는 **Static Web Server 영역(Nginx + Dev Vite + Reference Vite)** 과 **Web Application Server 영역(Tomcat)** 을 Docker Compose로 실행하기 위한 개발 환경입니다.

&emsp;애플리케이션 소스가 준비되지 않은 상태에서도 Nginx, Dev Vite, Reference Vite, Tomcat 4개 서버를 모두 기동하고 브라우저에서 접속 여부를 확인할 수 있습니다. Dev Vite와 Reference Vite는 소스가 없으면 이미지 내부의 fallback Vite 화면을 제공합니다.

## 1. Server Specification

### &emsp;1.1. Nginx Web Server

> &emsp;| 항목 | 값 |
> &emsp;| --- | --- |
> &emsp;| Compose service | `nginx-staticweb` |
> &emsp;| Image | `nginx:1.30.4-alpine3.24` |
> &emsp;| Container port | `80` |
> &emsp;| Default host port | `8080` |
> &emsp;| Default URL | `http://localhost:8080` |
> &emsp;| Configuration | `nginx/default.dev.conf` |
> &emsp;| 역할 | 개발 React 화면 프록시 및 `/api/*` 요청을 Tomcat으로 전달 |
>
> &emsp;개발 구성에서 `/` 요청은 `vite-devserver:8183`으로 전달하고 `/api/*` 요청은 `tomcat-frontend:8080`으로 전달합니다.

### &emsp;1.2. Dev Vite Development Server

> &emsp;| 항목 | 값 |
> &emsp;| --- | --- |
> &emsp;| Compose service | `vite-devserver` |
> &emsp;| Base image | `node:24.20.0-bookworm` |
> &emsp;| Node.js | `24.20.0` |
> &emsp;| Package manager | Yarn 1.x |
> &emsp;| Working directory | `/workspace/react-web-ui` |
> &emsp;| Container port | `8183` |
> &emsp;| Default host port | `8183` |
> &emsp;| Default URL | `http://localhost:8183` |
> &emsp;| Host source | `${WEB_UI_SOURCE_PATH:-../react-web-ui}` |
> &emsp;| `node_modules` | Docker named volume `vite_node_modules` |
>
> &emsp;`WEB_UI_SOURCE_PATH`에 React 소스와 `package.json`이 있으면 필요한 dependency를 설치한 뒤 실제 Dev Vite 서버를 시작합니다. 소스가 없으면 fallback Vite를 `8183` 포트에서 실행합니다.

```sh
yarn dev --host 0.0.0.0 --port 8183
```

### &emsp;1.3. Reference Vite Development Server

> &emsp;| 항목 | 값 |
> &emsp;| --- | --- |
> &emsp;| Compose service | `ref-vite-devserver` |
> &emsp;| Base image | `node:24.20.0-bookworm` |
> &emsp;| Working directory | `/workspace/reference-ui/apps/react-vite` |
> &emsp;| Container port | `8184` |
> &emsp;| Default host port | `8184` |
> &emsp;| Default URL | `http://localhost:8184` |
> &emsp;| Host source | `${REFERENCE_UI_SOURCE_PATH:-../reactex/bulletproof-react}` |
> &emsp;| `node_modules` | Docker named volume `ref_vite_node_modules` |
>
> &emsp;Reference UI 소스가 있으면 실제 애플리케이션을 실행하고, 없으면 fallback Vite를 `8184` 포트에서 실행합니다.

### &emsp;1.4. Tomcat Web Application Server

> &emsp;| 항목 | 값 |
> &emsp;| --- | --- |
> &emsp;| Compose service | `tomcat-frontend` |
> &emsp;| Image | `tomcat:10.1.59-jre21-temurin-noble` 기반 |
> &emsp;| Tomcat | `10.1.59` |
> &emsp;| Java runtime | Eclipse Temurin JRE 21 |
> &emsp;| Container port | `8080` |
> &emsp;| Default host port | `18080` |
> &emsp;| Default URL | `http://localhost:18080` |
> &emsp;| 역할 | Front WAS 및 향후 WAR 배포 대상 |
>
> &emsp;Tomcat은 Maven 프로젝트나 WAR가 없어도 정상 기동됩니다. 애플리케이션 배포 전에는 `http://localhost:18080`에서 Apache Tomcat 기본 Welcome 화면을 확인할 수 있습니다.

## 2. Server Architecture

### &emsp;2.1. 서버 구성도

```text
                                  Browser
                                     |
                  +------------------+------------------+
                  |                                     |
                  | http://localhost:8080               | http://localhost:18080
                  v                                     v
       +--------------------------------+       +---------------------------+
       |       Static Web Server        |       | Web Application Server    |
       |                                |       |                           |
       |  +--------------------------+  |       |  +---------------------+  |
       |  | Nginx                    |  |       |  | Tomcat Front WAS    |  |
       |  | nginx-staticweb :80      |  |       |  | tomcat-frontend     |  |
       |  +------------+-------------+  |       |  | :8080               |  |
       |               |                |       |  +---------------------+  |
       |       +-------+-------+        |       +---------------------------+
       |       |               |        |
       |       | /             | /api/* +-----------------> Tomcat :8080
       |       v               |        |
       |  +-------------------------+   |
       |  | Dev Vite :8183          |   |
       |  +-------------------------+   |
       |                                |
       |  +-------------------------+   |
       |  | Reference Vite :8184    |   |
       |  +-------------------------+   |
       +--------------------------------+
```

### &emsp;2.2. 브라우저 접속 구조

```text
http://localhost:8080   -> Nginx -> Dev Vite
http://localhost:8183   -> Dev Vite 직접 접속
http://localhost:8184   -> Reference Vite 직접 접속
http://localhost:18080  -> Tomcat 직접 접속
```

## 3. Compose 개발 구성

### &emsp;3.1. Reference UI 포함

```powershell
docker compose -f docker-compose.dev.yml up --build -d
```

&emsp;실행 서비스: `nginx-staticweb`, `vite-devserver`, `ref-vite-devserver`, `tomcat-frontend`

&emsp;`WEB_UI_SOURCE_PATH`와 `REFERENCE_UI_SOURCE_PATH`에 실제 애플리케이션 소스가 없어도 fallback Vite가 실행되므로 4개 서버를 모두 브라우저에서 확인할 수 있습니다.

### &emsp;3.2. Reference UI 제외

```powershell
docker compose -f docker-compose.dev.no-reference.yml up --build -d
```

&emsp;이 구성은 `REFERENCE_UI_SOURCE_PATH`를 참조하지 않으며 Reference Vite를 제외한 3개 서비스를 실행합니다.

### &emsp;3.3. 환경 변수

&emsp;저장소 루트의 `.env`에서 설정합니다.

> &emsp;| 변수 | 기본값 | 용도 |
> &emsp;| --- | --- | --- |
> &emsp;| `APP_NAME` | `muilti-domain-rag` | Compose 및 컨테이너 식별자 |
> &emsp;| `NGINX_BIND_ADDRESS` | `127.0.0.1` | Nginx 호스트 바인딩 주소 |
> &emsp;| `NGINX_PORT` | `8080` | Nginx 호스트 포트 |
> &emsp;| `WEB_UI_SOURCE_PATH` | `../react-web-ui` | Dev React 소스 경로 |
> &emsp;| `VITE_BIND_ADDRESS` | `127.0.0.1` | Dev Vite 호스트 바인딩 주소 |
> &emsp;| `VITE_PORT` | `8183` | Dev Vite 호스트 포트 |
> &emsp;| `REFERENCE_UI_SOURCE_PATH` | `../reactex/bulletproof-react` | Reference UI 소스 경로 |
> &emsp;| `REFERENCE_UI_BIND_ADDRESS` | `127.0.0.1` | Reference Vite 바인딩 주소 |
> &emsp;| `REFERENCE_UI_PORT` | `8184` | Reference Vite 호스트 포트 |
> &emsp;| `VITE_USE_POLLING` | `true` | Windows bind mount 파일 변경 감지 |
> &emsp;| `FRONTWAS_BIND_ADDRESS` | `127.0.0.1` | Tomcat 호스트 바인딩 주소 |
> &emsp;| `FRONTWAS_PORT` | `18080` | Tomcat 호스트 포트 |
> &emsp;| `FRONTEND_SOURCE_PATH` | `../frontend` | 선택적 Maven/WAR 소스 경로 |

## 4. Docker Build 전 필수 사항

### &emsp;4.1. 필수 프로그램

> &emsp;| 항목 | 요구사항 | 다운로드 / 설치 |
> &emsp;| --- | --- | --- |
> &emsp;| Docker Desktop | Windows에서 Linux container 실행 가능 상태 | [Docker Desktop](https://www.docker.com/products/docker-desktop/) |
> &emsp;| Docker Engine | Docker Desktop에서 실행 중 | Docker Desktop에 포함 |
> &emsp;| Docker Compose | `docker compose` 명령 사용 가능 | Docker Desktop에 포함 |
> &emsp;| Git | 저장소 checkout 및 변경 관리 | [Git for Windows](https://git-scm.com/download/win) |
> &emsp;| VS Code | Dev Container 사용 시 권장 | [Visual Studio Code](https://code.visualstudio.com/download) |
> &emsp;| Dev Containers extension | VS Code Dev Container 사용 시 필요 | [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) |

&emsp;Node.js, Yarn, Nginx, Tomcat, Java는 호스트에 별도로 설치할 필요가 없습니다. Docker image 내부에서 제공합니다.

### &emsp;4.2. Docker 상태 확인

```powershell
docker version
docker compose version
docker info
```

### &emsp;4.3. 저장소와 소스 경로

```text
F:\project.rag
├─ nginx-vite-tomcat-env
├─ react-web-ui                 # 선택 사항
├─ frontend                     # 선택 사항
└─ reactex
   └─ bulletproof-react         # 선택 사항
```

&emsp;React 소스 디렉터리가 없어도 각 Vite 서비스는 fallback 서버로 기동합니다. Tomcat 역시 `frontend` 소스와 `pom.xml` 없이 기동합니다.

### &emsp;4.4. `.env` 준비

```powershell
Copy-Item .env.example .env
```

```dotenv
WEB_UI_SOURCE_PATH=F:/project.rag/react-web-ui
VITE_BIND_ADDRESS=127.0.0.1
VITE_PORT=8183

REFERENCE_UI_SOURCE_PATH=F:/project.rag/reactex/bulletproof-react
REFERENCE_UI_BIND_ADDRESS=127.0.0.1
REFERENCE_UI_PORT=8184

FRONTEND_SOURCE_PATH=F:/project.rag/frontend
FRONTWAS_BIND_ADDRESS=127.0.0.1
FRONTWAS_PORT=18080

NGINX_BIND_ADDRESS=127.0.0.1
NGINX_PORT=8080
```

## 5. Docker Build 및 실행

### &emsp;5.1. 저장소 위치로 이동

```powershell
cd F:\project.rag\nginx-vite-tomcat-env
```

### &emsp;5.2. Compose 설정 검증

```powershell
docker compose -f docker-compose.dev.yml config
```

### &emsp;5.3. Image build 및 컨테이너 시작

```powershell
docker compose -f docker-compose.dev.yml up --build -d
```

### &emsp;5.4. 실행 상태 확인

```powershell
docker compose -f docker-compose.dev.yml ps
```

### &emsp;5.5. 서비스 로그 확인

```powershell
docker compose -f docker-compose.dev.yml logs --tail=100 nginx-staticweb
docker compose -f docker-compose.dev.yml logs --tail=100 vite-devserver
docker compose -f docker-compose.dev.yml logs --tail=100 ref-vite-devserver
docker compose -f docker-compose.dev.yml logs --tail=100 tomcat-frontend
```

### &emsp;5.6. 서버 접속 확인

> &emsp;| 서버 | URL | 소스가 없을 때 |
> &emsp;| --- | --- | --- |
> &emsp;| Nginx | `http://localhost:8080` | Dev Vite fallback 화면으로 프록시 |
> &emsp;| Dev Vite | `http://localhost:8183` | fallback Vite 화면 |
> &emsp;| Reference Vite | `http://localhost:8184` | fallback Vite 화면 |
> &emsp;| Tomcat | `http://localhost:18080` | Tomcat Welcome 화면 |

### &emsp;5.7. 종료

```powershell
docker compose -f docker-compose.dev.yml down
```

## 6. Application Source와 Server Infrastructure 분리 원칙

### &emsp;6.1. 책임 분리

```text
Server Infrastructure
├─ Static Web Server
│  ├─ Nginx
│  ├─ Dev Vite runtime
│  └─ Reference Vite runtime
└─ Web Application Server
   └─ Tomcat

Application Source / Build
├─ React source
├─ Reference React source
└─ Maven source / WAR
```

### &emsp;6.2. API Proxy

```text
Browser /api/users
       |
       v
Nginx :8080
       |
       v
http://tomcat-frontend:8080/api/users
```

&emsp;WAR가 배포되지 않은 상태에서는 `/api/*`에 애플리케이션 응답이 없을 수 있으며, 이는 Tomcat 서버 기동 실패와 구분합니다.
