pluginManagement {
    // Discover Flutter SDK path from local.properties
    val props = java.util.Properties().apply {
        file("local.properties").inputStream().use { load(it) }
    }
    val flutterSdkPath = props.getProperty("flutter.sdk")
        ?: error("flutter.sdk not set in local.properties")

    // Include Flutter's Gradle tooling
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    // Versions for additional plugins used by the app module
    plugins {
        // Firebase Google Services plugin
        id("com.google.gms.google-services") version "4.4.2"
    }
}

plugins {
    // Flutter’s root plugin loader
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    // Toolchain versions (keep in sync with your environment)
    id("com.android.application") version "8.7.2" apply false
    id("org.jetbrains.kotlin.android") version "2.0.20" apply false
}

include(":app")
