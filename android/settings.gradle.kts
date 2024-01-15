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
                // ask credentials to support@meetinglawyers.com
                username = ""
                password = ""
            }
        }
    }

}

rootProject.name = "Android Sample"
include(":app")
 