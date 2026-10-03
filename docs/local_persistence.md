# Política de persistencia local

DonApp aplica minimización: conserva estructuras mínimas de perfil/caché y las creaciones pendientes; el flujo integrado permite Explorar y encolar desde una sesión ya abierta, sin restauración offline del perfil. SQLite se cifra con SQLCipher; las imágenes se guardan en archivos privados separados sin cifrado SQLCipher. Los secretos se separan en almacenamiento seguro y los datos de cada cuenta se aíslan mediante `cacheUserId`.

## Esquema y migraciones

La base Drift usa `schemaVersion = 4`. Contiene `local_authenticated_users`, `local_categories`, `local_donations`, `local_donation_memberships`, `local_donation_images`, `local_requests`, `local_collection_metadata` y `pending_operations`.

Las migraciones son incrementales y no destructivas: la versión 2 agregó `lastAccessedAt`, la 3 incorporó la cola y sus índices, y la 4 agregó `cachedLocalPath` a las imágenes. Los datos existentes se conservan durante estas actualizaciones.

## Inventario y retención

| Dato | Ubicación | Propósito | Retención | Eliminación |
| --- | --- | --- | --- | --- |
| Perfil: `userId`, `nombreVisible`, `city`, `lastValidatedAt`, `offlineSessionValidUntil` | SQLite: `local_authenticated_users` | Estructura preparada de perfil mínimo; SessionCoordinator actual restaura tokens y consulta perfil remoto, sin restauración offline integrada | Mientras la sesión local sea válida | Base destruida en logout |
| Access token | `flutter_secure_storage`: `donapp_access_token` | Autenticar solicitudes | Hasta expiración, invalidez o logout | Sesión inválida o logout local |
| Refresh token | `flutter_secure_storage`: `donapp_refresh_token` | Renovar y restaurar la sesión | Hasta expiración, invalidez o logout | Sesión inválida o logout local |
| Clave SQLCipher aleatoria de 32 bytes | `flutter_secure_storage`: `donapp_local_database_key_v1` | Cifrar y abrir SQLite | Mientras exista el almacenamiento local de la sesión | Logout; su valor no se registra ni expone |
| Categorías: identificador, nombre, descripción, `lastSyncedAt`, `expiresAt` | SQLite: `local_categories` | Filtros, creación de donaciones y funcionamiento offline | TTL de 24 horas; vencidas siguen disponibles como desactualizadas | Base destruida en logout |
| Donaciones: identificadores local/remoto/de cliente y cuenta; título, descripción, ciudad, categoría, estado, datos de imagen, timestamps y metadatos de caché/sync | SQLite: `local_donations` | Explorar local-first, creación pendiente y reconciliación; detalle y Mis donaciones de la UI siguen remotos | Explore y detalle: TTL de 30 minutos. Vencer no borra; siete días después sólo puede ser candidata a limpieza futura | Reconciliación cuando corresponda o logout; no hay limpieza automática por antigüedad |
| Solicitudes: identificadores de cuenta, solicitud y colección; detalle, estado, causa opcional de cancelación y fechas; datos mínimos visibles de donación y participante; timestamps de servidor y caché | SQLite: `local_requests` | Estructura preparada de solicitud; pantallas/repositorio actuales consultan remoto | TTL declarado de 30 minutos; vencidas pueden seguir disponibles como desactualizadas | Base destruida en logout |
| URL e identificador remotos, orden, MIME, tamaño y estado de subida de imagen | SQLite: `local_donation_images` | Mostrar la imagen y conservar referencias de sincronización | Mientras la donación permanezca en caché o pendiente | Reconciliación o logout |
| `managedLocalPath` | SQLite y archivo privado en `pending_donation_images` | Copia temporal para subida diferida | Hasta confirmar sincronización o logout | Confirmación remota o logout, incluidos huérfanos del directorio administrado |
| `cachedLocalPath` | SQLite y archivo privado en `remote_donation_images` | Copia de una imagen remota ya publicada para lectura offline | Mientras la imagen permanezca en caché o hasta logout | Limpieza de caché futura o logout, incluidos huérfanos del directorio administrado |
| `cacheUserId`, donación, colección, `lastSeenAt`, `expiresAt` | SQLite: `local_donation_memberships` | Componer Explore/donaciones propias y controlar vigencia | Mientras la colección esté en caché; expirar no borra | Reconciliación o logout |
| `cacheUserId`, clave de colección, `lastSyncedAt`, `expiresAt` | SQLite: `local_collection_metadata` | Control técnico de frescura y sincronización | TTL de la colección | Refresh exitoso o logout |
| `operationId`, `entityClientId`, `cacheUserId`, tipos, estado, intentos, fechas de control y `lastErrorCode` sanitizado | SQLite: `pending_operations` | Reintentar sincronización sin duplicarla | Mientras esté pendiente, procesándose o esperando reintento | Queda completed tras confirmar; se conserva la fila hasta destruir la base en logout |

Las solicitudes tienen estructura local y TTL preparados; esto no implica que todas sus pantallas o mutaciones offline estén integradas. Membresías y metadatos son controles técnicos vinculables a la cuenta, no datos personales principales. No se persisten cursores ni otros metadatos de paginación.

## Imágenes locales

La URL remota es una referencia para mostrar o sincronizar una imagen. En una creación pendiente, `managedLocalPath` apunta a una copia temporal controlada por la aplicación dentro de almacenamiento privado. Se elimina tras la confirmación remota o el logout y no se conserva deliberadamente después.

