# DonApp

## Descripción

DonApp es una aplicación móvil orientada a facilitar la donación de artículos y recursos entre personas.

Busca conectar a personas que tienen ropa, alimentos, útiles escolares y otros artículos en buen estado que ya no utilizan con personas que los necesitan.

El frontend móvil y el backend de DonApp se mantienen en repositorios independientes. Este repositorio contiene únicamente el cliente Flutter; el backend debe configurarse y ejecutarse por separado.

## Público objetivo

DonApp está dirigida principalmente a personas mayores de 18 años que desean donar o solicitar artículos.

También puede beneficiar a familias, estudiantes y comunidades con acceso a un teléfono móvil e Internet.

## Plataforma y tecnologías

- Android como plataforma inicial.
- Flutter.
- Dart, con restricción de SDK `^3.13.0` declarada en `pubspec.yaml`.
- Material 3.
- `package:http` `^1.6.0` para consumir la API REST.
- `flutter_secure_storage` `^9.2.4` para almacenar los tokens.

El proyecto no fija una versión concreta de Flutter; debe utilizarse una instalación compatible con la restricción de Dart del proyecto.

## Estado actual

Actualmente el frontend implementa:

- Registro de usuario desde la aplicación.
- Inicio de sesión.
- Almacenamiento seguro de `accessToken` y `refreshToken`.
- Verificación de autenticación mediante el endpoint de perfil protegido.
- Home inicial con información real del usuario.
- Configuración de la API mediante `API_BASE_URL`.
- Conexión desde un dispositivo Android físico mediante ADB reverse.
- Manejo de errores de validación, red, timeout y autenticación.
- Prueba técnica de categorías conservada en el código para evolución posterior.

Todavía están pendientes en el cliente:

- Publicación completa de donaciones.
- Búsqueda completa.
- Solicitudes.
- Chat.
- Calificaciones.
- Recuperación de contraseña.
- Renovación automática del refresh token.

## Requisitos

Para preparar y ejecutar la aplicación se necesita:

- Flutter instalado.
- Dart, incluido normalmente con Flutter.
- Android SDK.
- Un dispositivo Android reconocido por Flutter.
- Depuración USB habilitada si se utiliza un dispositivo físico.
- Conexión USB para el procedimiento con ADB reverse documentado aquí.
- Backend de DonApp configurado y ejecutándose por separado.
- PostgreSQL disponible y configurado para el backend.

Redis y BullMQ no son necesarios para probar registro, inicio de sesión y consulta del perfil.

## Verificación del entorno

Ejecute los siguientes comandos antes de instalar o iniciar la aplicación:

```powershell
flutter --version
dart --version
flutter channel
flutter doctor -v
flutter devices
```

- `flutter --version`: muestra la versión instalada de Flutter y el Dart incluido.
- `dart --version`: confirma que el ejecutable de Dart está disponible.
- `flutter channel`: muestra el canal de Flutter actualmente seleccionado.
- `flutter doctor -v`: revisa Flutter, Android SDK, licencias, toolchains y dispositivos con información detallada.
- `flutter devices`: enumera los destinos en los que Flutter puede ejecutar la aplicación.

Resuelva los problemas relevantes mostrados por `flutter doctor -v` antes de continuar.

## Instalación

Descargue el frontend y abra una terminal en la raíz de `donapp-frontend`. Instale las dependencias:

```powershell
flutter pub get
```

Compruebe el código y las pruebas:

```powershell
flutter analyze
flutter test
```

## Preparar el backend

Abra otra terminal en la raíz del repositorio independiente del backend DonApp. Instale sus dependencias y ejecútelo:

```powershell
yarn install
yarn dev
```

El backend utiliza su propio archivo `.env` y su propia conexión con PostgreSQL. Esa configuración no se define en el frontend.

El procedimiento documentado supone que el backend queda disponible en el puerto `3000` de la computadora.

## Configuración de API_BASE_URL

El frontend obtiene la URL del backend mediante:

```dart
String.fromEnvironment('API_BASE_URL')
```

Por eso la URL se proporciona al compilar o ejecutar la aplicación usando `--dart-define`.

Para la conexión comprobada con un dispositivo físico y ADB reverse se utiliza:

```text
http://localhost:3000
```

No agregue `/api` al final. Los servicios del frontend incorporan las rutas completas de cada endpoint.

## Conectar un dispositivo Android físico

Conecte el dispositivo mediante USB, acepte la autorización de depuración y confirme que Flutter lo detecta:

```powershell
flutter devices
```

