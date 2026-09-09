# React Web Server와 Tomcat Front WAS 개발 환경

이 저장소는 Nginx, Vite React 개발 서버, Reference Vite 서버, Tomcat WAS를 Docker Compose로 실행하기 위한 개발 환경입니다. 애플리케이션 소스가 준비되지 않은 상태에서도 Nginx와 Tomcat 같은 서버 인프라는 먼저 기동할 수 있도록 구성합니다.

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

개발 구성에서 `/` 요청은 `vite-devserver:8183`으로 전달하고 `/api/*` 요청은 `tomcat-frontend:8080`으로 전달합니다.

### Main Vite Development Server

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

컨테이너 시작 시 `node_modules/.bin/vite`의 존재 여부를 확인합니다. Vite가 설치되어 있지 않으면 컨테이너 내부에서 `yarn install`을 실행한 뒤 다음 명령으로 개발 서버를 시작합니다.

```sh
yarn dev --host 0.0.0.0 --port 8183
```

Windows 호스트의 파일 변경 감지를 위해 기본적으로 `CHOKIDAR_USEPOLLING=true`를 사용합니다.

### Reference Vite Development Server

| 항목 | 값 |
| --- | --- |
| Compose service | `ref-vite-devserver` |
| Image | `node:24.20.0-bookworm` |
| Working directory | `/workspace/reference-ui/apps/react-vite` |
| Container port | `8184` |
| Default host port | `8184` |
| Default URL | `http://localhost:8184` |
| Host source | `${REFERENCE_UI_SOURCE_PATH:-../reactex/bulletproof-react}` |
| `node_modules` | Docker named volume `ref_vite_node_modules` |

Reference UI는 Nginx를 거치지 않고 호스트의 `8184` 포트에서 직접 접속합니다. 컨테이너 시작 시 Vite 실행 파일이 없으면 `yarn install`을 수행한 후 Vite를 실행합니다.

Reference UI가 필요하지 않은 경우 `docker-compose.dev.no-reference.yml`을 사용합니다. 이 Compose 파일에는 `ref-vite-devserver`, `REFERENCE_UI_SOURCE_PATH`, `REFERENCE_UI_PORT`, `ref_vite_node_modules`가 포함되지 않습니다.

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

Tomcat 컨테이너는 Maven 프로젝트나 WAR가 없어도 정상 기동됩니다. 공식 Tomcat 이미지의 `webapps.dist`를 `webapps`로 복원하므로 애플리케이션을 배포하기 전에는 `http://localhost:18080`에서 Apache Tomcat 기본 Welcome 화면을 확인할 수 있습니다.

Maven 빌드와 WAR 배포는 Tomcat 서버 기동과 분리합니다. 따라서 `FRONTEND_SOURCE_PATH`에 소스나 `pom.xml`이 없더라도 Tomcat 서버 자체의 Docker build 및 실행에는 영향을 주지 않습니다.

## 개발 서버 연결 구조

