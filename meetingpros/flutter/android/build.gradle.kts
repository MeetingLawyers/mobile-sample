allprojects {
    repositories {
        google()
        mavenCentral()
        // MeetingDoctors SDKs (public)
        maven { url = uri("https://storage.googleapis.com/production-mobile-sdks/android/") }
        // MeetingLawyers SDK (public)
        maven {
            url = uri("https://sdk-download.meetinglawyers.com/android/maven/")
            content { includeGroup("com.meetinglawyers") }
        }
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
