plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.invest_ledger"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // 你可以根据需要保留或更新此 NDK 版本

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        
        applicationId = "com.example.invest_ledger"
        
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // 修改后的部分：设置 APK 文件的基础名称
        setProperty("archivesBaseName", "invest_ledger")
    }

    buildTypes {
        release {
            
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    
}

flutter {
    source = "../.."
}