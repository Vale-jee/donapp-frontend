# DonApp

DonApp es una aplicación móvil que conecta a personas que desean donar artículos en buen estado con personas interesadas en recibirlos. Este repositorio contiene el cliente Flutter; la API REST se ejecuta y configura por separado.

## Tecnologías principales

- Flutter y Dart.
- Material 3.
- API REST de DonApp mediante `package:http`.
- Drift sobre SQLite cifrado con SQLCipher para persistencia local.
- Autenticación JWT con access token y refresh token.
- Almacenamiento seguro mediante `flutter_secure_storage`.
- Navegación declarativa con GoRouter.
- Selección de imágenes y subida HTTPS mediante un flujo firmado hacia Cloudinary.

## Funcionalidades implementadas

- Registro e inicio de sesión.
- Restauración automática de sesión y recuperación del perfil autenticado.
- Almacenamiento seguro de access token y refresh token.
- Renovación y rotación automática de tokens.
- Rutas públicas y privadas, con regreso al destino solicitado después del Login.
- Manejo diferenciado de 401, 403 por permisos y cuenta inactiva.
- Inicio con información real del usuario.
- Exploración paginada de donaciones y filtro por categoría.
- Detalle de donación.
- Publicación completa con categorías obtenidas del backend.
- Selección, validación y subida segura de imágenes.
- Consulta de donaciones propias.
- Solicitudes enviadas y recibidas, detalle y creación de solicitudes.
- Aceptación, rechazo y cancelación de solicitudes.
- Validación de formularios al perder foco y nuevamente al enviar.
- Presentación de errores locales y remotos debajo del campo correspondiente.
- Conservación del contenido del formulario durante navegación temporal con `push`.
- Componentes reutilizables para carga, contenido vacío, error y reintento.

## Sesión y navegación

El inicio normal de la aplicación sigue este flujo:

```text
Inicio de app
  → restaurar sesión
  → consultar perfil
  → renovar tokens si es necesario
  → abrir Inicio o el destino privado solicitado
```

Una sesión inválida elimina los tokens y el perfil en memoria. El router abandona las rutas privadas y conserva el destino para regresar después de un nuevo Login.

El recorrido funcional principal es:

```text
Login
  → Inicio
  → Explorar
  → Detalle
  → Inicio
  → Donar
  → Publicar
  → Detalle de la nueva donación
```

La descripción de cada paso, sus endpoints y las capturas sugeridas se encuentra en [Flujo funcional de DonApp](docs/functional_flow.md).

## Arquitectura resumida

Las pantallas consumen repositorios que coordinan fuentes locales y remotas (`UI → Repository → LocalDataSource / RemoteDataSource`). Los servicios de sesión administran autenticación y limpieza local; `SyncCoordinator` procesa la cola persistida. El backend sigue siendo la autoridad remota sobre los datos confirmados.

## Funcionalidades futuras

- Búsqueda textual completa.
- Chat.
- Calificaciones.
- Recuperación de contraseña.

## Requisitos y ejecución

Se necesita Flutter compatible con la restricción de Dart declarada en `pubspec.yaml`, Android SDK, un dispositivo o emulador y el backend de DonApp en ejecución.

Instale las dependencias y verifique el proyecto:

```powershell
flutter pub get
flutter analyze
flutter test
```

### Configuración por ambiente

`APP_ENV` y `API_BASE_URL` son constantes de compilación suministradas con `--dart-define`. Los únicos ambientes válidos son `dev`, `test` y `prod`. Si se omite `APP_ENV`, se utiliza `dev` para conservar compatibilidad con los comandos existentes y la tarea de VS Code. No hay URL predeterminada: `API_BASE_URL` es obligatoria al consumir la API, sin agregar `/api` al final.

| Ambiente | Configuración | Uso |
| --- | --- | --- |
| `dev` | URL HTTP o HTTPS; la variante Android debug permite HTTP solo hacia localhost | Desarrollo local con backend propio |
| `test` | URL ficticia e inyección de clientes simulados | Pruebas automatizadas sin backend real |
| `prod` | URL HTTPS obligatoria | Ejecución o compilación para producción |

