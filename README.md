# WebServer(Nginx + Vite) + WebApplicationServer(Tomcat)

## Server responsibilities

| Service | Development | Production |
| --- | --- | --- |
| `nginx-staticweb` | Proxies `/` to Vite and public `/api/*` to Front WAS | Serves React `dist` and proxies public `/api/*` to Front WAS |
| `vite-devserver` | React + TypeScript + Vite development server | Not started |
| `tomcat-frontWas` | Spring REST API / BFF | Spring REST API / BFF |

## URL contract

Public URLs do not expose the Tomcat WAR context name.

```text
Browser / React
├─ /, /members, /orders ...       -> React SPA
└─ /api/*                         -> Nginx Reverse Proxy
                                      -> tomcat-frontweb:8080/frontweb/api/*
```

`frontweb.war` is still deployed with the internal Tomcat context `/frontweb/`. Nginx maps the public `/api/*` namespace to that internal context. React therefore calls only same-origin URLs such as `fetch("/api/members")`.

## Required repository layout

```text
repository-root/
├─ web-ui/
├─ frontweb/                     # Spring Boot / Java / WAR
└─ nginx-vite-tomcat-compose/
   ├─ nginx/
   │  ├─ default.dev.conf
   │  └─ default.prod.conf
   ├─ docker-compose.dev.yml
   └─ docker-compose.prod.yml
```

## Development

```bash
cd nginx-vite-tomcat-compose
cp .env.example .env
docker compose -f docker-compose.dev.yml up --build -d
```

Open `http://localhost:8080`. React uses `/`; REST APIs use `/api/*`.

Examples:

```text
GET  http://localhost:8080/api/health
GET  http://localhost:8080/api/members
POST http://localhost:8080/api/login
```

For a cloud development server, keep `NGINX_BIND_ADDRESS=127.0.0.1` and use an SSH tunnel.

## Production-like validation

```bash
docker compose -f docker-compose.prod.yml up --build -d
```

In production mode Vite is not started. Nginx serves the React build and uses `try_files $uri $uri/ /index.html` so React Router URLs can be opened or refreshed directly.
