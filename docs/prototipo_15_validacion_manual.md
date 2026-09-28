# Prototipo 15: validación externa reproducible

Estado inicial: E2E, monitoreo remoto y rendimiento físico NO aprobados.
No se necesitan cambios del backend ni del esquema para preparar estos pasos.

## E2E de publicación

Preparada en `integration_test/publish_donation_e2e_test.dart`. Usa DonApp y sus
servicios reales. Solo se sustituye el selector del sistema por un PNG verde de
64×64 generado en memoria, sin información personal. No simula REST, subida,
SQLCipher, sesión ni sincronización. No prueba la interfaz nativa de la galería.

Requisitos:

1. Flutter 3.47.0 / Dart 3.13.0 y Samsung `RZCXC0568GK` autorizado por ADB.
2. Backend desechable accesible desde el teléfono, sin datos de producción.
3. Cuenta activa de prueba con ciudad/perfil válidos, permisos para donar y
   categoría activa llamada exactamente como `E2E_CATEGORY` (por defecto Muebles).
4. Firma y subida Cloudinary operativas en el entorno de pruebas. No basta
   levantar solamente los endpoints de autenticación.
5. Instalación de prueba sin sesión anterior. No usar una sesión con pendientes:
   cerrar sesión borra la outbox. El test falla si detecta access token existente
   y nunca borra automáticamente los datos para forzar su ejecución.

Desde la raíz de donapp-frontend, PowerShell:

```powershell
flutter devices
Copy-Item -LiteralPath tool/e2e.example.json -Destination tool/e2e.local.json
```

Editar localmente `tool/e2e.local.json`: API_BASE_URL, E2E_EMAIL, E2E_PASSWORD y
E2E_CATEGORY. APP_ENV debe ser test y E2E_ALLOW_WRITES true. El archivo está
ignorado por Git; no compartirlo, ni subir el APK de pruebas con defines de
credenciales. No copiar la contraseña en la línea de comandos o en capturas.

```powershell
flutter test integration_test/publish_donation_e2e_test.dart -d RZCXC0568GK --dart-define-from-file=tool/e2e.local.json
```

Si el backend de prueba corre en la PC y escucha en el puerto 3000, se puede usar
`adb -s RZCXC0568GK reverse tcp:3000 tcp:3000` y API_BASE_URL
`http://127.0.0.1:3000` para esta compilación debug de pruebas. Usar HTTPS en
producción; no cambiar la política de tráfico release para ejecutar este caso.

El caso exige login, formulario, retorno a Inicio, publicación remota visible en
Mis donaciones, estado Publicada, una imagen y detalle correcto. Espera estados
con plazos (55 s por carga y hasta 3 min para publicación), sin introducir fallos.
Si falta configuración falla explícitamente: no usa skip y no simula un éxito.

Guardar: salida final del runner, nombre sintético `P15 E2E ...`, captura de tarjeta
y detalle, fecha, versión y entorno sin URL privada/credenciales. El test deja
la donación remota para inspección. Después, retirar/eliminar la fixture mediante
el mecanismo administrativo autorizado del entorno de pruebas y limpiar su imagen
en Cloudinary; si no existe ese mecanismo, renovar el entorno desechable mediante
su procedimiento habitual. No se inventa un endpoint de eliminación. Cerrar la
sesión de prueba después de recoger evidencia. No borrar datos de producción.

## Monitoreo de fallos: decisión pendiente

La auditoría de lib/ y pubspec no encontró Sentry, Crashlytics ni otro SDK de
crash monitoring. HttpRequestLogger registra metadatos locales, no entrega
incidentes a un servidor. No se instaló un SDK ni se configuró un DSN ficticio.

Recomendación: **Sentry**, paquete `sentry_flutter`, con plan Developer gratuito.
La página oficial consultada el 21/09/2026 ofrece un usuario y 5k errores; revisar
los límites al crear la cuenta: <https://sentry.io/pricing/>. El SDK oficial es
<https://pub.dev/packages/sentry_flutter> y su código está en
<https://github.com/getsentry/sentry-dart>. No se requiere una suscripción pagada
para la comprobación inicial dentro de la cuota.

Necesito que el usuario elija Sentry y cree un proyecto Flutter, confirme región
y retención apropiadas, y facilite el **DSN del proyecto de pruebas**. El DSN no
es un token de administración. Un auth token privado solo sería necesario para
automatizar subida de símbolos; no debe introducirse en la aplicación.

Plan exacto tras esa decisión:

1. Añadir la versión compatible estable de sentry_flutter a pubspec.yaml y
   resolver pubspec.lock. Añadir `lib/services/error_monitoring.dart` y sus tests
   con transporte local falso; inicializar desde main.dart con SentryFlutter.init.
2. Leer SENTRY_DSN desde dart-define; si está vacío, iniciar DonApp sin SDK activo.
   Leer ambiente desde APP_ENV. Nunca insertar DSN/credenciales reales en Git.
3. Fijar sendDefaultPii=false, attachScreenshot=false y attachViewHierarchy=false.
   Mantener replay y tracing desactivados inicialmente; no instrumentar clientes
   HTTP/cuerpos ni activar captura de pantallas por defecto.
