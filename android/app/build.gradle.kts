plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.diario_de_una_pareja"

    // 1. Cambiamos de 34 a 35 como pidió el error
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.diario_de_una_pareja"

        // 2. Subimos a 24 para evitar la advertencia de Flutter
        minSdk = 24
        targetSdk = 36

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        // 3. AGREGA ESTA LÍNEA (Vital para las notificaciones)
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }
}

// 4. Busca la sección de dependencies al final del archivo y añade esto:
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
