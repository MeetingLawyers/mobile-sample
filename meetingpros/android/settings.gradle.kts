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
        // MeetingDoctors SDKs (public)
        maven { url = uri("https://storage.googleapis.com/production-mobile-sdks/android/") }
        // MeetingLawyers SDK (public)
        maven {
            url = uri("https://sdk-download.meetinglawyers.com/android/maven/")
            content { includeGroup("com.meetinglawyers") }
        }
    }
}

rootProject.name = "MeetingPros Sample"
include(":app")
 