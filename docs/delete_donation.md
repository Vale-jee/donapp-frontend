# Eliminar una donación propia

Implementación online autorizada el 29 de septiembre de 2026. Esta autorización
reemplaza, para esta operación, la prohibición de DELETE de la especificación
histórica 006. No cambia Editar, Retirar, creación offline ni el esquema Prisma.

## Backend y relaciones

`DELETE /api/donaciones/{id}` reutiliza `requireAuth`, la validación de ID y el
contrato común. El servicio además limita el ID al rango de un entero PostgreSQL.
La identidad procede de la sesión, nunca del cuerpo de la petición.

En una sola transacción Prisma:

1. Bloquear la fila Donacion con `SELECT ... FOR UPDATE` parametrizado.
2. Comprobar existencia, propietario y estado PUBLICADA.
3. Buscar solicitudes sin filtrar por estado. Cualquiera impide el borrado.
4. Rechazar `solicitudAceptadaId`, Calificacion, ExencionCalificacion o auditoría
   administrativa de la entidad DONACION.
5. Ejecutar `imagenDonacion.deleteMany({where: {donacionId: id}})`.
6. Ejecutar `donacion.delete({where: {id}, select: {id: true}})`.

Si falla el último paso, Prisma revierte también el borrado de imágenes. El
bloqueo serializa cambios de estado e inserciones que referencien esa donación
por FK. Los errores de integridad y concurrencia se traducen a 409 seguro.

Relaciones reales: Donacion referencia Usuario, Categoria y opcionalmente una
Solicitud aceptada. ImagenDonacion, Solicitud, Calificacion y
ExencionCalificacion referencian Donacion con `onDelete: Restrict`. Chat depende
de Solicitud y Mensaje de Chat; no existe una relación directa con Donacion.
AuditoriaAdministrativa utiliza entidad/entidadId sin FK, y se conserva también.

ImagenDonacion se elimina porque contiene metadatos propios de la publicación
(referencia y orden), con autorización expresa. No se elimina ningún Usuario,
Categoria, Solicitud, Chat, Mensaje, Calificacion, Exencion ni auditoría. No se
agregan cascadas ni migraciones. No se borran archivos de Cloudinary: las URLs
pueden quedar como recursos remotos huérfanos.

Calificaciones y exenciones requieren ENTREGADA y una solicitud aceptada en los
servicios normales. Sin embargo, las FK/constraints actuales no expresan esa
condición entre tablas. Una PUBLICADA inconsistente con esas relaciones es
posible en BD y se rechaza explícitamente.

| Situación | HTTP |
|---|---|
| Éxito, `data: {id}` | 200 |
| ID inválido | 400 |
| Sin autenticación/sesión inválida | 401 |
| Cuenta inactiva | 403 |
| Inexistente o usuario ajeno | 404 |
| Estado distinto de PUBLICADA | 409 |
| Solicitudes, historial o conflicto concurrente | 409 |
| Método no permitido | 405 con Allow |
| Error interno | 500 sanitizado |

Se conserva la política de mutaciones existente: una donación ajena recibe el
mismo 404 que una inexistente para no revelar recursos de otro usuario.

## Frontend y los seis cambios parciales

Se conservaron DELETE en ApiClient, la delegación de DonationRemoteDataSource,
la validación de respuesta en DonationService y la clasificación DELETE del
logger. El logger sigue registrando solo metadatos y anonimiza IDs, sin tokens,
cuerpos, query strings ni mensajes privados.

Se completó DonationRepository con la invalidación confirmada y el filtrado de
lecturas propias que lleguen tarde. Se retiró la refactorización innecesaria de
propiedad del intento parcial y se conservó `canEditDonation` con su consulta
paginada de PUBLICADA. No se sustituyó el servicio configurado en el router.

Se corrigió DonationLocalDataSource: el intento parcial marcaba
`locallyDeleted=true`, pero no eliminaba la fila y `storeExplorePage` podía
restablecerla. Ahora se borra físicamente por `cacheUserId + remoteId` después
del éxito remoto. Las FK locales existentes limpian imágenes y membresías de
caché. Se conserva el resto de filas y no se toca ni crea outbox. Un conjunto
compartido por instancia de AppDatabase impide que lecturas antiguas vuelvan a
insertar una eliminación confirmada. Al reiniciar no quedan lecturas en vuelo y
la fila continúa ausente en SQLite.

