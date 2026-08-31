# Catálogo de componentes

Este documento describe la interfaz pública de los componentes presentacionales reutilizables ubicados en `lib/widgets/`.

## AppTextField

**Propósito:** unifica la presentación básica de un campo de formulario con etiqueta, ayuda opcional, icono inicial y validación.

**Reutilización:** está disponible para formularios que necesiten campos de texto consistentes. Cuenta con pruebas de componente y se utiliza en el formulario de creación de donaciones.

### Interfaz pública

| Parámetro | Tipo | Obligatorio | Valor por defecto | Descripción |
|---|---|---:|---|---|
| `label` | `String` | Sí | — | Etiqueta del campo. |
| `controller` | `TextEditingController` | Sí | — | Controla y permite leer o modificar el texto. Su ciclo de vida corresponde al widget que lo proporciona. |
| `validator` | `String? Function(String?)?` | No | `null` | Valida el valor y devuelve un mensaje o `null`. |
| `keyboardType` | `TextInputType?` | No | `null` | Tipo de teclado solicitado. |
| `textInputAction` | `TextInputAction?` | No | `null` | Acción mostrada en el teclado. |
| `prefixIcon` | `IconData?` | No | `null` | Icono situado al inicio del campo. |
| `hintText` | `String?` | No | `null` | Texto de ayuda dentro del campo. |
| `maxLines` | `int` | No | `1` | Número máximo de líneas. |
| `enabled` | `bool` | No | `true` | Habilita o deshabilita la edición. |
| `autovalidateMode` | `AutovalidateMode?` | No | `null` | Controla cuándo Flutter ejecuta automáticamente el validador. |
| `onChanged` | `ValueChanged<String>?` | No | `null` | Notifica cada cambio del texto al consumidor. |
| `key` | `Key?` | No | `null` | Identidad del widget en el árbol. |

**Contenido delegado:** la etiqueta, la ayuda, el icono y los mensajes producidos por `validator` provienen del consumidor.

**Estados o variantes:** habilitado/deshabilitado, una o varias líneas, con o sin icono, ayuda y validación.

**Tokens y tema:** usa `AppSpacing.medium` como padding horizontal y vertical. Si la extensión no está registrada, usa `AppSpacing()`; el resto de la apariencia proviene de `InputDecorationTheme` y del tema Material activo.

**Accesibilidad:** conserva la semántica nativa de `TextFormField`; la etiqueta identifica el control y los errores del validador se integran en el campo.

**Restricciones:** no administra ni libera el `TextEditingController`, no define `obscureText` y no agrega borde de forma explícita.

```dart
AppTextField(
  label: 'Ciudad',
  controller: cityController,
  prefixIcon: Icons.location_city_outlined,
  textInputAction: TextInputAction.done,
  validator: (value) => value == null || value.trim().isEmpty
      ? 'La ciudad es obligatoria.'
      : null,
)
```

## AppPrimaryButton

**Propósito:** presenta la acción principal a ancho completo, con opción de icono y estado de carga.

**Reutilización:** se usa en `WelcomeScreen`, `LoginScreen`, `RegisterScreen` y `CreateDonationScreen`; también es apropiado para otras acciones principales.

### Interfaz pública

| Parámetro | Tipo | Obligatorio | Valor por defecto | Descripción |
|---|---|---:|---|---|
| `text` | `String` | Sí | — | Etiqueta visible y semántica del botón. |
| `onPressed` | `VoidCallback` | Sí | — | Callback ejecutado al pulsar el botón cuando está habilitado y no está cargando. |
| `isLoading` | `bool` | No | `false` | Sustituye visualmente la etiqueta por un indicador y bloquea la interacción. |
| `enabled` | `bool` | No | `true` | Permite o bloquea la interacción. |
| `icon` | `IconData?` | No | `null` | Icono opcional junto a la etiqueta. |
| `key` | `Key?` | No | `null` | Identidad del widget en el árbol. |

**Callbacks:** `onPressed`; no se invoca si `enabled` es `false` o `isLoading` es `true`.