En Windows, confirme también que ADB reconoce el dispositivo:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
```

El dispositivo debe aparecer con estado `device`. Si aparece como `unauthorized`, revise la pantalla del teléfono y acepte la autorización USB.

Configure la redirección del puerto `3000`:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:3000 tcp:3000
```

Compruebe la configuración:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse --list
```

Debe aparecer una redirección equivalente a:

```text
tcp:3000 tcp:3000
```

ADB reverse permite que `localhost:3000` utilizado por la aplicación en el teléfono llegue al puerto `3000` de la computadora a través de USB.

## Ejecutar el frontend

Antes de ejecutar la aplicación confirme que:

- El backend está en ejecución.
- PostgreSQL está disponible para el backend.
- El dispositivo está conectado y reconocido.
- ADB reverse está configurado para el puerto `3000`.

Desde la raíz de `donapp-frontend`, ejecute:

```powershell
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

## Registro de usuario

El registro se realiza completamente desde la aplicación:

```text
DonApp
  → Regístrate
  → completar formulario
  → POST /api/auth/register
  → cuenta creada
  → volver al Login
```

El formulario actual solicita:

- Nombre completo.
- Nombre de usuario.
- Correo electrónico.
- Ciudad.
- Contraseña.
- Confirmar contraseña.

`Confirmar contraseña` es una validación exclusiva del frontend y no se envía al backend. La contraseña no se almacena. Después del registro, el backend crea una cuenta activa con rol `USUARIO` y la aplicación vuelve al Login con únicamente el correo prellenado.

No es necesario utilizar Postman para registrar usuarios.

## Inicio de sesión

El flujo de autenticación es:

```text
Correo + contraseña
  → POST /api/auth/login
  → accessToken + refreshToken
  → almacenamiento seguro
  → GET /api/usuarios/perfil
  → Home
```

Endpoints utilizados:

```text
POST /api/auth/login
GET  /api/usuarios/perfil
```

La consulta del perfil envía el access token con el encabezado:

```http
Authorization: Bearer <accessToken>
```

La contraseña debe escribirse en el Login después de crear la cuenta. El Home se abre únicamente cuando el backend acepta el login y el endpoint protegido devuelve el perfil.

## Almacenamiento seguro

- `accessToken` y `refreshToken` se almacenan mediante `flutter_secure_storage`.
- La contraseña nunca se almacena.
- El correo no se almacena como credencial.
- El perfil completo no se persiste en el almacenamiento seguro.
- La renovación automática mediante refresh token todavía está pendiente.

## Seguridad de red Android

La configuración Android incluye:

- El permiso `android.permission.INTERNET` en `AndroidManifest.xml`.
- La referencia a `network_security_config.xml`.
- HTTP sin cifrar denegado por defecto.
- Una excepción de desarrollo únicamente para el dominio `localhost`.

No se habilita HTTP globalmente. La excepción permite utilizar `http://localhost:3000` con ADB reverse durante el desarrollo.

## Estructura del frontend

```text
lib/
├── config/
│   └── api_config.dart
├── models/
│   ├── auth_session.dart
│   ├── category.dart
│   └── user_profile.dart
├── screens/
│   ├── home_screen.dart
│   ├── login_screen.dart
│   └── register_screen.dart
├── services/
│   ├── api_exception.dart
│   ├── auth_service.dart
│   ├── category_service.dart
│   ├── profile_service.dart
│   └── token_storage.dart
├── widgets/
│   └── app_password_field.dart
└── main.dart
```

- `config/`: valida `API_BASE_URL` y construye las URL de los endpoints.
- `models/`: representa y valida las respuestas de autenticación, perfil y categorías.
- `screens/`: contiene Registro, Login y Home.
- `services/`: consume la API, traduce errores y encapsula el almacenamiento de tokens.
- `widgets/`: contiene componentes reutilizables del formulario.
- `main.dart`: inicializa Material 3 y abre el Login.

## Base de datos

No es necesario abrir una herramienta de base de datos para registrar usuarios. El flujo normal es:

```text
Flutter
  → API del backend
  → Prisma
  → PostgreSQL
```

Como comprobación opcional, el backend incluye Prisma como dependencia de desarrollo. Desde la raíz del backend puede abrirse Prisma Studio con:

```powershell
yarn prisma studio
```

Prisma Studio no forma parte del procedimiento necesario para registrar, iniciar sesión o consultar el perfil.

## Comandos rápidos

### Backend

```powershell
yarn dev
```

### Frontend en dispositivo físico

```powershell
flutter devices
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:3000 tcp:3000
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse --list
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

### Verificación

```powershell
flutter analyze
flutter test
```
