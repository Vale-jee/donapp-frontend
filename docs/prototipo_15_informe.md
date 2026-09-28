# Prototipo 15 — informe de continuación

## A. Qué quedó pendiente al retomar la sesión

La selección y línea base ya estaban confirmadas: 683 tests, 63,60 % total y
86,90 % sin código .g.dart. Estaban escritos los tests de formulario/Explorar,
las aserciones de timeout, el caso de chat, el logger JSON, E2E, workflow,
inventario de riesgos y las instrucciones externas. Restaban verificar los dos
ajustes de tests, cierre completo, cobertura posterior, checklist y registro IA.
Se revisó el estado/diff sin reiniciar el análisis ni deshacer trabajo.

## B. Qué se terminó

- Timeout: fecha comparada como instante UTC, TIMEOUT, intento y backoff correctos,
  IDs conservados, una fila y ausencia de nuevo POST después de completar.
- Chat: conservar texto ante ApiException; esperar a que desaparezca el snackbar;
  reintentar, comprobar un mensaje confirmado y vaciar el editor solo tras éxito.
- Auditoría final de logs y señuelos de correo, nombre, documento y coordenadas.
- Comprobación de unitarias en orden aleatorio, sin backend ni emulador.
- Documentación reproducible de E2E, monitoreo y medición física.
- Checklist y registro de IA. No hubo optimización de rendimiento sin medición.

No se modificaron backend, esquema ni migraciones. Target Android fijado en 36.

## C. Estado de las cinco pruebas prioritarias

| # | Nombre exacto | Archivo | Nivel | Estado de implementación |
| --- | --- | --- | --- | --- |
| 1 | `401 protegido renueva y repite una sola vez con token nuevo` | `test/services/api_client_test.dart` | Unitaria con MockClient y SessionRecovery falso | Existente, sin reescribir |
| 2 | `formulario inválido no encola; al corregir guarda una sola donación pendiente` | `test/screens/create_donation_screen_test.dart` | Componente | Nueva, un testWidgets |
| 3 | `repository persiste antes de HTTP; timeout conserva IDs y outbox` | `test/services/offline_donations_test.dart` | Integración local | Existente, aserciones reforzadas solo para timeout |
| 4 | `Explorar distingue carga, vacío y error; conserva datos al fallar y se recupera` | `test/screens/explore_local_first_test.dart` | Componente | Nueva, un testWidgets |
| 5 | `E2E: iniciar sesión, guardar una donación y verla publicada en Mis donaciones` | `integration_test/publish_donation_e2e_test.dart` | E2E | Nueva, PENDIENTE DE EJECUCIÓN |

Las cuatro primeras están aprobadas en ejecuciones focalizadas y se incluyen en
la batería final. E2E solo tiene verificación estática del analizador; no se ha
compilado/ejecutado su recorrido en Android. Son exactamente cinco prioridades:
1 unitaria, 2 componentes, 1 integración y 1 E2E. Chat y logger son batería general.

La n.º 1 comprueba 401→recuperación única→Bearer nuevo→200 y datos correctos,
sin backend. No demuestra por sí sola refresh concurrente ni persistencia real
de tokens; session_coordinator_test ya cubre esas garantías.

La n.º 2 usa _PendingCreationRepository, _Picker y _UploadService, con un Completer
que mantiene pendiente el guardado durante la doble pulsación. Comprueba cero
encolados inválidos y exactamente uno válido, contenido/categoría/imagen y cero
subidas desde UI. La persistencia real pertenece a la n.º 3.

La n.º 3 usa base Drift en archivo, imagen temporal, repositorio/fuente remota/
servicio/ApiClient reales y MockClient para HTTP. Cierra y reabre la conexión;
comprueba IDs, reutilización de URL, backoff y reconciliación. Se selecciona solo
la instancia timeout, no los otros casos registrados por el bucle.

La n.º 4 utiliza _ScriptedExploreRepository y streams/Completers controlados: carga,
vacío, error sin contenido, reintento con tarjeta, fallo con tarjeta conservada y
aviso, recuperación sin aviso. No necesita Drift ni red. Home es navegación;
el listado relevante es ExploreDonationsScreen.

El inventario ordenado y razones de exclusión están en
[prototipo_15_riesgos.md](prototipo_15_riesgos.md). Cámara/GPS tienen alternativas;
la exclusión más defendible es regresión exclusivamente estética. 200, 422,
errores de servidor y otras garantías siguen en la batería general.

## D. Prueba adicional revelada por cobertura