`DonationDetail.id` y `DonationListItem.id` vienen de la API y son `remoteId`.
Nunca se usa la PK `localId` ni el UUID `clientId` en la ruta REST. Las pruebas
del router comprueban GET/PATCH/DELETE con 731, distinto del ID local, utilizando
el servicio configurado; el repositorio offline solo recibe la confirmación.

Eliminar se muestra junto a Editar únicamente cuando la lista propia acredita
propiedad y el detalle está PUBLICADA. El diálogo permite cancelar sin DELETE.
Desde que se abre se bloquea un segundo envío; tras confirmar se bloquea el
regreso hasta terminar. El éxito retira inmediatamente la tarjeta de Mis
donaciones y muestra «Donación eliminada correctamente.».

Los errores conservan el detalle y la caché, permiten reintentar y pasan por
ApiErrorMapper. Un 409 por solicitudes muestra el mensaje de negocio exacto.
No hay reintentos automáticos por fallo de red; se conserva la recuperación de
sesión existente ante 401. Si se pierde la respuesta después de que el servidor
confirma DELETE, no se puede garantizar que la donación siga en PostgreSQL: el
cliente conserva su caché y un reintento podría devolver 404.

## Validación automatizada final

Resultados sobre los cambios finales, sin commit ni push:

| Comando | Resultado |
|---|---|
| Backend: `npx.cmd vitest run tests/unit/donation-delete.test.ts --reporter=dot` | 26/26 aprobadas |
| Backend: DELETE, list/detail y permisos focalizados | 30/30 aprobadas |
| Backend: `npm.cmd test -- --reporter=dot` | 61/61 aprobadas, 10 archivos |
| Backend: smoke HTTP de resolución de rutas, servidor local en 3000 | 2/2 aprobadas |
| Backend: `npm.cmd run lint` | Salida 0 |
| Backend: `npm.cmd run build` | Salida 0, compilación de producción correcta |
| Backend: `npx.cmd tsc --noEmit` | Salida 1: único TS2322 preexistente en `tests/integration/bullmq-robustness.test.ts:58:35` |
| Frontend: `flutter analyze` | Salida 0, No issues found |
| Frontend: `flutter test` | Salida 0, 742/742 aprobadas |
| Frontend: corrida focalizada de eliminación, edición, router, logger y offline/outbox | Salida 0, 139/139 aprobadas |

La corrida focalizada utiliza:

```powershell
flutter test test/screens/delete_donation_screen_test.dart test/repositories/delete_donation_repository_test.dart test/screens/edit_donation_screen_test.dart test/repositories/edit_donation_repository_test.dart test/navigation/app_router_test.dart test/services/http_request_logger_test.dart test/services/offline_donations_test.dart test/data/local/pending_operation_local_data_source_test.dart test/data/local/pending_operations_dao_test.dart
```

La prueba BullMQ tiene el mismo contenido que HEAD (`git diff --exit-code HEAD
-- tests/integration/bullmq-robustness.test.ts`, salida 0). Su callback que solo
lanza error infiere `Worker<any, never, string>`, incompatible con el tipo del
arreglo en que se guarda. No fue modificada para forzar un typecheck verde.

Los archivos `edit_donation_screen.dart`, `create_donation_screen.dart`,
`offline_donations.dart` y `local_tables.dart` no presentan diferencias respecto
al commit `dea0a06`. Las pruebas de creación y outbox están incluidas en las 742.

Integración HTTP intentada con:

```powershell
node --env-file=.env.test node_modules/vitest/vitest.mjs run tests/integration/api-flows.test.ts --reporter=dot
```

