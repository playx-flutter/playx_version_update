package io.sourcya.playx_version_update

import android.app.Activity
import com.google.android.play.core.install.model.ActivityResult
import com.google.android.play.core.install.model.InstallErrorCode
import com.google.android.play.core.install.model.InstallStatus
import io.sourcya.playx_version_update.core.model.AppUpdateAvailability
import io.sourcya.playx_version_update.core.model.DownloadInfo
import io.sourcya.playx_version_update.core.model.DownloadStatus
import io.sourcya.playx_version_update.core.model.PlayxAppUpdateType
import io.sourcya.playx_version_update.core.model.PlayxInAppUpdateFailedException
import io.sourcya.playx_version_update.core.model.PlayxInstallError
import io.sourcya.playx_version_update.core.model.PlayxUnknownUpdateType
import io.sourcya.playx_version_update.core.model.PlayxUpdateCanceledException
import io.sourcya.playx_version_update.core.model.PlayxUpdateException
import io.sourcya.playx_version_update.core.model.PlayxUpdateInProgress
import io.sourcya.playx_version_update.core.model.PlayxUpdateNotAllowed
import io.sourcya.playx_version_update.core.model.PlayxUpdateNotAvailable
import io.sourcya.playx_version_update.core.model.UpdateFlowResult
import org.json.JSONObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertIs
import kotlin.test.assertTrue

/**
 * Tests the plain Kotlin parts of the plugin: the values and error codes shared with the Dart
 * side (see `PlayxVersionUpdateError.fromInAppUpdateErrorCode` in Dart) and the translation of
 * the Play Core results. Run with `./gradlew :playx_version_update:testDebugUnitTest` from
 * `example/android`.
 */
internal class UpdateModelsTest {

    @Test
    fun updateFlowResult_acceptedIsTrue() {
        assertTrue(UpdateFlowResult.toStarted(Activity.RESULT_OK))
    }

    @Test
    fun updateFlowResult_deniedIsCancelled() {
        assertFailsWith<PlayxUpdateCanceledException> {
            UpdateFlowResult.toStarted(Activity.RESULT_CANCELED)
        }
    }

    @Test
    fun updateFlowResult_failureIsAnError_notSuccess() {
        // RESULT_IN_APP_UPDATE_FAILED is 1: it used to be reported as a started update.
        assertFailsWith<PlayxInAppUpdateFailedException> {
            UpdateFlowResult.toStarted(ActivityResult.RESULT_IN_APP_UPDATE_FAILED)
        }
        assertFailsWith<PlayxInAppUpdateFailedException> { UpdateFlowResult.toStarted(42) }
    }

    @Test
    fun errorCodes_matchTheDartSide() {
        val codes = mapOf<PlayxUpdateException, String>(
            PlayxUpdateCanceledException() to "PLAYX_UPDATE_CANCELLED",
            PlayxInAppUpdateFailedException() to "PLAYX_IN_APP_UPDATE_FAILED",
            io.sourcya.playx_version_update.core.model.ActivityNotFoundException() to "ACTIVITY_NOT_FOUND",
            PlayxUpdateNotAvailable() to "PLAYX_UPDATE_NOT_AVAILABLE",
            PlayxUpdateInProgress() to "PLAYX_UPDATE_IN_PROGRESS",
            PlayxUpdateNotAllowed() to "PLAYX_UPDATE_NOT_ALLOWED",
            PlayxUnknownUpdateType() to "PLAYX_UNKNOWN_UPDATE_TYPE",
        )
        codes.forEach { (exception, code) -> assertEquals(code, exception.errorCode()) }
    }

    @Test
    fun installErrors_mapEveryStatusCode() {
        val expected = mapOf(
            InstallErrorCode.ERROR_API_NOT_AVAILABLE to "INSTALL_API_NOT_AVAILABLE",
            InstallErrorCode.ERROR_APP_NOT_OWNED to "INSTALL_APP_NOT_OWNED",
            InstallErrorCode.ERROR_DOWNLOAD_NOT_PRESENT to "INSTALL_DOWNLOAD_NOT_PRESENT",
            -8 to "INSTALL_IN_PROGRESS",
            InstallErrorCode.ERROR_INSTALL_NOT_ALLOWED to "INSTALL_NOT_ALLOWED",
            InstallErrorCode.ERROR_INSTALL_UNAVAILABLE to "INSTALL_UNAVAILABLE",
            InstallErrorCode.ERROR_INTERNAL_ERROR to "INSTALL_INTERNAL_ERROR",
            InstallErrorCode.ERROR_INVALID_REQUEST to "INSTALL_INVALID_REQUEST",
            InstallErrorCode.ERROR_PLAY_STORE_NOT_FOUND to "INSTALL_PLAY_STORE_NOT_FOUND",
            InstallErrorCode.ERROR_UNKNOWN to "INSTALL_UNKNOWN_ERROR",
            12345 to "INSTALL_UNKNOWN_ERROR",
        )
        expected.forEach { (status, code) ->
            assertEquals(code, PlayxInstallError.fromStatusCode(status).errorCode(), "status $status")
        }
    }

