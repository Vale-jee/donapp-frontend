# Prototipo 15: decisión de riesgos antes de implementar

Revisión del 21 de septiembre de 2026. Se mantiene la selección preliminar.
Probabilidad e impacto son estimaciones cualitativas; no métricas de producción.
Se ponderan consecuencia, exposición, historial y esfuerzo marginal de prueba.

| Prioridad | Qué puede romperse / consecuencia | Probabilidad | Impacto | Esfuerzo | Evidencia existente |
| --- | --- | --- | --- | --- | --- |
| 1 | Creación pendiente perdida o reenviada incorrectamente después de timeout/reinicio | Alta | Muy alto | Medio | offline_donations_test; sync_coordinator_test: disco, IDs, backoff, reconciliación |
| 2 | Expiración de access token interrumpe todos los flujos protegidos | Alta | Muy alto | Bajo | api_client_test; session_coordinator_test; fix ae27d02 de renovación concurrente |
| 3 | Datos inválidos en outbox o doble pulsación crea dos donaciones | Media-alta | Alto | Bajo | create_donation_screen_test; validadores en widget y prueba de composición con outbox |
| 4 | Fallo de composición entre login, router, imágenes, persistencia y publicación | Media | Muy alto | Alto | Pruebas parciales; no había integration_test ni E2E completa |
| 5 | Listado confunde fallo con vacío o pierde tarjetas guardadas | Alta | Alto | Medio | explore_local_first_test; fixes 42aaa26 y 47bd421 |
| 6 | Fuga de datos entre cuentas o limpieza local incorrecta | Media | Muy alto | Medio | aislamiento cacheUserId, local_session_cleanup, migraciones SQLCipher |
| 7 | Fallo parcial de imágenes publica referencias incompletas | Media | Alto | Medio | image_upload_service_test; sync_coordinator_test |
| 8 | 400/422/401/5xx mal clasificado o detalle privado en error | Media | Alto | Bajo | api_error_mapper_test; api_client_test; fixes 39a5f53 y 4c5a2df |
| 9 | Chat enviado pero recarga falla: resultado ambiguo o duplicación al reintentar | Media | Alto | Medio | chat_screen_test cubre envío/doble pulsación; ChatRepository es remoto, sin outbox |
| 10 | Datos obsoletos, paginación incorrecta o actualización tras dispose | Media | Medio | Bajo-medio | TTL, repositorios, read_cancellation y read_dispose |
| 11 | Cámara o GPS no disponibles | Media | Menor por degradación | Medio | pruebas de permisos, galería y chat manual; fix cámara 0577b6a |
| 12 | Diferencias exclusivamente visuales | Media | Bajo | Variable | pruebas de overflow; sin goldens |

## Exactamente cinco prioritarias

1. `401 protegido renueva y repite una sola vez con token nuevo` — unitaria con dobles.
2. `formulario inválido no encola; al corregir guarda una sola donación pendiente` — componente.
3. `repository persiste antes de HTTP; timeout conserva IDs y outbox` — integración local con HTTP doble; solo instancia timeout.
4. `Explorar distingue carga, vacío y error; conserva datos al fallar y se recupera` — componente con streams falsos.
5. `E2E: iniciar sesión, guardar una donación y verla publicada en Mis donaciones` — E2E real pendiente de entorno externo.

Pirámide de esta selección: 1 unitaria, 2 componentes, 1 integración, 1 E2E.
Son cinco casos, no cinco suites. La prueba adicional guiada por cobertura no
pertenece a esta selección. Varias fases de una misma secuencia son defendibles
como un caso; un bucle que registra cuatro casos no cuenta como uno.

## Exclusiones explícitas

- Cámara y geolocalización: tienen galería y escritura manual; menor consecuencia.
- Regresión puramente visual: exclusión más defendible; no evita pérdida de datos.
- 200: desenlace del caso 401 y cobertura general; no ocupa lugar separado.
- 422: cobertura general de compatibilidad. Backend DonApp usa 400 para Zod.
- Timeout: incluido mediante recuperación duradera, no solo mensaje.
- Estados: incluidos en Explorar; Home es principalmente navegación/perfil.
- Validación y E2E: incluidos. La E2E debe comprobar PUBLICADA y detalle remoto.
- Concurrencia de refresh, aislamiento, migraciones, chat y subida parcial:
  se mantienen en la batería general, sin ampliar los cinco del foro.

## Riesgos residuales y límites

La composición normal encola y vuelve a Inicio. Los errores por campo funcionan
en la ruta remota directa del formulario; un rechazo diferido de sincronización
no vuelve al formulario. SyncCoordinator conserva failedPermanent y no existe
una UI para corregir/reactivar esa operación. No se implementa esa función aquí.

Reinicio normal conserva outbox; logout la elimina por política de privacidad.
La restauración de sesión puede necesitar red. Mis donaciones y chat siguen
remotos. Conservar clientId no prueba por sí solo deduplicación del servidor.

No se modifican backend, esquema ni migraciones. No se optimiza rendimiento sin
medición inicial y no se declara éxito de E2E/monitoreo/perfilado sin evidencia.
