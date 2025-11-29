# mi_tienda_web_web

Capa web de la aplicación Phoenix (controllers, views, LiveView).

## Archivos

### `endpoint.ex`
Punto de entrada HTTP. Configura:
- WebSocket para LiveView
- Archivos estáticos
- Parseo de requests
- Cookies y sesiones

### `router.ex`
Define las rutas de la aplicación:
- `/` - Página de productos
- `/login` - Inicio de sesión
- `/register` - Registro de usuarios
- `/cart` - Carrito de compras

### `gettext.ex`
Configuración de internacionalización (i18n).

### `telemetry.ex`
Métricas y eventos del sistema para monitoreo.

## Subcarpetas

- `components/` - Componentes reutilizables y layouts
- `controllers/` - Controladores tradicionales
- `live/` - LiveViews (interfaces en tiempo real)