**Contenido delegado:** el consumidor proporciona la etiqueta y, opcionalmente, el icono.

**Estados o variantes:** normal, deshabilitado, cargando, con icono y sin icono.

**Tokens y tema:** usa `AppSpacing.large` para el padding horizontal, `AppSpacing.medium` para el vertical y `AppSpacing.small` entre icono y texto. Si falta la extensión, usa `AppSpacing()`. Colores y forma proceden del tema de `FilledButton`.

**Accesibilidad:** expone semántica de botón, estado habilitado y una etiqueta. Durante la carga anuncia `"<texto>. Cargando"`; excluye la semántica visual duplicada del contenido interno.

**Restricciones:** ocupa todo el ancho disponible, respeta como mínimo `kMinInteractiveDimension` de altura y requiere siempre un callback aunque pueda quedar temporalmente bloqueado.

```dart
AppPrimaryButton(
  text: 'Guardar',
  icon: Icons.save_outlined,
  isLoading: isSaving,
  enabled: canSave,
  onPressed: save,
)
```

## AppContentState

**Propósito:** representa de forma consistente estados de carga, contenido vacío o error, con mensaje y acción opcionales.

**Reutilización:** se usa en `SessionGate`, `CreateDonationScreen`, `ExploreDonationsScreen`, `MyDonationsScreen`, `DonationDetailScreen`, las listas de solicitudes enviadas y recibidas, y `RequestDetailScreen`.

### Interfaz pública

El tipo público `AppContentStateType` admite `loading`, `empty` y `error`.

| Parámetro | Tipo | Obligatorio | Valor por defecto | Descripción |
|---|---|---:|---|---|
| `type` | `AppContentStateType` | Sí | — | Selecciona el estado y su presentación. |
| `title` | `String` | Sí | — | Título principal del estado. |
| `message` | `String?` | No | `null` | Explicación adicional. |
| `icon` | `IconData?` | No | `null` | Reemplaza el icono predeterminado cuando el estado no muestra el indicador de carga. |
| `actionText` | `String?` | No | `null` | Etiqueta de la acción opcional. |
| `onAction` | `VoidCallback?` | No | `null` | Callback de la acción opcional. |
| `key` | `Key?` | No | `null` | Identidad del widget en el árbol. |

**Callbacks:** `onAction`. El botón solo aparece cuando `actionText` y `onAction` tienen valor.

**Contenido delegado:** título, mensaje, icono alternativo y texto de acción.

**Estados o variantes:** `loading` muestra un `CircularProgressIndicator`; `empty` usa `Icons.inbox_outlined`; `error` usa `Icons.error_outline`. Un icono proporcionado reemplaza el predeterminado de `empty` y `error`; en `loading` se sigue mostrando el indicador.

**Tokens y tema:** usa `AppSpacing.large`, `medium` y `small`, con fallback a `AppSpacing()`. Consume `textTheme.titleLarge`, `textTheme.bodyLarge`, `colorScheme.primary` y `colorScheme.error`.

**Accesibilidad:** es un contenedor semántico. Carga y error son regiones vivas; vacío no lo es. El indicador de carga tiene la etiqueta semántica `Cargando` y el botón conserva la semántica Material.

**Restricciones:** para mostrar la acción deben proporcionarse juntos `actionText` y `onAction`; proporcionar solo uno no produce botón.

```dart
AppContentState(
  type: AppContentStateType.error,
  title: 'No fue posible cargar el contenido',
  message: 'Intenta nuevamente.',
  actionText: 'Reintentar',
  onAction: reload,
)
```

## DonationCard

**Propósito:** presenta el resumen seleccionable de una donación con imagen, título, categoría, ubicación, estado y subtítulo opcional.

**Reutilización:** cuenta con pruebas de componente y se utiliza en Explorar y Mis donaciones.

### Interfaz pública

