# DonApp — cliente Flutter

DonApp conecta a personas que donan artículos con personas interesadas en recibirlos en la misma ciudad. Este repositorio contiene la aplicación móvil; requiere la API REST del repositorio separado `donapp`, configurada con PostgreSQL, Redis y Cloudinary.

## Tecnologías y estructura

Flutter/Dart, Material 3, GoRouter, `package:http`, Drift con SQLCipher, `flutter_secure_storage`, `image_picker`, `permission_handler`, `geolocator` y `url_launcher`. Versiones declaradas/resueltas: `pubspec.yaml` y `pubspec.lock`.

```text
lib/
  config/          URL, ambientes y timeouts
  models/          Modelos y serialización JSON
  navigation/      Router y protección de rutas
  screens/         Pantallas
  repositories/    Coordinación de fuentes de datos
  data/local/      Drift, DAO, caché y outbox
  data/remote/     Delegación a servicios HTTP
  services/        HTTP, sesión, permisos, imágenes y sincronización
  theme/           Tema y tokens visuales
  widgets/         Componentes reutilizables
test/              Pruebas automatizadas de escritorio
integration_test/  E2E de publicación con servicios reales
docs/              Documentación técnica e informes históricos
```

## Funciones disponibles

- Bienvenida, registro, inicio y cierre de sesión, restauración de sesión y renovación de tokens.
- Perfil editable e Inicio con los datos del usuario.
- Explorar donaciones paginadas de la misma ciudad, filtro por categoría y detalle.
- Publicar con una a cinco imágenes desde cámara o galería.
- Mis donaciones; editar título, descripción y categoría de una publicación propia `PUBLICADA`. El formulario Editar conserva las imágenes.
- Eliminar online una publicación propia `PUBLICADA` sin solicitudes ni historial restrictivo.
- Crear solicitudes, consultar enviadas/recibidas y detalle; aceptar, rechazar y cancelar.
- Lista de chats, conversación HTTP, envío de mensajes y ubicación compartida como mensaje con apertura de un mapa externo.

El backend toma la ciudad de la donación del perfil al crearla; no usa GPS y esa ciudad no cambia al editar posteriormente el perfil. Explorar filtra por ciudad, no por distancia.

### CRUD de donaciones

| Operación móvil | API | Restricción principal |
| --- | --- | --- |
| Crear | `POST /api/donaciones` después de sincronizar imágenes | Sesión válida, categoría activa y referencias de imágenes válidas |
| Leer | `GET /api/donaciones`, `/mias`, `/{id}` | Explorar usa caché; Mis donaciones y detalle son remotos |
| Editar | `PATCH /api/donaciones/{id}` | Propietario y `PUBLICADA`; Flutter envía los campos modificados de texto/categoría |
| Eliminar | `DELETE /api/donaciones/{id}` | Propietario, `PUBLICADA`, sin solicitudes de ningún estado ni historial restrictivo |

DELETE bloquea la fila y comprueba solicitudes, solicitud aceptada, calificación, exención y auditoría `DONACION`. En una transacción elimina primero `ImagenDonacion` y después `Donacion`; un fallo revierte ambos pasos. No elimina solicitudes, chats, mensajes, calificaciones, exenciones ni auditorías. Tampoco borra archivos físicos de Cloudinary. La retirada lógica del backend es distinta. Consulte [Editar](docs/edit_donation.md) y [Eliminar](docs/delete_donation.md).

## Offline y sincronización

| Flujo | Alcance sin conexión |
| --- | --- |
| Explorar | Lee primero donaciones, categorías e imágenes ya descargadas; informa frescura y última sincronización |
| Crear | Guarda donación, copias de imágenes y operación en Drift antes de enviar; requiere sesión ya abierta y categorías guardadas |
| Restaurar sesión al iniciar | Consulta perfil remoto; no hay restauración offline integrada desde el perfil Drift |
| Mis donaciones, detalle, edición, eliminación | Necesitan backend; no tienen cola de mutaciones offline |
| Registro/login, perfil, solicitudes y chat | Necesitan conexión; chat no tiene outbox |

SQLite se cifra con SQLCipher; tokens y clave se guardan en almacenamiento seguro. Las imágenes están en archivos privados separados y no están cifradas por SQLCipher.

`OfflineDonations` compone un `SyncCoordinator` por sesión. Se activa al encolar, establecer sesión y volver a primer plano; programa reintentos en primer plano. No es un servicio Android de sincronización en segundo plano ni tiene un detector de conectividad integrado.

La outbox admite solo creación. Sube imágenes, conserva URLs confirmadas y publica con el mismo UUID `clientId`; el backend deduplica por `(propietarioId, clientId)`. `operationId` identifica el trabajo local. Hay hasta cinco intentos: tras fallos recuperables espera 5, 15, 30 y 60 s; la función contempla 120 s, pero el quinto fallo ya pasa a permanente. Recupera trabajos `processing` abandonados después de cinco minutos y pausa por autenticación.

No existe UI para corregir/reactivar errores permanentes. Logout intenta eliminar caché, base, clave, tokens, imágenes administradas y creaciones pendientes; continúa aunque alguna limpieza o la revocación remota falle. TTL significa frescura; no hay limpieza automática por antigüedad. Consulte [Persistencia local](docs/local_persistence.md).

## Requisitos e instalación

Flutter compatible con Dart `^3.13.0`, Android SDK, Java 17 y dispositivo/emulador. Para iOS se necesita macOS/Xcode; las pruebas de escritorio no verifican plugins ni diálogos nativos. Configure primero el backend siguiendo su README.

Desde este repositorio:

```powershell
flutter pub get
flutter run --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://localhost:3000
```