```text
Browser
  |
  +-- http://localhost:8080
  |      |
  |      +-- Nginx
  |             +-- /       -> vite-devserver:8183
  |             +-- /api/*  -> tomcat-frontend:8080
  |
  +-- http://localhost:8183 -> Main Vite 직접 접속
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

### Reference UI 제외

Reference 소스가 없거나 Reference UI를 실행할 필요가 없으면 다음 구성을 사용합니다.

```sh
docker compose -f docker-compose.dev.no-reference.yml up --build -d
```

실행 서비스:

```text
nginx-staticweb
vite-devserver
tomcat-frontend
```

이 구성은 `REFERENCE_UI_SOURCE_PATH`를 전혀 참조하지 않으므로 `../reactex/bulletproof-react` 디렉터리가 없어도 Compose를 실행할 수 있습니다.

## 환경 변수

저장소 루트의 `.env`에서 설정합니다.

| 변수 | 기본값 | 용도 |
| --- | --- | --- |
| `APP_NAME` | `muilti-domain-rag` | Compose 및 컨테이너 식별자 |
| `NGINX_BIND_ADDRESS` | `127.0.0.1` | Nginx 호스트 바인딩 주소 |
| `NGINX_PORT` | `8080` | Nginx 호스트 포트 |
| `WEB_UI_SOURCE_PATH` | `../react-web-ui` | Main React 소스 경로 |
| `VITE_BIND_ADDRESS` | `127.0.0.1` | Main Vite 호스트 바인딩 주소 |
| `VITE_PORT` | `8183` | Main Vite 호스트 포트 |
| `REFERENCE_UI_SOURCE_PATH` | `../reactex/bulletproof-react` | Reference UI 소스 경로 |
| `REFERENCE_UI_BIND_ADDRESS` | `127.0.0.1` | Reference Vite 바인딩 주소 |
| `REFERENCE_UI_PORT` | `8184` | Reference Vite 호스트 포트 |
| `VITE_USE_POLLING` | `true` | Windows bind mount 파일 변경 감지 |
| `FRONTWAS_BIND_ADDRESS` | `127.0.0.1` | Tomcat 호스트 바인딩 주소 |
| `FRONTWAS_PORT` | `18080` | Tomcat 호스트 포트 |
| `FRONTEND_SOURCE_PATH` | `../frontend` | 별도 Maven/WAR 빌드 절차에서 사용할 선택적 소스 경로 |

`docker-compose.dev.no-reference.yml`을 사용할 때는 Reference UI 관련 환경 변수가 필요하지 않습니다.

## 2. Docker Build 전 필수 사항

### 필수 프로그램

개발 호스트에는 다음 환경이 필요합니다.

| 항목 | 요구사항 |
| --- | --- |
| Docker Desktop | Windows에서 Linux container 실행 가능 상태 |
| Docker Engine | Docker Desktop에서 실행 중이어야 함 |
| Docker Compose | `docker compose` 명령 사용 가능 |
| Git | 저장소 checkout 및 변경 관리 |
| VS Code | 선택 사항이지만 Dev Container 사용 시 필요 |
| Dev Containers extension | VS Code Dev Container 사용 시 필요 |

Node.js, Yarn, Nginx, Tomcat, Java는 호스트에 별도로 설치할 필요가 없습니다. 각 Docker image 내부에서 제공합니다.

### Docker 상태 확인

PowerShell에서 다음 명령이 정상적으로 실행되어야 합니다.

```powershell
docker version
docker compose version
docker info
```

Docker Desktop은 Linux container 모드로 실행되어 있어야 합니다.

### 저장소와 소스 경로

예시 구조는 다음과 같습니다.

```text
F:\project.rag
├─ nginx-vite-tomcat-env
├─ react-web-ui
├─ frontend                     # 선택 사항
└─ reactex
   └─ bulletproof-react         # Reference 구성 사용 시 필요
```

Main Vite를 실행하려면 `WEB_UI_SOURCE_PATH`가 가리키는 디렉터리가 실제로 존재해야 합니다. Reference 포함 Compose를 사용할 경우 `REFERENCE_UI_SOURCE_PATH`도 존재해야 합니다.

Tomcat 자체를 실행할 때는 `frontend` 소스와 `pom.xml`이 필요하지 않습니다.

### `.env` 준비

저장소 루트에서 `.env`가 없으면 `.env.example`을 기준으로 생성합니다.

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

Reference 없는 Compose를 사용할 경우 `REFERENCE_UI_SOURCE_PATH`를 준비할 필요가 없습니다.

## Docker Build 및 실행 과정

### 1. 저장소 위치로 이동

```powershell
cd F:\project.rag\nginx-vite-tomcat-env
```

Compose 파일 경로는 현재 디렉터리를 기준으로 해석되므로 저장소 루트에서 실행하는 것을 권장합니다.

### 2. Compose 설정 검증

Reference 포함:

```powershell
docker compose -f docker-compose.dev.yml config
```

Reference 제외:

```powershell
docker compose -f docker-compose.dev.no-reference.yml config
```

이 단계에서 환경 변수와 bind mount 경로가 올바르게 해석되는지 먼저 확인합니다.

### 3. Docker image build 및 컨테이너 시작

Reference 포함:

```powershell
docker compose -f docker-compose.dev.yml up --build -d
```

Reference 제외:

```powershell
docker compose -f docker-compose.dev.no-reference.yml up --build -d
```

주요 동작은 다음 순서입니다.

```text
Docker image 확인/build
        |
        +-- Nginx image 준비
        +-- Vite Node image 준비
        +-- Tomcat image build
        |
        v
