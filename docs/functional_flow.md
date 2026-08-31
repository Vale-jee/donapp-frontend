# Flujo funcional de DonApp

Este documento resume el recorrido principal del cliente móvil, los endpoints que intervienen y el resultado visible esperado en cada paso.

## Recorrido principal

| Paso | Acción | Endpoint o servicio | Resultado esperado | Evidencia visual sugerida |
|---|---|---|---|---|
| Login | Ingresar correo y contraseña. | `POST /api/auth/login` y `GET /api/usuarios/perfil` | Los tokens se almacenan de forma segura, se recupera el perfil y se abre Inicio o el destino privado solicitado. | Login completo e Inicio autenticado. |
| Explorar | Abrir Explorar desde Inicio. | `GET /api/donaciones` | Se presenta un listado real y paginado de donaciones, con filtro opcional por categoría. | Varias tarjetas de donaciones. |
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

## Capturas recomendadas

1. Login completo.
2. Inicio autenticado.
3. Explorar con donaciones reales.
4. Detalle de una donación.
5. Formulario de publicación completo con categoría e imágenes.
6. Detalle de la donación recién creada.
