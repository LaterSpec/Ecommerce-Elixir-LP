# Supermarket CLI - Sistema de Gestión de Supermercado

Sistema completo de gestión de inventario, productos y carrito de compras para supermercado, desarrollado en Elixir con Ecto y PostgreSQL.

## Requisitos Previos

Antes de compilar y ejecutar el proyecto, asegúrate de tener instalado:

- **Elixir** >= 1.15
- **Erlang/OTP** >= 24
- **PostgreSQL** >= 12
- **Mix** (incluido con Elixir)

### Verificar instalaciones

```bash
elixir --version
psql --version
mix --version
```

## 🚀 Instalación y Configuración

### 1. Clonar el repositorio

```bash
git clone <url-del-repositorio>
cd ProyectoFinalV2
```

### 2. Configurar la base de datos

Edita el archivo `config/dev.exs` con tus credenciales de PostgreSQL:

```elixir
config :supermarket, Supermarket.Repo,
  username: "postgres",      # Tu usuario de PostgreSQL
  password: "tu_password",   # Tu contraseña de PostgreSQL
  hostname: "localhost",
  database: "supermarket_dev",
  port: 5432,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
```

### 3. Instalar dependencias

```bash
mix deps.get
```

### 4. Crear y migrar la base de datos

```bash
# Crear la base de datos
mix ecto.create

# Ejecutar las migraciones
mix ecto.migrate
```

Las migraciones se encuentran en `priv/repo/migrations` y crean:
- Tabla `products` (productos del supermercado)
- Tabla `stock_items` (inventario)
- Tabla `users` (usuarios del sistema)
- Tabla `cart_items` (carrito de compras)

### 5. Compilar el proyecto

```bash
mix compile
```

## Uso del Sistema

### Iniciar la aplicación principal

```bash
mix run lib/welcome.exs
```

La aplicación presenta un menú interactivo con las siguientes opciones:

#### Gestión de Usuarios
- **Login**: Iniciar sesión con usuario y contraseña
- **Sign in**: Crear una nueva cuenta de usuario
- **Roles**: 
  - `ADMIN`: Acceso completo (gestión de productos y stock)
  - Usuario normal: Compras y gestión de carrito

#### Funcionalidades de Usuario Normal
1. Listar productos disponibles
2. Buscar productos por categoría
3. **Ver mi carrito** 🛒
4. **Agregar productos al carrito**
5. **Actualizar cantidad en carrito**
6. **Remover productos del carrito**
7. **Vaciar carrito completo**
8. **Checkout (realizar compra)** 💳
   - Descuenta automáticamente el stock
   - Vacía el carrito después de comprar
   - Valida disponibilidad antes de procesar

#### Funcionalidades de Administrador
1. Listar todos los productos
2. Buscar productos por categoría
3. Crear nuevos productos
4. Ver stock completo o por SKU
5. Establecer cantidad de stock por SKU

### Scripts Disponibles

El proyecto incluye varios scripts independientes en `lib/`:

#### Gestión de Productos

```bash
# Crear un producto (nombre, categoría, precio)
elixir lib/create_product.exs "Manzana" "Frutas" 450

# Listar todos los productos
elixir lib/list_products.exs

# Buscar productos por categoría
elixir lib/search_products.exs "Frutas"

# Buscar por múltiples categorías
elixir lib/search_products.exs "Frutas,Verduras"

# Listar categorías disponibles
elixir lib/search_products.exs --list-categories
```

#### Gestión de Inventario

```bash
# Inicializar stock de productos (20 unidades por defecto)
elixir lib/init_stock.exs

# Ver stock actual (todos los productos)
elixir lib/stock_show.exs

# Ver stock de un producto específico (por SKU)
elixir lib/stock_show.exs 10001

# Establecer cantidad de stock
elixir lib/stock_set.exs <SKU> <cantidad>
# Ejemplo: elixir lib/stock_set.exs 10001 50
```

#### Gestión de Carrito

```bash
# Probar funcionalidades del carrito
elixir lib/cart_test.exs
```

Este script de prueba:
- Agrega productos al carrito
- Muestra el contenido del carrito
- Actualiza cantidades
- Remueve productos
- Realiza un checkout de prueba

#### Verificación

```bash
# Verificar conexión a la base de datos y esquema
elixir lib/verify.exs
```

## Estructura del Proyecto

