# inventory

Módulo de control de inventario y stock.

## Archivos

### `inventory.ex`
Funciones de gestión de stock:
- `get_stock_by_sku/1` - Consulta cantidad disponible por SKU
- `set_stock_by_sku/2` - Establece cantidad exacta de stock
- `inc_stock_by_sku/2` - Incrementa/decrementa stock (acepta valores negativos)

Usa transacciones para garantizar consistencia de datos.

### `stock_item.ex`
Schema Ecto para registros de stock. Campos:
- `quantity`: Cantidad disponible (mínimo 0)
- `product_id`: Referencia al producto

Restricción única por producto (un registro de stock por producto).
