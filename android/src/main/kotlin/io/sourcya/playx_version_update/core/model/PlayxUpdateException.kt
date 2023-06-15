package io.sourcya.playx_version_update.core.model

sealed class PlayxUpdateException : Exception() {

    abstract fun errorCode() :String
}

class ActivityNotFoundException : PlayxUpdateException() {

    override val message: String = "Activity is not available. The app must be in Foreground."

    override fun errorCode()= "ACTIVITY_NOT_FOUND"

}

class AppUpdateMangerNotFoundException : PlayxUpdateException() {

    override val message: String = "App update manger is not available."

    override fun errorCode()= "APP_UPDATE_MANGER_NOT_FOUND"

}


class PlayxRequestCanceledException : PlayxUpdateException() {

    override val message: String = "Getting update info request was cancelled."

    override fun errorCode()= "PLAYX_REQUEST_CANCELLED"
}

class PlayxUpdateNotAvailable : PlayxUpdateException() {

    override val message: String = "Update is not available. 22"

    override fun errorCode()= "PLAYX_UPDATE_NOT_AVAILABLE"
}

class PlayxUpdateInProgress : PlayxUpdateException() {

    override val message: String = "Update is currently in progress. 122"

    override fun errorCode()= "PLAYX_UPDATE_IN_PROGRESS"
}


class PlayxUpdateNotAllowed : PlayxUpdateException() {

    override val message: String = "Update is not allowed."

    override fun errorCode()= "PLAYX_UPDATE_NOT_ALLOWED"
}


class PlayxUnknownUpdateType : PlayxUpdateException() {
    override val message: String = "Unknown update type."

    override fun errorCode()= "PLAYX_UNKNOWN_UPDATE_TYPE"
}


class PlayxInAppUpdateFailed: PlayxUpdateException() {
    override val message: String = "In app update failed."

    override fun errorCode()= "PLAYX_IN_APP_UPDATE_FAILED"
}


