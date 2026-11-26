import java.net.URI
import java.util.zip.ZipFile

group = "top.tau2c.pds.flutter.pds_flutter"
version = "1.0-SNAPSHOT"

buildscript {
    val kotlinVersion = "2.2.20"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.11.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

val pdsClientVersion = "v0.9.0-dev.3"
val libsDir = layout.projectDirectory.dir("libs").asFile
libsDir.mkdirs()

val releaseUrl = "https://github.com/PDS-PersonalDataStore/pds-android/releases/download/$pdsClientVersion/client-sdk-release.aar"
val aarFile = libsDir.resolve("client-sdk-release.aar")
val jarFile = libsDir.resolve("client-sdk.jar")

if (!jarFile.exists()) {
    if (!aarFile.exists()) {
        URI(releaseUrl).toURL().openStream().use { input ->
            aarFile.outputStream().use { output ->
                input.copyTo(output)
            }
        }
    }
    ZipFile(aarFile).use { zip ->
        val entry = zip.getEntry("classes.jar") ?: error("classes.jar not found in $aarFile")
        zip.getInputStream(entry).use { input ->
            jarFile.outputStream().use { output ->
                input.copyTo(output)
            }
        }
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
    id("kotlin-android")
}

android {
    namespace = "top.tau2c.pds.flutter.pds_flutter"

    compileSdk = 36

    buildFeatures {
        aidl = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            all {
                it.useJUnitPlatform()

                it.outputs.upToDateWhen { false }

                it.testLogging {
                    events("passed", "skipped", "failed", "standardOut", "standardError")
                    showStandardStreams = true
                }
            }
        }
    }
}

dependencies {
    implementation(files(jarFile))
    implementation("org.bouncycastle:bcprov-jdk18on:1.80")
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")
    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testImplementation("org.mockito:mockito-core:5.0.0")
}
