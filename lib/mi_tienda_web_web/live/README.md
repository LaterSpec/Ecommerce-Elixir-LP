# live

Módulos LiveView para interfaces en tiempo real.

## Archivos

### `product_live.ex`
Página principal de productos. Funcionalidades:
- Lista de productos con búsqueda y filtro por categoría
- Selector de cantidad para agregar al carrito
- Panel de administrador (crear/editar/eliminar productos)
- UI moderna con paleta blanco/negro/gris

### `cart_live.ex`
Carrito de compras del usuario. Funcionalidades:
- Ver items en el carrito
- Modificar cantidades (+/-)
- Eliminar productos
- Validación de stock en tiempo real
- Proceso de checkout con alertas de conflictos

### `login_live.ex`
Página de inicio de sesión. Funcionalidades:
- Formulario de login (username/password)
- Manejo de errores de autenticación
- Redirección a productos al iniciar sesión

### `register_live.ex`
Página de registro de usuarios. Funcionalidades:
- Formulario con validación (username, password, confirmación)
- Creación de cuenta con rol "user" por defecto
- Redirección a login al registrarse
