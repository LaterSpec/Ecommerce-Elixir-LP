# migrations

Migraciones de base de datos (cambios al esquema).

## Archivos

### `20251105195101_create_products.exs`
Crea tabla `products`:
- `name`, `sku`, `category`, `price`, `active`
- Índice único en `sku`

### `20251105210846_create_users.exs`
Crea tabla `users`:
- `username`, `password_hash`
- Índice único en `username`

### `20251105215230_create_stock_items.exs`
Crea tabla `stock_items`:
- `product_id`, `quantity`
- FK a products, índice único por producto
- Constraint: quantity >= 0

### `20251106184457_create_cart_items.exs`
Crea tabla `cart_items`:
- `quantity`, `user_id`, `product_id`
- FKs a users y products
- Índice único: un item por usuario/producto

### `20251120175901_add_role_to_users.exs`
Agrega columna `role` a users (default: "user").

### `20251120190900_add_stock_to_products.exs`
Agrega columna `stock` a products (default: 0).

## Ejecutar migraciones
```bash
mix ecto.migrate
```
