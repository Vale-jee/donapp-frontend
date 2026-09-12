# Flujo funcional de DonApp

Este documento resume el recorrido principal del cliente móvil, los endpoints que intervienen y el resultado visible esperado en cada paso.

## Recorrido principal

| Paso | Acción | Endpoint o servicio | Resultado esperado | Evidencia visual sugerida |
|---|---|---|---|---|
| Login | Ingresar correo y contraseña. | `POST /api/auth/login` y `GET /api/usuarios/perfil` | Los tokens se almacenan de forma segura, se recupera el perfil y se abre Inicio o el destino privado solicitado. | Login completo e Inicio autenticado. |
| Explorar | Abrir Explorar desde Inicio. | Caché local y `GET /api/donaciones` | Se muestran primero las tarjetas guardadas y luego se intenta el refresh remoto. Ante un fallo se conservan el contenido, las imágenes locales disponibles y la última sincronización real. | Varias tarjetas de donaciones y, sin red, aviso de datos guardados. |
| Detalle | Seleccionar una donación. | `GET /api/donaciones/{id}` | Se muestra la información completa de la donación y las acciones disponibles para el usuario. | Pantalla de detalle. |
| Crear | Volver a Inicio y abrir Donar. | `GET /api/categorias` | El formulario queda preparado con las categorías activas obtenidas del backend. | Formulario con una categoría seleccionada. |
| Imágenes | Seleccionar entre una y cinco imágenes válidas. | `POST /api/imagenes/firma` y subida HTTPS firmada hacia Cloudinary | Se obtienen URL seguras, conservando el orden, listas para incluir en la creación. | Previsualizaciones de imágenes en el formulario. |
| Publicar | Completar el formulario y pulsar **Publicar donación**. | `POST /api/donaciones` | La API crea la donación y devuelve su información. | Formulario completo antes de publicar. |
| Detalle creado | Finalizar la publicación. | Navegación a `/donaciones/{id}` | La aplicación reemplaza el formulario por el detalle de la nueva donación. | Detalle de la donación recién creada. |

El recorrido Explorar → Detalle → Crear no representa una transición directa desde el detalle. El flujo normal es:

```text
Explorar
  → Detalle
  → volver a Inicio
  → Donar
  → Crear
```

## Sesión y navegación

Al iniciar la aplicación:

```text
Inicio de aplicación
  → leer tokens
  → validar sesión
  → renovar tokens si es necesario
  → recuperar perfil
  → abrir la ruta privada
```

Las rutas privadas reaccionan al estado global de autenticación. Si el usuario intentó abrir una antes del Login, el router conserva ese destino y lo recupera después de autenticarlo.

Ante una autenticación definitivamente inválida:

```text
401 definitivo
  → eliminar tokens y perfil
  → pasar a no autenticado
  → Bienvenida conservando redirect
  → Login
  → regresar al destino solicitado
```

- Un 401 de una petición protegida intenta renovar la sesión y repetir la petición una sola vez. Un segundo 401 invalida la sesión sin crear un ciclo.
- Un 401 de Login representa credenciales incorrectas y no inicia una renovación.
- Un 403 por falta de permisos conserva la sesión y muestra acceso denegado.
- Un 403 que identifica una cuenta inactiva elimina la sesión y bloquea las rutas privadas.
- Los fallos recuperables de red, timeout o servidor durante la renovación no eliminan los tokens.

## Validación del formulario de donaciones

- Título, descripción y categoría se validan al perder foco.
- Al pulsar **Publicar donación**, el formulario vuelve a validar todos sus campos antes de realizar peticiones remotas.
- Las reglas locales muestran mensajes debajo del campo correspondiente.
- Los errores estructurados que devuelve la API para `titulo`, `descripcion`, `categoriaId` e `imagenes` se asocian al control correspondiente; errores generales o desconocidos permanecen como mensaje del formulario.
- Las imágenes se validan por cantidad, formato y tamaño antes de subirlas.
- Una navegación temporal realizada con `push` mantiene montado el formulario y conserva texto, categoría e imágenes. Si el usuario abandona la ruta y abre un formulario nuevo, comienza limpio.

## Cliente HTTP y justificación técnica

DonApp mantiene **package:http** (`http: ^1.6.0`, versión resuelta 1.6.0). La funcionalidad transversal de la API se centraliza en `ApiClient`, `ApiErrorMapper` y coordinadores propios: `SessionCoordinator` administra recuperación y rotación de sesión; `SyncCoordinator` define reintentos de operaciones persistidas. Esta separación permite completar las necesidades HTTP identificadas sin trasladar políticas de red a las pantallas ni cambiar la arquitectura. No se identifica una necesidad técnica de migrar ahora a Dio.

