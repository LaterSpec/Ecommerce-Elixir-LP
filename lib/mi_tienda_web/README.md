# mi_tienda_web

Módulos base de la aplicación Phoenix.

## Archivos

### `application.ex`
Punto de entrada de la aplicación OTP. Inicia y supervisa los procesos principales:
- Telemetría
- Repositorio de base de datos (Repo)
- DNS Cluster
- Phoenix PubSub
- Endpoint web

### `mailer.ex`
Configuración del servicio de correo electrónico usando Swoosh.

### `repo.ex`
Repositorio Ecto para interactuar con PostgreSQL. Define la conexión a la base de datos.
