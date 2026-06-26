plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "live.mindmate.alzheimers"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "live.mindmate.alzheimers"
        // You can update the following values to match your application needs.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            //Add signing config for the release build.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
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