Archivo: `test/screens/chat_screen_test.dart`.
Nombre: `fallo de envío conserva borrador y permite reintentar sin perder el mensaje`.
La línea base dejaba sin ejecutar el catch ApiException de _send en
`lib/screens/chat_detail_screen.dart`, líneas 114–118. Riesgo: perder el texto o
dejar bloqueado el envío. El fake falla una vez antes de almacenar el mensaje y
luego acepta. Se verifica contenido del editor, aviso, llamadas y lista confirmada.
El caso individual pasó, junto al caso timeout: 2/2. El archivo de producción del
chat no cambió. No se prueba aquí el caso distinto de envío exitoso y recarga fallida.

## E. Cobertura antes y después

La cobertura inicial está preservada en `coverage_p15_before.json` y, localmente,
`coverage/lcov.before.info`. El script `tool/coverage_summary.py` resume DA por
archivo, deduplica líneas y separa .g.dart sin modificar código. El total se refiere
a archivos instrumentados por el runner; no inventa 0 % para archivos ausentes.
LCOV de esta ejecución mide líneas; no se afirma cobertura exhaustiva de ramas.

| Medida | Antes | Después |
| --- | --- | --- |
| Total instrumentado, incluye .g.dart | 5783/9093 = 63,60 % | 5795/9100 = 63,68 % |
| Sin archivos .g.dart | 4313/4963 = 86,90 % | 4325/4970 = 87,02 % |
| ChatDetailScreen | 207/255 = 81,18 % | 212/255 = 83,14 % |

Se ejecutó UNA sola cobertura final: 687 tests aprobados, exit code 0.
El aumento específico del chat son las cinco líneas 114–118 del catch ApiException,
sin cambiar el archivo de producción. El denominador global también cambió por
el logger y la inyección opcional del selector; no atribuir todo el incremento al chat.
Las prioridades de formulario y Explorar refuerzan secuencias aunque no aumentan
las líneas cubiertas: su valor es detectar regresiones de comportamiento.
Snapshot posterior: coverage_p15_after.json; salida: coverage/p15-coverage-final.log.

Mapa restante de líneas ejecutables sin cubrir:

| Archivo | Cubiertas/total | Ejemplos pendientes |
| --- | --- | --- |
| screens/my_donations_screen.dart | 117/152 | 85–88, 136–165: errores/caminos de carga y paginación |
| screens/chat_detail_screen.dart | 212/255 | 75–86: fallos de carga; 121–123: excepción genérica de envío |
| screens/create_donation_screen.dart | 286/318 | 189–202: errores al preparar formulario; 393–395: fallo genérico al guardar |
| screens/explore_donations_screen.dart | 277/309 | 159–166: excepción genérica local-first; 340–343: error genérico de paginación |
| services/session_coordinator.dart | 102/109 | 120, 134, 189, 210, 214, 218, 222 |
| services/sync_coordinator.dart | 172/178 | 24–25, 57–59, 102 |
| services/location_share_service.dart | 11/33 | llamadas nativas y alternativas de permisos/localización |

Este mapa describe líneas, no demuestra que todas las ramas de los archivos con
alta cobertura estén comprobadas. No se añadieron casos para perseguir un umbral.

Se usa como mapa: MyDonations y errores del chat conservan zonas sin recorrer;
los métodos nativos de ubicación requieren otra clase de evidencia. Un mapper
con 100 % de líneas no garantiza todas sus combinaciones de entrada. El E2E no
forma parte de este porcentaje de escritorio.

## F. Pruebas desactivadas

Búsqueda en test/ e integration_test/ de skip:, @Skip, skipTest, @TestOn/testOn,
tags/exclusiones y declaraciones test/testWidgets/group comentadas: sin hallazgos.
No se eliminó ningún test. La E2E no usa skip: falla explícitamente sin configuración;
no ejecutarla aquí por falta de entorno no equivale a desactivarla.

## G. Logging estructurado y privacidad

Se conservó HttpRequestLogger como punto único. Ahora emite JSON de seis campos:
event, level, method, route, status_code y duration_ms. LogLevel define
debug/info/warning/error y un umbral mínimo: éxitos usan info, 4xx warning y
sin respuesta/5xx error. debug es el umbral más detallado, no un permiso para
registrar cuerpos. HTTP_LOGS=false desactiva; test/prod y kReleaseMode bloquean.

La API del logger no acepta headers, cuerpos ni excepciones. Conserva una lista
de rutas permitidas, elimina query/fragmentos y oculta IDs de rutas; rutas
desconocidas se omiten. Un fallo del sink no cambia el resultado HTTP.

Solo se encontró debugPrint en lib/services/http_request_logger.dart, como sink
central después del filtro. No hay print dispersos en lib/. Tests actualizados
comprueban claves JSON, niveles, redacción de tokens/cookies/Authorization,
contraseña y señuelos personales (correo/nombre/documento/coordenadas). La
política release se prueba con su parámetro inyectable y además kReleaseMode
impide reactivarla en un binario release. No se afirma haber capturado logcat release.