```
ProyectoFinalV2/
├── config/
│   ├── config.exs          # Configuración principal
│   └── dev.exs             # Configuración de desarrollo
├── lib/
│   ├── supermarket/        # Módulos principales del sistema
│   │   ├── accounts/       # Lógica de usuarios y autenticación
│   │   │   ├── accounts.ex # Contexto de cuentas
│   │   │   └── user.ex     # Schema de usuarios
│   │   ├── cart/           # Lógica del carrito de compras
│   │   │   ├── cart.ex     # Contexto del carrito
│   │   │   └── cart_item.ex# Schema de ítems del carrito
│   │   ├── inventory/      # Lógica de inventario
│   │   │   ├── inventory.ex    # Contexto de inventario
│   │   │   └── stock_item.ex   # Schema de stock
│   │   ├── application.ex  # Aplicación OTP
│   │   ├── product.ex      # Schema de productos
│   │   └── repo.ex         # Repositorio Ecto
│   ├── cart_test.exs       # Script: pruebas de carrito
│   ├── create_product.exs  # Script: crear producto
│   ├── init_stock.exs      # Script: inicializar stock
│   ├── list_products.exs   # Script: listar productos
│   ├── search_products.exs # Script: buscar productos
│   ├── stock_set.exs       # Script: establecer stock
│   ├── stock_show.exs      # Script: mostrar stock
│   ├── verify.exs          # Script: verificar conexión
│   └── welcome.exs         # Punto de entrada principal (CLI)
├── priv/
│   └── repo/
│       └── migrations/     # Migraciones de base de datos
│           ├── 20251105195101_create_products.exs
│           ├── 20251105195947_change_sku_to_integer.exs
│           ├── 20251105210846_create_users.exs
│           ├── 20251105215230_create_stock_items.exs
│           └── 20251106184457_create_cart_items.exs
├── mix.exs                 # Configuración del proyecto
├── .gitignore              # Archivos ignorados por Git
└── README.md               # Este archivo
```

## Esquema de Base de Datos

### Tabla: `products`
- `id` (bigserial, PK)
- `name` (varchar) - Nombre del producto
- `sku` (integer, único) - Generado automáticamente desde 10001
- `category` (varchar) - Categoría del producto
- `price` (integer) - Precio en centavos
- `active` (boolean) - Estado del producto
- `inserted_at`, `updated_at` (timestamp)

**Relaciones:**
- `has_many :stock_items` → stock_items
- `has_many :cart_items` → cart_items

### Tabla: `stock_items`
- `id` (bigserial, PK)
- `product_id` (bigint, FK → products, único)
- `quantity` (integer) - Debe ser >= 0
- `inserted_at`, `updated_at` (timestamp)

**Relaciones:**
- `belongs_to :product` → products

**Constraints:**
- `unique_index(:product_id)` - Un solo registro de stock por producto
- `check: "quantity >= 0"` - No permite stock negativo

### Tabla: `users`
- `id` (bigserial, PK)
- `username` (varchar, único) - Nombre de usuario
- `password_hash` (varchar) - Contraseña hasheada (SHA256)
- `inserted_at`, `updated_at` (timestamp)

**Relaciones:**
- `has_many :cart_items` → cart_items

**Constraints:**
- `unique_index(:username)`
- Usuario especial: `ADMIN` con acceso completo

### Tabla: `cart_items`
- `id` (bigserial, PK)
- `user_id` (bigint, FK → users, on_delete: :delete_all)
- `product_id` (bigint, FK → products, on_delete: :delete_all)
- `quantity` (integer) - Cantidad en el carrito
- `inserted_at`, `updated_at` (timestamp)

**Relaciones:**
- `belongs_to :user` → users
- `belongs_to :product` → products

**Constraints:**
- `unique_index([:user_id, :product_id])` - Un producto por usuario en carrito
- `check: "quantity > 0"` - Cantidad debe ser positiva

## Funcionalidades del Carrito

### Agregar al Carrito
```elixir
# Desde el módulo Cart
Cart.add_to_cart(username, sku, cantidad)
```
- Valida que el producto exista
- Verifica stock disponible
- Si el producto ya está en el carrito, incrementa la cantidad
- Si no existe, crea un nuevo ítem

