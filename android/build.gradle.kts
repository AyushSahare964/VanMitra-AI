import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

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
    project.evaluationDependsOn(":app")
}

// Set KotlinCompile JVM target for all plugin subprojects.
//
// Rationale: different plugins ship with different Kotlin JVM targets (11, 17, 21).
// We normalize them all to JVM_17.
//
// For plugins whose Java compileOptions is also 17 (cloud_functions, etc.): exact match.
// For plugins whose Java compileOptions is 11 (flutter_image_compress_common, etc.):
//   a warning is logged (not an error) because gradle.properties sets
//   kotlin.jvm.target.validation.mode=WARNING — the build proceeds normally.
//
// We use gradle.projectsEvaluated so this runs AFTER all AGP afterEvaluate hooks.
// We never touch JavaCompile tasks (doing so breaks the Android SDK classpath for
// geolocator_android — "package android.content does not exist").
gradle.projectsEvaluated {
    subprojects {
        // :app sets JVM_17 for both Java and Kotlin inside android/app/build.gradle.kts.
        if (project.name == "app") return@subprojects

        tasks.withType<KotlinCompile>().configureEach {
            compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}