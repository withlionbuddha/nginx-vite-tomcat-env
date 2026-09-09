# React Web Server와 Front WAS 개발 환경

React 소스는 호스트 폴더를 Vite 컨테이너의 `/workspace/web-ui`에 연결합니다. VS Code Dev Container는 같은 `vite-devserver`에 접속합니다. 초기화와 npm 설치는 Vite 시작 시 처리합니다.

## 실행 구성

| Compose 파일 | 실행하는 컨테이너 | 용도 |
| --- | --- | --- |
| `docker-compose.staticweb.dev.yml` | Nginx + Vite | React 개발, Dev Container 기본 구성 |
| `docker-compose.staticweb.prod.yml` | Nginx | 빌드한 React 정적 파일 제공 |
| `docker-compose.frontwas.dev.yml` | Tomcat | Front WAS 독립 개발 실행 |
| `docker-compose.frontwas.prod.yml` | Tomcat | Front WAS 독립 운영 구성 확인 |
| `docker-compose.dev.yml` | Nginx + Vite + Tomcat | 개발 화면과 API 프록시 통합 확인 |
| `docker-compose.prod.yml` | Nginx + Tomcat | 정적 화면과 API 프록시 통합 확인 |

정적 웹과 Front WAS의 분리 구성은 서로 다른 Compose 프로젝트와 네트워크를 사용합니다. 한쪽을 종료해도 다른 쪽의 컨테이너가 함께 종료되지 않도록 구분했습니다. Front WAS의 dev/prod 파일은 현재 같은 WAR 빌드 방식을 사용하며 Java 핫 리로드나 원격 디버깅은 포함하지 않습니다.

개발·운영 모드, 통합·분리 모드는 같은 서버의 대체 실행 방식입니다. 고정 컨테이너 이름과 공개 포트가 겹치므로 같은 `APP_NAME`으로 대체 모드를 동시에 실행하지 마십시오. 정적 웹 분리 구성과 Front WAS 분리 구성은 함께 실행할 수 있습니다.

## 환경 변수

저장소 루트의 `.env`에서 설정합니다. 기존 파일이 없을 때만 `.env.example`을 복사합니다.

| 변수 | 기본값 | 적용 범위 |
| --- | --- | --- |
| `APP_NAME` | `muilti-domain-rag` | Compose 프로젝트와 컨테이너 이름 |
| `NGINX_BIND_ADDRESS` | `127.0.0.1` | 모든 Nginx 구성의 호스트 바인딩 |
| `NGINX_PORT` | `8080` | 모든 Nginx 구성의 공개 포트 |
| `WEB_UI_HOST_PATH` | `../web-ui` | 개발 소스 마운트와 운영 React 빌드 입력 |
| `VITE_USE_POLLING` | `true` | Windows 파일 변경 감지 |
| `FRONTWAS_HOST_PATH` | `../frontend` | Maven 프로젝트 폴더; `pom.xml`이 있는 위치 |
| `FRONTWAS_BIND_ADDRESS` | `127.0.0.1` | 독립 Front WAS의 호스트 바인딩 |
| `FRONTWAS_PORT` | `18080` | 독립 Front WAS의 공개 포트 |

`WEB_UI_PATH=/workspace/web-ui`는 컨테이너 내부에서 초기화 스크립트가 사용하는 경로입니다. 호스트 경로인 `WEB_UI_HOST_PATH`와 용도가 다릅니다. Vite 내부 포트는 `8183`, Tomcat 내부 포트는 `8080`으로 고정하며 공개 포트와 구분합니다.

기존에 `STATICWEB_PORT`, `STATICWEB_BIND_ADDRESS`를 설정했다면 각각 `NGINX_PORT`, `NGINX_BIND_ADDRESS`로 옮기십시오. 현재 저장소에 있는 `APP_NAME` 값은 기존 식별자를 보존하기 위해 유지했습니다.

## 호스트와 소스 폴더

Windows에는 Docker Desktop의 WSL 2 엔진과 Linux 컨테이너 모드, VS Code, Dev Containers 확장이 필요합니다. 운영 빌드와 Front WAS 빌드는 named build context를 사용하므로 Docker Compose 2.17 이상과 이를 지원하는 BuildKit/buildx가 필요합니다.