### Alcance real

Se consumen **18 operaciones método+ruta sobre 17 rutas de la API**: autenticación (4: registro, login, refresh y logout), perfil (1), categorías (1), donaciones (4: crear, disponibles, propias y detalle), solicitudes (7: crear, enviadas, recibidas, detalle, aceptar, rechazar y cancelar) y firma de imágenes (1). Además, se realiza POST multipart a la URL firmada de Cloudinary y GET de imágenes con URL variable para caché; estas transferencias no se cuentan como endpoints adicionales del backend.

| Aspecto | Implementación actual con package:http | Aporte concreto de Dio |
| --- | --- | --- |
| Bearer y configuración | Los servicios agregan Authorization; ApiConfig centraliza API_BASE_URL. El router comparte un ApiClient con SessionRecovery entre servicios protegidos. | BaseOptions e interceptores facilitarían headers y opciones comunes; no son necesarios para centralizar estas políticas. |
| Renovación y 401 | ApiClient repite una vez después de recuperar el token. SessionCoordinator comparte el refresh entre 401 concurrentes, reutiliza el token ya rotado y guarda ambos tokens. Login no dispara recuperación; un segundo 401 invalida la sesión. | Interceptores y QueuedInterceptor ofrecen mecanismos de coordinación; las reglas de rotación, exclusión de login/refresh e invalidación seguirían siendo propias. |
| Multipart | ImageUploadService solicita firma mediante ApiClient y sube 1–5 imágenes secuencialmente con AbortableMultipartRequest y un cliente separado, sin Bearer de DonApp. | FormData, MultipartFile y callbacks de progreso simplificarían transferencias con progreso; multipart ya está implementado. |
| Timeouts y cancelación | Plazos totales centralizados: API 15 s por intento, subida 120 s por imagen y descarga 30 s por imagen; todos incluyen el body. Solo la subida tiene aborto por timeout. No hay cancelación HTTP expuesta a la interfaz. | Timeouts de conexión/envío/recepción y CancelToken reducen código de control. Sus plazos por fase no equivalen automáticamente a un límite total de operación. |
| Errores y logging | ApiErrorMapper traduce estados, validaciones, red y timeout a ApiException. Cloudinary tiene clasificación propia. No existe logging HTTP transversal; lastErrorCode de sincronización no es un log de peticiones. | DioException y LogInterceptor aportan mecanismos, pero requieren adaptar clasificación y ocultar credenciales, firmas y datos privados. |
| Pruebas | Client inyectable, MockClient y clientes simulados de streaming; existen pruebas de servicios, sesión, errores y subida. | También permite pruebas mediante adaptadores; migrar obliga a adaptar los dobles de transporte y verificar equivalencia. |

### Trabajo propio y costo de cambio

La composición de la API se establece por instancia de `SessionCoordinator`: recibe un `ApiClient` inyectable o crea el cliente base. Autenticación y restauración de perfil comparten ese cliente sin recuperación automática; `protectedApiClient` es una vista estable que reutiliza el mismo transporte, URL y timeout mediante `withSessionRecovery`. El router reutiliza el AuthService del coordinador e inyecta la vista protegida en perfil, categorías, donaciones, solicitudes y firma de imágenes. Así, el arranque normal utiliza dos vistas ApiClient sobre un único http.Client para la API propia, sin singleton global. Los constructores independientes y los reemplazos de servicios se conservan para pruebas; no forman parte de la composición normal de la app.

La separación de políticas evita que el refresh intente renovarse a sí mismo y conserva la restauración inicial gestionada por SessionCoordinator. Cloudinary mantiene su transporte multipart separado, sin Bearer de DonApp. RemoteImageCache también mantiene un transporte de recursos, incluso cuando una referencia relativa se resuelve contra el host de la API: no consume el sobre JSON ni aplica recuperación de sesión. Esta composición no cambia timeouts, cancelación, serialización, logging ni políticas de cierre existentes.

Con package:http ya se implementan manualmente serialización y validación del sobre JSON, headers Bearer, recuperación tras 401, rotación concurrente, traducción de errores y política de reintentos de sincronización. No hay reintento genérico de todos los errores HTTP. El refresh automático depende de inyectar SessionRecovery; construir ApiClient() por separado no lo habilita. La restauración inicial de sesión tiene su propio flujo en SessionCoordinator.

Si se requieren cancelación desde la interfaz, progreso o logging, habrá que incorporar propagación de señales Abortable mediante Client.send, seguimiento de bytes y registros sanitizados en las capas de transporte. También queda por definir el cierre de los clientes propios: los wrappers actuales no exponen close. Son mejoras pendientes, no limitaciones que obliguen a cambiar de biblioteca.

