allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    if (project.name != "app") {
        project.evaluationDependsOn(":app")
    }
    
    fun configureAndroid() {
        val android = project.extensions.findByName("android")
        if (android != null) {
            val targetSdk = 36
            
            // Try setting compileSdk
            try {
                val setCompileSdk = android.javaClass.getMethod("setCompileSdk", Int::class.javaPrimitiveType)
                setCompileSdk.invoke(android, targetSdk)
            } catch (e: Exception) {
                // Ignore
            }
            
            // Try setting compileSdkVersion (fallback for older AGP/plugins)
            try {
                val setCompileSdkVersion = android.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                setCompileSdkVersion.invoke(android, targetSdk)
            } catch (e: Exception) {
                // Ignore
            }
            
            // Try setting compileSdkVersion with String (sometimes required)
            try {
                val setCompileSdkVersion = android.javaClass.getMethod("setCompileSdkVersion", String::class.java)
                setCompileSdkVersion.invoke(android, "android-$targetSdk")
            } catch (e: Exception) {
                // Ignore
            }

            // Force Java 17 compatibility
            try {
                val getCompileOptions = android.javaClass.getMethod("getCompileOptions")
                val compileOptions = getCompileOptions.invoke(android)
                val setSourceCompatibility = compileOptions.javaClass.getMethod("setSourceCompatibility", JavaVersion::class.java)
                val setTargetCompatibility = compileOptions.javaClass.getMethod("setTargetCompatibility", JavaVersion::class.java)
                
                setSourceCompatibility.invoke(compileOptions, JavaVersion.VERSION_17)
                setTargetCompatibility.invoke(compileOptions, JavaVersion.VERSION_17)
            } catch (e: Exception) {
                // Ignore
            }

            // Suppress warnings
            project.tasks.withType(JavaCompile::class.java).configureEach {
                options.compilerArgs.add("-Xlint:-unchecked")
                options.compilerArgs.add("-Xlint:-deprecation")
                options.compilerArgs.add("-Xlint:-options")
                options.compilerArgs.add("-nowarn")
            }
        }
    }

    if (project.state.executed) {
        configureAndroid()
    } else {
        project.afterEvaluate {
            configureAndroid()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
