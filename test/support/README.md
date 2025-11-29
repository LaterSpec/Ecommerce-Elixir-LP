# support

Módulos de soporte para tests.

## Archivos

### `conn_case.ex`
Caso de prueba para tests que requieren conexión HTTP:
- Configura el endpoint de testing
- Importa helpers de `Phoenix.ConnTest` y `Plug.Conn`
- Habilita sandbox de BD para aislar cada test

Usar con: `use MiTiendaWebWeb.ConnCase`

### `data_case.ex`
Caso de prueba para tests de capa de datos:
- Importa `Ecto`, `Ecto.Changeset`, `Ecto.Query`
- Configura sandbox de BD
- Incluye helper `errors_on/1` para validar errores de changeset

Usar con: `use MiTiendaWeb.DataCase`