Migrar ahora tendría un costo moderado y riesgo de regresión en sesión, errores y subida: habría que sustituir transporte, adaptar excepciones y pruebas, conservar el reintento único, evitar rotaciones duplicadas y mantener los plazos y la separación de credenciales de Cloudinary. Los modelos y repositorios podrían conservarse detrás de ApiClient, pero Dio no reemplazaría la cola persistida, la idempotencia ni las reglas de sesión. Se reconsiderará si el producto necesita de forma extensa progreso, cancelación y políticas de transferencia por fase; el número actual de endpoints no justifica por sí solo una migración.

Evidencia local: [ApiClient](../lib/services/api_client.dart), [configuración](../lib/config/api_config.dart), [inyección en router](../lib/navigation/app_router.dart), [sesión](../lib/services/session_coordinator.dart), [subida](../lib/services/image_upload_service.dart), [caché de imágenes](../lib/services/remote_image_cache.dart) y [sincronización](../lib/services/sync_coordinator.dart). Las pruebas existentes cubren [401 y errores de transporte](../test/services/api_client_test.dart), [rotación concurrente y restauración](../test/services/session_coordinator_test.dart), [multipart, errores y aborto por timeout](../test/services/image_upload_service_test.dart) y [política de errores](../test/services/service_error_policy_test.dart). Esta evaluación revisa el código y las pruebas; no constituye una nueva ejecución de la suite.

