#!/usr/bin/env bash
set -euo pipefail

# 스크립트 위치를 기준으로 환경변수 파일 읽기
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

set -a
source "$script_dir/../nginx/nginx.env"
set +a

# 필수 환경변수 확인
: "${SSL_CERT_PATH:?SSL_CERT_PATH가 nginx.env에 설정되어야 합니다.}"
: "${SSL_KEY_PATH:?SSL_KEY_PATH가 nginx.env에 설정되어야 합니다.}"

cert_file="$script_dir/../.offline/nginx-cert.pem"
key_file="$script_dir/../.offline/nginx-key.pem"

# 실제 복사할 파일 확인
for file in "$cert_file" "$key_file"; do
  if [[ ! -f "$file" ]]; then
    echo "파일을 찾을 수 없습니다: $file" >&2
    exit 1
  fi
done

read -r -p 'Docker container ID: ' container_id

if [[ ! "$container_id" =~ ^[[:xdigit:]]{4,64}$ ]]; then
  echo '올바른 Docker 컨테이너 ID를 입력하세요.' >&2
  exit 1
fi

# 컨테이너 존재 확인
docker inspect "$container_id" >/dev/null

# 인증서와 개인키의 대상 폴더 생성
cert_dir="$(dirname -- "$SSL_CERT_PATH")"
key_dir="$(dirname -- "$SSL_KEY_PATH")"

docker exec "$container_id" mkdir -p "$cert_dir" "$key_dir"

# 파일 복사
docker cp "$cert_file" "$container_id:$SSL_CERT_PATH"
docker cp "$key_file" "$container_id:$SSL_KEY_PATH"

# 개인키 권한 제한
docker exec --user 0 "$container_id" chmod 600 "$SSL_KEY_PATH"

printf '\n파일 복사 완료. Nginx 설정을 확인합니다...\n'

if docker exec "$container_id" nginx -t; then
  echo '설정이 정상입니다. Nginx를 다시 불러옵니다.'
  docker exec "$container_id" nginx -s reload
  echo '완료되었습니다.'
else
  echo '설정 검사 실패: Nginx를 다시 불러오지 않았습니다.' >&2
  echo '복사한 파일은 컨테이너에 남아 있습니다.' >&2
  exit 1
fi