`API_BASE_URL` es obligatoria al construir peticiones y no debe terminar en `/api`. `APP_ENV` admite `dev`, `test` y `prod`; por defecto es `dev`. Elegir `test` no simula HTTP: las pruebas deben inyectar dobles.

### Android por USB

Con depuración USB autorizada y backend en el puerto 3000:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:3000 tcp:3000
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

Con varios dispositivos, seleccione uno con `adb -s <ID_DISPOSITIVO>` y `flutter run -d <ID_DISPOSITIVO>`. Para desconexión real retire el túnel con `adb reverse --remove tcp:3000`: modo avión puede dejar funcionando el acceso USB.

### Inicio conjunto desde VS Code

La tarea está en `Proyecto/.vscode/tasks.json`, fuera de ambos repositorios. Si descarga solamente este repositorio desde GitHub, use comandos manuales o prepare esa estructura conjunta.

1. Abra Docker Desktop y espere a Docker Engine.
2. Tenga PostgreSQL disponible y el contenedor Redis existente `donapp-security-test-redis` preparado; la tarea no crea contenedores.
3. Conecte/autorice Android; instale dependencias y configure ambos repositorios previamente.
4. Abra la carpeta raíz **Proyecto** en VS Code.
5. Ejecute **Terminal → Run Task... → DonApp: Iniciar entorno**.

Coordina **Redis → ADB reverse → backend → Flutter**. Inicia Redis si está detenido, ejecuta `yarn.cmd dev` en `donapp` y espera `Ready in` antes de `flutter run` en `donapp-frontend`, con `API_BASE_URL=http://localhost:3000`. No inicia Docker Desktop/PostgreSQL, no aplica migraciones ni inicia el worker BullMQ.

## Android, cámara y ubicación

| Configuración actual | Valor/fuente |
| --- | --- |
| Nombre visible | DonApp, manifest principal |
| Versión/build | `1.0.0+1`, pubspec; sobrescribibles al compilar |
| namespace/applicationId | `com.example.donapp_mobile`, Gradle |
| compileSdk | `flutter.compileSdkVersion`; SDK local: 36 |
| targetSdk | 36, explícito en Gradle |
| minSdk | `flutter.minSdkVersion`; SDK local: 24 |
| Permisos principales | INTERNET, CAMERA, ACCESS_COARSE_LOCATION, ACCESS_FINE_LOCATION |

Valores heredados verificados en el SDK local `<FLUTTER_SDK>/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt`; pueden cambiar con el SDK. No hay ubicación en segundo plano ni almacenamiento amplio en el manifest principal. Auto Backup está deshabilitado.

La cámara se usa al publicar, con explicación/permiso; cancelar vuelve al formulario y la galería es alternativa. La galería usa el selector del sistema con `requestFullMetadata: false`. La ubicación se solicita en el chat con confirmación, precisión alta y redondeo a tres decimales, sin seguimiento continuo. Ante denegación puede escribirse el punto de encuentro; se ofrecen ajustes cuando corresponde. iOS declara explicaciones de cámara, selección de fotos y ubicación al usar la app en `Info.plist`.

## Red, pruebas y compilación

Plazos totales HTTP: API 15 s por intento, subida 120 s por imagen y descarga de caché 30 s por imagen. GET reintenta red, timeout y HTTP 500/502/503/504 hasta tres intentos con esperas de 500 ms y 1 s; 429 solo si Retry-After indica un entero entre 0 y 5 segundos, respetando la espera mayor. No reintenta mutaciones por esos fallos; la recuperación protegida ante 401 puede renovar y repetir una vez. `ReadCancellation` aborta lecturas donde está integrado y evita resultados después de abandonar pantallas; no se generaliza a todo el chat ni mutaciones.

Mis donaciones y mensajes usan `ListView.builder`. `DonationCard` aplica `ResizeImage` solo al activar `limitContainedImageDecode` con `BoxFit.contain`, como en Mis donaciones; Explorar no usa `ListView.builder`. La caché remota de imágenes respalda Explorar. No se promete mejora global de rendimiento sin medición.

```powershell
flutter analyze
flutter test
flutter test --dart-define=APP_ENV=test --dart-define=API_BASE_URL=https://donapp.test
flutter build apk --release --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://api.example.com
```

Los dominios son ejemplos; sustituya el de producción. Con dependencias resueltas puede agregar `--no-pub` a analyze/test. La [E2E de publicación](docs/prototipo_15_validacion_manual.md) requiere servicios reales y escribe una donación; no se ejecuta con la suite de escritorio.

En `prod`, Dart exige HTTPS para API/imágenes. `--release` no elige `APP_ENV`. Android release/profile bloquea cleartext; debug permite únicamente `localhost`. iOS no tiene excepciones ATS. Los `dart-define` quedan en el artefacto: no guarde secretos allí. El logger filtra metadatos y queda deshabilitado en release/test/prod.

Release actualmente firma con claves debug y mantiene un applicationId de ejemplo: compilar APK no equivale a preparar distribución comercial. No suba `.env`, credenciales, keystores, tokens ni archivos locales E2E.

## Limitaciones y documentación

Chat HTTP se recarga al abrir/refrescar/enviar; no usa WebSocket ni actualización automática en tiempo real. La UI carga hasta 100 mensajes recientes y no navega las páginas anteriores de la API. No hay push reales, mapa de donaciones ni búsqueda por distancia. Cambiar contraseña muestra «próximamente»; no hay recuperación de contraseña ni panel administrativo móvil. Entrega bilateral, calificaciones, exenciones y administración existen en backend, pero no son flujos Flutter terminados. No hay SDK de monitoreo remoto integrado.

Consulte [Flujo funcional](docs/functional_flow.md), [Componentes](docs/component_catalog.md). Los informes `prototipo_15_*` son evidencia histórica; sus conteos/cobertura no certifican esta versión.
