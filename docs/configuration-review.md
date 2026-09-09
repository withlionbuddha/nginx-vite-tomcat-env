# 설정 불일치 점검 및 수정안

점검 대상: [withlionbuddha/nginx-vite-tomcat-env PR #1](https://github.com/withlionbuddha/nginx-vite-tomcat-env/pull/1)

기준 커밋: `a4667ccaab47c7c526036b9356e62204aa9c92bb`

이 문서는 해당 커밋을 기준으로 준비한 수정 내역입니다.

## 확인된 문제와 수정 내용

| 번호 | 영향 | 확인된 문제 | 수정 내용 |
| --- | --- | --- | --- |
| 1 | 이미지 빌드 실패 | 운영·독립 WAS Compose가 저장소에 없는 `nginx-vite-tomcat-compose/tomcat-frontweb/Dockerfile` 등을 참조 | 저장소 루트 `context: .`와 실제 `nginx/Dockerfile.prod`, `tomcat-frontend/Dockerfile` 경로 사용 |
| 2 | Nginx 시작·API 연결 실패 | 운영 Compose의 서비스명은 `tomcat-frontweb`, Nginx의 대상 이름은 `tomcat-frontend` | 모든 Compose와 Nginx에서 `tomcat-frontend` 사용 |
| 3 | WAR 복사 실패 | Maven은 `frontend`에서 빌드하지만 Dockerfile은 `frontweb/target`에서 WAR를 복사 | 빌드 폴더를 `/workspace/frontend`, 결과를 `/workspace/frontend/target/*.war`로 일치 |
| 4 | API 404 가능 | 개발 Nginx는 `/rag/api/`, 운영 설정과 WAR 이름은 `/frontweb/api/`를 전제로 함 | WAR를 `ROOT.war`로 배포하고 공개 `/api/*`를 같은 내부 `/api/*`로 전달 |
| 5 | 포트 설정 미반영 | `.env`는 `NGINX_PORT`를 정의하지만 정적 웹 Compose는 `STATICWEB_PORT`를 사용 | 모든 Nginx 구성에서 `NGINX_PORT`, `NGINX_BIND_ADDRESS` 사용 |
| 6 | 독립 정적 웹 운영 실패 | Tomcat 없이 실행하는 운영 Nginx에도 Tomcat 프록시 설정이 포함 | `default.staticweb.prod.conf` 추가. 정적 파일 제공과 API 404 응답으로 구성하고 통합 모드와 이미지 태그 분리 |
| 7 | 독립 환경 간 간섭 | 여러 Compose의 프로젝트명과 명시적 네트워크 이름이 동일 | `staticweb`, `frontwas`, `integrated` 및 dev/prod별 프로젝트명 사용. 네트워크는 프로젝트 범위로 생성 |
| 8 | 다른 React 소스를 빌드할 수 있음 | 개발은 `WEB_UI_HOST_PATH`를 사용하지만 운영은 부모 폴더의 `web-ui`를 고정 참조 | 운영도 동일한 `WEB_UI_HOST_PATH`를 named build context로 사용 |
| 9 | Windows 초기화 실패·경로 무시 | PowerShell 스크립트가 호스트 npm을 요구하고 `.env`의 React 경로를 사용하지 않음 | 기존 Vite 컨테이너를 Compose로 시작하는 보조 명령으로 변경. 설치는 컨테이너 내부에서 실행 |
| 10 | 운영 의존성 오염 가능 | 운영 Dockerfile이 `npm ci` 후 호스트 소스 전체를 복사하여 Windows `node_modules`가 덮어쓸 수 있음 | 소스 복사에서 `node_modules`, `dist`, `.git` 제외. Maven 소스도 기존 `target`과 `.git` 제외 |

기본값이 있는 환경 변수가 `.env`에 없다는 사실 자체는 Compose 문법 오류가 아닙니다. 5번의 핵심은 설정한 변수와 실제 읽는 변수의 이름이 달라 설정 변경이 적용되지 않는 점입니다. 독립 WAS의 포트·바인딩 변수도 `.env`와 `.env.example`에 함께 명시했습니다.

## 통일한 설정

| 구분 | 수정안 |
| --- | --- |
| Nginx 서비스명 | `nginx-staticweb` |
| React 개발 컨테이너 | `vite-devserver` |
| Front WAS 서비스명 | `tomcat-frontend` |
| Vite 작업 경로 / 내부 포트 | `/workspace/web-ui` / `8183` |
| WAR 이름 / Tomcat 내부 포트 | `ROOT.war` / `8080` |
| 통합 API 프록시 | `http://tomcat-frontend:8080` — 요청 `/api/*` 유지 |
| React 소스 변수 | `WEB_UI_HOST_PATH` — 개발·운영 공통 |
| Maven 소스 변수 | `FRONTWAS_HOST_PATH` — 모든 WAS 빌드 공통 |

`tomcat-frontend/Dockerfile`, Compose 서비스명, 이미지명과 컨테이너명을 `tomcat-frontend`로 통일했습니다.

## 확인이 필요한 전제

- **Spring 소스 경로:** `FRONTWAS_HOST_PATH=../frontend`를 기본값으로 준비했습니다. 실제 `pom.xml`은 이 저장소에 없어 경로와 Spring 버전은 확인하지 못했습니다.
- **API 경로:** Spring 컨트롤러가 `/api/*`를 처리하고 애플리케이션에 별도 `/rag` 또는 `/frontweb` 컨텍스트 경로를 지정하지 않는 구성을 전제로 합니다. 기존 컨텍스트 설정이 있으면 함께 제거하거나, Nginx 경로를 그 설정에 맞춰야 합니다.
- **WAR 빌드:** Maven 프로젝트에서 `target/*.war` 하나가 생성되어야 합니다. JAR 전용 프로젝트, 다른 출력 폴더나 복수 WAR를 사용하는 프로젝트는 실제 프로젝트에 맞춘 추가 설정이 필요합니다.
- **개발·운영 전환:** 고정 컨테이너 이름과 공개 포트는 유지합니다. 같은 서버의 대체 모드를 동시에 실행하는 구성은 아니며, 기존 구성을 종료한 뒤 전환해야 합니다.
- **Compose 요구 사항:** 추가 빌드 컨텍스트를 지원하는 Docker Compose 2.17 이상과 BuildKit/buildx가 필요합니다.
- **기존 실행 환경:** 프로젝트 이름이 달라지므로 기존 설정으로 컨테이너를 종료한 뒤 변경을 적용해야 합니다. 호스트 React 소스나 기존 볼륨을 삭제하는 명령은 포함하지 않았습니다.
- **기존 `APP_NAME`:** 현재 값 `muilti-domain-rag`는 `multi-domain-rag`의 철자 오류로 보이지만 외부 컨테이너·볼륨 식별자가 바뀔 수 있어 이번 수정안에서는 유지했습니다.

## 이미지 버전 확인

| 이미지 | 확인 결과 |
| --- | --- |
| `node:24.20.0-bookworm` | Docker Official Images 목록에 해당 태그 있음 |
| `nginx:1.30.4-alpine3.24` | Docker Official Images 목록에 해당 태그 있음 |
| `maven:3.9.16-eclipse-temurin-21-noble` | Docker Official Images 목록에 해당 태그 있음 |
| `tomcat:10.1.59-jre21-temurin-noble` | Docker Official Images 목록에 해당 태그 있음 |

기존 태그는 유지했습니다. 목록 확인은 실제 이미지 다운로드나 애플리케이션 호환성 검증을 대신하지 않습니다.

## 수행한 검증

- 6개 Compose의 YAML 파싱, 환경 변수 정의, 서비스 의존성과 프로젝트명 구분 검사: 통과.
- Dockerfile 경로, 추가 빌드 컨텍스트, Nginx 설정 파일과 upstream 이름·포트 검사: 통과.
- `.env`와 `.env.example`의 기본값 일치 및 Dev Container 연결 검사: 통과.
- 소스 복사에 사용하는 tar 명령을 임시 소스로 실행하여 Linux 의존성 보존과 호스트 의존성·빌드 결과 제외 확인: 통과.
- 기존 셸 스크립트의 `sh -n`, 변경 파일의 `git diff --check`: 통과.
- 실제 `docker compose config`, 이미지 빌드, Nginx 기동, PowerShell 실행: 도구가 없는 환경으로 미실행.
- React 빌드와 Spring WAR 실행: 실제 애플리케이션 소스가 없어 미검증.

## 근거와 변경 파일

기존 파일은 [점검 기준 커밋](https://github.com/withlionbuddha/nginx-vite-tomcat-env/tree/a4667ccaab47c7c526036b9356e62204aa9c92bb)에서 확인할 수 있습니다. 사용 절차는 [README](../README.md)에 반영했습니다.

- [Docker Compose 프로젝트명](https://docs.docker.com/compose/how-tos/project-name/)
- [Docker Compose additional_contexts](https://docs.docker.com/reference/compose-file/build/#additional_contexts)
- [Tomcat WAR 배포](https://tomcat.apache.org/tomcat-10.1-doc/deployer-howto.html)
- Docker Official Images: [Node](https://github.com/docker-library/official-images/blob/master/library/node), [Nginx](https://github.com/docker-library/official-images/blob/master/library/nginx), [Maven](https://github.com/docker-library/official-images/blob/master/library/maven), [Tomcat](https://github.com/docker-library/official-images/blob/master/library/tomcat)
