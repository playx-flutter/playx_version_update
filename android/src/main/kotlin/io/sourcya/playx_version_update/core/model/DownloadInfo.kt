package io.sourcya.playx_version_update.core.model

import com.google.android.play.core.install.model.InstallStatus
import org.json.JSONObject

data class DownloadInfo (    private val status: DownloadStatus,
                             private val bytesDownloaded:Long,
                             private val totalBytesToDownload: Long,
                             private val installErrorCode:Int,
) {


    fun toJson(): String {
        val map = mapOf(
            "status" to status.ordinal,
            "bytesDownloaded" to bytesDownloaded,
            "totalBytesToDownload" to totalBytesToDownload,
            "installErrorCode" to installErrorCode
        )

        return JSONObject(map).toString()
    }
}


    enum class DownloadStatus {
        UNKNOWN,
        PENDING,
        DOWNLOADING,
        DOWNLOADED,
        INSTALLING,
        INSTALLED,
        FAILED,
        CANCELED;


        companion object {

            fun from(value: Int): DownloadStatus {
                return when (value) {
                    InstallStatus.UNKNOWN -> UNKNOWN
                    InstallStatus.PENDING -> PENDING
                    InstallStatus.DOWNLOADING -> DOWNLOADING
                    InstallStatus.DOWNLOADED -> DOWNLOADED
                    InstallStatus.INSTALLING -> INSTALLING
                    InstallStatus.INSTALLED -> INSTALLED
                    InstallStatus.FAILED -> FAILED
                    InstallStatus.CANCELED -> CANCELED
                    else -> UNKNOWN
                }
            }
        }
    }