Container 생성
        |
        +-- Main Vite 시작
        |      +-- node_modules/.bin/vite 확인
        |      +-- 없으면 yarn install
        |      +-- yarn dev :8183
        |
        +-- Reference Vite 시작 (Reference 포함 구성만)
        |      +-- node_modules/.bin/vite 확인
        |      +-- 없으면 yarn install
        |      +-- yarn dev :8184
        |
        +-- Tomcat 시작 :8080
        |
        +-- Nginx 시작 :80
        v
Host ports publish
```

`yarn install`은 image build 단계가 아니라 개발 컨테이너 실행 시 필요한 경우 수행됩니다. 설치된 `node_modules`는 named volume에 보관되므로 컨테이너를 다시 만들더라도 볼륨이 유지되면 재사용할 수 있습니다.

### 4. 실행 상태 확인

```powershell
docker compose -f docker-compose.dev.yml ps
```

Reference 없는 구성은 해당 Compose 파일명을 사용합니다.

서비스별 로그:

```powershell
docker compose -f docker-compose.dev.yml logs --tail=100 nginx-staticweb
docker compose -f docker-compose.dev.yml logs --tail=100 vite-devserver
docker compose -f docker-compose.dev.yml logs --tail=100 ref-vite-devserver
docker compose -f docker-compose.dev.yml logs --tail=100 tomcat-frontend
```

### 5. 서버 접속 확인

```text
http://localhost:8080   Nginx를 통한 Main React
http://localhost:8183   Main Vite 직접 접속
http://localhost:8184   Reference Vite 직접 접속
http://localhost:18080  Tomcat 기본 Welcome 화면
```

Reference 없는 Compose에서는 `8184` 서버가 존재하지 않습니다.

### 6. 종료

Reference 포함:

```powershell
docker compose -f docker-compose.dev.yml down
```

Reference 제외:

```powershell
docker compose -f docker-compose.dev.no-reference.yml down
```

named volume까지 삭제하려면 `down -v`를 사용할 수 있지만, 이 경우 다음 실행 시 Yarn dependency를 다시 설치해야 합니다.

## Application Source와 Server Infrastructure 분리 원칙

이 개발환경에서는 다음 두 책임을 분리합니다.

```text
Server Infrastructure
├─ Nginx
├─ Vite runtime
└─ Tomcat

Application Source / Build
├─ React source
├─ Reference React source
└─ Maven source / WAR
```

특히 Tomcat은 Maven 소스가 없더라도 기동되어야 합니다. WAR 생성과 배포는 별도의 애플리케이션 build/deploy 과정으로 처리합니다. WAR가 배포되지 않은 상태에서는 Tomcat 기본 Welcome 화면을 서버 정상 여부 확인용으로 사용합니다.

## API Proxy

개발 Nginx 설정에서 `/api/*` 요청은 Tomcat으로 URI를 변경하지 않고 전달합니다.

```text
Browser /api/users
       |
       v
Nginx :8080
       |
       v
http://tomcat-frontend:8080/api/users
```

WAR가 배포되지 않은 상태에서는 `/api/*`에 애플리케이션 응답이 없을 수 있지만, 이것은 Tomcat 서버 기동 실패와는 구분해야 합니다.

## 공식 문서

- Docker Compose: https://docs.docker.com/compose/
- Docker bind mounts: https://docs.docker.com/engine/storage/bind-mounts/
- Docker volumes: https://docs.docker.com/engine/storage/volumes/
- Apache Tomcat 10.1: https://tomcat.apache.org/tomcat-10.1-doc/
- Vite server options: https://vite.dev/config/server-options
