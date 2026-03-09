package com.example.mindmate

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // SharedPreferencesPlugin is Kotlin-only and gets stripped from
        // GeneratedPluginRegistrant.java by the Gradle workaround.
        // Register both the async (Kotlin) and legacy (Java) variants via reflection.
        registerPluginByReflection(flutterEngine,
            "io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin")
        registerPluginByReflection(flutterEngine,
            "io.flutter.plugins.sharedpreferences.LegacySharedPreferencesPlugin")
    }

    private fun registerPluginByReflection(flutterEngine: FlutterEngine, className: String) {
        try {
            val pluginClass = Class.forName(className)
            val pluginInstance = pluginClass.getDeclaredConstructor().newInstance() as FlutterPlugin
            flutterEngine.plugins.add(pluginInstance)
        } catch (e: Exception) {
            // Skip silently if not found
        }
    }
}
