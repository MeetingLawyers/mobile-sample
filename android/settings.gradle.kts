pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()

    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://maven.pkg.github.com/MeetingLawyers/android-sdk-chat/")
            credentials {
                // ask credentials to support@meetinglawyers.com and set them in
                // ~/.gradle/gradle.properties or as environment variables — never commit them.
                username = providers.gradleProperty("GPR_USER").orNull ?: System.getenv("GPR_USER") ?: ""
                password = providers.gradleProperty("GPR_TOKEN").orNull ?: System.getenv("GPR_TOKEN") ?: ""
            }
        }
    }

}

rootProject.name = "Android Sample"
include(":app")
 