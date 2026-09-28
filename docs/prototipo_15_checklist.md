# Prototipo 15 — checklist previa a publicación

APROBADO se aplica únicamente a la evidencia indicada. Pasar tests de escritorio
no aprueba automáticamente la app en un dispositivo físico ni su distribución.

| Ámbito | Verificación | Estado | Evidencia / acción |
| --- | --- | --- | --- |
| Funcional | 401 recuperable usa token nuevo y reintenta una vez | APROBADO | api_client_test, transporte doble |
| Funcional | Entrada inválida no encola; corrección y doble pulsación | APROBADO | único testWidgets prioritario de formulario |
| Funcional | Timeout conserva creación, IDs, imagen y backoff; reinicio recupera | APROBADO | caso timeout con Drift en disco y HTTP doble |
| Funcional | Publicación completa contra servicios reales | PENDIENTE DE VERIFICACIÓN FÍSICA | ejecutar E2E con cuenta y backend de pruebas |
| Pruebas | Cinco prioritarias identificables; rama adicional separada | APROBADO | nombres exactos en informe; chat fuera de las cinco |
| Pruebas | Unitarias de modelos, mapper, configuración y conflictos aisladas | APROBADO | sin API configurada, ejecución aleatoria seed 15 |
| Pruebas | CI efectivamente ejecutada en GitHub | PENDIENTE DE CONFIGURACIÓN | publicar workflow solo cuando se autorice y revisar ejecución |
| Estados | Explorar carga/vacío/error/datos/aviso/recuperación | APROBADO | secuencia con repositorio y streams falsos |
| Estados | Validación remota directa por campo 400/422 | APROBADO | tests existentes; no equivale a corregir rechazo diferido de outbox |
| Estados | Chat conserva borrador al fallar envío y permite reintentar | APROBADO | prueba adicional guiada por cobertura |
| Permisos | Degradación cámara→galería, GPS→chat escrito con dobles | APROBADO | batería de permisos/pantallas |
| Permisos | Diálogos Android reales, denegación permanente y retorno desde Ajustes | PENDIENTE DE VERIFICACIÓN FÍSICA | comprobar cámara y ubicación en Samsung |
| Seguridad | Logs limitados a metadatos; señuelos personales no salen | APROBADO | logger y pruebas de privacidad |
| Seguridad | Logger bloqueado por kReleaseMode y ambientes test/prod | APROBADO | inspección + prueba de política release; no captura física release |
| Seguridad | Firma apta para distribución | PENDIENTE DE CONFIGURACIÓN | build.gradle.kts aún usa signingConfig debug para release; no se cambió |
| Seguridad | Verificar logs y permisos del APK release en teléfono | PENDIENTE DE VERIFICACIÓN FÍSICA | evidencia del build final, sin credenciales de E2E |
| Rendimiento | Baseline UI/Raster de Explorar y Mis donaciones | PENDIENTE DE VERIFICACIÓN FÍSICA | instrucciones en prototipo_15_validacion_manual.md |
| Rendimiento | Corrección medida y comparación posterior | PENDIENTE DE VERIFICACIÓN FÍSICA | requiere baseline; no hay optimización especulativa |
| Monitoreo | Servicio, proyecto y DSN de pruebas | PENDIENTE DE CONFIGURACIÓN | Sentry recomendado, no instalado sin decisión/DSN |
| Monitoreo | Filtro PII y evento controlado visibles en servicio | PENDIENTE DE CONFIGURACIÓN | implementar y verificar tras decisión; no hay evento enviado |
| Configuración/API 36 | targetSdk explícitamente 36 | APROBADO | android/app/build.gradle.kts; SDK Flutter local compileSdk=36 |
| Configuración/API 36 | HTTPS obligatorio en APP_ENV=prod | APROBADO | ApiConfig y tests |
| Configuración/API 36 | Backend e imágenes accesibles en teléfono/profile | PENDIENTE DE VERIFICACIÓN FÍSICA | URL de pruebas real, sin cambiar política release |

Riesgos residuales: no existe UI de corrección de errores de validación diferidos;
logout elimina pendientes por privacidad; chat no tiene outbox; un envío exitoso
seguido de recarga fallida sigue siendo un caso distinto al nuevo test de envío.
No se declara que la aplicación esté lista para publicación comercial con estos
pendientes, ni se modifica backend/base para ocultarlos.
