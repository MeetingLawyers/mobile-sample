plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
    // The MeetingLawyers SDK pulls in Firebase Crashlytics; once Firebase is
    // initialized this plugin is required or the app crashes on launch.
    id("com.google.firebase.crashlytics")
}

// Demo credentials live in the repo-root .env (git-ignored), see ../.env.example.
val dotEnv: Map<String, String> = rootProject.file("../.env").takeIf { it.exists() }?.readLines().orEmpty()
    .map { it.split("=", limit = 2) }
    .filter { it.size == 2 && !it[0].trimStart().startsWith("#") }
    .associate { (key, value) -> key.trim() to value.trim() }

android {
    namespace = "com.meetinglawyers.sample"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.meetinglawyers.sdk.sample"
        minSdk = 23
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        listOf("ML_API_KEY", "ML_USER_ID", "ML_ENVIRONMENT").forEach { key ->
            buildConfigField("String", key, "\"${dotEnv[key].orEmpty()}\"")
        }
    }

    buildFeatures {
        buildConfig = true
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {

    // sample dependencies
    implementation("com.meetinglawyers:sdk:2.1.15")
    implementation(platform("com.google.firebase:firebase-bom:32.7.1"))
    implementation("com.google.firebase:firebase-messaging")

    // android base dependencies
    implementation("androidx.core:core-ktx:1.9.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")

    // android test dependencies
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}