Desarrollo explícito:

```powershell
flutter run --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://localhost:3000
```

El comando anterior de desarrollo también sigue siendo válido:

```powershell
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

Para usar un dispositivo Android físico conectado por USB con el backend local:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:3000 tcp:3000
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

Para comprobar una desconexión real, retire temporalmente el reverse con `adb reverse --remove tcp:3000`: el túnel USB puede mantener accesible el backend incluso con modo avión. Esta es una consideración exclusiva de desarrollo y depuración.

Pruebas automatizadas:

```powershell
flutter test --dart-define=APP_ENV=test --dart-define=API_BASE_URL=https://donapp.test
```

`donapp.test` es una dirección ficticia. Las pruebas inyectan `MockClient`, servicios simulados o constructores de URL; no necesitan un servidor escuchando allí. Seleccionar `test` no simula por sí solo el transporte ni impide conexiones: el aislamiento lo proporcionan los dobles de prueba. `flutter test` sin defines también sigue permitido; las pruebas no requieren una URL real y verifican explícitamente la ausencia de configuración.

Producción (reemplace el dominio de ejemplo por la dirección pública de su despliegue):

```powershell
flutter run --release --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://api.example.com
flutter build apk --release --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://api.example.com
```

El modo `--release` no selecciona el ambiente automáticamente: producción debe indicar `APP_ENV=prod`. `ApiConfig` valida al construir cada endpoint, antes de enviar la petición. Rechaza ambientes desconocidos o vacíos, URL ausente o inválida y cualquier URL base HTTP en `prod`, incluso localhost. Lanza `ApiConfigException` con el motivo; `ApiClient` conserva su traducción a error de configuración para la interfaz. No se agrega validación nueva al arranque sin peticiones.

La configuración Android común (`android/app/src/main/res/xml/network_security_config.xml`) bloquea cleartext sin excepciones. El manifest principal declara también `usesCleartextTraffic=false`. Release y profile usan esa configuración. Solo debug sustituye el recurso desde `android/app/src/debug/res/xml/network_security_config.xml` para permitir HTTP hacia `localhost`, sin subdominios. Se mantiene `adb reverse tcp:3000 tcp:3000` con la URL `http://localhost:3000`; no se habilitan direcciones LAN ni dominios externos.

La variante Android y `APP_ENV` son configuraciones distintas: `APP_ENV=dev` no habilita la excepción nativa en release/profile, y debug con `APP_ENV=prod` sigue rechazando una URL base HTTP en Dart. Para medir en profile utilice un backend HTTPS. En producción use siempre ambos: `--release` y `--dart-define=APP_ENV=prod`.

La validación Dart de HTTPS se conserva porque la política nativa no protege por sí sola todos los sockets de Flutter. En `prod`, ApiConfig también rechaza referencias HTTP de imágenes antes de que los widgets o RemoteImageCache las soliciten. Cloudinary conserva su validación de firma HTTPS, host autorizado y respuesta `secure_url` HTTPS. iOS no tiene excepciones ATS para cargas inseguras. No se desactiva la validación de certificados.

HttpRequestLogger sigue sin emitir registros en `prod` ni `test`. En `dev` registra únicamente método, ruta filtrada, status y duración; no cabeceras, cuerpos, tokens ni firmas.

Los valores `dart-define` se incorporan al artefacto compilado y **no son secretos**. No deben contener contraseñas, tokens ni credenciales; la URL debe ser una dirección pública de configuración.

## Inicio rápido desde VS Code

1. Abra Docker Desktop.
2. Confirme que PostgreSQL está disponible.
3. Conecte y autorice el teléfono Android.
4. Abra la carpeta `Proyecto` en VS Code.
5. Vaya a `Terminal → Run Task...`.
6. Ejecute `DonApp: Iniciar entorno`.

VS Code comprobará e iniciará Redis cuando sea necesario, configurará ADB reverse, levantará el backend y, cuando este se encuentre listo, iniciará Flutter.

