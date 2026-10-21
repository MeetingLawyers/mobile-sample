pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()

    }
}
// Credentials live in the repo-root .env (git-ignored), see ../../.env.example.
val dotEnv: Map<String, String> = file("../../.env").takeIf { it.exists() }?.readLines().orEmpty()
    .map { it.split("=", limit = 2) }
    .filter { it.size == 2 && !it[0].trimStart().startsWith("#") }
    .associate { (key, value) -> key.trim() to value.trim() }

fun credential(key: String): String =
    dotEnv[key]?.takeIf { it.isNotBlank() } ?: providers.gradleProperty(key).orNull ?: System.getenv(key) ?: ""

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        // MeetingDoctors SDKs (public)
        maven { url = uri("https://storage.googleapis.com/production-mobile-sdks/android/") }
        // MeetingLawyers SDK (GitHub Packages)
        maven {
            url = uri("https://maven.pkg.github.com/MeetingLawyers/android-sdk-chat/")
            credentials {
                // .env first, then ~/.gradle/gradle.properties, then environment variables.
                username = credential("GPR_USER")
                password = credential("GPR_TOKEN")
            }
        }
    }
}

rootProject.name = "MeetingPros Sample"
include(":app")
 