Resultado: 1 suite falló en preparación, 6 pruebas omitidas. PostgreSQL no
responde en `127.0.0.1:55432`; tampoco están accesibles el Redis configurado en
`127.0.0.1:16379` ni la API en `127.0.0.1:3100`. La comprobación se repitió fuera
del sandbox sin cambiar la configuración. No se verificó contra PostgreSQL
real el borrado ni el rollback mediante esta suite automatizada; están implementados mediante la transacción y
preparados los casos de integración. Para repetirlos, levantar los servicios de
pruebas existentes con `.env.test` según `donapp/docs/testing.md`, sin apuntar la
suite a la base habitual.

## Prueba física en Samsung

El usuario confirmó físicamente en Samsung: eliminación de una PUBLICADA propia
sin solicitudes y desaparición de la app; ausencia de Eliminar en RESERVADA;
rechazo de PUBLICADAS con solicitudes; y apertura del detalle después de
reiniciar Next.js. Esta evidencia fue aportada por el usuario, no ejecutada por
el agente. No equivale a verificar todos los casos históricos ni un rollback
forzado en PostgreSQL.

Para repetir la prueba se requiere el backend actualizado, PostgreSQL/Redis
habituales disponibles, una cuenta autenticada y publicaciones de prueba.

1. Conectar el Samsung por USB, habilitar depuración USB y aceptar el equipo.
2. En PowerShell, desde `Proyecto/donapp`, iniciar el backend:

   ```powershell
   npm.cmd run dev -- --port 3000
   ```

3. En otra terminal, desde `Proyecto/donapp-frontend`, comprobar el dispositivo
   y ejecutar (el número documentado del Samsung es `RZCXC0568GK`; si `devices`
   muestra otro, usar ese número en los comandos):

   ```powershell
   $donappAdb = 'C:\Users\parap\AppData\Local\Android\sdk\platform-tools\adb.exe'
   & $donappAdb devices
   & $donappAdb -s RZCXC0568GK reverse tcp:3000 tcp:3000
   flutter run -d RZCXC0568GK --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://localhost:3000
   ```

4. Publicar una donación propia de prueba con una imagen y esperar la
   sincronización. Abrir Mis donaciones → detalle: deben verse Editar y Eliminar.
5. Pulsar Eliminar → Cancelar: permanecer en detalle, sin petición DELETE.
6. Pulsar Eliminar y confirmar dos veces rápidamente: un solo envío, acciones
   deshabilitadas mientras procesa, regreso a Mis donaciones, tarjeta ausente y
   mensaje de éxito. Cerrar y abrir la app: la tarjeta no debe reaparecer.
7. Desde Postman, GET del ID eliminado con la misma cuenta debe devolver 404.
   Comprobar en PostgreSQL que Donacion e ImagenDonacion de ese ID ya no existen.
   Los archivos de Cloudinary pueden seguir presentes.
8. Con otra cuenta solicitar otra publicación de prueba. Su propietario debe
   recibir «Esta donación no se puede eliminar porque ya tiene solicitudes
   asociadas.» y conservar la publicación. Rechazar la solicitud o cancelarla
   desde la cuenta solicitante y volver a probar: debe seguir bloqueada.
9. Abrir una publicación propia RESERVADA, ENTREGADA o RETIRADA existente: no
   debe mostrarse Eliminar. Abrir una ajena desde Explorar: tampoco.
10. Para fallo de red, abrir primero el detalle elegible con conexión y retirar
    el túnel USB antes de confirmar:

    ```powershell
    & $donappAdb -s RZCXC0568GK reverse --remove tcp:3000
    ```

    Confirmar, esperar el error y comprobar que conserva el detalle y permite
    reintento. El modo avión por sí solo no corta el túnel USB. Restaurarlo:

    ```powershell
    & $donappAdb -s RZCXC0568GK reverse tcp:3000 tcp:3000
    ```

    Reintentar y comprobar el éxito.
11. En otra donación PUBLICADA, Editar título/descripción/categoría, guardar y
    verificar PATCH, detalle, lista y persistencia al reabrir.
12. Sin conexión real, crear una publicación: debe conservar la cola offline
    existente. Reconectar y verificar su sincronización normal.

No crear calificaciones/exenciones inconsistentes en la base habitual para
probarlas manualmente: los casos negativos están preparados en la suite de
integración aislada.
