import java.util.Properties

val p4uSigningFile = rootProject.file("key.properties")
val p4uSigning = Properties().apply {
    if (p4uSigningFile.exists()) p4uSigningFile.inputStream().use(::load)
}
val hasP4uSigning = p4uSigningFile.exists() &&
    listOf("keyAlias", "keyPassword", "storeFile", "storePassword")
        .all { !p4uSigning.getProperty(it).isNullOrBlank() }

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.p4u.p4u_vendor"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.p4u.p4u_vendor"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasP4uSigning) {
            create("p4uVendor") {
                keyAlias = p4uSigning.getProperty("keyAlias")
                keyPassword = p4uSigning.getProperty("keyPassword")
                storeFile = file(p4uSigning.getProperty("storeFile"))
                storePassword = p4uSigning.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (!hasP4uSigning) {
                throw GradleException("Vendor release signing requires android/key.properties")
            }
            signingConfig = signingConfigs.getByName("p4uVendor")
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


