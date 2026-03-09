plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.mindmate"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.mindmate"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// Workaround: GeneratedPluginRegistrant.java references SharedPreferencesPlugin
// which is a Kotlin class. javac can't resolve it due to Gradle parallel compilation.
// We strip ONLY that one line and register it via reflection in MainActivity.kt,
// leaving all other (Java-based) plugin registrations intact.
afterEvaluate {
    tasks.withType(JavaCompile::class.java).configureEach {
        doFirst {
            val regFile = file("src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java")
            if (regFile.exists()) {
                val content = regFile.readText()
                val fixed = content.lines().joinToString("\n") { line ->
                    if (line.contains("SharedPreferencesPlugin")) {
                        "      // Removed: $line  (registered via reflection in MainActivity.kt)"
                    } else {
                        line
                    }
                }
                regFile.writeText(fixed)
            }
        }
    }
}
