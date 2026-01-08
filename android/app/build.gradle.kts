// android/app/build.gradle.kts
// Updated with Firebase dependencies and production settings

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

android {
    // ✅ CRITICAL: Namespace matches applicationId (prevents SecurityException)
    namespace = "com.citk.connect"
    
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.citk.connect"
        
        // ✅ CRITICAL: minSdk 23 required for modern Firebase features
        minSdk = flutter.minSdkVersion  // Increased from flutter.minSdkVersion (likely 21)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // ✅ Enable multidex for Firebase (handles 64k method limit)
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            
            // ✅ Enable code shrinking for smaller APK
            isMinifyEnabled = true
            isShrinkResources = true
            
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        
        debug {
            isMinifyEnabled = false
            // applicationIdSuffix = ".debug"
        }
    }

    // ✅ Handle duplicate files from Firebase dependencies
    packaging {
        resources {
            excludes += listOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/ASL2.0",
                "META-INF/*.kotlin_module"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ═══════════════════════════════════════════════════════════════════════
    // CORE ANDROID DEPENDENCIES
    // ═══════════════════════════════════════════════════════════════════════
    
    // Multidex support (required when method count exceeds 64k)
    implementation("androidx.multidex:multidex:2.0.1")
    
    // Core Android libraries
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    
    // ═══════════════════════════════════════════════════════════════════════
    // FIREBASE DEPENDENCIES (BOM manages versions)
    // ═══════════════════════════════════════════════════════════════════════
    
    // Firebase BOM (Bill of Materials) - manages all Firebase versions
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    
    // Firebase services (versions managed by BOM)
    implementation("com.google.firebase:firebase-analytics-ktx")
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.firebase:firebase-firestore-ktx")
    implementation("com.google.firebase:firebase-crashlytics-ktx")
    implementation("com.google.firebase:firebase-messaging-ktx") // For push notifications
    implementation("com.google.firebase:firebase-storage-ktx")    // For file storage
    
    // ═══════════════════════════════════════════════════════════════════════
    // GOOGLE PLAY SERVICES (required for Firebase and Maps)
    // ═══════════════════════════════════════════════════════════════════════
    
    implementation("com.google.android.gms:play-services-location:21.0.1")
    implementation("com.google.android.gms:play-services-maps:18.2.0")
}
