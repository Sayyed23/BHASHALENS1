allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // Only redirect build dir for subprojects on the same drive root (Windows cross-drive fix)
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    val subprojectRoot = project.projectDir.toPath().root
    val buildRoot = newSubprojectBuildDir.asFile.toPath().root
    if (subprojectRoot == buildRoot) {
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
