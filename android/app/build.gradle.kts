import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: environment variables (CI) first, then android/key.properties (local).
// Neither file nor secrets are ever committed. See docs/release-process.md.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) FileInputStream(file).use { load(it) }
}

fun signingValue(env: String, property: String): String? =
    System.getenv(env)?.takeIf { it.isNotBlank() } ?: keystoreProperties.getProperty(property)

val releaseKeystore = signingValue("ANUVAAD_KEYSTORE_PATH", "storeFile")

android {
    namespace = "app.anuvaad"
    compileSdk = 37 // permission_handler_android requires compiling against API 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Placeholder until the owner confirms the final App ID (design Q1). Changing it after
        // the first published release would break updates.
        applicationId = "app.anuvaad"
        minSdk = 29
        targetSdk = flutter.targetSdkVersion
        // Release builds pass -P force-version-code-ignoring-abi=true so split APKs keep the
        // pubspec build number as their versionCode (the updater compares build numbers).
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (releaseKeystore != null) {
                storeFile = file(releaseKeystore)
                storePassword = signingValue("ANUVAAD_KEYSTORE_PASSWORD", "storePassword")
                keyAlias = signingValue("ANUVAAD_KEY_ALIAS", "keyAlias")
                keyPassword = signingValue("ANUVAAD_KEY_PASSWORD", "keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

// Never fall back to the debug key for a release build: a debug-signed APK could not be
// updated by later releases.
gradle.taskGraph.whenReady {
    val buildsRelease = allTasks.any { it.project == project && it.name.contains("Release") }
    if (buildsRelease && releaseKeystore == null) {
        throw GradleException("Release signing is not configured. See docs/release-process.md.")
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

dependencies {
    implementation("androidx.core:core-ktx:1.17.0") // FileProvider for update APKs
}