## Estructura del frontend

```text
lib/
├── config/       # Configuración y construcción de URL de la API
├── models/       # Autenticación, perfil, donaciones y solicitudes
├── navigation/   # Rutas públicas, privadas y redirecciones
├── screens/      # Pantallas y flujos de usuario
├── services/     # API, sesión, almacenamiento, imágenes y entidades
├── widgets/      # Componentes presentacionales reutilizables
└── main.dart     # Inicialización de estado de sesión y router

docs/
├── component_catalog.md
├── functional_flow.md
└── local_persistence.md
```

Consulte también el [catálogo de componentes](docs/component_catalog.md).
DonApp utiliza almacenamiento local cifrado para soporte offline. Sus políticas
de minimización, retención, sincronización y limpieza de sesión se documentan en
la [política de persistencia local](docs/local_persistence.md).

El soporte offline actual incluye la lectura local-first de Explore y la creación de donaciones desde una sesión autenticada. Explore conserva donaciones, categorías e imágenes remotas que ya alcanzaron a descargarse, e informa la última sincronización cuando los datos están desactualizados o falla el refresh. La pantalla de publicación guarda primero la donación, sus imágenes y una operación en la base local cifrada; `SyncCoordinator` sube las imágenes pendientes y crea la donación en el backend cuando puede, conservando reintentos e idempotencia mediante `clientId`. Si no hay categorías locales, el formulario necesita red para prepararse. Mis donaciones, detalle, solicitudes, edición y eliminación siguen dependiendo del backend y no tienen un flujo offline completo.

## Uso de inteligencia artificial

Durante el desarrollo del frontend se utilizó **Codex** como apoyo para revisar el código real, proponer alternativas, detectar riesgos, generar pruebas y documentar decisiones. Las propuestas no se aceptaron automáticamente.

| Área | Uso de Codex | Resultado utilizado | Revisión y verificación |
| --- | --- | --- | --- |
| Persistencia local | Comparación de alternativas y revisión del esquema, cifrado, migraciones, minimización y TTL. | Drift sobre SQLite con SQLCipher, migraciones no destructivas, almacenamiento seguro separado y limpieza destructiva al cerrar sesión. | Pruebas de esquema, cifrado, migración, retención y logout. |
| Lectura y recursos offline | Revisión del flujo local-first, estados de frescura y ciclo de vida de imágenes. | Explore conserva datos locales, distingue caché stale de refresh fallido y usa `cachedLocalPath` para imágenes remotas; las copias de subida usan `managedLocalPath`. | Pruebas de repositorio y widgets, accesibilidad y ejecución offline en dispositivo. |
| Sincronización | Análisis de colas, reintentos, concurrencia, conflictos e identificadores estables. | `pending_operations`, `SyncCoordinator`, UUID para `clientId` y `operationId`, backoff, máximo de intentos, idempotencia y resolución SERVER-WINS/LWW con timestamps del servidor. | Pruebas de unicidad, reintentos, concurrencia, reconciliación y conflictos. |
| Diagnóstico y calidad | Apoyo para aislar diferencias entre pruebas automatizadas y el entorno físico. | Se comprobó que `adb reverse` puede mantener accesible el backend por USB durante modo avión y debe retirarse temporalmente para una prueba offline real. | `flutter analyze`, suite automatizada, revisión de Git y verificación final en un celular. |

Las decisiones finales y la aceptación de cambios correspondieron al equipo, con revisión del diff, análisis estático, pruebas automatizadas y comprobaciones reales de la aplicación.

## Registro y Login

El registro consume `POST /api/auth/register` y vuelve al Login con el correo prellenado. El Login consume `POST /api/auth/login`, guarda ambos tokens, consulta `GET /api/usuarios/perfil` y actualiza el estado global de autenticación. La contraseña nunca se almacena.

## Configuración del backend

El backend utiliza su propio entorno, PostgreSQL y configuración de servicios. Desde su repositorio independiente puede iniciarse con:

```powershell
yarn install
yarn dev
```

El frontend no contiene configuración de base de datos.
