package io.sourcya.playx_version_update.core.model
enum class AppUpdateAvailability {
    UNKNOWN,
     NOT_AVAILABLE,
     AVAILABLE,
     IN_PROGRESS;


    companion object{
        fun fromUpdateAvailability(value: Int) = AppUpdateAvailability.values()[value]

    }
}