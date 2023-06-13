package io.sourcya.playx_version_update.core.manger

import android.app.Activity
import android.content.Context
import com.google.android.gms.tasks.Task
import com.google.android.play.core.appupdate.AppUpdateInfo
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import io.sourcya.playx_version_update.core.model.AppUpdateAvailability
import io.sourcya.playx_version_update.core.model.AppUpdateMangerNotFoundException
import io.sourcya.playx_version_update.core.model.DownloadInfo
import io.sourcya.playx_version_update.core.model.PlayxAppUpdateType
import io.sourcya.playx_version_update.core.model.PlayxRequestCanceledException
import io.sourcya.playx_version_update.core.model.PlayxUnknownUpdateType
import io.sourcya.playx_version_update.core.model.PlayxUpdateNotAllowed
import io.sourcya.playx_version_update.core.model.PlayxUpdateNotAvailable

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class UpdateManger {


    private var appUpdateInfoTask: Task<AppUpdateInfo>? = null
    private var appUpdateManager: AppUpdateManager? = null
    private val job = Job()
    private val coroutineScope = CoroutineScope(Dispatchers.IO + job)


    suspend fun getUpdateAvailability(): AppUpdateAvailability =
        suspendCancellableCoroutine { continuation ->
            // Checks that the platform will allow the specified type of update.
            if (appUpdateInfoTask == null) {
                continuation.resumeWithException(AppUpdateMangerNotFoundException())
            }

            appUpdateInfoTask?.addOnSuccessListener { appUpdateInfo ->
                val updateAvailability =
                    AppUpdateAvailability.fromUpdateAvailability(appUpdateInfo.updateAvailability())
                continuation.resume(updateAvailability)
            }?.addOnFailureListener {
                continuation.resumeWithException(it)
            }?.addOnCanceledListener {
                continuation.resumeWithException(PlayxRequestCanceledException())
            }
        }


    // check the number of days since the update became available on the Play Store
    //If an update is available or in progress, this method returns the number of days
    // since the Google Play Store app on the user's device has learnt about an available update.
    //If update is not available, or if staleness information is unavailable, this method returns -1.
    suspend fun getUpdateStalenessDays(): Int = suspendCancellableCoroutine { continuation ->
        if (appUpdateInfoTask == null) {
            continuation.resumeWithException(AppUpdateMangerNotFoundException())
        }

        appUpdateInfoTask?.addOnSuccessListener { appUpdateInfo ->
            val days = appUpdateInfo.clientVersionStalenessDays() ?: -1
            continuation.resume(days)
        }?.addOnFailureListener {
            continuation.resumeWithException(it)
        }?.addOnCanceledListener {
            continuation.resumeWithException(PlayxRequestCanceledException())
        }
    }


    //The Google Play Developer API allows you to set the priority of each update.
    // This allows your app to decide how strongly to recommend an update to the user.
    //To determine priority, Google Play uses an integer value between 0 and 5, with 0 being the default and 5 being the highest priority.
    // To set the priority for an update, use the inAppUpdatePriority field under Edits.tracks.releases in the Google Play Developer API.
    // All newly-added versions in the release are considered to be the same priority as the release.
    // Priority can only be set when rolling out a new release and cannot be changed later.
    // This method returns the current priority value.
    suspend fun getUpdatePriority(): Int = suspendCancellableCoroutine { continuation ->
        if (appUpdateInfoTask == null) {
            continuation.resumeWithException(AppUpdateMangerNotFoundException())
        }

        appUpdateInfoTask?.addOnSuccessListener { appUpdateInfo ->
            val priority = appUpdateInfo.updatePriority()
            continuation.resume(priority)
        }?.addOnFailureListener {
            continuation.resumeWithException(it)
        }?.addOnCanceledListener {
            continuation.resumeWithException(PlayxRequestCanceledException())
        }
    }


    // Checks that the platform will allow the specified type of update.
    suspend fun isUpdateAllowed(type: PlayxAppUpdateType?): Boolean =
        suspendCancellableCoroutine { continuation ->

            if (appUpdateInfoTask == null) {
                continuation.resumeWithException(AppUpdateMangerNotFoundException())
            }

            appUpdateInfoTask?.addOnSuccessListener { appUpdateInfo ->
                if (appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE) {
                    when (type) {
                        PlayxAppUpdateType.FLEXIBLE -> {
                            val isAllowed =
                                appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)
                            continuation.resume(isAllowed)
                        }

                        PlayxAppUpdateType.IMMEDIATE -> {
                            val isAllowed =
                                appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)
                            continuation.resume(isAllowed)

                        }

                        else ->
                            continuation.resumeWithException(PlayxUnknownUpdateType())

                    }
                } else {
                    continuation.resume(false)
                }
            }?.addOnFailureListener {
                continuation.resumeWithException(it)
            }?.addOnCanceledListener {
                continuation.resumeWithException(PlayxRequestCanceledException())
            }
        }

    suspend fun startImmediateUpdate(activity: Activity): Boolean? =
        suspendCancellableCoroutine { continuation ->
            if (appUpdateInfoTask == null || appUpdateManager == null) {
                continuation.resumeWithException(AppUpdateMangerNotFoundException())
            }

            appUpdateInfoTask?.addOnSuccessListener { appUpdateInfo ->
                if (appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE) {
                    val isAllowed = appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)
                    
                    if (isAllowed) {
                        
                        val isStarted = appUpdateManager?.startUpdateFlowForResult(
                            appUpdateInfo,
                            activity,
                            AppUpdateOptions.newBuilder(AppUpdateType.IMMEDIATE)
                                .setAllowAssetPackDeletion(true)
                                .build(),
                            IMMEDIATE_UPDATE_REQUEST_CODE
                        )
                        continuation.resume(isStarted)
                    } else {
                        continuation.resumeWithException(PlayxUpdateNotAllowed())
                    }
                } else {
                    continuation.resumeWithException(PlayxUpdateNotAvailable())
                }
            }?.addOnFailureListener {
                continuation.resumeWithException(it)
            }?.addOnCanceledListener {
                continuation.resumeWithException(PlayxRequestCanceledException())
            }
        }


    suspend fun startFlexibleUpdate(activity: Activity): Boolean? =
        suspendCancellableCoroutine { continuation ->
            if (appUpdateInfoTask == null || appUpdateManager == null) {
                continuation.resumeWithException(AppUpdateMangerNotFoundException())
            }
            appUpdateInfoTask?.addOnSuccessListener { appUpdateInfo ->
                if (appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE) {
                    val isAllowed = appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)
                    if (isAllowed) {
                        val isStarted = appUpdateManager?.startUpdateFlowForResult(
                            appUpdateInfo,
                            activity,
                            AppUpdateOptions.newBuilder(AppUpdateType.FLEXIBLE)
                                .setAllowAssetPackDeletion(true)
                                .build(),
                            FLEXIBLE_UPDATE_REQUEST_CODE
                        )
                        continuation.resume(isStarted)

                    } else {
                        continuation.resumeWithException(PlayxUpdateNotAllowed())
                    }
                } else {
                    continuation.resumeWithException(PlayxUpdateNotAvailable())
                }
            }?.addOnFailureListener {
                continuation.resumeWithException(it)
            }?.addOnCanceledListener {
                continuation.resumeWithException(PlayxRequestCanceledException())
            }
        }


    @OptIn(ExperimentalCoroutinesApi::class)
    fun getDownloadInfoStateFlow() = callbackFlow {

        val listener = InstallStateUpdatedListener { state ->
            launch {
                send(
                    DownloadInfo(
                        DownloadInfo.DownloadStatus.from(state.installStatus()),
                        state.bytesDownloaded(),
                        state.totalBytesToDownload(),
                        state.installErrorCode()
                    )
                )
            }
        }

        appUpdateManager?.registerListener(listener)

        awaitClose {
            appUpdateManager?.unregisterListener(listener)
        }
    }


    suspend fun completeFlexibleUpdate(): Boolean = suspendCancellableCoroutine { continuation ->
        if (appUpdateInfoTask == null || appUpdateManager == null) {
            continuation.resumeWithException(AppUpdateMangerNotFoundException())
        }
        val result = appUpdateManager?.completeUpdate()
        result?.addOnSuccessListener {
            continuation.resume(true)
        }?.addOnFailureListener {
            continuation.resumeWithException(it)
        }?.addOnCanceledListener {
            continuation.resumeWithException(PlayxRequestCanceledException())
        }
    }


    suspend fun isFlexibleUpdateNeedToBeInstalled(): Boolean =
        suspendCancellableCoroutine { continuation ->
            if (appUpdateInfoTask == null) {
                continuation.resumeWithException(AppUpdateMangerNotFoundException())
            }
            appUpdateInfoTask?.addOnSuccessListener { appUpdateInfo ->
                continuation.resume(appUpdateInfo.installStatus() == InstallStatus.DOWNLOADED)
            }?.addOnFailureListener {
                continuation.resumeWithException(it)
            }?.addOnCanceledListener {
                continuation.resumeWithException(PlayxRequestCanceledException())
            }
        }


    fun startListening(context: Context) {
        appUpdateManager = AppUpdateManagerFactory.create(context)
        appUpdateInfoTask = appUpdateManager!!.appUpdateInfo
    }


    fun stopListening() {
        appUpdateInfoTask = null
        appUpdateManager = null
        job.cancel()
        coroutineScope.cancel()
    }


    fun handleOnResume(activity: Activity?) {
        if (activity == null || appUpdateManager == null) return

        appUpdateManager?.appUpdateInfo
            ?.addOnSuccessListener { appUpdateInfo ->
                if (appUpdateInfo.updateAvailability()
                    == UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS
                ) {
                    coroutineScope.launch {
                        startImmediateUpdate(activity)
                    }
                }
            }
    }


    companion object {
        const val FLEXIBLE_UPDATE_REQUEST_CODE = 125
        const val IMMEDIATE_UPDATE_REQUEST_CODE = 126

    }


}