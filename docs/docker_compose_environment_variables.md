# Docker 환경변수 적용 방법


## 파일과 설정 위치

```text
DEV_ENV/
├── .env                         # Compose가 설정 치환에 사용하는 기본 파일
├── compose.yml                  # services와 build 설정
└── nginx/
    ├── nginx.env                # env_file이 참조하는 실제 파일
    ├── Dockerfile.dev           # ARG, COPY 등 이미지 빌드 명령
    └── default.conf             # Nginx 설정 템플릿 예시
```

다음은 `compose.yml`의 `services` 안에서 `nginx` 서비스에 환경변수 파일을 지정하는 예입니다.

```yaml
# DEV_ENV/compose.yml
services:
  nginx:
    image: nginx:alpine
    env_file:
      - ./nginx/nginx.env
```

`env_file`은 설정 항목이며, `./nginx/nginx.env`는 읽을 실제 파일의 경로입니다.  
이 예에서는 해당 파일의 값이 `nginx` 컨테이너에 전달됩니다. 

## 적용시점

Image Build(이미지 빌드), Container(컨테이너), Environment Variable(환경변수), Interpolation(변수 치환)을 기준으로 적용 시점을 비교합니다.

| 방법 | 주로 사용하는 시점 | 사용하는 대상 | 변경 후 필요한 작업 |
|---|---|---|---|
| `project/.env` | Compose 설정 해석 | `compose.yaml`의 `${VAR}` | Compose 명령 재실행. 결과가 컨테이너 설정이면 재생성, 빌드 인자이면 재빌드 |
| `compose.yml`의 `env_file` | 컨테이너 생성 | 해당 서비스 컨테이너의 환경 | 컨테이너 재생성 |
| `compose.yml`의 `environment` | 컨테이너 생성 | 해당 서비스 컨테이너의 환경 | 컨테이너 재생성 |
| `compose.yml`의 `build.args` + Dockerfile `ARG` | 이미지 빌드 | Dockerfile 빌드 단계 | 이미지 재빌드. 컨테이너에 반영하려면 재생성 |

> **핵심:** `.env`는 Compose가 설정을 해석할 때 사용합니다. `env_file`과 `environment`는 컨테이너에 값을 전달합니다. `ARG`는 이미지 빌드에 사용합니다.

## 목차