| 실행 위치 | React 경로 예시 | Front WAS 경로 예시 |
| --- | --- | --- |
| Windows VS Code / PowerShell | `F:/project.asdf/web-ui` | `F:/project.asdf/frontend` |
| Docker Desktop과 연동된 WSL 배포판 | `/mnt/f/project.asdf/web-ui` | `/mnt/f/project.asdf/frontend` |
| Linux / 클라우드 Docker 호스트 | `/srv/project.asdf/web-ui` | `/srv/project.asdf/frontend` |

Windows에서 실행할 때 Docker Desktop 내부 VM 경로를 직접 지정하지 않습니다. 상대 경로는 Compose 파일이 있는 폴더가 기준입니다. 원격 Docker 호스트를 사용할 때는 그 호스트에 소스가 있어야 합니다.

`../frontend`는 기본 경로 예시입니다. 실제 Spring 소스는 이 저장소에 포함되어 있지 않으므로 `FRONTWAS_HOST_PATH`를 실제 프로젝트 위치로 지정하십시오. Front WAS 빌드는 해당 폴더의 Maven 프로젝트에서 `target/*.war` 하나가 생성되는 구성을 전제로 합니다. Spring 버전과 WAR의 Tomcat 호환성은 실제 `pom.xml`에서 확인해야 합니다.

## Dev Container로 React 개발하기

PowerShell에서 저장소와 React 폴더를 준비합니다.

```powershell
Set-Location F:\project.asdf\nginx-vite-tomcat-env
New-Item -ItemType Directory -Force F:\project.asdf\web-ui
code .
```

`.env`의 React 소스 경로를 설정합니다.

```dotenv
WEB_UI_HOST_PATH=F:/project.asdf/web-ui
VITE_USE_POLLING=true
```

VS Code 명령 팔레트에서 **Dev Containers: Reopen in Container**를 실행합니다. 변경된 설정을 적용할 때는 **Dev Containers: Rebuild and Reopen in Container**를 실행합니다.

컨테이너가 소스를 마운트한 뒤 프로젝트 생성, 의존성 설치, Vite 실행을 순서대로 처리합니다. `package.json`이 있으면 기존 프로젝트를 사용합니다. 잠금 파일이 있으면 `npm ci`, 없으면 `npm install`을 실행합니다. `package.json` 없이 다른 소스가 있는 폴더는 덮어쓰지 않고 중단합니다.

VS Code 터미널의 `pwd`는 `/workspace/web-ui`여야 합니다. 여기서 수정한 파일은 호스트의 React 폴더에도 반영됩니다. `node_modules`는 Docker 볼륨에 별도로 보관하며 Windows의 의존성과 섞이지 않습니다.

Vite 준비 메시지가 나오면 `http://localhost:8080`으로 접속합니다. 최초 패키지 설치 중에는 일시적으로 Nginx 502 응답이 나올 수 있습니다. Vite는 자동 실행되므로 `npm run dev`를 중복 실행할 필요가 없습니다.

## 호스트 터미널에서 실행하기

React 개발:

```sh
docker compose -f docker-compose.staticweb.dev.yml config --quiet
docker compose -f docker-compose.staticweb.dev.yml up --build -d
docker compose -f docker-compose.staticweb.dev.yml logs -f vite-devserver
```

Front WAS 독립 실행:

```sh
docker compose -f docker-compose.frontwas.dev.yml config --quiet
docker compose -f docker-compose.frontwas.dev.yml up --build -d
```

개발 통합 확인:

```sh
docker compose -f docker-compose.dev.yml config --quiet
docker compose -f docker-compose.dev.yml up --build -d
```

같은 파일을 지정한 `docker compose -f <파일명> down`으로 종료합니다. 통합 구성으로 전환하기 전에는 사용 중인 분리 구성을 먼저 종료합니다.

기존 `scripts/init-web-ui.ps1`은 Vite 컨테이너를 시작하는 보조 명령으로 변경했습니다. 호스트 Node.js/npm을 호출하지 않으며, 패키지 설치 상태는 Vite 로그에서 확인합니다. Dev Container를 이용한다면 이 보조 명령을 따로 실행할 필요가 없습니다.

## 운영 빌드와 API 경로

정적 웹 운영 구성:

```sh
docker compose -f docker-compose.staticweb.prod.yml up --build -d
```

통합 운영 구성:

```sh
docker compose -f docker-compose.prod.yml up --build -d
```