    @Test
    fun updateType_indexesMatchTheDartEnum() {
        // Dart: PlayxAppUpdateType { flexible, immediate }
        assertEquals(PlayxAppUpdateType.FLEXIBLE, PlayxAppUpdateType.fromUpdateType(0))
        assertEquals(PlayxAppUpdateType.IMMEDIATE, PlayxAppUpdateType.fromUpdateType(1))
        assertEquals(null, PlayxAppUpdateType.fromUpdateType(2))
        assertEquals(null, PlayxAppUpdateType.fromUpdateType(null))
    }

    @Test
    fun availability_indexesMatchTheDartEnum() {
        // Dart: PlayxAppUpdateAvailability { unknown, notAvailable, available, inProgress }
        assertEquals(0, AppUpdateAvailability.UNKNOWN.ordinal)
        assertEquals(1, AppUpdateAvailability.NOT_AVAILABLE.ordinal)
        assertEquals(2, AppUpdateAvailability.AVAILABLE.ordinal)
        assertEquals(3, AppUpdateAvailability.IN_PROGRESS.ordinal)
    }

    @Test
    fun availability_aFutureValueIsUnknownInsteadOfCrashing() {
        assertEquals(AppUpdateAvailability.UNKNOWN, AppUpdateAvailability.fromUpdateAvailability(99))
        assertEquals(AppUpdateAvailability.UNKNOWN, AppUpdateAvailability.fromUpdateAvailability(-1))
    }

    @Test
    fun downloadStatus_indexesMatchTheDartEnum() {
        // Dart: PlayxDownloadStatus { unknown, pending, downloading, downloaded, installing,
        // installed, failed, canceled }
        val expected = listOf(
            DownloadStatus.UNKNOWN, DownloadStatus.PENDING, DownloadStatus.DOWNLOADING,
            DownloadStatus.DOWNLOADED, DownloadStatus.INSTALLING, DownloadStatus.INSTALLED,
            DownloadStatus.FAILED, DownloadStatus.CANCELED,
        )
        assertEquals(expected, DownloadStatus.values().toList())
    }

    @Test
    fun downloadStatus_mapsEveryInstallStatus() {
        assertEquals(DownloadStatus.PENDING, DownloadStatus.from(InstallStatus.PENDING))
        assertEquals(DownloadStatus.DOWNLOADING, DownloadStatus.from(InstallStatus.DOWNLOADING))
        assertEquals(DownloadStatus.DOWNLOADED, DownloadStatus.from(InstallStatus.DOWNLOADED))
        assertEquals(DownloadStatus.INSTALLING, DownloadStatus.from(InstallStatus.INSTALLING))
        assertEquals(DownloadStatus.INSTALLED, DownloadStatus.from(InstallStatus.INSTALLED))
        assertEquals(DownloadStatus.FAILED, DownloadStatus.from(InstallStatus.FAILED))
        assertEquals(DownloadStatus.CANCELED, DownloadStatus.from(InstallStatus.CANCELED))
        assertEquals(DownloadStatus.UNKNOWN, DownloadStatus.from(999))
    }

    @Test
    fun downloadInfo_jsonHasTheKeysTheDartSideReads() {
        val json = JSONObject(DownloadInfo(DownloadStatus.DOWNLOADING, 10L, 100L, 0).toJson())

        assertEquals(DownloadStatus.DOWNLOADING.ordinal, json.getInt("status"))
        assertEquals(10L, json.getLong("bytesDownloaded"))
        assertEquals(100L, json.getLong("totalBytesToDownload"))
        assertEquals(0, json.getInt("installErrorCode"))
    }

    @Test
    fun installErrors_areUpdateExceptions() {
        assertIs<PlayxUpdateException>(PlayxInstallError.fromStatusCode(InstallErrorCode.ERROR_INTERNAL_ERROR))
    }
}