`cachedLocalPath` tiene un ciclo de vida independiente: corresponde a una copia
de lectura de una imagen remota ya publicada y nunca se utiliza como fuente de
una subida pendiente. Si la copia ya fue descargada, Explore puede mostrarla sin red.

No se guardan imágenes como blobs o base64 en SQLite ni se extraen columnas EXIF. Las copias de archivos pueden conservar metadatos embebidos: no hay rutina de eliminación EXIF que garantice su ausencia. Los temporales externos administrados por el selector de imágenes no pertenecen al directorio privado gestionado por DonApp.

## Datos excluidos deliberadamente

DonApp no persiste localmente:

- contraseña;
- email dentro del perfil offline mínimo;
- teléfono e información personal adicional no requerida;
- roles o atributos administrativos innecesarios;
- tokens o clave SQLCipher en SQLite;
- payloads o cuerpos HTTP completos;
- cuerpos o mensajes completos de error;
- URLs firmadas temporales y payloads en la cola;
- blobs/base64 en SQLite ni columnas EXIF extraídas (no garantiza borrar EXIF de los archivos).

Los tokens y la clave están únicamente en `flutter_secure_storage`; no se copian a SQLite. Persistencia y sincronización evitan registrar sus valores, payloads HTTP, respuestas completas o rutas privadas.

## TTL, retención y borrado

El TTL representa frescura, no tiempo máximo de almacenamiento ni una orden de borrado. `expiresAt` se calcula con el reloj local como `lastSyncedAt + TTL`; las fechas de negocio del servidor no participan. Un dato vencido puede seguir visible offline como posiblemente desactualizado.

`LocalCachePolicy` clasifica como candidata a limpieza futura una entrada que lleva más de siete días vencida. Esta clasificación no elimina datos: no existe limpieza automática basada en esos siete días. Un refresh exitoso renueva `lastSyncedAt` y `expiresAt`, aunque el contenido no cambie; un error remoto conserva los valores anteriores.

El perfil no comparte los TTL de caché: `offlineSessionValidUntil` delimita su validez y se conserva mientras la sesión local sea válida.

## Lectura local-first

Explore presenta primero las donaciones y categorías almacenadas y luego intenta actualizarlas desde la API. Si el refresh remoto falla, las tarjetas y el `lastSyncedAt` de la última sincronización real permanecen visibles; el spinner termina y puede mostrarse el aviso de datos guardados. Solo un refresh exitoso renueva la fecha y la frescura. Un TTL vencido señala contenido posiblemente desactualizado, pero no lo elimina.

Como evidencia histórica aportada en una revisión anterior, este flujo se validó en un dispositivo físico con donaciones, una imagen previamente descargada, el aviso de datos guardados y la hora de última sincronización visibles sin red.

## Cola, reintentos y conflictos

`pending_operations` conserva cada trabajo con un `operationId` estable. La donación conserva por separado un UUID `clientId`, que identifica la misma creación en todos los reintentos y permite al backend evitar duplicados; `operationId` no lo sustituye.

`SyncCoordinator` procesa actualmente `CREATE_DONATION`, con `syncMaxAttempts = 5`. Tras fallos recuperables espera 5, 15, 30 y 60 segundos; la función contempla 120 segundos, pero el quinto fallo ya es permanente. Una operación que queda en `processing` puede recuperarse tras cinco minutos como procesamiento abandonado. Al confirmar el servidor, el coordinador reconcilia el ID remoto y adopta `createdAt` y `updatedAt` remotos.

La resolución compara versiones confirmadas del servidor y protege creaciones locales pendientes; no es un merge offline general. SERVER-WINS/LWW aquí significa que `serverUpdatedAt` y los timestamps del servidor son la autoridad para conflictos; el reloj local solo controla caché, reintentos y sincronización. Es una estrategia simple y determinista. Si en el futuro se habilitan ediciones offline concurrentes, podrían perderse cambios porque no existe merge por campo.

La pantalla actual de publicación usa la infraestructura local cuando DonApp se compone con `OfflineDonations`: valida y copia las imágenes, guarda la donación y la operación en Drift, y vuelve a Inicio con el aviso de que se publicará cuando haya conexión. `SyncCoordinator` procesa después la outbox: sube las imágenes pendientes, crea la donación remota con el mismo `clientId` y reconcilia la fila local. La ruta remota directa del repositorio se conserva para la composición sin outbox y para pruebas, pero no es la composición normal de la aplicación. Explore es la lectura local-first integrada; solicitudes, edición y eliminación no tienen un flujo offline completo en la UI.

## Cierre de sesión

El logout invalida inmediatamente autenticación y perfil en memoria. Luego bloquea sincronizaciones nuevas, espera la activa, cierra Drift y elimina `donapp.sqlite` y sus sidecars `-wal`, `-shm` y `-journal`. También elimina imágenes privadas administradas, clave SQLCipher, access token y refresh token.

Al destruir la base desaparecen perfil, cachés, membresías, metadatos y operaciones pendientes. Las donaciones no sincronizadas y sus imágenes se pierden deliberadamente por privacidad y no pasan a otro login. Una sesión nueva crea almacenamiento vacío y una clave nueva.

La revocación remota no condiciona la limpieza local, de modo que un fallo de red no impide el logout. Android Auto Backup está deshabilitado para evitar restaurar la base, imágenes o secretos fuera de su contexto criptográfico.

## Nota de privacidad

La estrategia combina minimización, cifrado local, separación de secretos y limpieza al cerrar sesión. Estas medidas reducen la exposición sin sustituir los controles de seguridad del sistema operativo y del dispositivo.
