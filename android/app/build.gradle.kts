import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: android/key.properties locally (git-ignored), or the
// KEYSTORE_FILE / KEYSTORE_PASSWORD environment variables in CI. Without
// either, release builds fall back to the debug key.
val keyProps = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
val releaseStoreFile: String? =
    keyProps.getProperty("storeFile") ?: System.getenv("KEYSTORE_FILE")
val releaseStorePassword: String? =
    keyProps.getProperty("storePassword") ?: System.getenv("KEYSTORE_PASSWORD")
val hasReleaseKey = releaseStoreFile != null && releaseStorePassword != null &&
    file(releaseStoreFile).exists()

android {
    namespace = "uz.azizbek.killer_sudoku"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "uz.azizbek.killer_sudoku"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Version code and name come from pubspec.yaml.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = keyProps.getProperty("keyAlias") ?: "upload"
                keyPassword = keyProps.getProperty("keyPassword") ?: releaseStorePassword
                storeType = "pkcs12"
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (hasReleaseKey) "release" else "debug")
            // R8 shrinking is off: with AGP 9 it can strip plugin classes
            // that are only reached through platform channels. Size is not
            // a concern for this sideloaded app.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
