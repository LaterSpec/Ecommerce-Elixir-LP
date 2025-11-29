# supermarket

Lógica de negocio del supermercado. Contiene los módulos de dominio.

## Archivos

### `application.ex`
Supervisor OTP alternativo para el contexto Supermarket.

### `product.ex`
Schema Ecto para productos. Campos:
- `name`: Nombre del producto
- `sku`: Código único (identificador)
- `category`: Categoría del producto
- `price`: Precio en centavos
- `stock`: Cantidad en inventario
- `active`: Estado activo/inactivo

## Subcarpetas

- `accounts/` - Gestión de usuarios y autenticación
- `cart/` - Carrito de compras
- `inventory/` - Control de inventario y stock
