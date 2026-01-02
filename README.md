# diario_de_una_pareja

Diario de una Pareja es una aplicación móvil desarrollada en Flutter diseñada para acortar la distancia física entre dos personas. El proyecto nació como una herramienta personal para Isael y Mariana, permitiéndoles compartir estados de ánimo, notas de apoyo, ubicación en tiempo real y un calendario sincronizado para gestionar guardias médicas y citas.

--Características Principales

    Latidos en Tiempo Real: Envío de vibraciones instantáneas a la pareja mediante notificaciones push de alta prioridad para simular cercanía.

    Calendario Compartido: Gestión de eventos específicos como guardias de hospital, exámenes académicos, días libres y citas de pareja.

    Muro de Notas: Un espacio para dejar mensajes de apoyo rápidos o personalizados que se sincronizan instantáneamente.

    Mood Tracker: Selección de estados de ánimo mediante emojis para que tu pareja sepa cómo te sientes en cada momento.

    Geolocalización: Cálculo dinámico de la distancia en kilómetros entre ambos usuarios.

    Contador de Tiempo: Visualización de los días transcurridos desde el inicio de la relación y cuenta regresiva para el próximo encuentro.

--Tecnologías Utilizadas

    Lenguaje: Dart.

Framework: Flutter.

    Base de Datos: Cloud Firestore (NoSQL) para sincronización en tiempo real.

    Notificaciones: Firebase Cloud Messaging (FCM) con la API HTTP v1 para envío de mensajes entre dispositivos.

    Almacenamiento Local: Shared Preferences para la persistencia del rol de usuario.

    Fuentes y Estilo: Google Fonts (Quicksand) y paleta de colores personalizada.

--Guía de Instalación y Adaptación

Debido a que este repositorio no incluye las llaves de seguridad (por el archivo .gitignore), sigue estos pasos para configurar tu propio diario:

1. Requisitos Previos

    Tener instalado Flutter SDK.

    Un proyecto creado en Firebase Console.

2. Configuración de Firebase

    Registra la App: Crea una aplicación Android en tu proyecto de Firebase con el ID de paquete que configuraste en tu build.gradle.kts.

    Archivo de Configuración: Descarga el archivo google-services.json y colócalo en la carpeta android/app/.

    Habilitar Servicios: Activa Firestore Database y Firebase Cloud Messaging.

    API HTTP v1: En la configuración del proyecto, ve a "Cuentas de servicio", genera una nueva clave privada JSON, renómbrala como service-account.json y guárdala en assets/data/.

3. Preparación de Archivos Locales

Para que la app funcione, debes crear o añadir manualmente los siguientes archivos en la carpeta assets/:

    Fotos: Añade tus imágenes en assets/images/ (nombradas del foto1.jpg al foto12.jpg o ajusta el código en intro_screen.dart).

    Frases: Crea un archivo assets/data/frases.json con una lista de mensajes personalizados.
    
4. Ejecución

# Clonar el repositorio
git clone https://github.com/tu-usuario/diario-pareja.git

# Instalar dependencias
flutter pub get

# Ejecutar la aplicación
flutter run

--Seguridad

Los archivos sensibles como service-account.json, google-services.json y las fotos personales están excluidos del control de versiones mediante .gitignore para proteger la privacidad de los datos y las credenciales de acceso al servidor.
