plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.smarthome.control"
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
        applicationId = "com.smarthome.control"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // App metadata
        resValue "string/app_name", "Smart Home Control"
        resValue "string/app_version", "${flutter.versionName} (${flutter.versionCode})"
        
        // Multi-dex support
        multiDexEnabled true
    }

    buildTypes {
        release {
            // Enable code shrinking and obfuscation
            minifyEnabled true
            proguardFiles getDefaultProguardFile("proguard-android.txt")
            proguardFiles "proguard-rules.pro"
            
            // TODO: Add your own signing config for release build.
            // For production, create a release keystore
            signingConfig = signingConfigs.getByName("debug")
        }
        debug {
            applicationIdSuffix ".debug"
        }
    }
}

flutter {
    source = "../.."
}