1. [Container Lifecycle(컨테이너 생명주기)별 흐름](#1-container-lifecycle컨테이너-생명주기별-흐름)
2. [Compose 설정 해석: `.env`](#2-compose-설정-해석-env)
3. [이미지 빌드: `build.args`와 `ARG`](#3-이미지-빌드-buildargs와-arg)
4. [컨테이너 생성: `env_file`과 `environment`](#4-컨테이너-생성-env_file과-environment)
5. [생성 후와 실행 중 변경](#5-생성-후와-실행-중-변경)
6. [우선순위와 치환 문법](#6-우선순위와-치환-문법)
7. [Nginx Template(템플릿) 예시](#7-nginx-template템플릿-예시)
8. [확인 명령과 오류 진단](#8-확인-명령과-오류-진단)

---

## 1. Container Lifecycle(컨테이너 생명주기)별 흐름

### ① Compose Configuration Resolution(Compose 설정 해석)

Compose가 셸 환경과 `.env` 등의 값을 읽어 Compose 파일의 `${VAR}`를 실제 값으로 바꿉니다. `ports`, `volumes`, `build.args`, `environment` 등에 적용할 수 있습니다.

### ② Image Build(이미지 빌드)

`build.args`가 Dockerfile의 `ARG`에 값을 전달합니다. `RUN`과 `COPY` 등 빌드 명령에서 사용합니다. `ARG`는 자동으로 실행 시 환경변수가 되지 않습니다.

### ③ Container Creation and Start(컨테이너 생성 및 시작)

이미지의 `ENV`, 서비스 `env_file`, `environment` 등을 바탕으로 컨테이너 환경이 결정됩니다. 프로그램과 시작 스크립트가 해당 값을 읽습니다.

### ④ 실행 중과 생성 후

호스트에서 `.env`나 `env_file`을 바꾸어도 이미 생성된 컨테이너의 환경은 바뀌지 않습니다. `docker compose restart`도 새 설정을 적용하지 않습니다. 변경된 컨테이너 환경을 사용하려면 **재생성**합니다.

## 2. Compose 설정 해석: `.env`

### 2-1. 기본 사용법

보통 Compose 프로젝트 디렉터리의 이름이 정확히 `.env`인 파일을 자동으로 읽습니다. `nginx.env`처럼 이름이 다른 파일은 자동으로 기본 파일이 되지 않습니다.

```dotenv
# project/.env
APP_NAME=demo
NGINX_HOST_PORT=8080
```

```yaml
# DEV_ENV/compose.yml
services:
  nginx:
    image: nginx:alpine
    container_name: nginx-${APP_NAME}
    ports:
      - "${NGINX_HOST_PORT}:80"
```

Compose가 해석한 포트 연결은 `8080:80`입니다. **`.env`에 작성한 값이 컨테이너에 자동 전달되는 것은 아닙니다.**

프로젝트 디렉터리는 `--project-directory`, 첫 번째 Compose 파일, 실행 위치 등에 따라 결정됩니다. 여러 Compose 파일을 `-f`로 병합하면 경로 기준에 유의합니다.

### 2-2. 다른 이름 또는 위치의 파일

```powershell
docker compose --env-file .\config\compose.dev.env -f docker-compose.dev.yml config
```

`--env-file`은 이 Compose 명령의 **설정 치환용 파일**입니다. 서비스 아래 `env_file:`과 구분합니다. 여러 `--env-file`을 지정하면 같은 변수에 대해 뒤의 파일이 앞 파일보다 우선합니다. 셸에 같은 변수가 있으면 셸 값이 우선할 수 있습니다.

```powershell
docker compose -f docker-compose.dev.yml config --environment
```

`COMPOSE_ENV_FILES` 또는 `include.env_file`도 있으나 각각 별도의 Compose 기능입니다.

### 2-3. `.env` 값으로 포트와 파일 경로 지정

```dotenv
# DEV_ENV/.env
SSL_HOST_DIR=F:/project.earth.power/tools/keystore
NGINX_HOST_SSL_PORT=443
```

```yaml
services:
  nginx:
    ports:
      - "${NGINX_HOST_SSL_PORT}:443"
    volumes:
      - "${SSL_HOST_DIR}:/etc/nginx/ssl:ro"
```

`ports`와 `volumes`의 변수는 Compose가 컨테이너를 만들기 전에 치환합니다. 서비스 `env_file`의 값은 이 치환에 자동으로 사용되지 않습니다.

## 3. 이미지 빌드: `build.args`와 `ARG`

설정 위치: `compose.yml`의 `nginx` 서비스에서 `build.args`를 작성하고 Dockerfile에서 `ARG`를 선언합니다.

```dotenv
# DEV_ENV/.env
NGINX_CONFIG=default.env.dev.conf
```

```yaml
# DEV_ENV/compose.yml
services:
  nginx:
    build:
      context: .
      args:
        NGINX_CONFIG: "${NGINX_CONFIG:-default.env.dev.conf}"
```

```dockerfile
FROM nginx:alpine
ARG NGINX_CONFIG=default.env.dev.conf
COPY nginx/${NGINX_CONFIG} /etc/nginx/templates/default.conf.template
```

1. Compose가 `project/.env`에서 `NGINX_CONFIG`를 읽습니다.
2. `compose.yml`에 작성한 `build.args`가 값을 빌드에 전달합니다.
3. Dockerfile의 `ARG`가 값을 받아 `COPY`에서 사용합니다.

빌드 인자 또는 Dockerfile에서 복사하는 원본을 바꾸면 재빌드합니다.

```powershell
docker compose -f docker-compose.dev.yml build nginx
docker compose -f docker-compose.dev.yml up -d nginx
```

**`ARG`는 빌드용**이므로 컨테이너의 프로그램이 자동으로 읽을 수 없습니다. 서비스 `env_file`도 Dockerfile의 `RUN`에 자동으로 전달되지 않습니다. `ARG`는 각 빌드 단계의 선언 범위에 주의해야 합니다.

### Dockerfile `ENV`: Image Default Environment(이미지 기본 환경)

`ENV`는 빌드 단계에서 사용되며 이미지의 기본 환경으로 남습니다.

```dockerfile
ARG APP_MODE=dev
ENV APP_MODE=${APP_MODE}
```

이 경우 `ARG`의 값을 명시적으로 `ENV`로 복사한 것입니다. 컨테이너 생성 시 `env_file`이나 `environment`로 같은 값을 덮어쓸 수 있습니다. 비밀번호나 개인키를 `ARG` 또는 `ENV`에 넣지 마세요.

## 4. 컨테이너 생성: `env_file`과 `environment`

### 4-1. `compose.yml`의 `env_file`

```dotenv
# DEV_ENV/nginx/nginx.env
SERVER_NAME=localhost
TOMCAT_HOST=tomcat-frontend
TOMCAT_PORT=8080
```

```yaml
services:
  nginx:
    image: nginx:alpine
    env_file:
      - ./nginx/nginx.env
```

`compose.yml`의 `nginx` 서비스에 `env_file`을 작성하며, 값이 있는 실제 파일은 `project/nginx/nginx.env`입니다. 변수는 **이 `nginx` 서비스의 컨테이너**에 전달됩니다. 다른 서비스에 필요하면 그 서비스에도 설정해야 합니다.

여러 파일을 나열할 수 있습니다. 같은 이름이 있으면 뒤 파일의 값이 우선합니다.

```yaml
env_file:
  - ./nginx/common.env
  - ./nginx/dev.env
```

### 4-2. `compose.yml`의 `environment`

Compose에 값을 직접 쓰거나 `.env` 값을 치환해 전달할 수 있습니다.

```dotenv
# DEV_ENV/.env
NGINX_CONTAINER_PORT=80
```

```yaml
services:
  nginx:
    env_file:
      - ./nginx/nginx.env
    environment:
      NGINX_CONTAINER_PORT: "${NGINX_CONTAINER_PORT:-80}"
      TOMCAT_HOST: tomcat-frontend
```

같은 변수가 `env_file`과 `environment` 양쪽에 있으면 **`environment`가 우선**합니다. 값을 비워 지정해도 우선할 수 있습니다.

### 4-3. 컨테이너마다 다른 값

```yaml
services:
  frontend:
    environment:
      APP_MODE: frontend
  backend:
    environment:
      APP_MODE: backend
```

두 컨테이너의 환경은 별도입니다. 한 서비스에 지정한 값은 다른 서비스에 자동 전달되지 않습니다.

## 5. 생성 후와 실행 중 변경

| 상황 | 변경 효과 |
|---|---|
| 호스트에서 `.env` 또는 `env_file` 수정 | 실행 중인 기존 컨테이너 환경은 그대로 |
| `docker compose restart` | 기존 컨테이너를 재시작. 변경한 환경설정 미반영 |
| `docker compose up -d --force-recreate 서비스` | 현재 Compose 설정으로 컨테이너 재생성 |
| Dockerfile `ARG` 또는 `ENV` 변경 | 재빌드 후 새 이미지로 컨테이너 재생성 필요 |
| `docker exec -e` | 새로 실행하는 해당 프로세스에만 적용 |
| 컨테이너 셸의 `export` | 해당 셸과 그 셸에서 시작한 자식 프로세스에만 적용 |

```powershell
# 환경설정을 변경한 후
docker compose -f docker-compose.dev.yml up -d --force-recreate nginx-staticweb

# 이미지 빌드 내용도 변경한 후
docker compose -f docker-compose.dev.yml up -d --build nginx-staticweb
```

`docker cp`로 컨테이너 내부에 넣은 파일은 컨테이너를 재생성하면 사라집니다. Bind Mount(바인드 마운트)의 원본과 Named Volume(이름 있는 볼륨)은 컨테이너와 별도로 보관됩니다.

### 일회성 프로세스에만 값 전달

```powershell
docker exec -e APP_MODE=debug nginx-staticweb-demo printenv APP_MODE
```

이 명령의 `APP_MODE`는 새로 실행한 `printenv` 프로세스에만 적용됩니다. **이미 실행 중인 Nginx의 환경이나 설정은 바뀌지 않습니다.**

`docker compose run -e`는 새 일회성 컨테이너에서 사용할 값을 지정합니다. 기존 서비스 컨테이너를 수정하지 않습니다.

## 6. 우선순위와 치환 문법

### 6-1. Compose Interpolation(Compose 변수 치환) 시

일반적으로 셸 환경변수가 우선하고, 다음으로 `--env-file`, 지정하지 않았다면 프로젝트 기본 `.env`를 사용합니다. 환경에 따라 `COMPOSE_FILE` 관련 추가 `.env`가 읽히는 예외가 있습니다.

### 6-2. 컨테이너 환경을 만들 때

- 서비스 `environment`는 같은 변수의 서비스 `env_file`보다 우선합니다.
- 여러 서비스 `env_file`은 뒤에 나열한 파일이 우선합니다.
- 이미지 `ENV`는 Compose 설정에서 같은 값을 지정하지 않았을 때 기본값입니다.
- `docker compose run -e`는 `run`으로 만드는 일회성 컨테이너에 우선 적용됩니다.

값이 어디서 치환되었는지에 따른 상세 사례는 아래 공식 우선순위 문서를 참고하세요.

### 6-3. 자주 사용하는 문법

| 문법 | 의미 |
|---|---|
| `${VAR}` | 변수 값. 미설정 시 경고 후 빈 문자열이 될 수 있음 |
| `${VAR:-default}` | 미설정이거나 빈 문자열이면 기본값 |
| `${VAR-default}` | 미설정일 때만 기본값 |
| `${VAR:?message}` | 미설정이거나 빈 문자열이면 오류 |
| `${VAR?message}` | 미설정이면 오류 |
| `$$` | Compose 치환을 피하고 `$`를 전달 |

Compose의 env 파일과 Bash 문법은 완전히 같지 않습니다. `source`는 파일을 Bash 코드로 실행하므로 신뢰할 수 있는 파일에만 사용합니다.

## 7. Nginx Template(템플릿) 예시

공식 Nginx 이미지의 기본 Entrypoint(시작 진입점)는 `/etc/nginx/templates/*.template`을 읽어 환경변수를 치환한 후 `/etc/nginx/conf.d/`에 설정을 생성합니다.

```dockerfile
FROM nginx:alpine
COPY nginx/default.conf /etc/nginx/templates/default.conf.template
```

```dotenv
# DEV_ENV/nginx/nginx.env
SERVER_NAME=localhost
```

```yaml
services:
  nginx:
    build: .
    env_file:
      - ./nginx/nginx.env
    environment:
      NGINX_CONTAINER_PORT: "${NGINX_CONTAINER_PORT:-80}"
```

```nginx
# nginx/default.conf — 템플릿
server {
    listen ${NGINX_CONTAINER_PORT};
    server_name ${SERVER_NAME};
}
```

여기에는 두 번의 치환이 있습니다.

1. Compose가 `environment`의 `${NGINX_CONTAINER_PORT:-80}`을 해석하고 컨테이너에 값을 전달합니다.
2. 컨테이너 시작 시 Nginx 이미지가 템플릿의 `${NGINX_CONTAINER_PORT}`와 `${SERVER_NAME}`을 치환합니다.

`NGINX_ENVSUBST_FILTER`는 Nginx 이미지의 **선택 설정**으로 치환할 환경변수 이름을 제한합니다. 사용 중이라면 포트 변수를 포함해야 합니다. Nginx 자체 변수 `$host` 등이 실수로 치환되지 않도록 이름 충돌에도 주의합니다.

`nginx -s reload`는 생성된 설정을 다시 읽지만, 컨테이너 환경을 변경하거나 템플릿을 다시 처리하지 않습니다. `env_file`의 값을 바꾸면 컨테이너를 재생성하세요.

## 8. 확인 명령과 오류 진단

```powershell
# Compose가 치환에 사용할 환경 확인
docker compose -f docker-compose.dev.yml config --environment

# 치환된 Compose 모델 확인
docker compose -f docker-compose.dev.yml config

# 컨테이너 생성 시 등록된 환경 확인. 중지된 컨테이너도 가능
docker inspect <컨테이너ID> --format '{{range .Config.Env}}{{println .}}{{end}}'

# 실행 중인 컨테이너의 Nginx 설정 검사
docker compose -f docker-compose.dev.yml exec nginx-staticweb nginx -t
```

출력에 비밀번호나 토큰이 있을 수 있으므로 공유하기 전에 제거합니다. `docker inspect`는 컨테이너 설정에 기록된 환경을 표시하며 애플리케이션이 자체적으로 변경한 모든 프로세스 환경을 뜻하지는 않습니다.

| 증상 | 확인할 부분 |
|---|---|
| `${NGINX_CONTAINER_PORT}`가 그대로 남음 | 컨테이너에 값이 전달됐는지, Nginx 치환 필터에 포함됐는지 확인 |
| `RUN mkdir -p ${SSL_DIR}` 실패 | 빌드 단계에 `ARG`가 선언되고 `build.args`로 전달됐는지 확인 |
| env 파일 수정 후 값이 그대로 | 올바른 Compose 설정으로 컨테이너를 재생성했는지 확인 |
| Windows 경로 앞에 다른 경로가 붙음 | Compose를 Windows에서 실행하는지 확인하고 `F:/...` 형식의 실제 경로 사용 |

## 공식 자료

- [Compose 환경변수 치환](https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/)
- [서비스의 환경변수 설정](https://docs.docker.com/compose/how-tos/environment-variables/set-environment-variables/)
- [환경변수 우선순위](https://docs.docker.com/compose/how-tos/environment-variables/envvars-precedence/)
- [Docker 빌드 변수](https://docs.docker.com/build/building/variables/)
- [`docker compose restart`](https://docs.docker.com/reference/cli/docker/compose/restart/)
- [`docker exec --env`](https://docs.docker.com/reference/cli/docker/container/exec/)
- [공식 Nginx 이미지 템플릿](https://github.com/docker-library/docs/blob/master/nginx/content.md)
