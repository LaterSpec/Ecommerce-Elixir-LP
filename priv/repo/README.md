# repo

Archivos de base de datos.

## Archivos

### `seeds.exs`
Script para poblar la base de datos con datos iniciales:
- Limpia tablas existentes
- Crea 3 productos de ejemplo (Manzana, Leche, Pan)
- Asigna stock a cada producto
- Crea usuario admin (`admin` / `admin123`)
- Crea usuario de prueba (`invitado` / `123456`)

Ejecutar con: `mix run priv/repo/seeds.exs`

## Subcarpeta

### `migrations/`
Migraciones de base de datos en orden cronológico.
