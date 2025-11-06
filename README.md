# Supermarket CLI - Sistema de Gestión de Supermercado

Sistema de gestión de inventario, productos y carrito de compras desarrollado en Elixir con Ecto y PostgreSQL.

## Requisitos

- Elixir >= 1.15
- Erlang/OTP >= 24
- PostgreSQL >= 12
- Mix (incluido con Elixir)

## Instalación

```bash
# 1. Clonar repositorio
git clone <url-del-repositorio>
cd ProyectoFinalV2

# 2. Configurar base de datos
# Editar config/dev.exs con tus credenciales de PostgreSQL

# 3. Instalar dependencias
mix deps.get

# 4. Crear y migrar base de datos
mix ecto.create
mix ecto.migrate

# 5. Compilar
mix compile
```

## Uso

### Aplicación Principal

```bash
mix run lib/welcome.exs
```

**Roles de usuario:**
- **ADMIN**: Gestión completa de productos y stock
- **Usuario normal**: Compras y gestión de carrito personal

**Funcionalidades principales:**
- Login y registro de usuarios
- Ver y buscar productos
- Agregar productos al carrito
- Gestionar cantidades en el carrito
- Realizar compras (checkout con descuento automático de stock)
- Gestión de inventario (solo admin)

### Scripts Individuales

```bash
# Productos
elixir lib/create_product.exs "Manzana" "Frutas" 450
elixir lib/list_products.exs
elixir lib/search_products.exs "Frutas"

# Inventario
elixir lib/init_stock.exs
elixir lib/stock_show.exs
elixir lib/stock_set.exs 10001 50

# Carrito
elixir lib/cart_test.exs
```

## Estructura del Proyecto

```
ProyectoFinalV2/
├── config/                 # Configuración
├── lib/
│   ├── supermarket/        # Módulos principales
│   │   ├── accounts/       # Autenticación y usuarios
│   │   ├── cart/           # Carrito de compras
│   │   ├── inventory/      # Gestión de stock
│   │   ├── product.ex      # Schema de productos
│   │   └── repo.ex         # Repositorio Ecto
│   └── *.exs               # Scripts ejecutables
├── priv/repo/migrations/   # Migraciones de BD
└── mix.exs                 # Configuración del proyecto
```

## Base de Datos

### Tablas principales

**products**
- `sku` (integer, único) - Generado automáticamente desde 10001
- `name`, `category`, `price` (integer, en centavos), `active`

**stock_items**
- `product_id` (FK → products)
- `quantity` (>= 0)

**users**
- `username` (único)
- `password_hash` (SHA256)

**cart_items**
- `user_id` (FK → users)
- `product_id` (FK → products)
- `quantity` (> 0)
- Constraint: Un producto por usuario en carrito

## Funcionalidades Clave

### Carrito de Compras
- Agregar/actualizar/remover productos
- Ver resumen con totales
- Checkout transaccional (descuenta stock automáticamente)
- Persistencia entre sesiones

### Autenticación
- Registro de usuarios con validación
- Login con contraseñas hasheadas
- Roles: ADMIN (gestión) y Usuario normal (compras)

## Notas Técnicas

- SKUs generados automáticamente desde 10001
- Checkout usa transacciones para garantizar atomicidad
- Stock validado antes de agregar al carrito y al comprar

## Equipo de Desarrollo

**Tecnologías:** Elixir, Ecto, PostgreSQL, Plug.Crypto  
**Versión:** 0.1.0  
**Curso:** Lenguajes de Programación - 8vo Semestre