## H. Monitoreo

PENDIENTE DE CONFIGURACIÓN MANUAL. No existía un SDK y no se añadió uno con
credenciales inventadas. Se recomienda Sentry/sentry_flutter con capa gratuita;
se necesita decisión, proyecto y DSN de pruebas. Las instrucciones detallan
pubspec, main.dart, servicio de monitoreo, filtros beforeSend, eliminación de
request/Authorization/PII, ID interno opcional, release/dist y evento controlado.
Referencia oficial consultada: <https://sentry.io/pricing/> y
<https://pub.dev/packages/sentry_flutter>. La configuración propuesta se apoya
en las opciones del SDK oficial, no en una integración ejecutada.

Plan completo en [validación manual](prototipo_15_validacion_manual.md).
No se ha enviado ningún evento ni se dispone de captura de un panel remoto.

## I. Rendimiento

PENDIENTE DE MEDICIÓN FÍSICA. No se cambiaron listas ni imágenes por hipótesis.
Ejecutar, sustituyendo únicamente la URL:

```powershell
flutter run --profile -d RZCXC0568GK --dart-define=APP_ENV=test --dart-define=API_BASE_URL=https://BACKEND-DE-PRUEBAS
```

Abrir DevTools → Performance. Grabar Explorar (entrada, scroll con paginación,
refresh) y Mis donaciones (scroll, refresh y detalle), 30 s por recorrido, frío
y caliente, con datos y condiciones reproducibles. Guardar timeline, gráfico de
frames y detalle de un frame lento; registrar frecuencia de pantalla y duraciones
UI/Raster por separado. Presupuesto=1000/Hz ms. UI alta dirige la investigación
a Dart/build/layout; Raster alto a pintura/imágenes/GPU. No inferir la causa solo
de una barra roja. Entregar traces y capturas antes de corregir y volver a medir.
Procedimiento completo y plantilla: prototipo_15_validacion_manual.md.

## J. E2E

Preparada, NO ejecutada. integration_test configurado en pubspec y lockfile.
DonApp acepta opcionalmente el selector que el router ya permitía inyectar; el
valor normal no cambia. El caso usa login, REST, subida firmada y outbox reales.
Solo la selección de imagen se reemplaza por un PNG sintético preparado.

Faltan URL de backend desechable, cuenta activa/contraseña, categoría válida,
servicio de firma/subida de imágenes y ejecución en dispositivo. APP_ENV=test y
E2E_ALLOW_WRITES=true evitan una ejecución inadvertida con configuración normal.
No existe un control automático que certifique que una URL pertenece a pruebas:
el operador debe aportar el entorno correcto.

```powershell
Copy-Item -LiteralPath tool/e2e.example.json -Destination tool/e2e.local.json
# Completar el archivo local ignorado por Git, sin publicar credenciales.
flutter test integration_test/publish_donation_e2e_test.dart -d RZCXC0568GK --dart-define-from-file=tool/e2e.local.json
```

No compartir el APK de pruebas con defines de credenciales. La donación sintética
queda para inspección y requiere limpieza en el entorno desechable. El mensaje
guardada no basta: el test exige tarjeta Publicada, categoría, imagen y detalle.

## K. Checklist previa a publicación

Archivo: [prototipo_15_checklist.md](prototipo_15_checklist.md).
Incluye Funcional, Pruebas, Estados, Permisos, Seguridad, Rendimiento, Monitoreo y
Configuración/API 36. Solo evidencia automatizada/estática comprobada se marca
APROBADO. E2E, permisos Android reales y rendimiento quedan pendientes físicos;
DSN/servicio y firma de distribución quedan pendientes de configuración.

La limitación de errores diferidos se conserva: 400/422 se asocian a campos en
la ruta remota directa; la composición habitual encola y vuelve a Inicio.
Un rechazo posterior queda en failedPermanent sin UI de corrección/reactivación.
Logout elimina pendientes deliberadamente. No se presenta todo como offline.

## L. CI

Nuevo `.github/workflows/flutter.yml` para push, pull_request y workflow_dispatch.
Checkout, Flutter 3.47.0 stable (SDK local verificado, Dart 3.13.0), pub get,
analyze y test. Solo permiso contents:read; sin secretos ni publicación APK.
La E2E externa no se ejecuta dentro del job de escritorio.

YAML validado mediante package:yaml, ya disponible transitivamente, y comprobaciones
de triggers/comandos/versión/permisos. No se instaló PyYAML: no estaba disponible.
La ejecución en GitHub está pendiente; no hubo push para provocarla.

