android {
    namespace = "com.example.gansh_todo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
    }
}

dependencies {
    implementation(platform("org.jetbrains.kotlin:kotlin-bom:1.9.22"))
    implementation("androidx.core:core-ktx:1.12.0")
    // Exclude sign_in_with_apple
    configurations.all {
        exclude(group = "com.aboutyou.dart_packages", module = "sign_in_with_apple")
    }
}

flutter {
    // ... existing code ...
} 