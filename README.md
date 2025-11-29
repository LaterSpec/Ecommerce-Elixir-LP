# Mi Tienda Web

Aplicacion web de comercio electronico desarrollada con Phoenix Framework y Elixir. Permite a los usuarios navegar por un catalogo de productos, gestionar un carrito de compras y realizar compras con validacion de stock en tiempo real.

---

## Tabla de Contenidos

1. [Tecnologias Utilizadas](#tecnologias-utilizadas)
2. [Requisitos Previos](#requisitos-previos)
3. [Instalacion y Configuracion](#instalacion-y-configuracion)
4. [Comandos Disponibles](#comandos-disponibles)
5. [Estructura del Proyecto](#estructura-del-proyecto)
6. [Funcionalidades](#funcionalidades)
7. [Rutas de la Aplicacion](#rutas-de-la-aplicacion)
8. [Base de Datos](#base-de-datos)
9. [Usuarios de Prueba](#usuarios-de-prueba)

---

## Tecnologias Utilizadas

| Tecnologia | Version | Descripcion |
|------------|---------|-------------|
| Elixir | ~> 1.15 | Lenguaje de programacion funcional |
| Phoenix Framework | ~> 1.8.1 | Framework web en tiempo real |
| Phoenix LiveView | ~> 1.1.0 | Interfaces interactivas sin JavaScript |
| Ecto | ~> 3.13 | ORM para base de datos |
| PostgreSQL | - | Base de datos relacional |
| Tailwind CSS | ~> 0.3 | Framework de estilos CSS |
| Bandit | ~> 1.5 | Servidor HTTP |

---

## Requisitos Previos

Antes de ejecutar la aplicacion, asegurate de tener instalado:

- **Elixir** (version 1.15 o superior)
- **Erlang/OTP** (version compatible con Elixir)
- **Node.js** (para compilar assets)
- **PostgreSQL** (o acceso a una instancia remota)

Para verificar las versiones instaladas:

```bash
elixir --version
node --version
psql --version
```

---

## Instalacion y Configuracion

### 1. Clonar el repositorio

```bash
git clone <url-del-repositorio>
cd mi_tienda_web_3_final
```

### 2. Instalar dependencias y configurar base de datos

```bash
mix setup
```

Este comando ejecuta automaticamente:
- `mix deps.get` - Descarga dependencias de Elixir
- `mix ecto.create` - Crea la base de datos
- `mix ecto.migrate` - Ejecuta las migraciones
- `mix run priv/repo/seeds.exs` - Pobla datos iniciales
- Instalacion de Tailwind y esbuild

### 3. Iniciar el servidor

```bash
mix phx.server
```

La aplicacion estara disponible en: [http://localhost:4000](http://localhost:4000)

### Modo interactivo (IEx)

```bash
iex -S mix phx.server
```

---

## Comandos Disponibles

| Comando | Descripcion |
|---------|-------------|
| `mix setup` | Instalacion completa (deps + BD + assets) |
| `mix phx.server` | Inicia el servidor de desarrollo |
| `mix deps.get` | Descarga dependencias de Elixir |
| `mix ecto.create` | Crea la base de datos |
| `mix ecto.migrate` | Ejecuta migraciones pendientes |
| `mix ecto.reset` | Elimina y recrea la BD desde cero |
| `mix ecto.rollback` | Revierte la ultima migracion |
| `mix test` | Ejecuta las pruebas automatizadas |
| `mix format` | Formatea el codigo fuente |
| `mix compile` | Compila el proyecto |

---

## Estructura del Proyecto

```
mi_tienda_web_3_final/
|
|-- assets/                  # Assets frontend (JS, CSS)
|   |-- css/
|   |-- js/
|   |-- vendor/
|
|-- config/                  # Configuracion por entorno
|   |-- config.exs           # Configuracion base
|   |-- dev.exs              # Configuracion desarrollo
|   |-- prod.exs             # Configuracion produccion
|   |-- runtime.exs          # Configuracion en tiempo de ejecucion
|   |-- test.exs             # Configuracion para tests
|
|-- lib/
|   |-- mi_tienda_web/       # Logica de aplicacion OTP
|   |   |-- application.ex   # Supervisor principal
|   |   |-- mailer.ex        # Servicio de correo
|   |   |-- repo.ex          # Repositorio Ecto (BD)
|   |
|   |-- mi_tienda_web_web/   # Capa web (Phoenix)
|   |   |-- components/      # Componentes reutilizables
|   |   |-- controllers/     # Controladores HTTP
|   |   |-- live/            # Modulos LiveView
|   |   |   |-- cart_live.ex
|   |   |   |-- login_live.ex
|   |   |   |-- product_live.ex
|   |   |   |-- register_live.ex
|   |   |-- endpoint.ex      # Punto de entrada HTTP
|   |   |-- router.ex        # Definicion de rutas
|   |
|   |-- supermarket/         # Logica de negocio (dominio)
|       |-- accounts/        # Gestion de usuarios
|       |   |-- accounts.ex  # Funciones de autenticacion
|       |   |-- user.ex      # Schema de usuario
|       |
|       |-- cart/            # Carrito de compras
|       |   |-- cart.ex      # Operaciones del carrito
|       |   |-- cart_item.ex # Schema de item
|       |
|       |-- inventory/       # Control de inventario
|       |   |-- inventory.ex # Funciones de stock
|       |   |-- stock_item.ex
|       |
|       |-- product.ex       # Schema de producto
|
|-- priv/
|   |-- repo/
|   |   |-- migrations/      # Migraciones de BD
|   |   |-- seeds.exs        # Datos iniciales
|   |-- static/              # Archivos estaticos
|
|-- test/                    # Pruebas automatizadas
|   |-- support/             # Helpers para tests
|   |-- mi_tienda_web_web/
|
|-- mix.exs                  # Definicion del proyecto
|-- mix.lock                 # Versiones fijas de dependencias
```

---

## Funcionalidades

### Autenticacion de Usuarios

- **Registro de cuenta**: Crear nuevos usuarios con username y password
- **Inicio de sesion**: Autenticacion con validacion de credenciales
- **Roles de usuario**: Soporte para usuarios normales y administradores
- **Cifrado de passwords**: Hash SHA-256 con salt para seguridad

### Catalogo de Productos

- **Listado de productos**: Vista de todos los productos disponibles
- **Busqueda por texto**: Filtrar productos por nombre
- **Filtro por categoria**: Seleccionar productos por categoria
- **Selector de cantidad**: Elegir cuantas unidades agregar al carrito

### Carrito de Compras

- **Agregar productos**: Anadir items al carrito con validacion de stock
- **Modificar cantidades**: Aumentar o disminuir unidades
- **Eliminar productos**: Quitar items individuales del carrito
- **Vaciar carrito**: Eliminar todos los productos
- **Calculo de totales**: Subtotales por producto y total general

### Proceso de Compra (Checkout)

- **Validacion de stock en tiempo real**: Verifica disponibilidad antes de comprar
- **Deteccion de conflictos**: Alerta cuando otro usuario compro el mismo producto
- **Transacciones atomicas**: Garantiza consistencia de datos
- **Descuento automatico de stock**: Actualiza inventario tras la compra

### Panel de Administrador

- **Crear productos**: Agregar nuevos productos al catalogo
- **Editar productos**: Modificar nombre, precio, categoria, stock
- **Eliminar productos**: Remover productos del sistema
- **Gestion de inventario**: Control de cantidades disponibles

---

## Rutas de la Aplicacion

| Ruta | Metodo | Descripcion |
|------|--------|-------------|
| `/` | GET | Pagina principal (redirige a productos) |
| `/productos` | LiveView | Catalogo de productos |
| `/carrito` | LiveView | Carrito del usuario |
| `/login` | LiveView | Inicio de sesion |
| `/register` | LiveView | Registro de usuario |

---

## Base de Datos

### Tablas

| Tabla | Descripcion |
|-------|-------------|
| `users` | Usuarios del sistema (username, password_hash, role) |
| `products` | Catalogo de productos (name, sku, category, price, stock) |
| `stock_items` | Registros de inventario por producto |
| `cart_items` | Items en carritos de usuarios |

### Diagrama de Relaciones

```
users (1) ----< (N) cart_items (N) >---- (1) products
                                              |
                                              |
                                        (1) stock_items
```

### Migraciones

Las migraciones se encuentran en `priv/repo/migrations/` y se ejecutan en orden cronologico:

1. `create_products` - Tabla de productos
2. `create_users` - Tabla de usuarios
3. `create_stock_items` - Tabla de inventario
4. `create_cart_items` - Tabla de carrito
5. `add_role_to_users` - Campo role en usuarios
6. `add_stock_to_products` - Campo stock en productos

---

## Usuarios de Prueba

Al ejecutar `mix setup` o `mix run priv/repo/seeds.exs`, se crean los siguientes usuarios:

| Usuario | Password | Rol | Descripcion |
|---------|----------|-----|-------------|
| `admin` | `admin123` | admin | Acceso completo, puede gestionar productos |
| `invitado` | `123456` | user | Usuario normal, solo puede comprar |

---

## Configuracion de Base de Datos

La configuracion de conexion se encuentra en `config/dev.exs`. Por defecto conecta a una instancia remota de PostgreSQL:

```elixir
config :mi_tienda_web, MiTiendaWeb.Repo,
  username: "postgres",
  password: "****",
  hostname: "34.46.167.102",
  database: "supermarket_dev",
  port: 5432
```

Para usar una base de datos local, modifica estos valores segun tu configuracion.

---

## Notas Adicionales

- La aplicacion usa **Phoenix LiveView** para actualizaciones en tiempo real sin necesidad de JavaScript adicional
- El diseno utiliza **Tailwind CSS** con una paleta de colores en escala de grises
- Las sesiones de usuario se manejan a traves de cookies del navegador
- El stock se valida en tiempo real para evitar sobreventa en compras concurrentes

---

## Recursos

- [Phoenix Framework](https://www.phoenixframework.org/)
- [Elixir Lang](https://elixir-lang.org/)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/)
- [Ecto](https://hexdocs.pm/ecto/)
- [Tailwind CSS](https://tailwindcss.com/)
