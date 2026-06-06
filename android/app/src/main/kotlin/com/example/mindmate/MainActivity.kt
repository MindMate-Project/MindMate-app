package com.example.mindmate

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // When a reminder alarm fires via its full-screen intent, the OS launches
        // this activity. Show it over the keyguard and turn the screen on so the
        // patient sees the ringing alarm even on a locked / sleeping device.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
    }

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