Nginx 이미지는 `WEB_UI_HOST_PATH`의 `package.json`과 `package-lock.json`으로 의존성을 설치한 뒤 React를 빌드합니다. 호스트의 `node_modules`와 기존 `dist`는 이미지 빌드에 복사하지 않습니다. 최종 Nginx 이미지에는 빌드 결과 `dist`를 배치합니다.

Tomcat 이미지는 `FRONTWAS_HOST_PATH`의 소스를 `/workspace/frontend`에서 빌드하고 `/workspace/frontend/target/*.war`를 `ROOT.war`로 배포합니다. 이 이름은 애플리케이션을 Tomcat의 루트 컨텍스트에 배치하므로 내부 URL에도 별도 WAR 이름이 붙지 않습니다.

공개 API 경로는 일반적으로 `/api/*`처럼 클라이언트 계약으로 고정하고 내부 WAR 이름을 노출하지 않습니다. 통합 구성은 URI가 없는 `proxy_pass http://tomcat-frontend:8080;`을 사용하므로 Nginx가 `/api/users?active=true`를 같은 경로와 질의 문자열로 전달합니다. Spring 컨트롤러도 `/api/*`를 처리해야 하며, 별도의 `/rag` 또는 `/frontweb` 컨텍스트 경로는 설정하지 않는 구성을 전제로 합니다.

| 구성 | 화면 요청 | API 요청 |
| --- | --- | --- |
| 분리 개발 | Nginx에서 Vite로 전달 | Front WAS 주소를 직접 사용하는 경우 애플리케이션의 CORS·인증 설정 필요 |
| 분리 운영 | Nginx에서 `dist` 제공 | `/api/*`는 404; Front WAS 프록시 없음 |
| 통합 개발 | Nginx에서 Vite로 전달 | `/api/*` → `tomcat-frontend:8080/api/*` |
| 통합 운영 | Nginx에서 `dist` 제공 | `/api/*` → `tomcat-frontend:8080/api/*` |

분리 운영용 Nginx와 통합 운영용 Nginx는 서로 다른 설정 파일과 이미지 태그를 사용합니다. 실제 API 컨트롤러가 없으면 올바른 프록시 경로라도 WAS는 404를 반환할 수 있습니다.

## 설정 변경 후 확인

이번 변경으로 Compose 프로젝트 이름과 네트워크 구분이 바뀝니다. 기존 컨테이너가 실행 중이면 **기존 설정으로 해당 구성을 종료한 뒤** 수정본을 적용하십시오. 소스 폴더를 옮기거나 기존 볼륨을 삭제할 필요는 없습니다. 새 프로젝트의 의존성 볼륨은 시작 시 다시 설치됩니다.

| 증상 | 확인할 사항 |
| --- | --- |
| 마운트 경로가 없다는 오류 | `WEB_UI_HOST_PATH`의 실제 폴더 생성 여부와 Windows/WSL 표기 |
| Front WAS 빌드 실패 | `FRONTWAS_HOST_PATH/pom.xml`, WAR 패키징과 JDK/Tomcat 호환성 |
| 운영 React 빌드 실패 | 소스 폴더의 `package-lock.json`과 실제 `npm run build` |
| Nginx API 연결 실패 | 통합 구성을 사용하는지, `tomcat-frontend`의 `ROOT.war` 실행 상태와 Spring의 `/api/*` 매핑 |
| 포트 변경이 반영되지 않음 | `.env`의 `NGINX_PORT`와 컨테이너 재생성 여부 |
| Windows 변경 사항이 갱신되지 않음 | `VITE_USE_POLLING=true`, 프로젝트의 `server.watch` 설정 |
| 기존 컨테이너 이름 충돌 | 설정 변경 전 실행한 구성을 종료했는지 확인 |

## 공식 문서

- [Docker Compose의 프로젝트 구분](https://docs.docker.com/compose/how-tos/project-name/)
- [Docker Compose의 추가 빌드 컨텍스트](https://docs.docker.com/reference/compose-file/build/#additional_contexts)
- [Docker의 바인드 마운트](https://docs.docker.com/engine/storage/bind-mounts/)
- [Tomcat WAR 배포와 컨텍스트 경로](https://tomcat.apache.org/tomcat-10.1-doc/deployer-howto.html)
- [VS Code의 Compose 컨테이너 연결](https://code.visualstudio.com/remote/advancedcontainers/connect-multiple-containers)
- [Vite의 WSL 2 파일 변경 감지](https://vite.dev/config/server-options#server-watch)
