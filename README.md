# React Web Server와 Tomcat Front WAS 개발 환경

[![Reference](https://img.shields.io/badge/Reference-Official%20Docs-blue)](#공식-문서)

&emsp;이 저장소는 **Static Web Server 영역(Nginx + Dev Vite + Reference Vite)** 과 **Web Application Server 영역(Tomcat)** 을 Docker Compose로 실행하기 위한 개발 환경입니다.

&emsp;애플리케이션 소스가 준비되지 않은 상태에서도 Nginx, Dev Vite, Reference Vite, Tomcat 4개 서버를 모두 기동하고 브라우저에서 접속 여부를 확인할 수 있도록 구성합니다. Dev Vite와 Reference Vite는 소스가 없으면 이미지 내부의 fallback Vite 화면을 제공합니다.

## 1. Server Specification

### Nginx Web Server

| 항목 | 값 |
| --- | --- |
| Compose service | `nginx-staticweb` |
| Image | `nginx:1.30.4-alpine3.24` |
| Container port | `80` |
| Default host port | `8080` |
| Default URL | `http://localhost:8080` |
| Configuration | `nginx/default.dev.conf` |
| 역할 | 개발 React 화면 프록시 및 `/api/*` 요청을 Tomcat으로 전달 |

&emsp;개발 구성에서 `/` 요청은 `vite-devserver:8183`으로 전달하고 `/api/*` 요청은 `tomcat-frontend:8080`으로 전달합니다.

### Dev Vite Development Server

| 항목 | 값 |
| --- | --- |
| Compose service | `vite-devserver` |
| Base image | `node:24.20.0-bookworm` |
| Node.js | `24.20.0` |
| Package manager | Yarn 1.x |
| Working directory | `/workspace/react-web-ui` |
| Container port | `8183` |
| Default host port | `8183` |
| Default URL | `http://localhost:8183` |
| Host source | `${WEB_UI_SOURCE_PATH:-../react-web-ui}` |
| `node_modules` | Docker named volume `vite_node_modules` |

&emsp;`WEB_UI_SOURCE_PATH`에 React 소스와 `package.json`이 있으면 컨테이너 시작 시 `node_modules/.bin/vite`의 존재 여부를 확인하고, 필요하면 컨테이너 내부에서 `yarn install`을 실행한 뒤 실제 Dev Vite 서버를 시작합니다.

```sh
yarn dev --host 0.0.0.0 --port 8183
```

&emsp;소스가 없으면 이미지 내부의 fallback Vite 애플리케이션을 `8183` 포트에서 실행하므로 서버 자체의 기동 및 브라우저 접속을 확인할 수 있습니다.

&emsp;Windows 호스트의 파일 변경 감지를 위해 기본적으로 `CHOKIDAR_USEPOLLING=true`를 사용합니다.

### Reference Vite Development Server

| 항목 | 값 |
| --- | --- |
| Compose service | `ref-vite-devserver` |
| Base image | `node:24.20.0-bookworm` |
| Working directory | `/workspace/reference-ui/apps/react-vite` |
| Container port | `8184` |
| Default host port | `8184` |
| Default URL | `http://localhost:8184` |
| Host source | `${REFERENCE_UI_SOURCE_PATH:-../reactex/bulletproof-react}` |
| `node_modules` | Docker named volume `ref_vite_node_modules` |

&emsp;Reference UI 소스가 있으면 실제 Reference Vite 애플리케이션을 실행하고, 소스가 없으면 이미지 내부의 fallback Vite 애플리케이션을 `8184` 포트에서 실행합니다.

&emsp;Reference UI가 필요하지 않은 실행 구성 자체가 필요한 경우에는 `docker-compose.dev.no-reference.yml`을 사용할 수 있습니다.

### Tomcat Front WAS

| 항목 | 값 |
| --- | --- |
| Compose service | `tomcat-frontend` |
| Image | `tomcat:10.1.59-jre21-temurin-noble` 기반 |
| Tomcat | `10.1.59` |
| Java runtime | Eclipse Temurin JRE 21 |
| Container port | `8080` |
| Default host port | `18080` |
| Default URL | `http://localhost:18080` |
| 역할 | Front WAS 및 향후 WAR 배포 대상 |

&emsp;Tomcat 컨테이너는 Maven 프로젝트나 WAR가 없어도 정상 기동됩니다. 공식 Tomcat 이미지의 `webapps.dist`를 `webapps`로 복원하므로 애플리케이션을 배포하기 전에는 `http://localhost:18080`에서 Apache Tomcat 기본 Welcome 화면을 확인할 수 있습니다.

&emsp;Maven 빌드와 WAR 배포는 Tomcat 서버 기동과 분리합니다. 따라서 `FRONTEND_SOURCE_PATH`에 소스나 `pom.xml`이 없더라도 Tomcat 서버 자체의 Docker build 및 실행에는 영향을 주지 않습니다.

## 서버 구성도

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
       |       +-------+-------+        |       |                           |
       |       |               |        |       +---------------------------+
       |       | /             | /api/* |
       |       v               +-----------------------> Tomcat :8080
       |  +-------------------------+   |
       |  | Dev Vite                |   |
       |  | vite-devserver :8183    |   |
       |  +-------------------------+   |
       |                                |
       |  +-------------------------+   |
       |  | Reference Vite          |   |
       |  | ref-vite-devserver      |   |
       |  | :8184                   |   |
       |  +-------------------------+   |
       +--------------------------------+
                  |               |
                  |               +--> http://localhost:8184
                  +-------------------> http://localhost:8183
```

&emsp;Nginx와 Dev Vite는 개발용 Static Web Server 영역을 구성합니다. 브라우저의 `/` 요청은 Nginx를 통해 Dev Vite로 전달됩니다.

&emsp;Reference Vite는 동일한 Static Web Server 영역의 별도 개발 서버이며 `8184` 포트로 직접 접속할 수 있습니다.

&emsp;동적 애플리케이션 요청인 `/api/*`는 Nginx에서 Tomcat Web Application Server로 전달됩니다. Tomcat은 `18080` 호스트 포트로 직접 접속하여 서버 상태도 확인할 수 있습니다.

## 개발 서버 연결 구조

```text
Browser
  |
  +-- http://localhost:8080
  |      |
  |      +-- Nginx
  |             +-- /       -> Dev Vite :8183
  |             +-- /api/*  -> Tomcat :8080
  |
  +-- http://localhost:8183 -> Dev Vite 직접 접속
  |
  +-- http://localhost:8184 -> Reference Vite 직접 접속
  |
  +-- http://localhost:18080 -> Tomcat 직접 접속
```

## Compose 개발 구성

### Reference UI 포함

```sh
docker compose -f docker-compose.dev.yml up --build -d
```

실행 서비스:

```text
nginx-staticweb
vite-devserver
ref-vite-devserver
tomcat-frontend
```

&emsp;이 구성에서는 `WEB_UI_SOURCE_PATH`와 `REFERENCE_UI_SOURCE_PATH`의 실제 애플리케이션 소스가 없어도 fallback Vite 서버가 실행되므로 4개 서버를 모두 기동하고 브라우저에서 확인할 수 있습니다.

### Reference UI 제외

&emsp;Reference UI 서비스를 실행할 필요가 없는 경우 다음 구성을 사용합니다.

```sh
docker compose -f docker-compose.dev.no-reference.yml up --build -d
```

실행 서비스:

```text
nginx-staticweb
vite-devserver
tomcat-frontend
```

&emsp;이 구성은 `REFERENCE_UI_SOURCE_PATH`를 참조하지 않습니다.

## 환경 변수

&emsp;저장소 루트의 `.env`에서 설정합니다.

| 변수 | 기본값 | 용도 |
| --- | --- | --- |
| `APP_NAME` | `muilti-domain-rag` | Compose 및 컨테이너 식별자 |
| `NGINX_BIND_ADDRESS` | `127.0.0.1` | Nginx 호스트 바인딩 주소 |
| `NGINX_PORT` | `8080` | Nginx 호스트 포트 |
| `WEB_UI_SOURCE_PATH` | `../react-web-ui` | Dev React 소스 경로 |
| `VITE_BIND_ADDRESS` | `127.0.0.1` | Dev Vite 호스트 바인딩 주소 |
| `VITE_PORT` | `8183` | Dev Vite 호스트 포트 |
| `REFERENCE_UI_SOURCE_PATH` | `../reactex/bulletproof-react` | Reference UI 소스 경로 |
| `REFERENCE_UI_BIND_ADDRESS` | `127.0.0.1` | Reference Vite 바인딩 주소 |
| `REFERENCE_UI_PORT` | `8184` | Reference Vite 호스트 포트 |
| `VITE_USE_POLLING` | `true` | Windows bind mount 파일 변경 감지 |
| `FRONTWAS_BIND_ADDRESS` | `127.0.0.1` | Tomcat 호스트 바인딩 주소 |
| `FRONTWAS_PORT` | `18080` | Tomcat 호스트 포트 |
| `FRONTEND_SOURCE_PATH` | `../frontend` | 별도 Maven/WAR 빌드 절차에서 사용할 선택적 소스 경로 |

&emsp;`docker-compose.dev.no-reference.yml`을 사용할 때는 Reference UI 관련 환경 변수가 필요하지 않습니다.

## 2. Docker Build 전 필수 사항

### 필수 프로그램

&emsp;개발 호스트에는 다음 환경이 필요합니다.

| 항목 | 요구사항 | 다운로드 / 설치 |
| --- | --- | --- |
| Docker Desktop | Windows에서 Linux container 실행 가능 상태 | [Docker Desktop](https://www.docker.com/products/docker-desktop/) |
| Docker Engine | Docker Desktop에서 실행 중이어야 함 | Docker Desktop에 포함 |
| Docker Compose | `docker compose` 명령 사용 가능 | Docker Desktop에 포함 |
| Git | 저장소 checkout 및 변경 관리 | [Git for Windows](https://git-scm.com/download/win) |
| VS Code | Dev Container 사용 시 권장 | [Visual Studio Code](https://code.visualstudio.com/download) |
| Dev Containers extension | VS Code Dev Container 사용 시 필요 | [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) |

&emsp;Node.js, Yarn, Nginx, Tomcat, Java는 호스트에 별도로 설치할 필요가 없습니다. 각 Docker image 내부에서 제공합니다.

### Docker 상태 확인

&emsp;PowerShell에서 다음 명령이 정상적으로 실행되어야 합니다.

```powershell
docker version
docker compose version
docker info
```

&emsp;Docker Desktop은 Linux container 모드로 실행되어 있어야 합니다.

### 저장소와 소스 경로

&emsp;예시 구조는 다음과 같습니다.

```text
F:\project.rag
├─ nginx-vite-tomcat-env
├─ react-web-ui                 # 선택 사항: 없으면 Dev Vite fallback 화면 실행
├─ frontend                     # 선택 사항: Tomcat 자체 기동에는 불필요
└─ reactex
   └─ bulletproof-react         # 선택 사항: 없으면 Reference Vite fallback 화면 실행
```

&emsp;`WEB_UI_SOURCE_PATH` 또는 `REFERENCE_UI_SOURCE_PATH`의 소스 디렉터리가 없어도 개발 Compose는 서버를 기동할 수 있습니다. Docker Compose가 필요한 디렉터리를 만들고, 각 Vite 서비스는 애플리케이션 소스 유무를 확인하여 실제 앱 또는 fallback 앱을 실행합니다.

&emsp;Tomcat 자체를 실행할 때는 `frontend` 소스와 `pom.xml`이 필요하지 않습니다.

### `.env` 준비

&emsp;저장소 루트에서 `.env`가 없으면 `.env.example`을 기준으로 생성합니다.

```powershell
Copy-Item .env.example .env
```

Windows 예시:

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

&emsp;Reference 없는 Compose를 사용할 경우 `REFERENCE_UI_SOURCE_PATH`를 준비할 필요가 없습니다.

## Docker Build 및 실행 과정

### 1. 저장소 위치로 이동

```powershell
cd F:\project.rag\nginx-vite-tomcat-env
```

&emsp;Compose 파일 경로는 현재 디렉터리를 기준으로 해석되므로 저장소 루트에서 실행하는 것을 권장합니다.

### 2. Compose 설정 검증

Reference 포함:

```powershell
docker compose -f docker-compose.dev.yml config
```

Reference 제외:

```powershell
docker compose -f docker-compose.dev.no-reference.yml config
```

&emsp;이 단계에서 환경 변수와 bind mount 경로가 올바르게 해석되는지 먼저 확인합니다.

### 3. Docker image build 및 컨테이너 시작

Reference 포함:

```powershell
docker compose -f docker-compose.dev.yml up --build -d
```

Reference 제외:

```powershell
docker compose -f docker-compose.dev.no-reference.yml up --build -d
```

&emsp;주요 동작은 다음 순서입니다.

```text
Docker image 확인/build
        |
        +-- Nginx image 준비
        +-- Vite Node/fallback image 준비
        +-- Tomcat image build
        |
        v
Container 생성
        |
        +-- Dev Vite 시작 :8183
        |      +-- 소스 있음 -> dependency 확인/install -> 실제 앱 실행
        |      +-- 소스 없음 -> fallback Vite 실행
        |
        +-- Reference Vite 시작 :8184
        |      +-- 소스 있음 -> dependency 확인/install -> 실제 앱 실행
        |      +-- 소스 없음 -> fallback Vite 실행
        |
        +-- Tomcat 시작 :8080
        |
        +-- Nginx 시작 :80
        v
Host ports publish
```

&emsp;실제 애플리케이션 소스를 사용하는 경우 `yarn install`은 image build 단계가 아니라 개발 컨테이너 실행 시 필요한 경우 수행됩니다. 설치된 `node_modules`는 named volume에 보관되므로 컨테이너를 다시 만들더라도 볼륨이 유지되면 재사용할 수 있습니다.

### 4. 실행 상태 확인

```powershell
docker compose -f docker-compose.dev.yml ps
```

&emsp;Reference 없는 구성은 해당 Compose 파일명을 사용합니다.

서비스별 로그:

```powershell
docker compose -f docker-compose.dev.yml logs --tail=100 nginx-staticweb
docker compose -f docker-compose.dev.yml logs --tail=100 vite-devserver
docker compose -f docker-compose.dev.yml logs --tail=100 ref-vite-devserver
docker compose -f docker-compose.dev.yml logs --tail=100 tomcat-frontend
```

### 5. 서버 접속 확인

```text
http://localhost:8080   Nginx를 통한 Dev Vite
http://localhost:8183   Dev Vite 직접 접속
http://localhost:8184   Reference Vite 직접 접속
http://localhost:18080  Tomcat 기본 Welcome 화면
```

&emsp;애플리케이션 소스가 없을 때도 `8080`, `8183`, `8184`, `18080`의 브라우저 접속을 통해 각 서버가 기동되었는지 확인할 수 있습니다.

&emsp;Reference 없는 Compose에서는 `8184` 서버가 존재하지 않습니다.

### 6. 종료

Reference 포함:

```powershell
docker compose -f docker-compose.dev.yml down
```

Reference 제외:

```powershell
docker compose -f docker-compose.dev.no-reference.yml down
```

&emsp;named volume까지 삭제하려면 `down -v`를 사용할 수 있지만, 이 경우 다음 실행 시 Yarn dependency를 다시 설치해야 합니다.

## Application Source와 Server Infrastructure 분리 원칙

&emsp;이 개발환경에서는 다음 두 책임을 분리합니다.

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

&emsp;서버 인프라는 애플리케이션 소스의 존재 여부와 분리합니다. Dev Vite와 Reference Vite는 소스가 없으면 fallback 서버로 동작하고, Tomcat은 Maven 소스 또는 WAR가 없어도 기본 서버를 기동합니다.

&emsp;WAR 생성과 배포는 별도의 애플리케이션 build/deploy 과정으로 처리합니다. WAR가 배포되지 않은 상태에서는 Tomcat 기본 Welcome 화면을 서버 정상 여부 확인용으로 사용합니다.

## API Proxy

&emsp;개발 Nginx 설정에서 `/api/*` 요청은 Tomcat으로 URI를 변경하지 않고 전달합니다.

```text
Browser /api/users
       |
       v
Nginx :8080
       |
       v
http://tomcat-frontend:8080/api/users
```

&emsp;WAR가 배포되지 않은 상태에서는 `/api/*`에 애플리케이션 응답이 없을 수 있지만, 이것은 Tomcat 서버 기동 실패와는 구분해야 합니다.

## 공식 문서

- [Docker Compose](https://docs.docker.com/compose/)
- [Docker bind mounts](https://docs.docker.com/engine/storage/bind-mounts/)
- [Docker volumes](https://docs.docker.com/engine/storage/volumes/)
- [Apache Tomcat 10.1](https://tomcat.apache.org/tomcat-10.1-doc/)
- [Vite server options](https://vite.dev/config/server-options)
