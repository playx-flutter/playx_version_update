package io.sourcya.playx_version_update.core.model

import com.google.android.play.core.install.model.InstallErrorCode

/**
 * Base sealed class for all exceptions related to Playx version update operations.
 * Each specific exception should extend this class and provide an [errorCode].
 */
sealed class PlayxUpdateException : Exception() {
    /**
     * A unique string code representing the type of error.
     */
    abstract fun errorCode(): String
}

/**
 * Exception thrown when the required Android Activity is not available (e.g., the app is not in the foreground).
 */
class ActivityNotFoundException : PlayxUpdateException() {
    override val message: String = "Activity is not available. The app must be in Foreground."
    override fun errorCode() = "ACTIVITY_NOT_FOUND"
}

/**
 * Exception thrown when an in-app update operation was explicitly cancelled by the user.
 */
class PlayxUpdateCanceledException : PlayxUpdateException() {
    override val message: String = "Update was cancelled."
    override fun errorCode() = "PLAYX_UPDATE_CANCELLED"
}

class PlayxUpdateNotAvailable : PlayxUpdateException() {

    override val message: String = "Update is not available."

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


/**
 * A sealed class representing specific errors that can occur during the installation
 * phase of a Play In-App Update, mapped directly to [InstallErrorCode] status codes.
 *
 * Each subclass encapsulates a distinct installation error, allowing for precise
 * error handling using `when` expressions.
 *
 * @param statusCode The integer status code from [InstallErrorCode].
 * @param message A human-readable description of the error.
 */
sealed class PlayxInstallError(
    val statusCode: Int,
    override val message: String
) : PlayxUpdateException() {

    // Removed the default errorCode() implementation here,
    // as each subclass will now provide its own.

    /**
     * The API is not available on this device.
     * Corresponds to [InstallErrorCode.ERROR_API_NOT_AVAILABLE].
     */
    class ApiNotAvailable : PlayxInstallError(
        InstallErrorCode.ERROR_API_NOT_AVAILABLE,
        "The Play In-App Update API is not available on this device for installation."
    ) {
        override fun errorCode() = "INSTALL_API_NOT_AVAILABLE"
    }

    /**
     * The app is not owned by any user on this device.
     * Corresponds to [InstallErrorCode.ERROR_APP_NOT_OWNED].
     */
    class AppNotOwned : PlayxInstallError(
        InstallErrorCode.ERROR_APP_NOT_OWNED,
        "The app is not owned by any user on this device (e.g., app installed from side-loaded APK)."
    ) {
        override fun errorCode() = "INSTALL_APP_NOT_OWNED"
    }

    /**
     * The install/update has not been (fully) downloaded yet.
     * Corresponds to [InstallErrorCode.ERROR_DOWNLOAD_NOT_PRESENT].
     */
    class DownloadNotPresent : PlayxInstallError(
        InstallErrorCode.ERROR_DOWNLOAD_NOT_PRESENT,
        "The install/update has not been (fully) downloaded yet. Ensure the flexible update is downloaded before trying to complete installation."
    ) {
        override fun errorCode() = "INSTALL_DOWNLOAD_NOT_PRESENT"
    }

    /**
     * The install is already in progress and there is no UI flow to resume.
     * Corresponds to [-8].
     */
    class InstallInProgress : PlayxInstallError(
        -8,
        "The install is already in progress and there is no UI flow to resume."
    ) {
        override fun errorCode() = "INSTALL_IN_PROGRESS"
    }

    /**
     * The download/install is not allowed, due to the current device state.
     * Corresponds to [InstallErrorCode.ERROR_INSTALL_NOT_ALLOWED].
     */
    class InstallNotAllowed : PlayxInstallError(
        InstallErrorCode.ERROR_INSTALL_NOT_ALLOWED,
        "The download/install is not allowed due to the current device state (e.g., insufficient storage, network restrictions, or system policy)."
    ) {
        override fun errorCode() = "INSTALL_NOT_ALLOWED"
    }

    /**
     * The install is unavailable to this user or device.
     * Corresponds to [InstallErrorCode.ERROR_INSTALL_UNAVAILABLE].
     */
    class InstallUnavailable : PlayxInstallError(
        InstallErrorCode.ERROR_INSTALL_UNAVAILABLE,
        "The install is unavailable to this user or device (e.g., not a primary user, or a restricted profile)."
    ) {
        override fun errorCode() = "INSTALL_UNAVAILABLE"
    }

    /**
     * An internal error happened in the Play Store.
     * Corresponds to [InstallErrorCode.ERROR_INTERNAL_ERROR].
     */
    class InternalError : PlayxInstallError(
        InstallErrorCode.ERROR_INTERNAL_ERROR,
        "An internal error happened in the Play Store during installation."
    ) {
        override fun errorCode() = "INSTALL_INTERNAL_ERROR"
    }

    /**
     * The request that was sent by the app is malformed.
     * Corresponds to [InstallErrorCode.ERROR_INVALID_REQUEST].
     */
    class InvalidRequest : PlayxInstallError(
        InstallErrorCode.ERROR_INVALID_REQUEST,
        "The request sent by the app for installation is malformed (e.g., invalid arguments)."
    ) {
        override fun errorCode() = "INSTALL_INVALID_REQUEST"
    }

    /**
     * The Play Store app is either not installed or not the official version.
     * Corresponds to [InstallErrorCode.ERROR_PLAY_STORE_NOT_FOUND].
     */
    class PlayStoreNotFound : PlayxInstallError(
        InstallErrorCode.ERROR_PLAY_STORE_NOT_FOUND,
        "The Play Store app is either not installed or not the official version on this device, preventing installation."
    ) {
        override fun errorCode() = "INSTALL_PLAY_STORE_NOT_FOUND"
    }

    /**
     * An unknown error occurred.
     * Corresponds to [InstallErrorCode.ERROR_UNKNOWN].
     */
    class UnknownInstallError (statusCode: Int): PlayxInstallError(
        InstallErrorCode.ERROR_UNKNOWN,
        "An unknown error occurred during installation. $statusCode"
    ) {
        override fun errorCode() = "INSTALL_UNKNOWN_ERROR"
    }


    companion object {
        /**
         * Creates a [PlayxInstallError] instance based on the given [statusCode].
         * This factory method helps in mapping the integer code to the specific sealed class instance.
         */
        fun fromStatusCode(statusCode: Int): PlayxInstallError {
            return when (statusCode) {
                InstallErrorCode.ERROR_API_NOT_AVAILABLE -> ApiNotAvailable()
                InstallErrorCode.ERROR_APP_NOT_OWNED -> AppNotOwned()
                InstallErrorCode.ERROR_DOWNLOAD_NOT_PRESENT -> DownloadNotPresent()
                -8 -> InstallInProgress()
                InstallErrorCode.ERROR_INSTALL_NOT_ALLOWED -> InstallNotAllowed()
                InstallErrorCode.ERROR_INSTALL_UNAVAILABLE -> InstallUnavailable()
                InstallErrorCode.ERROR_INTERNAL_ERROR -> InternalError()
                InstallErrorCode.ERROR_INVALID_REQUEST -> InvalidRequest()
                InstallErrorCode.ERROR_PLAY_STORE_NOT_FOUND -> PlayStoreNotFound()
                InstallErrorCode.ERROR_UNKNOWN -> UnknownInstallError(statusCode)
                else -> UnknownInstallError(statusCode)
            }
        }
    }
}