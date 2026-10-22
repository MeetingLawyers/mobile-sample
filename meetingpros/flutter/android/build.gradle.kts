// Credentials live in the repo-root .env (git-ignored), see ../../../.env.example.
val dotEnv: Map<String, String> = file("../../../.env").takeIf { it.exists() }?.readLines().orEmpty()
    .map { it.split("=", limit = 2) }
    .filter { it.size == 2 && !it[0].trimStart().startsWith("#") }
    .associate { (key, value) -> key.trim() to value.trim() }

fun credential(key: String): String =
    dotEnv[key]?.takeIf { it.isNotBlank() } ?: providers.gradleProperty(key).orNull ?: System.getenv(key) ?: ""

allprojects {
    repositories {
        google()
        mavenCentral()
        // MeetingDoctors SDKs (public)
        maven { url = uri("https://storage.googleapis.com/production-mobile-sdks/android/") }
        // MeetingLawyers SDK (GitHub Packages): .env first, then gradle.properties, then environment variables.
        maven {
            url = uri("https://maven.pkg.github.com/MeetingLawyers/android-sdk-chat/")
            credentials {
                username = credential("GPR_USER")
                password = credential("GPR_TOKEN")
            }
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
