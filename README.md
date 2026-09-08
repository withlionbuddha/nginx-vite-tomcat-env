# React 개발 환경: Nginx + Vite / Front WAS

VS Code Dev Container는 Docker Compose의 `vite-devserver`에 직접 연결합니다. React 소스는 호스트의 `web-ui` 폴더를 컨테이너의 `/workspace/web-ui`에 바인드 마운트합니다.

## 작업 폴더 연결

| 구분 | 경로 또는 설정 | 역할 |
| --- | --- | --- |
| Windows React 소스 | `F:/project.asdf/web-ui` | 소스와 `package.json`, 잠금 파일을 호스트에 보관 |
| 환경 설정 저장소 | `F:/project.asdf/nginx-vite-tomcat-env` | Compose, Dockerfile, Dev Container 설정 |
| Vite 작업 경로 | `/workspace/web-ui` | 호스트의 React 소스와 같은 파일을 읽고 수정 |
| VS Code 작업 경로 | `/workspace/web-ui` | `vite-devserver`에 접속한 상태로 열리는 폴더 |
| Linux 의존성 | `/workspace/web-ui/node_modules` | `vite_node_modules`라는 Docker 볼륨 사용 |

소스 수정은 호스트 폴더에도 반영됩니다. Windows의 기존 `node_modules`는 컨테이너에서 별도 볼륨으로 가려지므로 Linux용 의존성과 섞이지 않습니다. 볼륨의 실제 이름에는 Compose 프로젝트 이름이 붙습니다.

## 1. 호스트 경로 설정

Windows에 Docker Desktop(WSL 2 엔진, Linux 컨테이너 모드), VS Code와 Dev Containers 확장이 필요합니다. Node.js와 npm은 Vite 컨테이너 안에서 실행합니다.

PowerShell에서 환경 설정 저장소를 열고 React 폴더가 존재하는지 확인합니다.

```powershell
Set-Location F:\project.asdf\nginx-vite-tomcat-env
New-Item -ItemType Directory -Force F:\project.asdf\web-ui
code .
```

저장소 루트의 `.env`에 다음 값을 설정합니다. 기존 `.env`의 다른 값은 유지합니다.

```dotenv
WEB_UI_HOST_PATH=F:/project.asdf/web-ui
VITE_USE_POLLING=true
```

| Compose를 실행하는 위치 | `WEB_UI_HOST_PATH` 예시 |
| --- | --- |
| Windows VS Code / PowerShell | `F:/project.asdf/web-ui` |
| Docker Desktop과 연동된 WSL 배포판의 셸 | `/mnt/f/project.asdf/web-ui` |
| Linux 또는 클라우드 Docker 호스트 | `/srv/project.asdf/web-ui` |
| 저장소와 React 폴더가 같은 부모 폴더에 있는 경우 | `../web-ui` — 기본값 |

Windows에서 실행할 때 Docker Desktop 내부의 VM 경로를 직접 지정할 필요는 없습니다. `/mnt/f/...`는 WSL 배포판에서 실행할 때의 예시입니다. 원격 Docker 호스트에서는 해당 호스트에 소스가 있어야 합니다.

상대 경로는 Compose 파일이 있는 디렉터리를 기준으로 해석합니다. 경로 오타로 빈 프로젝트가 생기지 않도록 `create_host_path: false`를 설정했으므로, 지정한 호스트 폴더는 미리 만들어야 합니다.

## 2. Dev Container로 열기

1. VS Code에서 `nginx-vite-tomcat-env` 폴더를 엽니다.
2. `Ctrl+Shift+P`에서 **Dev Containers: Reopen in Container**를 실행합니다. 기존 연결을 갱신할 때는 **Dev Containers: Rebuild and Reopen in Container**를 실행합니다.
3. `docker-compose.staticweb.dev.yml`로 `vite-devserver`와 `nginx-staticweb`이 시작됩니다.
4. VS Code는 `vite-devserver`의 `/workspace/web-ui`를 엽니다.
5. Vite 로그에 서버 준비 메시지가 나오면 `http://localhost:8080`에 접속합니다.

컨테이너 시작 명령이 프로젝트 초기화, 의존성 설치, Vite 실행을 순서대로 처리합니다. 따라서 별도의 `postCreateCommand`에서 개발 서버를 실행하지 않습니다. 최초 설치 중에는 편집기가 먼저 열릴 수 있으며 Nginx 접속 시 잠시 502가 나올 수 있습니다.

Dev Container 터미널에서 확인합니다.

```sh
pwd
node --version
npm --version
ls package.json src
```

`pwd`는 `/workspace/web-ui`여야 합니다. 여기서 `src/App.tsx`를 수정하면 호스트의 같은 파일이 바뀌며 Vite가 변경을 감지합니다. Vite는 이미 컨테이너의 시작 명령으로 실행 중이므로 `npm run dev`를 중복 실행할 필요가 없습니다.

## 3. VS Code 없이 실행하기

저장소 폴더의 PowerShell 또는 호스트 셸에서 실행합니다.

