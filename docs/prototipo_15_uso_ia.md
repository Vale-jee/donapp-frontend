# Uso de IA — Prototipo 15

Herramienta: ChatGPT/Codex. Fecha de trabajo: 21 de septiembre de 2026.

Finalidad: inspeccionar el proyecto y su historial, priorizar riesgos, preparar
pruebas con aserciones, revisar privacidad de logs y documentar validaciones
reproducibles. No se incluyen conversaciones, cuentas, credenciales ni datos reales.

## Propuestas aceptadas

- Mantener exactamente cinco pruebas prioritarias: 401, validación/outbox del
  formulario, timeout duradero, estados de Explorar y E2E de publicación.
- Reutilizar la prueba existente del 401; reforzar solamente las aserciones que
  faltaban en timeout (TIMEOUT, backoff UTC, IDs y ausencia de reenvío posterior).
- Añadir una secuencia por componente con dobles controlados, sin backend.
- Usar la cobertura inicial para elegir el error de envío del chat: comprobar
  borrador conservado y reintento exitoso. No es una sexta prioridad del foro.
- Preparar E2E con app/REST/outbox reales y solo selector de imagen preparado.
- Mejorar el logger existente a JSON con niveles, campos permitidos y bloqueo
  release; evitar otro sistema de logging paralelo.
- Mantener API Android 36 explícita y preparar CI sin publicación ni secretos.

## Propuestas descartadas o diferidas

- No duplicar casos HTTP 200/401/422/timeout ya útiles.
- No llamar E2E a tests con MockClient, ni llamar publicación al guardado local.
- No reemplazar prioridades por cámara/GPS/regresión estética: existen alternativas.
- No reestructurar validadores ni repositorios solo para cambiar la pirámide.
- No instalar monitoreo sin decisión del usuario y DSN; documentar Sentry.
- No optimizar listas/imágenes sin medición física inicial.
- No implementar corrección de rechazos diferidos de la outbox en este alcance.

## Aserciones y revisión humana/técnica

Las pruebas afirman resultados observables: número de llamadas, encabezado nuevo,
datos devueltos, estado pending/retryWait/completed, IDs estables, archivo de imagen,
tarjetas/errores visibles, borrador preservado y publicación remota. No se considera
evidencia que un método simplemente se ejecute sin lanzar una excepción.

La ejecución focalizada detectó una comparación UTC/local en una aserción y un
snackbar que cubría el botón de reintento; se corrigieron los tests sin cambiar
la lógica de negocio para hacerlos pasar. El usuario decidió la selección final
y pidió continuar desde el estado actual sin repetir la investigación.

## Evidencia técnica

- Línea base: flutter test --coverage, 683 aprobadas, 5783/9093 líneas (63,60 %);
  sin .g.dart: 4313/4963 (86,90 %). Snapshot: coverage_p15_before.json.
- Flutter analyze inicial sin incidencias y pruebas focalizadas revisadas.
- YAML de CI parseado con package:yaml ya presente en el grafo de dependencias;
  comprobados triggers, comandos, versión y permisos de lectura.
- Cierre final: format de ocho archivos Dart; analyze sin incidencias; flutter
  test y una sola cobertura final con 687 aprobadas cada una. Cobertura posterior:
  5795/9100 (63,68 %); sin .g.dart 4325/4970 (87,02 %). Chat 207/255→212/255.
- Dos casos individuales timeout/chat aprobados y 77 pruebas puras/aisladas en
  orden aleatorio seed 15. git diff --check sin errores. Evidencia detallada y
  pendientes externos en prototipo_15_informe.md; E2E y monitoreo no ejecutados.
- No hubo commit ni push; no se alteraron backend ni esquema de base de datos.
