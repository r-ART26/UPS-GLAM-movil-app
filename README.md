# UPStagram

Aplicación móvil desarrollada en Flutter para compartir fotografías con la comunidad UPS. La aplicación permite aplicar filtros avanzados a las imágenes, publicar posts y gestionar un perfil de usuario.

## 📋 Tabla de Contenidos

- [Características](#-características)
- [Requisitos Previos](#-requisitos-previos)
- [Instalación](#-instalación)
- [Configuración](#-configuración)
- [Archivos Sensibles](#-archivos-sensibles)
- [Configuración del Icono](#-configuración-del-icono)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Ejecución](#-ejecución)
- [Tecnologías Utilizadas](#-tecnologías-utilizadas)

## ✨ Características

- 🔐 **Autenticación JWT**: Sistema de login y registro seguro
- 📷 **Gestión de Imágenes**: Selección desde cámara o galería
- 🎨 **Filtros Avanzados**: Aplicación de múltiples filtros de procesamiento de imágenes:
  - Canny (detección de bordes)
  - Gaussian (desenfoque)
  - Negative (negativo)
  - Emboss (relieve)
  - Watermark (marca de agua)
  - Ripple (ondas)
  - Collage (collage)
- 📱 **Feed de Publicaciones**: Visualización de posts de la comunidad
- 👤 **Perfil de Usuario**: Gestión de perfil con estadísticas
- 🌐 **Conexión a Backend**: Integración con servidor Spring Boot en red local

## 🔧 Requisitos Previos

- Flutter SDK (versión 3.10.3 o superior)
- Dart SDK (versión 3.10.3 o superior)
- Android Studio / Xcode (para desarrollo móvil)
- Servidor Spring Boot ejecutándose en la red local
- Cuenta de Firebase configurada

## 📦 Instalación

1. **Clonar el repositorio**
   ```bash
   git clone `https://github.com/r-ART26/UPS-GLAM-movil-app`
   cd UPS-GLAM-movil-app
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar archivos sensibles** (ver sección [Archivos Sensibles](#-archivos-sensibles))

4. **Generar iconos de la aplicación** (ver sección [Configuración del Icono](#-configuración-del-icono))

## ⚙️ Configuración

### Configuración del Servidor Backend

Al iniciar la aplicación por primera vez, se te pedirá ingresar la dirección IP de tu servidor Spring Boot. Esta IP debe ser la dirección de tu red local donde está ejecutándose el backend. El repositorio del backend es [UPSGlam-2-backend-springboot](https://github.com/Jonnathan23/UPSGlam-2-backend-springboot). Este backend usa un microservicio de Fastapi -> [VisionProcessingGPU-Kit](https://github.com/Juanja1306/VisionProcessingGPU-Kit)

**Ejemplo:**
- Si tu servidor Spring Boot está en `http://192.168.1.100:8080`, ingresa: `192.168.1.100`

La configuración se guarda localmente y se utiliza para todas las peticiones al backend.

## 🔒 Archivos Sensibles

**IMPORTANTE:** Estos archivos contienen información sensible y NO deben subirse a Git. Asegúrate de tenerlos en tu entorno local antes de ejecutar la aplicación.

### Archivos Requeridos y sus Ubicaciones:

1. **`lib/firebase_options.dart`**
   - **Ubicación:** `lib/firebase_options.dart`
   - **Descripción:** Configuración de Firebase generada automáticamente
   - **Cómo obtenerlo:**
     ```bash
     flutterfire configure
     ```
   - **Nota:** Este archivo se genera al configurar Firebase en tu proyecto

2. **`android/app/google-services.json`**
   - **Ubicación:** `android/app/google-services.json`
   - **Descripción:** Archivo de configuración de Google Services para Android
   - **Cómo obtenerlo:**
     1. Ve a [Firebase Console](https://console.firebase.google.com/)
     2. Selecciona tu proyecto
     3. Ve a Configuración del proyecto > Tus aplicaciones
     4. Descarga el archivo `google-services.json` para Android
     5. Colócalo en `android/app/`

3. **`ios/Runner/GoogleService-Info.plist`** (Opcional)
   - **Ubicación:** `ios/Runner/GoogleService-Info.plist`
   - **Descripción:** Archivo de configuración de Google Services para iOS
   - **Cómo obtenerlo:**
     1. Ve a [Firebase Console](https://console.firebase.google.com/)
     2. Selecciona tu proyecto
     3. Ve a Configuración del proyecto > Tus aplicaciones
     4. Descarga el archivo `GoogleService-Info.plist` para iOS
     5. Colócalo en `ios/Runner/`

4. **`firebase.json`** (Opcional)
   - **Ubicación:** Raíz del proyecto (`firebase.json`)
   - **Descripción:** Configuración de Firebase Hosting (si se utiliza)
   - **Nota:** Solo necesario si planeas usar Firebase Hosting

### Verificación de Archivos Sensibles

Antes de ejecutar la aplicación, verifica que tengas estos archivos:

```bash
# Verificar archivos sensibles
ls lib/firebase_options.dart
ls android/app/google-services.json
ls ios/Runner/GoogleService-Info.plist
```

## 🎨 Configuración del Icono

La aplicación utiliza `flutter_launcher_icons` para generar los iconos automáticamente.

### Requisitos del Icono:

- **Ubicación:** `assets/icon/icon.png`
- **Tamaño recomendado:** 1024x1024 píxeles
- **Formato:** PNG
- **Resolución mínima:** 512x512 píxeles
- **Fondo:** Transparente (recomendado)

### Generar Iconos:

1. Coloca tu imagen del icono en `assets/icon/icon.png`

2. Ejecuta el comando para generar los iconos:
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

3. Los iconos se generarán automáticamente para:
   - Android: `android/app/src/main/res/mipmap-*/`
   - iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### Configuración del Icono Adaptativo (Android)

El icono adaptativo de Android usa:
- **Color de fondo:** `#002B5C` (Azul oscuro UPS)
- **Icono de primer plano:** `assets/icon/icon.png`

Puedes modificar estos valores en `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/icon.png"
  min_sdk_android: 21
  adaptive_icon_background: "#002B5C"
  adaptive_icon_foreground: "assets/icon/icon.png"
```

## 📁 Estructura del Proyecto

```
UPS-GLAM-movil-app/
├── android/                 # Configuración Android
│   └── app/
│       └── google-services.json  # ⚠️ Archivo sensible (NO subir a Git)
├── assets/
│   └── icon/
│       └── icon.png        # Icono de la aplicación
├── ios/                     # Configuración iOS
│   └── Runner/
│       └── GoogleService-Info.plist  # ⚠️ Archivo sensible (NO subir a Git)
├── lib/
│   ├── firebase_options.dart  # ⚠️ Archivo sensible (NO subir a Git)
│   ├── main.dart            # Punto de entrada de la aplicación
│   ├── router/
│   │   └── app_router.dart  # Configuración de rutas (GoRouter)
│   ├── services/
│   │   ├── api/
│   │   │   └── api_service.dart  # Servicio base para peticiones HTTP
│   │   ├── auth/
│   │   │   ├── auth_service.dart  # Gestión de JWT y autenticación
│   │   │   └── auth_middleware.dart  # Middleware de autenticación
│   │   ├── config/
│   │   │   └── app_config_service.dart  # Configuración del servidor
│   │   ├── image/
│   │   │   ├── image_processing_service.dart  # Procesamiento de filtros
│   │   │   └── temp_image_service.dart  # Gestión de imágenes temporales
│   │   └── posts/
│   │       └── post_service.dart  # Servicio para publicaciones
│   └── ui/
│       ├── layout/         # Layouts reutilizables
│       ├── screens/         # Pantallas de la aplicación
│       │   ├── auth/       # Login y registro
│       │   ├── feed/       # Feed de publicaciones
│       │   ├── post/       # Creación y detalle de posts
│       │   ├── profile/    # Perfil de usuario
│       │   └── welcome/    # Pantalla de bienvenida
│       ├── theme/          # Tema y estilos
│       └── widgets/        # Widgets reutilizables
├── pubspec.yaml           # Dependencias y configuración
└── README.md             # Este archivo
```

## 🚀 Ejecución

### Modo Desarrollo

```bash
flutter run
```

### Modo Release (Android)

```bash
flutter build apk --release
```

### Modo Release (iOS)

```bash
flutter build ios --release
```

### Ejecutar en un dispositivo específico

```bash
# Listar dispositivos disponibles
flutter devices

# Ejecutar en un dispositivo específico
flutter run -d <device-id>
```

## 🛠️ Tecnologías Utilizadas

### Framework y Lenguaje
- **Flutter** 3.10.3
- **Dart** 3.10.3

### Dependencias Principales
- **firebase_core** ^4.2.1 - Integración con Firebase
- **go_router** ^14.2.0 - Navegación y routing
- **shared_preferences** ^2.2.2 - Almacenamiento local
- **http** ^1.1.0 - Cliente HTTP básico
- **dio** ^5.4.0 - Cliente HTTP avanzado (multipart, cancelación)
- **image_picker** ^1.0.7 - Selección de imágenes desde cámara/galería
- **path_provider** ^2.1.1 - Gestión de rutas del sistema
- **flutter_launcher_icons** ^0.13.1 - Generación de iconos

### Backend
- **Spring Boot** - Servidor backend REST API
- **JWT** - Autenticación mediante tokens

## 📝 Notas Adicionales

### Permisos Requeridos (Android)

La aplicación requiere los siguientes permisos (ya configurados en `AndroidManifest.xml`):
- `CAMERA` - Para tomar fotos
- `READ_EXTERNAL_STORAGE` - Para acceder a la galería
- `READ_MEDIA_IMAGES` - Para acceder a imágenes en Android 13+

### Configuración de Red Local

Para que la aplicación se conecte al backend Spring Boot:
1. Asegúrate de que el servidor esté ejecutándose
2. Verifica que el dispositivo móvil y el servidor estén en la misma red
3. Ingresa la IP correcta en la pantalla de bienvenida
4. El formato debe ser solo la IP (ej: `192.168.1.100`), sin `http://` ni puerto

### Troubleshooting

**Problema:** La aplicación no se conecta al backend
- Verifica que el servidor Spring Boot esté ejecutándose
- Confirma que la IP ingresada sea correcta
- Asegúrate de que el dispositivo y el servidor estén en la misma red

**Problema:** Los iconos no se generan
- Verifica que la imagen esté en `assets/icon/icon.png`
- Asegúrate de que la imagen sea cuadrada (mismo ancho y alto)
- Ejecuta `flutter clean` y luego `flutter pub get` antes de generar iconos

## 👥 Contribuidores

- [Roberto Romero](https://github.com/r-ART26)
- [Juan Malo](https://github.com/Juanja1306)


## 📄 Licencia
Este proyecto está bajo la Licencia MIT. Ver el archivo [LICENSE](LICENSE) para más detalles.
