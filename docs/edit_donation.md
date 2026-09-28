# Editar una donación propia

## Contrato y alcance

La creación ya utiliza repositorio, Drift y outbox. El detalle y Mis donaciones
usan lecturas remotas; `PendingOperationType` solo admite `createDonation`.
Por ello, editar es una operación **online**, sin escritura optimista ni nueva
cola offline. No cambia la publicación, la autenticación ni la sincronización.

El contrato existente de `PATCH /api/donaciones/{id}` acepta campos parciales y
devuelve `data.donacion` con HTTP 200. El servicio conserva ApiClient, token,
logger y ApiException. Solo se envían los campos efectivamente modificados:
`titulo`, `descripcion`, `categoriaId`. No se reintenta automáticamente el PATCH.

La propiedad se comprueba consultando todas las páginas necesarias de
`GET /api/donaciones/mias?estado=PUBLICADA`. El detalle no contiene propietario;
`puedeSolicitar=false` no demuestra propiedad. El botón requiere un detalle
PUBLICADA y confirmación en la lista propia. El formulario vuelve a verificar
esa condición al abrir. El backend decide nuevamente al guardar, incluso si
cambió el estado mientras el formulario estaba abierto.

## Interfaz y persistencia

Desde Mis donaciones se abre el detalle y se pulsa Editar. El formulario muestra
los datos actuales y utiliza los validadores extraídos de creación, AppTextField,
AppPrimaryButton y el tema existente. Una categoría actual que ya no esté en el
catálogo se conserva; no se envía de nuevo si no cambió.

Sin diferencias normalizadas se muestra «No hay cambios para guardar.». Durante
el guardado se bloquean el botón, los campos y el regreso. Ante errores se
conservan los campos y se presenta la política de mensajes existente, incluidos
errores por campo. Tras guardar se vuelve al detalle con la respuesta del PATCH
y «Donación actualizada correctamente.».

El repositorio comparte la respuesta confirmada con Mis donaciones al regresar,
sin necesitar otra lectura para reflejar el cambio. Si existe una fila Drift
del usuario actual, actualiza texto, categoría, estado y versión del servidor
dentro de una transacción. Conserva identidad local, membresías, fotos y outbox.
ConflictResolver protege registros pendientes y versiones más recientes.
Un PATCH fallido no escribe en Drift. Al reabrir el detalle se consulta el
servidor como antes; no se añade soporte de detalle offline.

La lista propia, el detalle y la edición comparten un repositorio construido
con `DonationRepository.fromService(effectiveDonationService)`. El repositorio
offline no sustituye ese servicio para lecturas ni PATCH: recibe únicamente la
respuesta confirmada mediante `cacheConfirmedUpdate`, después de comprobar que
continúa activa la misma cuenta. Explorar y crear conservan su composición
local-first original.

### Identificadores y regresión de navegación

- `localId`: PK autoincremental de Drift; sirve para relaciones locales.
- `clientId`: identificador estable de creación/sincronización (UUID en una
  creación offline; las filas descargadas usan `remote-{id}`). No es el ID REST.
- `remoteId`: ID asignado por el backend. Es el `id` de DonationListItem y el
  único identificador válido para `/donaciones/{id}` y `/api/donaciones/{id}`.

La revisión encontró una sustitución de repositorios en el router, pero no una
conversión de `localId` a ID REST: `getOwnDonations` ya delegaba en remoto y
`_toModel` ya utilizaba `row.remoteId`. Se retiró esa sustitución para conservar
el servicio HTTP configurado originalmente. Las pruebas del router usan una
fila con PK local distinto de 731 y comprueban GET/PATCH con ID remoto 731,
cero peticiones por el servicio offline y actualización de UI/Drift al editar.

El logger HTTP anonimiza los números como `:id`; esa salida por sí sola no
permite saber qué ID numérico se envió en un dispositivo ni probar la causa
exacta de su 404. Los archivos revisados están en UTF-8 sin los mojibakes
reportados; las pruebas verifican también «Detalle de donación», «imágenes» y
«Donación actualizada correctamente.» en la interfaz.

## Imágenes

No se incluye edición de imágenes en esta entrega. El PATCH sí la soporta,
pero reemplaza toda la colección y genera nuevas filas de imágenes. El selector
actual de creación trabaja con XFile locales; las fotos existentes son objetos
remotos con id, referencia, orden y posible ruta de caché. Mezclarlas requiere
ampliar el selector y reconciliar sus identificadores/cachés. Se omite siempre
`imagenes` para conservar las fotos sin duplicar la subida ni arriesgar borrados.

## Verificación manual en Samsung

Usar una compilación del frontend con estos cambios, backend accesible y una
cuenta con una donación PUBLICADA. Si falta, publicarla con el flujo existente y
esperar a que termine la sincronización.

1. Iniciar sesión, abrir **Mis donaciones** y pulsar una publicación propia
   PUBLICADA. Confirmar que aparece **Editar**.
2. Pulsar **Editar**. Comprobar título, descripción y categoría precargados.
3. Pulsar **Guardar cambios** sin modificar nada. Debe aparecer
   «No hay cambios para guardar.» y continuar en el formulario.
4. Escribir `abc` en título y `corta` en descripción; pulsar Guardar cambios.
   Deben aparecer los mínimos de 5 y 20 caracteres. Probar también una
   descripción con etiquetas HTML y comprobar su rechazo.
5. Escribir `Mesa de prueba Samsung` y
   `Mesa de madera en buen estado para donar.`, elegir otra categoría válida y
   pulsar Guardar cambios dos veces rápidamente. Debe mostrarse carga, bloquear
   el segundo envío y regresar al detalle con una sola confirmación.
6. Comprobar los tres valores nuevos y que las fotografías siguen iguales.
7. Volver con Atrás a Mis donaciones. Verificar el título actualizado; abrir de
   nuevo la donación y comprobar descripción y categoría. Cerrar y abrir la app
   con conexión y comprobar que persisten.
8. Abrir Editar con conexión, modificar el título y **después** activar modo
   avión, apagando también Wi-Fi. Guardar y esperar el error/timeout: debe
   conservar lo escrito, permitir reintentar y no afirmar que quedó en cola.
   Restaurar conexión y guardar. Comprobar nuevamente detalle y lista.
9. Abrir una donación propia RESERVADA, ENTREGADA o RETIRADA disponible en la
   cuenta: no debe aparecer Editar. No cambiar estados solo para esta prueba.
10. Desde Explorar, abrir una donación ajena PUBLICADA: no debe aparecer Editar.
11. Volver a Crear donación y comprobar sus validaciones, selección de fotos y
    publicación habitual. Una creación offline debe conservar su flujo de cola.

Si una respuesta se pierde después de que el servidor aplique el PATCH, el
cliente no puede asegurar que falló la escritura remota. Se conserva el
formulario y no hay reintento automático, siguiendo la política existente.
