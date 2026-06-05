plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.antigravity.ownd"
    compileSdk = 36
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.antigravity.ownd"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.projectDir.parentFile.resolve("key.properties")
            val keystoreProperties = java.util.Properties()
            val hasProperties = keystorePropertiesFile.exists()
            if (hasProperties) {
                keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
            }

            val keystoreFile = file("ownd-release-key.jks")
            val keystorePassword = if (hasProperties) keystoreProperties.getProperty("storePassword") else System.getenv("OWND_KEYSTORE_PASSWORD")
            val keyAliasName = if (hasProperties) keystoreProperties.getProperty("keyAlias") else System.getenv("OWND_KEY_ALIAS")
            val keyPass = if (hasProperties) keystoreProperties.getProperty("keyPassword") else System.getenv("OWND_KEY_PASSWORD")
            
            val hasKeystoreEnv = keystorePassword != null && keystorePassword != "" &&
                                 keyAliasName != null && keyAliasName != "" &&
                                 keyPass != null && keyPass != ""

            if (keystoreFile.exists() && hasKeystoreEnv) {
                storeFile = keystoreFile
                storePassword = keystorePassword
                keyAlias = keyAliasName
                keyPassword = keyPass
            } else {
                // Fallback to debug configuration for local building ease
                val debugConfig = signingConfigs.getByName("debug")
                storeFile = debugConfig.storeFile
                storePassword = debugConfig.storePassword
                keyAlias = debugConfig.keyAlias
                keyPassword = debugConfig.keyPassword
            }
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            resValue("string", "app_name", "物记-Dev")
        }
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            resValue("string", "app_name", "物记")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.squareup.okhttp3:okhttp:4.9.0")
    implementation("com.google.android.play:core:1.10.3") // Legacy Play Core for Flutter R8 compatibility
}
