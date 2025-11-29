# accounts

Módulo de gestión de usuarios y autenticación.

## Archivos

### `accounts.ex`
Funciones principales de autenticación:
- `register_user/1` - Registra un nuevo usuario
- `authenticate/2` - Verifica credenciales (username + password)

Usa SHA-256 con salt para hashear contraseñas.

### `user.ex`
Schema Ecto para usuarios. Campos:
- `username`: Nombre de usuario (único)
- `role`: Rol del usuario ("user" o "admin")
- `password`: Campo virtual para formularios
- `password_hash`: Contraseña hasheada (SHA-256)

Validaciones:
- Contraseña mínimo 6 caracteres
- Username requerido