### Ver Carrito
```elixir
Cart.get_cart(username)
```
Retorna:
```elixir
{:ok, %{
  items: [
    %{
      cart_item_id: 1,
      product_name: "Manzana",
      sku: 10001,
      price: 450,
      quantity: 3,
      subtotal: 1350
    }
  ],
  total: 1350
}}
```

### Actualizar Cantidad
```elixir
Cart.update_quantity(username, sku, nueva_cantidad)
```
- Valida stock disponible
- Actualiza la cantidad del producto en el carrito

### Remover Producto
```elixir
Cart.remove_from_cart(username, sku)
```
- Elimina el producto del carrito del usuario

### Vaciar Carrito
```elixir
Cart.clear_cart(username)
```
- Elimina todos los productos del carrito del usuario
- Retorna la cantidad de ítems eliminados

### Checkout (Comprar)
```elixir
Cart.checkout(username)
```
**Proceso:**
1. Verifica que el carrito no esté vacío
2. Valida stock disponible para todos los productos
3. **Descuenta el stock** usando transacciones
4. Vacía el carrito automáticamente
5. Si algo falla, **revierte toda la operación** (atomicidad)

**Ejemplo de uso:**
```elixir
case Cart.checkout("usuario123") do
  {:ok, {:ok, %{items_count: 3, total: 5400}}} ->
    IO.puts("¡Compra exitosa! 3 productos, total: $54.00")
  {:error, :insufficient_stock} ->
    IO.puts("Stock insuficiente")
  {:error, :empty_cart} ->
    IO.puts("Carrito vacío")
end
```

## Sistema de Autenticación

### Registro de Usuarios
```elixir
Accounts.register_user(%{
  username: "nuevo_usuario",
  password: "contraseña123",
  password_confirmation: "contraseña123"
})
```

**Validaciones:**
- Username: 3-40 caracteres, único
- Password: 4-72 caracteres
- Password confirmation debe coincidir
- Hash: SHA256 con salt fijo

### Login
```elixir
Accounts.authenticate("usuario", "contraseña")
# Retorna: {:ok, :authenticated} o {:error, :invalid_password}
```

### Usuario Administrador
- Username: `ADMIN`
- Tiene acceso a funciones de gestión (crear productos, modificar stock)
- Los usuarios normales solo pueden comprar

## 🔧 Solución de Problemas

### Error: "database does not exist"
```bash
mix ecto.create
```

### Error: "could not find Ecto repos"
Verifica que existe `config/config.exs` y contiene:
```elixir
import Config
import_config "#{Mix.env()}.exs"
```

### Error de conexión a PostgreSQL
- Verifica que PostgreSQL está corriendo: 
  - Windows: `pg_ctl status`
  - Linux: `systemctl status postgresql`
- Revisa las credenciales en `config/dev.exs`
- Asegúrate de que el puerto 5432 está disponible

### Error: "module Ecto.Query is not loaded"
Este error ocurre en scripts `.exs` cuando `import Ecto.Query` se coloca antes de `Mix.install`. 
**Solución:** Mover el `import` dentro del módulo que lo usa.

### Warning: "invalid association product"
Este warning aparece si falta el archivo `lib/supermarket/product.ex`. 
Asegúrate de que existe y está compilado correctamente.

### Error: "key :database not found"
Verifica que `config/config.exs` importa correctamente `config/dev.exs`:
```elixir
import_config "#{Mix.env()}.exs"
```

### Recompilar desde cero
```bash
mix deps.clean --all
mix clean
mix deps.get
mix compile
```

## Flujo de Uso Típico

1. **Crear cuenta o iniciar sesión**
   ```bash
   mix run lib/welcome.exs
   # Seleccionar opción 2 (Sign in)
   ```

2. **Ver productos disponibles**
   - Opción 1: Listar todos
   - Opción 2: Buscar por categoría

3. **Agregar al carrito**
   - Opción 4: Ingresar SKU y cantidad

4. **Revisar carrito**
   - Opción 3: Ver resumen con totales

5. **Modificar carrito** (opcional)
   - Opción 5: Actualizar cantidades
   - Opción 6: Remover productos

6. **Realizar compra**
   - Opción 8: Checkout
   - Confirmar compra
   - El stock se descuenta automáticamente

## 👥 Equipo de Desarrollo

- **Tecnologías**: Elixir, Ecto, PostgreSQL, Plug.Crypto
- **Versión**: 0.1.0
- **Curso**: Lenguajes de Programación - 8vo Semestre