## M. Registro de IA

[prototipo_15_uso_ia.md](prototipo_15_uso_ia.md): ChatGPT/Codex, finalidad,
propuestas aceptadas y descartadas, cambios, aserciones reales y verificaciones.
No contiene conversaciones completas ni datos sensibles.

## N. flutter analyze

Ejecución final: sin incidencias, exit code 0. Incluye el archivo E2E en el
análisis estático. Salida local: coverage/p15-analyze-final.log.

## O. flutter test

`flutter test`: **687 aprobadas**, exit code 0 (1 min 10 s reportados por el runner).
`flutter test --coverage`: **687 aprobadas**, exit code 0 (1 min 48 s).
La E2E de integration_test/ no está incluida ni se presenta como aprobada.
El aumento desde 683 corresponde a formulario, Explorar, chat y política del logger.
Salidas locales: coverage/p15-tests-final.log y coverage/p15-coverage-final.log.

Adicionalmente: 77 tests de test/models, test/config, api_error_mapper_test y
conflict_resolver_test aprobados con seed 15 y APP_ENV=test, sin API_BASE_URL.
La línea base y ejecución normal complementan el orden aleatorio; no es una
demostración matemática de todos los órdenes posibles. Son funciones puras o
dobles sin internet/emulador. Los validadores del formulario permanecen dentro
del widget y se verifican como componentes, sin extraerlos artificialmente.

La batería HTTP existente comprueba 200 JSON válido, 401/recuperación, 422 con
errores de campo y timeout con MockClient. 422 es compatibilidad Flutter; el
backend real usa 400. La batería de cancelación tiene servidores loopback reales:
es integración local sin internet, no debe describirse como unitaria pura.

## P. git diff --check

`git diff --check`: exit code 0, sin errores de whitespace. Git advierte de su
conversión configurada LF→CRLF; no se cambió configuración global ni se confundió
esa advertencia con un fallo de prueba. Los archivos nuevos también se revisaron
para detectar whitespace final, dado que diff --check no incluye untracked.

## Q. git status --short

Estado final esperado y verificado, sin staging/commit/push:

```text
 M .gitignore
 M android/app/build.gradle.kts
 M lib/main.dart
 M lib/services/http_request_logger.dart
 M pubspec.lock
 M pubspec.yaml
 M test/screens/chat_screen_test.dart
 M test/screens/create_donation_screen_test.dart
 M test/screens/explore_local_first_test.dart
 M test/services/http_request_logger_test.dart
 M test/services/offline_donations_test.dart
?? .github/
?? docs/coverage_p15_after.json
?? docs/coverage_p15_before.json
?? docs/prototipo_15_checklist.md
?? docs/prototipo_15_informe.md
?? docs/prototipo_15_riesgos.md
?? docs/prototipo_15_uso_ia.md
?? docs/prototipo_15_validacion_manual.md
?? integration_test/
?? tool/
```

Archivos nuevos de esos directorios: .github/workflows/flutter.yml,
integration_test/publish_donation_e2e_test.dart, tool/coverage_summary.py y
tool/e2e.example.json. No se creó e2e.local.json ni se guardaron credenciales.
Los logs y LCOV permanecen en coverage/ ignorado por Git. El validador YAML
temporal se guardó en .dart_tool/ ignorado; no es una dependencia de producción.

## R. Pasos manuales exactos pendientes

1. Proporcionar backend desechable accesible, cuenta activa/contraseña de pruebas,
   categoría y firma/subida Cloudinary funcionales; completar e2e.local.json.
2. Preparar una instalación de pruebas sin sesión previa en el Samsung; ejecutar
   la E2E, guardar salida/capturas de publicación y detalle y limpiar la fixture
   remota/imagen mediante el procedimiento autorizado del entorno de pruebas.
3. Verificar físicamente permisos de cámara/ubicación, denegación permanente,
   regreso desde Ajustes y degradaciones; guardar evidencia sin datos personales.
4. Ejecutar los dos recorridos profile indicados; enviar traces, Hz, UI/Raster y
   capturas para elegir una corrección y repetir la medición antes/después.
5. Elegir servicio de monitoreo y facilitar DSN de proyecto de pruebas; después
   integrar/filtar/probar el evento controlado y verificarlo en el servicio externo.
6. Cuando se autorice publicar el workflow, comprobar su primera ejecución en
   GitHub Actions. No se solicita ni se realiza commit/push en esta sesión.
7. Antes de distribución real, configurar firma release propia y verificar el
   APK final/API 36, HTTPS y ausencia de logs sensibles en dispositivo. La firma
   debug preexistente se dejó intacta; no es aprobación de distribución.
