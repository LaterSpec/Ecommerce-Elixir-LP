# Supermarket CLI - Sistema de Gestión de Supermercado

Sistema de gestión de inventario y productos para supermercado, desarrollado en Elixir con Ecto y PostgreSQL.

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

## Instalación y Configuración

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

### 5. Compilar el proyecto

```bash
mix compile
```

## Uso del Sistema

### Iniciar la aplicación principal

```bash
mix run lib/welcome.exs
```

### Scripts disponibles

El proyecto incluye varios scripts independientes en `lib`:

#### Gestión de Productos

```bash
# Crear un producto (nombre, categoría, precio)
elixir lib/create_product.exs "Manzana" "Frutas" 450

# Listar todos los productos
elixir lib/list_products.exs

# Buscar productos por nombre o categoría
elixir lib/search_products.exs "manzana"
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

#### Verificación

```bash
# Verificar conexión a la base de datos
elixir lib/verify.exs
```

## Estructura del Proyecto

```
ProyectoFinalV2/
├── config/
│   ├── config.exs          # Configuración principal
│   └── dev.exs             # Configuración de desarrollo
├── lib/
│   ├── supermarket/        # Módulos principales
│   │   ├── accounts/       # Lógica de usuarios
│   │   ├── inventory/      # Lógica de inventario
│   │   ├── application.ex  # Aplicación OTP
│   │   ├── product.ex      # Schema de productos
│   │   └── repo.ex         # Repositorio Ecto
│   ├── create_product.exs  # Script: crear producto
│   ├── init_stock.exs      # Script: inicializar stock
│   ├── list_products.exs   # Script: listar productos
│   ├── search_products.exs # Script: buscar productos
│   ├── stock_set.exs       # Script: establecer stock
│   ├── stock_show.exs      # Script: mostrar stock
│   ├── verify.exs          # Script: verificar conexión
│   └── welcome.exs         # Punto de entrada principal
├── priv/
│   └── repo/
│       └── migrations/     # Migraciones de BD
│           ├── 20251105195101_create_products.exs
│           ├── 20251105195947_change_sku_to_integer.exs
│           ├── 20251105210846_create_users.exs
│           └── 20251105215230_create_stock_items.exs
├── mix.exs                 # Configuración del proyecto
├── .gitignore              # Archivos ignorados por Git
└── README.md
```

## Esquema de Base de Datos

### Tabla: `products`
- `id` (bigserial, PK)
- `name` (varchar)
- `sku` (integer, único) - Generado automáticamente desde 10001
- `category` (varchar)
- `price` (integer) - Precio en centavos
- `active` (boolean)
- `inserted_at`, `updated_at` (timestamp)

### Tabla: `stock_items`
- `id` (bigserial, PK)
- `product_id` (bigint, FK → products, único)
- `quantity` (integer) - Debe ser >= 0
- `inserted_at`, `updated_at` (timestamp)

### Tabla: `users`
- `id` (bigserial, PK)
- `name` (varchar)
- `email` (varchar, único)
- `password_hash` (varchar)
- `role` (varchar)
- `active` (boolean)
- `inserted_at`, `updated_at` (timestamp)

## Solución de Problemas

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
- Verifica que PostgreSQL está corriendo: `pg_ctl status` (Windows) o `systemctl status postgresql` (Linux)
- Revisa las credenciales en `config/dev.exs`
- Asegúrate de que el puerto 5432 está disponible

### Error: "module Ecto.Query is not loaded"
Este error ocurre en scripts `.exs` cuando falta agregar `{:ecto, "~> 3.10"}` en `Mix.install`. Ya está corregido en los scripts del proyecto.

### Recompilar desde cero
```bash
mix deps.clean --all
mix clean
mix deps.get
mix compile
```

### Warning: "invalid association product"
Este warning aparece si falta el archivo `lib/supermarket/product.ex`. Asegúrate de que existe y está compilado correctamente.

## Notas Importantes

- **SKU**: Los SKUs de productos se generan automáticamente comenzando desde 10001
- **Precio**: Se almacena como entero (centavos). Por ejemplo, 450 = $4.50
- **Stock**: No permite cantidades negativas
- **Contraseña BD**: Recuerda cambiar la contraseña en `config/dev.exs` antes de ejecutar

## Equipo de Desarrollo

- **Tecnologías**: Elixir, Ecto, PostgreSQL, Plug.Crypto
- **Versión**: 0.1.0

## Licencia

Este proyecto es parte de un trabajo académico para el curso de Lenguajes de Programación - 8vo Semestre.
