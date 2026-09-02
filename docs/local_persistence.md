# Política de persistencia local

DonApp conserva localmente solo los datos necesarios para restaurar una sesión
limitada, presentar contenido consultado anteriormente y sincronizar creaciones
de donaciones pendientes. La base SQLite está cifrada con SQLCipher y cada dato
de caché que pertenece a una cuenta se separa mediante `cacheUserId`.

## Datos persistidos

| Almacenamiento | Contenido necesario | Finalidad |
| --- | --- | --- |
| `local_authenticated_users` | Identificador, nombre visible, ciudad y vigencia de la validación offline | Identificar al dueño de la caché y ofrecer una sesión offline limitada |
| `local_categories` | Identificador, nombre, descripción y vigencia de caché | Reconstruir listados y formularios previamente cargados |
| `local_donations` | Identificadores local/remoto, datos visibles de la donación y estado de sincronización/caché | Explore, detalle, donaciones propias y creación pendiente |
| `local_donation_images` | Referencia remota o ruta privada temporal, orden, tipo técnico y estado de subida | Mostrar imágenes remotas y reintentar una creación pendiente |
| `local_requests` | Estado, relación con la donación y datos públicos mínimos del participante | Mostrar solicitudes consultadas sin habilitar mutaciones offline |
| membresías y metadatos | Identificadores de colección, acceso, sincronización y expiración | Componer vistas locales y controlar la caché |
| `pending_operations` | Identificadores, tipo, estado, intentos, tiempos de control y código de error sanitizado | Reintentar una operación sin duplicarla |

Las imágenes no se almacenan como bytes o base64 en SQLite. Una ruta privada
administrada por la aplicación solo se conserva mientras la creación la
necesita; se elimina después de una confirmación remota. Los archivos temporales
que pueda mantener el selector de imágenes quedan fuera de esta política y
deberán tratarse en un flujo de limpieza específico.

## Datos excluidos deliberadamente

SQLite no guarda email, teléfono, contraseña, nombre completo adicional,
atributos administrativos, tokens, clave SQLCipher, cuerpos HTTP, payloads de
operaciones, mensajes completos de error, URLs firmadas temporales, bytes de
imágenes ni metadatos EXIF.

`accessToken`, `refreshToken` y la clave de 32 bytes de SQLCipher se conservan
exclusivamente en `flutter_secure_storage`. No se copian a SQLite, preferencias,
archivos ni logs. El código de persistencia y sincronización tampoco registra
tokens, payloads, respuestas HTTP o rutas privadas de imágenes.

Los datos de negocio y los tiempos confirmados por el servidor permanecen
separados de los metadatos locales usados para caché, acceso, reintentos y
sincronización.
