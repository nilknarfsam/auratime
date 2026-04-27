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

    fun applyFallbackNamespace() {
        val androidExtension = project.extensions.findByName("android") ?: return
        val namespace = androidExtension.javaClass.getMethod("getNamespace").invoke(androidExtension) as? String
        if (namespace.isNullOrBlank()) {
            androidExtension.javaClass
                .getMethod("setNamespace", String::class.java)
                .invoke(androidExtension, project.group.toString())
        }
    }

    plugins.withId("com.android.library") { applyFallbackNamespace() }
    plugins.withId("com.android.application") { applyFallbackNamespace() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
