plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.ksp)
    id("jacoco")
}

android {
    namespace = "com.shamelagpt.android"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.shamelagpt.android"
        minSdk = 26
        targetSdk = 35
        versionCode = 4
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            ndk {
                debugSymbolLevel = "full"
            }
        }
        debug {
            // Enable coverage for unit + androidTest
            enableUnitTestCoverage = true
            enableAndroidTestCoverage = true
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    buildFeatures {
        compose = true
        buildConfig = true
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
            excludes += "META-INF/LICENSE.md"
            excludes += "META-INF/LICENSE-notice.md"
        }
    }

    testOptions {
        unitTests.isReturnDefaultValues = true
    }
}

// JaCoCo coverage reports for unit and instrumentation tests
tasks.register<JacocoReport>("jacocoTestReport") {
    dependsOn("testDebugUnitTest")
    reports {
        xml.required.set(true)
        html.required.set(true)
    }
    val fileFilter = listOf(
        "**/R.class", "**/R$*.class", "**/BuildConfig.*",
        "**/Manifest*.*", "**/*Test*.*", "android/**/*.*",
        "**/*\$Lambda$*.*", "**/*\$inlined$*.*"
    )
    val debugTree = fileTree("${buildDir}/intermediates/javac/debug") {
        exclude(fileFilter)
    } + fileTree("${buildDir}/tmp/kotlin-classes/debug") {
        exclude(fileFilter)
    }
    classDirectories.setFrom(debugTree)
    sourceDirectories.setFrom(files("src/main/java", "src/main/kotlin"))
    executionData.setFrom(
        fileTree("${buildDir}/outputs/unit_test_code_coverage/debugUnitTest") {
            include("**/*.exec", "**/*.ec")
        }
    )
}

tasks.register<JacocoReport>("jacocoAndroidTestReport") {
    dependsOn("connectedDebugAndroidTest")
    reports {
        xml.required.set(true)
        html.required.set(true)
    }
    val fileFilter = listOf(
        "**/R.class", "**/R$*.class", "**/BuildConfig.*",
        "**/Manifest*.*", "**/*Test*.*", "android/**/*.*",
        "**/*\$Lambda$*.*", "**/*\$inlined$*.*"
    )
    val kotlinClasses = fileTree("${buildDir}/tmp/kotlin-classes/debug") { exclude(fileFilter) }
    val javaClasses = fileTree("${buildDir}/intermediates/javac/debug") { exclude(fileFilter) }
    classDirectories.setFrom(kotlinClasses, javaClasses)
    sourceDirectories.setFrom(files("src/main/java", "src/main/kotlin"))
    executionData.setFrom(
        fileTree("${buildDir}/outputs/code_coverage/debugAndroidTest/connected") {
            include("**/*.ec")
        }
    )
}

tasks.register<JacocoReport>("jacocoCombinedReport") {
    dependsOn("testDebugUnitTest", "connectedDebugAndroidTest")
    reports {
        xml.required.set(true)
        html.required.set(true)
    }
    val fileFilter = listOf(
        "**/R.class", "**/R$*.class", "**/BuildConfig.*",
        "**/Manifest*.*", "**/*Test*.*", "android/**/*.*",
        "**/*\$Lambda$*.*", "**/*\$inlined$*.*"
    )
    val kotlinClasses = fileTree("${buildDir}/tmp/kotlin-classes/debug") { exclude(fileFilter) }
    val javaClasses = fileTree("${buildDir}/intermediates/javac/debug") { exclude(fileFilter) }
    classDirectories.setFrom(kotlinClasses, javaClasses)
    sourceDirectories.setFrom(files("src/main/java", "src/main/kotlin"))
    executionData.setFrom(
        fileTree(buildDir) {
            include(
                "outputs/unit_test_code_coverage/debugUnitTest/**/*.exec",
                "outputs/unit_test_code_coverage/debugUnitTest/**/*.ec",
                "outputs/code_coverage/debugAndroidTest/connected/**/*.ec"
            )
        }
    )
}

dependencies {
    // Core
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.activity.compose)

    // Compose
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.graphics)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.navigation.compose)

    // Koin (Dependency Injection)
    implementation(libs.koin.android)
    implementation(libs.koin.androidx.compose)

    // Retrofit (Networking)
    implementation(libs.retrofit)
    implementation(libs.retrofit.converter.gson)
    implementation(libs.okhttp.logging.interceptor)

    // Room (Database)
    implementation(libs.room.runtime)
    implementation(libs.room.ktx)
    ksp(libs.room.compiler)

    // Kotlin Serialization
    implementation(libs.kotlinx.serialization.json)

    // Coroutines
    implementation(libs.kotlinx.coroutines.android)

    // Markdown / RichText
    implementation(libs.richtext.ui.material3)
    implementation(libs.richtext.commonmark)

    // ML Kit Text Recognition (use 16.0.1+ for 16KB page size compatibility)
    implementation("com.google.mlkit:text-recognition:16.0.1")

    // CameraX - Required workaround for 16KB page size compatibility on Android 15+
    // CameraX 1.4.2+ includes 16KB-aligned native libraries that override ML Kit's non-compliant ones
    implementation("androidx.camera:camera-core:1.4.2")

    // Google Play Services Tasks (for ML Kit)
    implementation("com.google.android.gms:play-services-tasks:18.1.0")

    // Kotlinx Coroutines Play Services (for await() extension)
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.7.3")

    // Material Icons Extended
    implementation("androidx.compose.material:material-icons-extended:1.6.1")

    // Chrome Custom Tabs
    implementation("androidx.browser:browser:1.7.0")

    // Splash Screen
    implementation("androidx.core:core-splashscreen:1.0.1")

    // Material Components (for Theme.Material3.DayNight.NoActionBar in XML)
    implementation("com.google.android.material:material:1.11.0")

    // Testing - Unit Tests
    testImplementation(libs.junit)
    testImplementation(libs.mockk)
    testImplementation(libs.mockk.agent)
    testImplementation(libs.turbine)
    testImplementation(libs.truth)
    testImplementation(libs.kotlinx.coroutines.test)
    testImplementation(libs.androidx.arch.core.testing)
    testImplementation(libs.koin.test)
    testImplementation(libs.koin.test.junit4)
    testImplementation(libs.room.testing)
    testImplementation(libs.mockwebserver)

    // Testing - Instrumented Tests
    androidTestImplementation(libs.androidx.junit)
    androidTestImplementation(libs.androidx.espresso.core)
    androidTestImplementation(platform(libs.androidx.compose.bom))
    androidTestImplementation(libs.androidx.compose.ui.test.junit4)
    androidTestImplementation(libs.mockk.android)
    androidTestImplementation(libs.kotlinx.coroutines.test)
    androidTestImplementation(libs.androidx.arch.core.testing)
    androidTestImplementation(libs.koin.test)
    androidTestImplementation(libs.koin.test.junit4)
    androidTestImplementation(libs.room.testing)
    androidTestImplementation(libs.truth)

    // Debug
    debugImplementation(libs.androidx.compose.ui.tooling)
    debugImplementation(libs.androidx.compose.ui.test.manifest)
}
