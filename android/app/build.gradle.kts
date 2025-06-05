plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

android {
    namespace = "com.example.invest_ledger"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // 你可以根据需要保留或更新此 NDK 版本

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {

        applicationId = "com.example.invest_ledger"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        // 优先使用命令行参数，否则使用Flutter配置
        versionCode = project.findProperty("versionCode")?.toString()?.toIntOrNull() ?: flutter.versionCode
        versionName = project.findProperty("versionName")?.toString() ?: flutter.versionName

        println("📱 Android构建版本信息:")
        println("  - versionCode: $versionCode")
        println("  - versionName: $versionName")
        println("  - applicationId: $applicationId")
    }

    signingConfigs {
        create("release") {
            // 从环境变量或local.properties读取签名信息
            val keystorePropertiesFile = rootProject.file("key.properties")
            if (keystorePropertiesFile.exists()) {
                val keystoreProperties = Properties()
                keystoreProperties.load(FileInputStream(keystorePropertiesFile))

                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            } else {
                // 如果没有key.properties文件，暂时使用debug配置（开发阶段）
                keyAlias = "androiddebugkey"
                keyPassword = "android"
                storeFile = file("${System.getProperty("user.home")}/.android/debug.keystore")
                storePassword = "android"
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    buildFeatures {
        buildConfig = true
    }
   

    
}

flutter {
    source = "../.."
}