| Parámetro | Tipo | Obligatorio | Valor por defecto | Descripción |
|---|---|---:|---|---|
| `image` | `ImageProvider<Object>?` | Sí | — | Proveedor de la imagen principal; `null` muestra el placeholder. |
| `title` | `String` | Sí | — | Título de la donación. |
| `category` | `String` | Sí | — | Categoría mostrada en los metadatos. |
| `location` | `String` | Sí | — | Ubicación mostrada en los metadatos. |
| `status` | `String` | Sí | — | Estado mostrado como etiqueta visual. |
| `imageFit` | `BoxFit` | No | `BoxFit.cover` | Define cómo se ajusta la imagen dentro del espacio 16:9. |
| `onTap` | `VoidCallback?` | No | `null` | Callback ejecutado al pulsar la tarjeta; si es `null`, la tarjeta queda deshabilitada. |
| `subtitle` | `String?` | No | `null` | Descripción secundaria opcional. |
| `key` | `Key?` | No | `null` | Identidad del widget en el árbol. |

**Callbacks:** `onTap`, delegado directamente al `InkWell`.

**Contenido delegado:** imagen y todos los textos proceden del consumidor.

**Estados o variantes:** con o sin imagen, subtítulo y acción. La imagen ocupa una relación visual 16:9 y respeta el `imageFit` proporcionado.

**Tokens y tema:** usa `AppSpacing.small` y `medium`, `AppRadius.card`, `AppRadius.field` y `AppColorTokens.textSecondary`, todos con sus fallbacks estándar. También consume tipografía y colores del tema Material.

**Accesibilidad:** expone toda la tarjeta como botón con una etiqueta compuesta por título, categoría, ubicación y estado. Excluye la semántica interna y la imagen decorativa para evitar anuncios duplicados.

**Restricciones:** no incluye el subtítulo en la etiqueta semántica, no interpreta ni valida el texto del estado y no realiza ninguna acción adicional a `onTap`.

```dart
DonationCard(
  image: const AssetImage('assets/branding/donapp_icon.png'),
  title: 'Ropa en buen estado',
  subtitle: 'Varias prendas disponibles',
  category: 'Ropa',
  location: 'Bogotá',
  status: 'Disponible',
  onTap: openDonation,
)
```

## AppBottomNavigationBar

**Propósito:** ofrece la barra inferior común con cinco destinos fijos: Inicio, Explorar, Donar, Mensajes y Perfil.

**Reutilización:** cuenta con pruebas de componente y está disponible, pero todavía no está integrada como navegación principal de la aplicación.

### Interfaz pública

| Parámetro | Tipo | Obligatorio | Valor por defecto | Descripción |
|---|---|---:|---|---|
| `currentIndex` | `int` | Sí | — | Índice del destino seleccionado. |
| `onDestinationSelected` | `ValueChanged<int>` | Sí | — | Recibe el índice del destino pulsado. |
| `key` | `Key?` | No | `null` | Identidad del widget en el árbol. |

La constante pública `AppBottomNavigationBar.destinationCount` vale `5`.

**Callbacks:** `onDestinationSelected` recibe valores entre `0` y `4` según el destino elegido.

**Contenido delegado:** no admite destinos personalizados; delega al consumidor únicamente el índice actual y el manejo de la selección.

**Estados o variantes:** refleja el destino seleccionado mediante `currentIndex` y alterna entre iconos delineados y rellenos definidos internamente.

**Tokens y tema:** no consume extensiones de tokens propias. Su aspecto procede del `NavigationBarTheme` y del `ThemeData` Material activos.

**Accesibilidad:** cada destino tiene etiqueta visible y tooltip. Explorar y Donar usan tooltips más descriptivos: `Explorar donaciones` y `Publicar una donación`.

**Restricciones:** contiene exactamente cinco destinos fijos. `currentIndex` debe estar entre `0` y `destinationCount - 1`; el constructor lo comprueba mediante `assert`. El componente solo comunica la selección y no cambia rutas por sí mismo.

```dart
AppBottomNavigationBar(
  currentIndex: selectedIndex,
  onDestinationSelected: (index) {
    setState(() => selectedIndex = index);
  },
)
```