```sh
docker compose -f docker-compose.staticweb.dev.yml config
docker compose -f docker-compose.staticweb.dev.yml up --build -d
docker compose -f docker-compose.staticweb.dev.yml logs -f vite-devserver
```

기본 접속 주소는 `http://localhost:8080`입니다. 정적 웹 개발용 포트를 변경할 때는 `.env`에 `STATICWEB_PORT`를 지정합니다. 종료는 `docker compose -f docker-compose.staticweb.dev.yml down`입니다.

초기화만 수행하려면 Vite를 중지한 상태에서 실행합니다. 일반적인 Dev Container 시작에서는 이 명령을 따로 실행하지 않아도 됩니다.

```sh
docker compose -f docker-compose.staticweb.dev.yml --profile init run --rm --build web-ui-init
```

`web-ui-init`도 Vite와 동일한 소스 경로와 의존성 볼륨을 사용합니다. `package.json`이 있으면 기존 프로젝트를 사용하고, 잠금 파일이 있으면 `npm ci`, 없으면 `npm install`을 실행합니다. 빈 작업 폴더는 React + TypeScript 템플릿으로 생성합니다. `package.json` 없이 다른 소스가 있는 폴더는 덮어쓰지 않고 중단합니다.

## 4. 서버별 역할

| 컨테이너 | 개발 환경에서 수행하는 작업 |
| --- | --- |
| `nginx-staticweb` | 브라우저 요청과 HMR WebSocket을 `vite-devserver:8183`으로 전달 |
| `vite-devserver` | React 소스 마운트, Node.js/npm 실행, Vite 서버, VS Code 접속 |
| `tomcat-frontend` | 통합 개발용 Compose에서 Front WAS 실행 |

Dev Container의 기본 Compose는 React 개발에 필요한 Nginx와 Vite만 실행합니다. `nginx/default.staticweb.dev.conf`에는 Tomcat 의존성이 없습니다.

기존 통합 구성인 `docker-compose.dev.yml`에도 동일한 React 마운트를 적용했습니다. 통합 구성의 Nginx는 `/api/*`를 `tomcat-frontend:8080/rag/api/*`로 전달합니다. 두 개발용 Compose를 동시에 실행하면 Vite 컨테이너 이름과 공개 포트가 충돌하므로, 기존 구성을 종료한 뒤 선택한 구성을 시작하십시오.

**기존 Front WAS 구성의 확인 사항:** 현재 `tomcat-frontend/Dockerfile`은 `frontend`에서 빌드한 뒤 `frontweb/target`에서 WAR를 복사합니다. 배포 이름 `frontweb.war`와 Nginx의 `/rag` 경로도 다릅니다. 통합 서버 실행 전 실제 Spring 프로젝트에 맞춰 확인해야 합니다. 이 변경은 React 작업 폴더 연결과 정적 웹 개발 경로를 대상으로 합니다.

운영용 Compose와 Nginx Dockerfile에는 이전 저장소명인 `nginx-vite-tomcat-compose` 경로가 남아 있습니다. 위 개발용 명령은 운영 빌드 절차가 아니며, 운영 배포 전에는 경로와 WAR 배포 구성을 별도로 점검해야 합니다.

## 오류 확인

| 증상 | 확인 방법 |
| --- | --- |
| React 폴더가 열리지 않음 | `.env`의 실제 호스트 경로와 Dev Container의 `service: vite-devserver` 확인 후 Rebuild |
| `bind source path does not exist` | `WEB_UI_HOST_PATH` 폴더를 먼저 생성하고 Windows/WSL 경로 표기 확인 |
| `package.json`이 없어 빌드 실패 | 변경된 개발용 Dockerfile은 소스를 `COPY`하지 않습니다. 변경 파일을 모두 받은 뒤 Rebuild |
| npm 설치 오류 | Vite 로그에서 잠금 파일 일치 여부, 패키지 레지스트리와 프록시 연결 확인 |
| Rebuild 후 의존성 설치가 다시 실행됨 | 시작 시 잠금 파일 기준으로 Linux 볼륨의 의존성을 설치하는 동작 |
| Windows에서 저장해도 화면 갱신이 안 됨 | `VITE_USE_POLLING=true` 확인. 프로젝트의 `server.watch`가 이를 덮어쓰는지도 확인 |
| 이미지 다운로드 실패 | 기존 고정 이미지 태그의 레지스트리 제공 여부와 네트워크 확인 |
| Nginx가 502를 반환함 | `logs -f vite-devserver`에서 설치 완료와 `0.0.0.0:8183` 실행 여부 확인 |

## 공식 문서

- [VS Code: Docker Compose 컨테이너 연결](https://code.visualstudio.com/remote/advancedcontainers/connect-multiple-containers)
- [Docker Compose: 볼륨과 작업 경로](https://docs.docker.com/reference/compose-file/services/#volumes)
- [Docker: 바인드 마운트](https://docs.docker.com/engine/storage/bind-mounts/)
- [Vite: WSL 2 파일 변경 감지](https://vite.dev/config/server-options#server-watch)
