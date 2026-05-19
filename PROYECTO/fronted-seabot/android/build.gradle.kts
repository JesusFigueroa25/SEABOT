// Top-level build file for SeaBot in Kotlin DSL

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Cambiar directorio de build para limpiar estructura
val newBuildDir = rootProject.layout
    .buildDirectory
    .dir("../../build")
    .get()

rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

subprojects {
    evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