Referencias de capacidades: [documentación de package:http](https://pub.dev/packages/http) y [documentación de Dio](https://pub.dev/packages/dio).

## Validación de respuestas HTTP

ApiClient conserva el código HTTP real al clasificar errores, incluso si el cuerpo está vacío, contiene HTML o no es un objeto JSON. Los códigos esperados siguen definidos por operación mediante successStatusCodes (200 o 201 en los servicios actuales); una respuesta exitosa debe conservar el sobre JSON con success: true y data. Un sobre inválido produce unexpectedResponse con el status recibido.

ApiErrorMapper traduce 400/422 a validación, 401 a autenticación (credenciales inválidas en login), 403 a acceso denegado o cuenta inactiva, 404 a recurso no encontrado, 409 a conflicto, 429 a límite de solicitudes y 500–599 a error temporal del servidor. Otros estados producen unexpectedResponse sin perder el código. Un objeto JSON permite conservar errors y usar mensajes del backend según los filtros y permisos existentes; un cuerpo vacío o no JSON utiliza mensajes seguros del dominio. La recuperación protegida ante 401 evalúa el status sin depender del cuerpo y mantiene el límite de un reintento.

## Tiempos de espera de red

Las duraciones se definen en [NetworkTimeouts](../lib/config/network_timeouts.dart). Son límites totales de cada intercambio HTTP: incluyen establecimiento de conexión, envío, espera de cabeceras y lectura completa del body. No se reinician al recibir fragmentos ni se presentan como timeouts independientes de conexión y recepción.

| Operación | Constante | Plazo | Aplicación y resultado al vencer |
| --- | --- | --- | --- |
| API propia | `apiResponse` | 15 s por intento | ApiClient limita el Future de get/post/patch, que incluye el body. ApiErrorMapper devuelve ApiException de tipo timeout con el mensaje comprensible existente. |
| Subida a Cloudinary | `imageUpload` | 120 s por imagen | ImageUploadService limita send más Response.fromStream; conserva el aborto de AbortableMultipartRequest y CloudinaryFailure.timeout. Se mantiene el plazo porque ya se verificó una subida móvil superior a 30 s. |
| Descarga a caché | `imageDownload` | 30 s por imagen | RemoteImageCache limita get, incluido el body. Traduce TimeoutException a ApiException de tipo timeout, elimina el temporal y no publica una respuesta tardía. El plazo permite más transferencia que una respuesta JSON sin prolongarlo tanto como una subida. |

`package:http` no ofrece connectTimeout/receiveTimeout separados en la interfaz común de Client. Client.send devuelve una StreamedResponse y permite limitar por separado hasta cabeceras y la lectura posterior; sin embargo, la primera fase también incluye conexión y envío, por lo que no mide exclusivamente establecimiento de conexión. En plataformas IO se puede configurar connectionTimeout en dart:io HttpClient, pero no es una política portable de Client ni identifica todos los errores de red como timeout. DonApp conserva la interfaz inyectable actual y usa un presupuesto total finito: una conexión o recepción bloqueada consume ese mismo presupuesto. No se garantiza un plazo independiente de socket ni se informa en qué fase se agotó.

Future.timeout deja de esperar, pero no cancela por sí solo el transporte subyacente. API y descarga pueden seguir teniendo actividad de transporte después del error; su resultado tardío se descarta. La subida conserva su señal de aborto existente. Estos plazos limitan la espera del consumidor HTTP, no garantizan cierre del socket. No se añade cancelación desde pantallas ni se altera la política de reintentos.

El refresh y la repetición después de 401 son intercambios separados, cada uno con el plazo de API; 15 s no es un límite de todo el flujo de sesión. La firma de Cloudinary usa el plazo de API; 120 s aplica a cada imagen, no al lote. Lectura del archivo local previa a subir, escritura en disco, acceso al almacenamiento seguro y procesamiento posterior no forman parte de los plazos HTTP. Una imagen ya guardada no realiza petición. El repositorio conserva su manejo de fallos de caché para mantener disponible el contenido remoto.

Se verifica el límite del body de API, incluso con cabeceras y fragmentos recibidos; respuestas dentro de plazo; descarga bloqueada antes o después de cabeceras, limpieza y propagación del error; y las pruebas existentes de subida a los 60 s y timeout con aborto a los 120 s. Los clientes y plazos inyectables permiten pruebas sin backend real.

Referencias: [Client.send](https://pub.dev/documentation/http/latest/http/Client/send.html), [HttpClient.connectionTimeout](https://api.dart.dev/dart-io/HttpClient/connectionTimeout.html) y [Future.timeout](https://api.dart.dev/dart-async/Future/timeout.html).

## Correspondencia entre JSON del servidor y modelos Dart

Esta referencia describe el código actual de usuario/perfil, donación y solicitud. Las rutas de campo son relativas a `data.usuario`, `data.donacion` o `data.solicitud`, salvo que se indique `data` explícitamente. Los servicios extraen estos contenedores antes de invocar `fromJson`; no son atributos adicionales de las entidades.

En las tablas, **O** significa clave obligatoria en la respuesta del backend para la variante indicada; **C** significa presencia condicional. La columna **Null B/D** distingue backend y Dart. Una clave obligatoria puede contener `null`: los parsers actuales también toleran su ausencia cuando se indica «ausencia → null». Esto es tolerancia del cliente, no permiso para omitirla en el contrato. Los parámetros `required` de un constructor Dart no garantizan presencia en JSON ni impiden tipos nullable.

Los tipos backend corresponden a TypeScript y su representación JSON: `number` entero procede de `Int` de Prisma; `Date` se serializa como string ISO-8601. No se enumeran como campos JSON las columnas ni relaciones que los selectores del servidor excluyen. El esquema y la política de almacenamiento local se describen en [Persistencia local](local_persistence.md).

### Usuario y perfil

`GET /api/usuarios/perfil` produce `UserProfile`. `POST /api/auth/login` incluye una proyección menor, `AuthUser`, en `AuthSession.usuario`; no debe interpretarse como un perfil completo. El resumen público de participantes de solicitudes se documenta más abajo.

| Entidad/modelo | Campo JSON backend | Campo Dart | Tipo backend → JSON | Tipo Dart | Presencia | Null B/D | Transformación / observación |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Perfil | `id` | `id` | number entero | int | O | No/No | Directa. |
| Perfil | `nombreCompleto` | `nombreCompleto` | string | String | O | No/No | Exige string no vacío. |
| Perfil | `nombreVisible` | `nombreVisible` | string | String | O | No/No | Conserva el nombre español. |
| Perfil | `email` | `email` | string | String | O | No/No | Lectura sin normalización. |
| Perfil | `ciudad` | `ciudad` | string | String | O | No/No | Exige string no vacío. |
| Perfil | `telefono` | `telefono` | string o null | String? | O | Sí/Sí | Ausencia → null; admite string vacío. |
| Perfil | `fotoPerfil` | `fotoPerfil` | string o null | String? | O | Sí/Sí | Ausencia → null; admite string vacío. |
| Perfil | `activo` | `activo` | boolean | bool | O | No/No | Sin coerción. |
| Perfil | `createdAt` | `createdAt` | Date → string ISO | DateTime | O | No/No | DateTime.tryParse; sin toUtc explícito. |
| Perfil | `updatedAt` | `updatedAt` | Date → string ISO | DateTime | O | No/No | Igual que createdAt. |
| Perfil | `rol` | `rol` | objeto | ProfileRole | O | No/No | Objeto anidado. |
| Rol de perfil | `rol.codigo` | `rol.codigo` | Role → string: ADMIN/USUARIO | String | O | No/No | Dart valida string no vacío, no enum. |
| Rol de perfil | `rol.nombre` | `rol.nombre` | string | String | O | No/No | Directa. |
| Usuario de login | `id` | `AuthUser.id` | number entero | int | O | No/No | Directa. |
| Usuario de login | `nombreVisible` | `AuthUser.nombreVisible` | string | String | O | No/No | Sin renombrado. |
| Usuario de login | `fotoPerfil` | `AuthUser.fotoPerfil` | string o null | String? | O | Sí/Sí | Ausencia → null; admite string vacío. |
| Usuario de login | `rol` | `AuthUser.rol` | objeto | AuthRole | O | No/No | Objeto anidado. |
| Rol de login | `rol.codigo` | `rol.codigo` | string: ADMIN/USUARIO | String | O | No/No | No se convierte en enum Dart. |
| Rol de login | `rol.nombre` | `rol.nombre` | string | String | O | No/No | Directa. |

### Donación

**D** identifica `DonationDetail`, usado en GET por id y POST de creación. **L** identifica `DonationListItem`, usado en GET de disponibles y propias. El POST usa `fromMutationJson`; el GET por id usa `fromJson`.

| Entidad/modelo | Campo JSON backend | Campo Dart | Tipo backend → JSON | Tipo Dart | Presencia | Null B/D | Transformación / observación |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Donación D/L | `id` | `id` | number entero | int | O | No/No | Directa. |
| Donación D/L | `titulo` | `titulo` | string | String | O | No/No | No se llama title en estos modelos. |
| Donación D | `descripcion` | `descripcion` | string | String | O | No/No | No está en el listado. |
| Donación D/L | `ciudad` | `ciudad` | string | String | O | No/No | El backend la obtiene del perfil al crear. |
| Donación D/L | `estado` | `estado` | EstadoDonacion → string | DonationStatus | O | No/No | PUBLICADA/RESERVADA/ENTREGADA/RETIRADA → publicada/reservada/entregada/retirada. |
| Donación D/L | `createdAt` | `createdAt` | Date → string ISO | DateTime | O | No/No | Exige Z u offset ±hh:mm; parsea y convierte a UTC. |
| Donación D/L | `updatedAt` | `updatedAt` | Date → string ISO | DateTime | O | No/No | Misma conversión UTC. |
| Donación D/L | `categoria` | Sin objeto propio | objeto | — | O | No/— | Se aplana en dos atributos. |
| Donación D/L | `categoria.id` | `categoriaId` | number entero | int | O | No/No | Aplanamiento. |
| Donación D/L | `categoria.nombre` | `categoriaNombre` | string | String | O | No/No | Aplanamiento. |
| Donación D | `imagenes` | `imagenes` | array de objetos | List<DonationImage> | O | No/No | Copia inmutable ordenada por orden. |
| Donación L | `imagenPrincipal` | `imagenPrincipal` | objeto o null | DonationImage? | O | Sí/Sí | Primera imagen en backend; ausencia → null en Dart. |
| Donación L | `cantidadImagenes` | `cantidadImagenes` | number entero | int | O | No/No | Conteo del backend; no lo calcula Flutter. |
| Imagen | `imagenes[].id` / `imagenPrincipal.id` | `DonationImage.id` | number entero | int | O en imagen | No/No | Directa. |
| Imagen | `imagenes[].referencia` / `imagenPrincipal.referencia` | `DonationImage.referencia` | string | String | O en imagen | No/No | Referencia remota. |
| Imagen | `imagenes[].orden` / `imagenPrincipal.orden` | `DonationImage.orden` | number entero | int | O en imagen | No/No | Orden asignado desde 1 al crear. |
| Imagen local | No existe | `cachedLocalPath` | — | String? | Opcional local | —/Sí | No se lee del JSON; ruta de caché local. |
| Donación D | `puedeSolicitar` | `puedeSolicitar` | boolean | bool | O GET; ausente POST | No/No | Calculado por backend en GET; fromMutationJson asigna false sin leerlo. |
| Donación creada | `clientId` | No se lee en DonationDetail | string o null; propiedad TS opcional | — | C: POST lo selecciona; GET lo omite | Sí/— | El cliente lo envía para idempotencia, pero ignora el valor devuelto. |
| Respuesta de creación | `data.procesamientoAsincrono` | No consumido | objeto | — | O POST | No/— | Metadato fuera de donacion. |
| Respuesta de creación | `data.procesamientoAsincrono.estado` | No consumido | string: ENQUEUED/PENDING_RECONCILIATION | — | O POST | No/— | DonationService solo extrae data.donacion. |

### Solicitud y resúmenes anidados

Los campos comunes se leen mediante `_RequestFields` en `SentRequestListItem`, `ReceivedRequestListItem` y `RequestDetail`. `CreatedRequest` solo conserva `id`, `status` y `donation`, aunque POST devuelve más campos. Los listados usan GET `/api/solicitudes/enviadas` y `/recibidas`; detalle y acciones usan GET por id y PATCH `aceptar`, `rechazar`, `cancelar`.

| Entidad/modelo | Campo JSON backend | Campo Dart | Tipo backend → JSON | Tipo Dart | Presencia | Null B/D | Transformación / observación |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Solicitud | `id` | `id` | number entero | int | O | No/No | También CreatedRequest. |
| Solicitud | `estado` | `status` | EstadoSolicitud → string | RequestStatus | O | No/No | PENDIENTE/ACEPTADA/RECHAZADA/CANCELADA → pendiente/aceptada/rechazada/cancelada. También CreatedRequest. |
| Solicitud | `causaCancelacion` | `cancellationCause` | CausaCancelacionSolicitud → string o null | CancellationCause? | O | Sí/Sí | Ausencia → null; POST devuelve el campo pero CreatedRequest lo ignora. |
| Solicitud | `aceptadaAt` | `acceptedAt` | Date → string ISO o null | DateTime? | O | Sí/Sí | Ausencia → null; parseo sin toUtc explícito. Ignorado en CreatedRequest. |
| Solicitud | `rechazadaAt` | `rejectedAt` | Date → string ISO o null | DateTime? | O | Sí/Sí | Igual; ignorado en CreatedRequest. |
| Solicitud | `canceladaAt` | `cancelledAt` | Date → string ISO o null | DateTime? | O | Sí/Sí | Igual; ignorado en CreatedRequest. |
| Solicitud | `createdAt` | `createdAt` | Date → string ISO | DateTime | O | No/No | DateTime.tryParse; ignorado en CreatedRequest. |
| Solicitud | `updatedAt` | `updatedAt` | Date → string ISO | DateTime | O | No/No | Igual; ignorado en CreatedRequest. |
| Solicitud | `donacion` | `donation` | objeto RequestDonation | RequestDonationSummary | O | No/No | También CreatedRequest. |
| Solicitud enviada | `donante` | `donor` | objeto PublicUser | RequestUserSummary | O en enviadas | No/No | Ausente en creación y recibidas. |
| Solicitud recibida | `solicitante` | `applicant` | objeto PublicUser | RequestUserSummary | O en recibidas | No/No | Ausente en creación y enviadas. |
| Solicitud detalle/acción | `donante` / `solicitante` | `otherUser` | objetos PublicUser; propiedades TS opcionales | RequestUserSummary | C por actor | No/No | Flutter exige exactamente uno; incompatibilidad descrita abajo. |
| Donación resumida | `donacion.id` | `donation.id` | number entero | int | O | No/No | Directa. |
| Donación resumida | `donacion.titulo` | `donation.title` | string | String | O | No/No | Aquí sí existe titulo → title. |
| Donación resumida | `donacion.estado` | `donation.status` | EstadoDonacion → string | RequestDonationStatus | O | No/No | Mismos cuatro valores de donación; enum Dart separado. |
| Donación resumida | `donacion.imagenPrincipal` | `donation.mainImage` | string o null | String? | O | Sí/Sí | Es referencia de imagen, no objeto DonationImage; ausencia → null, string vacío inválido. |
| Usuario resumido | `donante.id` / `solicitante.id` | `RequestUserSummary.id` | number entero | int | O si existe usuario | No/No | Bajo donor, applicant u otherUser. |
| Usuario resumido | `donante.nombreVisible` / `solicitante.nombreVisible` | `RequestUserSummary.visibleName` | string | String | O si existe usuario | No/No | nombreVisible → visibleName solo en este modelo. |
| Usuario resumido | `donante.fotoPerfil` / `solicitante.fotoPerfil` | `RequestUserSummary.profilePhoto` | string o null | String? | O si existe usuario | Sí/Sí | Ausencia → null; string vacío inválido, a diferencia de UserProfile/AuthUser. |
| Usuario resumido | `donante.ciudad` / `solicitante.ciudad` | `RequestUserSummary.city` | string | String | O si existe usuario | No/No | Renombrado. |
| Solicitud derivada | No existe | `actor` | — | RequestActor | Derivado local | —/No | donante presente → applicant; solicitante presente → owner. |
| Solicitud derivada | No existe | `canAcceptOrReject` | — | bool | Getter local | —/No | actor owner, solicitud pendiente y donación publicada. |
| Solicitud derivada | No existe | `canCancel` | — | bool | Getter local | —/No | actor applicant y solicitud pendiente. |

`CancellationCause` traduce `VOLUNTARIA`, `OTRA_SOLICITUD_ACEPTADA`, `DONACION_RETIRADA` y `USUARIO_INACTIVO` a `voluntaria`, `otraSolicitudAceptada`, `donacionRetirada` y `usuarioInactivo`. Los parsers de enums rechazan valores desconocidos. Los getters `label` producen textos de presentación locales; los getters `apiValue` de estados producen los valores API en mayúsculas.

**Incompatibilidad actual de participantes:** `findRequestDetail` y `mutationDetailSelect` seleccionan siempre `solicitante`. `mapRequest` lo conserva y además agrega `donante` cuando el actor es el solicitante. Por tanto, GET del detalle y PATCH de cancelación como solicitante devuelven ambos objetos. `RequestDetail.fromJson` rechaza ese caso con `FormatException('Actor de solicitud inconsistente.')`, que el servicio convierte en respuesta inesperada. Como propietario, detalle/aceptación/rechazo contienen solo `solicitante`. Esta tabla registra la implementación actual; no presupone que la exclusividad esperada por Flutter esté garantizada ni corrige el contrato.

### Colecciones y paginación

En esta tabla las rutas son relativas a `data`. Cada fila de paginación aplica tanto a donaciones como a solicitudes.

| Entidad/modelo | Campo JSON backend | Campo Dart | Tipo backend → JSON | Tipo Dart | Presencia | Null B/D | Transformación / observación |
| --- | --- | --- | --- | --- | --- | --- | --- |
| DonationPage | `donaciones` | `donations` | array de OwnDonationListItem | List<DonationListItem> | O | No/No | Mapea elementos; admite lista vacía. |
| RequestPage<T> | `solicitudes` | `requests` | array de SafeRequest | List<T> | O | No/No | T es SentRequestListItem o ReceivedRequestListItem. |
| DonationPage / RequestPage | `pagination` | `pagination` | objeto | DonationPagination / RequestPagination | O | No/No | Modelo anidado. |
| Paginación | `pagination.page` | `pagination.page` | number entero | int | O | No/No | Directa. |
| Paginación | `pagination.limit` | `pagination.limit` | number entero | int | O | No/No | Directa. |
| Paginación | `pagination.total` | `pagination.total` | number entero | int | O | No/No | Conteo backend. |
| Paginación | `pagination.totalPages` | `pagination.totalPages` | number entero | int | O | No/No | Backend: Math.ceil(total / limit). |
| Paginación derivada | No existe | `pagination.hasNextPage` | — | bool | Getter local | —/No | page < totalPages. |

### Entradas de creación de donaciones y solicitudes

Estos nombres Dart son **parámetros de servicios**, no atributos de los modelos de respuesta. La obligatoriedad aquí corresponde al cuerpo de la petición.

| Entidad/operación | Campo JSON backend | Parámetro Dart | Tipo backend | Tipo Dart | Presencia | Null B/D | Transformación / observación |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Crear donación | `clientId` | `clientId` | string UUID | String? | Opcional | No/Sí | Si es null se omite la clave; backend acepta ausencia, no null. |
| Crear donación | `titulo` | `title` | string | String | O | No/No | Backend recorta y colapsa espacios; 5–100 caracteres. |
| Crear donación | `descripcion` | `description` | string | String | O | No/No | Backend recorta; 20–1000 caracteres, texto plano validado. |
| Crear donación | `categoriaId` | `categoryId` | number entero positivo | int | O | No/No | Identificador; respuesta usa categoria.id. |
| Crear donación | `imagenes` | `imageReferences` | string[] | List<String> | O | No/No | 1–5 referencias, recortadas y sin duplicados; respuesta devuelve objetos. |
| Crear solicitud | `donacionId` | `donationId` | number entero positivo | int | O | No/No | Cuerpo único; identidad del solicitante procede de autenticación. |

Los filtros son parámetros de URL, no campos JSON: `categoryId` → `categoriaId` en disponibles; `status` → `estado` en propias y solicitudes, mediante `apiValue`. Son opcionales y se omiten cuando valen null en Dart. `page` y `limit` se envían como strings; Zod los convierte a enteros, admite ausencia con valores 1 y 20 y limita `limit` a 100. Las acciones de solicitud envían un objeto vacío.

### Campos no consumidos y límites de la correspondencia

- Todos los campos de la proyección de perfil y del usuario de login tienen correspondencia. El endpoint independiente de perfil público no es invocado por `ProfileService`; los resúmenes públicos sí se consumen dentro de solicitudes.
- La respuesta de creación de donación devuelve `clientId` y `procesamientoAsincrono.estado`, que no se incorporan a modelos Flutter. `clientId` sí se utiliza como entrada de creación y en sincronización local; no es un campo completamente ajeno al cliente.
- En creación de solicitud, Flutter ignora `causaCancelacion`, `aceptadaAt`, `rechazadaAt`, `canceladaAt`, `createdAt` y `updatedAt`. En listados/detalle sí los modela.
- Otros contratos de donación del backend, no invocados por `DonationService`, exponen `retiradaAt` (retirada, Date no nullable → string ISO), y `donanteConfirmoAt`, `receptorConfirmoAt`, `entregadaAt` (confirmación de entrega, Date nullable → string ISO o null). Son claves obligatorias en esas respuestas, sin atributo Dart en los modelos actuales.
- Campos persistidos como `Usuario.rolId`, `Donacion.propietarioId`, `Donacion.solicitudAceptadaId` y `Solicitud.solicitanteId` no son campos JSON de las proyecciones consumidas. `Solicitud.donacionId` es entrada de creación; en respuestas el identificador se recibe dentro de `donacion.id`. Los hashes de autenticación tampoco forman parte del contrato público.
- Esta referencia cubre las tres entidades principales, sus proyecciones y paginación. No pretende inventariar tokens, categorías independientes, subida de imágenes, errores ni endpoints administrativos.

### Fuentes verificables

Los enlaces al backend suponen los repositorios hermanos `donapp-frontend` y `donapp`.

- Perfil: [modelo Dart](../lib/models/user_profile.dart), [servicio Flutter](../lib/services/profile_service.dart), [contrato backend](../../donapp/src/lib/services/usuario-service.ts), [selector seguro](../../donapp/database/usuarios/index.ts), [ruta de perfil](../../donapp/src/pages/api/usuarios/perfil.ts).
- Usuario de login: [AuthUser/AuthRole](../lib/models/auth_session.dart), [AuthService](../lib/services/auth_service.dart), [LoginResult](../../donapp/src/lib/services/auth-service.ts).
- Donación: [modelos Dart](../lib/models/donation.dart), [DonationService](../lib/services/donation_service.dart), [contratos y mapeos backend](../../donapp/src/lib/services/donacion-service.ts), [ruta de creación/listado](../../donapp/src/pages/api/donaciones/index.ts), [validaciones](../../donapp/src/lib/validations/donaciones.ts).
- Solicitud: [modelos Dart](../lib/models/request.dart), [RequestService](../lib/services/request_service.dart), [SafeRequest y mapeos](../../donapp/src/lib/services/solicitud-service.ts), [selectores de participantes](../../donapp/database/solicitudes/index.ts), [validaciones](../../donapp/src/lib/validations/solicitudes.ts).
- Tipos persistidos y serialización: [Prisma](../../donapp/prisma/schema.prisma), [respuestas JSON](../../donapp/src/lib/api/responses.ts).

## Capturas recomendadas

1. Login completo.
2. Inicio autenticado.
3. Explorar con donaciones reales.
4. Detalle de una donación.
5. Formulario de publicación completo con categoría e imágenes.
6. Detalle de la donación recién creada.

## Inyecci�n del access token

ApiClient obtiene el access token mediante TokenStorage.readAccessToken (FlutterSecureStorage) antes de cada petici�n con contexto protectedSession y almacenamiento configurado. SessionCoordinator configura esta dependencia en protectedApiClient; no mantiene una copia global del token. Sin token disponible, la petici�n protegida falla localmente con authentication/401 antes de enviarse. withTokenStorage conserva transporte, timeout, URL y recuperaci�n, y permite sustituir el almacenamiento en pruebas.

Donaciones, solicitudes y firma de im�genes delegan la lectura y construcci�n del Bearer al cliente. Sus par�metros de TokenStorage se conservan para inyecci�n independiente. Login, registro, refresh, logout y categor�as usan contextos publicos y no reciben access token autom�ticamente. Perfil conserva un Bearer expl�cito para consultar la identidad del token recibido durante login/restauraci�n. Un Authorization expl�cito tiene prioridad, sin distinguir may�sculas, y no se duplica. Ante 401, el reintento existente reemplaza ese header con el token que devuelve el coordinador; las peticiones siguientes vuelven a leer el almacenamiento.

Cloudinary y RemoteImageCache mantienen transportes externos separados y no usan esta inyecci�n. La firma de im�genes pertenece a la API propia y s� la utiliza.
