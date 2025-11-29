# cart

Módulo de carrito de compras.

## Archivos

### `cart.ex`
Funciones principales del carrito:
- `add_to_cart/3` - Agrega producto al carrito (verifica stock disponible)
- `get_cart/1` - Obtiene items del carrito de un usuario
- `remove_from_cart/2` - Elimina un producto del carrito
- `clear_cart/1` - Vacía el carrito completo
- `validate_stock/1` - Verifica stock antes de comprar
- `checkout/1` - Procesa la compra (descuenta stock, limpia carrito)
- `update_quantity/3` - Modifica cantidad de un item

Todas las operaciones validan stock en tiempo real para evitar conflictos.

### `cart_item.ex`
Schema Ecto para items del carrito. Campos:
- `quantity`: Cantidad del producto
- `user_id`: Referencia al usuario
- `product_id`: Referencia al producto

Restricción única: un usuario no puede tener el mismo producto duplicado.