4. En beforeSend aplicar lista permitida: código de error interno no personal,
   frames del código, versión y ambiente. Eliminar request completo (headers,
   Authorization, cookies, query/body), breadcrumbs y extras no aprobados; eliminar
   mensajes de excepción que puedan contener respuestas, correo, nombre, documento,
   coordenadas, contenido de chat o rutas locales. sendDefaultPii=false por sí solo
   NO sanitiza texto arbitrario. Revisar también las rutas nativas de captura.
5. Si se necesita correlación, usar un ID interno opaco/pseudónimo en SentryUser.id,
   nunca correo/nombre; omitir identidad si no es necesaria y borrar el scope al
   cerrar sesión. Un ID interno sigue siendo dato seudonimizado, no anonimato.
6. Incluir release `donapp_mobile@1.0.0+1` (actualizar desde la versión efectiva de
   pubspec/build al publicar), dist=build number y environment=APP_ENV. Conservar
   símbolos privados del build para simbolicación, sin subir secretos.
7. Probar el filtro con valores señuelo de Authorization, email, password y GPS y
   afirmar que no están en el evento serializado enviado al transporte falso.
8. En build de prueba, desde una acción temporal protegida por bandera de desarrollo,
   ejecutar `await Sentry.captureException(StateError('P15_CONTROLLED_FAILURE'))`.
   Confirmar el evento remoto, versión, stack sanitizado y ausencia de datos
   personales. Guardar captura e ID del evento. Esto prueba error capturado;
   un crash nativo requiere otra comprobación explícita. Retirar/desactivar la
   acción temporal antes de publicar y verificar arranque sin DSN.

Este subpunto queda pendiente de elección/DSN, como exige la solicitud. La app
continúa funcionando sin depender de un servicio de monitoreo no autorizado.

## Rendimiento físico: Samsung RZCXC0568GK

No hay mediciones todavía ni optimizaciones aplicadas. Candidatos del código:
Explorar y Mis donaciones construyen tarjetas con imágenes; Explorar comprueba
archivos locales sincrónicamente al elegir imágenes. Son hipótesis de costo,
no diagnósticos de jank. Medir antes de cambiar a construcción perezosa, ajustar
decodificación o cachear consultas a disco.

Desde la raíz del frontend:

```powershell
flutter devices
flutter run --profile -d RZCXC0568GK --dart-define=APP_ENV=test --dart-define=API_BASE_URL=https://BACKEND-DE-PRUEBAS
```

Sustituir la URL por el backend accesible. No colocar credenciales de login en
defines de este build; iniciar sesión manualmente. Usar HTTPS para evitar que la
medición dependa de excepciones de tráfico claro en profile. Mantener target API 36.

1. Registrar modelo, versión Android, versión app/build, frecuencia de pantalla,
   temperatura aproximada, ahorro de energía y red. Usar un conjunto estable de
   al menos 40 donaciones con imágenes representativas, y suficientes propias.
2. Abrir la URL de **DevTools** mostrada por flutter run. Entrar en **Performance**,
   borrar la grabación anterior y comenzar la captura. Medir separado de debug.
3. Explorar: entrada fría, esperar carga, desplazar hasta cargar otra página,
   regresar arriba y hacer pull-to-refresh. Duración sugerida: 30 s. Guardar una
   captura fría y otra caliente, repitiendo el mismo recorrido y datos.
4. Mis donaciones: entrada, scroll hasta siguiente página, volver, refrescar y abrir
   un detalle con imagen. Capturar 30 s en las mismas condiciones.
5. Guardar exportación de timeline de DevTools, captura del gráfico Flutter frames,
   y seleccionar al menos un frame lento para capturar sus duraciones UI y Raster.
   Anotar cantidad/porcentaje de frames sobre presupuesto si la herramienta los
   presenta; si se calculan fuera, conservar numerador, denominador y fórmula.
   Registrar máximos y percentiles solo si realmente se obtienen del trace.
6. Presupuesto: 1000/frecuencia ms (16,67 ms a 60 Hz; 8,33 ms a 120 Hz). No asumir
   la frecuencia del Samsung. Comparar UI y Raster por separado con ese presupuesto;
   no sumar etapas paralelas como si fueran una única duración de frame.
7. UI alta: investigar trabajo Dart, build/layout, listas y acceso síncrono con
   CPU Profiler/Timeline. Raster alto: revisar pintura, imágenes, efectos y carga
   GPU. Identificar el evento/stack concreto; una barra roja no demuestra la causa.
8. Enviar ambos traces y capturas. Elegiremos un problema observado, haremos una
   corrección y repetiremos el mismo recorrido/build profile/datos/dispositivo.
   Documentar antes/después, no prometer mejora sin repetir la medición.

Referencia oficial para profile y lectura UI/Raster:
<https://docs.flutter.dev/perf/ui-performance>.

Plantilla de evidencia (rellenar después, no valores inventados):

| Pantalla/build | Fría/caliente | Hz/presupuesto | Frames lentos/total | UI ms | Raster ms | Evento/causa | Trace/captura |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Explorar | PENDIENTE | PENDIENTE | PENDIENTE | PENDIENTE | PENDIENTE | PENDIENTE | PENDIENTE |
| Mis donaciones | PENDIENTE | PENDIENTE | PENDIENTE | PENDIENTE | PENDIENTE | PENDIENTE | PENDIENTE |
