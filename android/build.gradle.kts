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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    afterEvaluate {
        extensions.findByName("android")?.let { androidExtension ->
            val extensionClass = androidExtension.javaClass
            val getNamespace = extensionClass.methods.firstOrNull {
                it.name == "getNamespace" && it.parameterCount == 0
            }
            val setNamespace = extensionClass.methods.firstOrNull {
                it.name == "setNamespace" && it.parameterCount == 1
            }

            if (getNamespace != null && setNamespace != null) {
                val namespaceValue = getNamespace.invoke(androidExtension) as? String
                if (namespaceValue.isNullOrBlank()) {
                    setNamespace.invoke(androidExtension, project.group.toString())
                }
            }
        }
    }
}
