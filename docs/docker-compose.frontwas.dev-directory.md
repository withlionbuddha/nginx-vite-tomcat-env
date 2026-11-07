# Docker 내부 디렉터리 구조

## 1. 적용 환경

- 개발용 컨테이너: `tomcat-frontend-muilti-domain-rag-dev` (기존 실행 환경에서 확인한 이름)
- 기반 구성: Tomcat 10.1, Java 21, Maven 3.9.11을 목표로 하는 `tomcat/Dockerfile.dev`
- 소스 마운트: `${FRONTEND_SOURCE_PATH}:/workspace`
- 실제 설치 여부와 경로는 **현재 실행 중인 이미지 및 Maven 설정에 따라 달라질 수 있습니다.**

## 2. 디렉터리 구조

```text
/                               # 컨테이너 루트
├── opt/
│   └── java/
│       └── openjdk/             # Java 21 JDK (JAVA_HOME)
│           └── bin/
│               ├── java
│               ├── javac
│               └── keytool
├── usr/
│   ├── share/
│   │   └── maven/              # Maven 프로그램 (MAVEN_HOME)
│   │       └── bin/mvn
│   └── local/
│       └── tomcat/             # Tomcat 설치 경로 (CATALINA_HOME)
│           ├── bin/            # Tomcat 실행 스크립트
│           ├── conf/           # Tomcat 설정
│           ├── lib/            # Tomcat 공통 라이브러리
│           ├── logs/           # Tomcat 로그
│           ├── temp/           # 임시 파일
│           ├── webapps/        # 배포된 웹 애플리케이션
│           └── work/           # JSP 컴파일 등 작업 파일
├── root/
│   └── .m2/
│       └── repository/         # root로 실행할 때의 기본 Maven 의존성 캐시
└── workspace/                  # 호스트 프로젝트 디렉터리의 bind mount 대상
    ├── pom.xml                 # 프로젝트에 존재하는 경우
    ├── src/
    │   └── main/
    │       └── resources/
    │           └── keystore.p12 # 해당 위치에 생성한 경우
    ├── scripts/                # 프로젝트에 존재하는 경우
    └── target/                 # Maven 빌드 후 생성되는 기본 결과 디렉터리
        ├── classes/
        └── *.jar 또는 *.war
```

> 위 트리는 **예상 구조**입니다. 실제 파일 존재 여부는 컨테이너에서 확인해야 합니다. 특히 `/workspace`의 내용은 호스트에서 마운트한 폴더에 따라 달라집니다.

## 3. 호스트와 컨테이너 경로 대응

```yaml
services:
  tomcat-frontend:
    volumes:
      - ${FRONTEND_SOURCE_PATH}:/workspace
```

| 항목 | 경로 | 설명 |
|---|---|---|
| 호스트 소스 | `${FRONTEND_SOURCE_PATH}` | Compose 실행 시 해석되는 호스트 경로 |
| 컨테이너 소스 | `/workspace` | 호스트 폴더가 보이는 위치 |
| Tomcat | `/usr/local/tomcat` | Tomcat 실행 및 배포 위치 |
| JDK | `/opt/java/openjdk` | Java 실행기·컴파일러·keytool |
| Maven | `/usr/share/maven` | Maven 실행 프로그램 |
| Maven 캐시 | `/root/.m2/repository` | 기본값이며 사용자/설정에 따라 변경 가능 |
| Maven 산출물 | `/workspace/target` | `pom.xml`의 설정에 따라 변경 가능 |

`FRONTEND_SOURCE_PATH=.`인 경우, 일반적으로 Compose 파일이 위치한 프로젝트 디렉터리가 `/workspace`에 연결됩니다. 상대 경로는 Compose 파일을 기준으로 해석됩니다.

## 4. 빌드 라이브러리와 Tomcat 라이브러리의 차이

- `/usr/share/maven`: Maven **도구 자체**가 설치된 경로입니다.
- `/root/.m2/repository`: Maven이 다운로드한 **프로젝트 의존성 JAR**가 캐시되는 기본 경로입니다.
- `/workspace/target`: 컴파일 결과 및 패키징된 **JAR/WAR 산출물**이 저장되는 기본 경로입니다.
- `/usr/local/tomcat/lib`: Tomcat이 공통으로 사용하는 **서버 라이브러리** 경로입니다.
- `/usr/local/tomcat/webapps`: 외부 Tomcat에 배포하는 **WAR 또는 압축 해제된 웹 애플리케이션**의 기본 위치입니다.

`mvn package`만 실행한다고 `/usr/local/tomcat/webapps`에 자동 배포되지는 않습니다. 별도 복사 또는 배포 절차가 필요합니다. Spring Boot 실행형 JAR를 사용하는 경우 외부 Tomcat 배포가 필요하지 않을 수도 있습니다.

## 5. 실제 경로 검증 명령

호스트 PowerShell:

```powershell
docker exec -it -w /workspace tomcat-frontend-muilti-domain-rag-dev /bin/bash
```

컨테이너 내부:

```bash
pwd
ls -la /workspace
java -version
javac -version
mvn -version
echo "$JAVA_HOME"
echo "$MAVEN_HOME"
ls -la /usr/local/tomcat
mvn help:evaluate -Dexpression=settings.localRepository -q -DforceStdout
```

Keystore 파일이 `/workspace/src/main/resources/keystore.p12`에 있다면:

```bash
ls -lh /workspace/src/main/resources/keystore.p12
keytool -list -storetype PKCS12 -keystore /workspace/src/main/resources/keystore.p12
```

`server.ssl.key-alias=mycert`를 사용할 경우 Keystore 목록에서 `mycert` 별칭과 `PrivateKeyEntry` 유형을 확인해야 합니다.

## 6. Maven 캐시 영속화(선택)

컨테이너 재생성 후에도 Maven 의존성을 유지하려면 개발용 Compose에 이름 있는 볼륨을 추가할 수 있습니다.

```yaml
services:
  tomcat-frontend:
    volumes:
      - ${FRONTEND_SOURCE_PATH}:/workspace
      - maven-repository:/root/.m2/repository

volumes:
  maven-repository:
```

이 예시는 기존 Compose의 다른 설정을 생략한 **부분 설정**입니다. 기존 최상위 `volumes` 항목이 있다면 병합하십시오. Maven을 root가 아닌 다른 사용자로 실행한다면 캐시 마운트 경로도 변경해야 합니다.

## 7. 참고 사항

1. `working_dir: /workspace`는 프로세스의 작업 디렉터리를 지정하며, 소스 마운트 자체를 수행하지는 않습니다.
2. 컨테이너의 파일 변경 사항은 이미지에 자동 반영되지 않습니다.
3. 호스트와 연결된 `/workspace`의 파일 변경 사항은 양쪽에서 보일 수 있습니다.
4. 비밀번호, Keystore 및 개인키는 Git 저장소에 커밋하지 않는 것이 좋습니다.
5. 실제 JDK/Maven 설치 성공 여부는 `javac -version`, `mvn -version`으로 확인하십시오.
