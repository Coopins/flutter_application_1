plugins {
    id("com.android.application")
    kotlin("android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase Google Services
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.flutter_application_1"

    // Flutter-managed SDKs; explicitly pin NDK to silence warnings.
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.flutter_application_1"
        minSdk = maxOf(23, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Java/Kotlin 17
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false   // <- must be false if minify is false
        }
        release {
            // TODO: replace debug signing with your real release signing before shipping
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false     // enable later if you want shrinking
            isShrinkResources = false   // <- must be false since minify is false
            // If/when you enable shrinking later:
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
    }
}

flutter {
    source = "../.."
}
