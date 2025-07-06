package io.sourcya.playx_version_update.method_handler

import android.app.Activity
import android.content.Intent
import com.google.android.play.core.install.model.ActivityResult.RESULT_IN_APP_UPDATE_FAILED
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.sourcya.playx_version_update.core.manger.UpdateManger
import io.sourcya.playx_version_update.core.model.ActivityNotFoundException
import io.sourcya.playx_version_update.core.model.PlayxAppUpdateType
import io.sourcya.playx_version_update.core.model.PlayxUpdateException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class PlayxMethodCallHandler : MethodChannel.MethodCallHandler{


    /// The MethodChannel that will the communication between Flutter and native Android
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private var channel: MethodChannel? = null
    private var downloadStatusEventChannel: EventChannel? =null


    private var binding: FlutterPlugin.FlutterPluginBinding? = null
    private var activity: Activity? = null

    private lateinit var updateManger :UpdateManger

    private var startedFlexibleUpdateResult: MethodChannel.Result? = null
    private var startedImmediateUpdateResult: MethodChannel.Result? = null


    private val job = Job()
    private val coroutineScope = CoroutineScope(Dispatchers.IO + job)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {

        when (call.method) {
            GET_UPDATE_AVAILABILITY -> getUpdateAvailability(result)

            GET_UPDATE_STALENESS_DAYS -> getUpdateStalenessDays(result)

            GET_UPDATE_PRIORITY -> getUpdatePriority(result)

            IS_UPDATE_ALLOWED -> isUpdateAllowed(call, result)

            START_IMMEDIATE_UPDATE -> startImmediateUpdate(result)
            START_FLEXIBLE_UPDATE -> startFlexibleUpdate(result)

            COMPLETE_FLEXIBLE_UPDATE -> completeFlexibleUpdate(result)

            IS_FLEXIBLE_UPDATE_NEED_TO_BE_INSTALLED -> isFlexibleUpdateNeedToBeInstalled(result)

            REFRESH_PLAYX_UPDATE -> refresh(result)

            else -> result.notImplemented()
        }


    }


    //Check for update availability:
    //checks if there is an update available for your app.
    private fun getUpdateAvailability(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val updateAvailability = updateManger.getUpdateAvailability()
                result.success(updateAvailability.ordinal)
            } catch (e: Exception) {
                handleMethodException(e, result)
            }
        }

    }


    // check the number of days since the update became available on the Play Store
    //If an update is available or in progress, this method returns the number of days
    // since the Google Play Store app on the user's device has learnt about an available update.
    //If update is not available, or if staleness information is unavailable, this method returns -1.
    private fun getUpdateStalenessDays(result: MethodChannel.Result) {

        coroutineScope.launch {
            try {
                val days = updateManger.getUpdateStalenessDays()
                result.success(days)
            } catch (e: Exception) {
                handleMethodException(e, result)
            }
        }
    }


    //The Google Play Developer API allows you to set the priority of each update.
    // This allows your app to decide how strongly to recommend an update to the user.
    //To determine priority, Google Play uses an integer value between 0 and 5, with 0 being the default and 5 being the highest priority.
    // To set the priority for an update, use the inAppUpdatePriority field under Edits.tracks.releases in the Google Play Developer API.
    // All newly-added versions in the release are considered to be the same priority as the release.
    // Priority can only be set when rolling out a new release and cannot be changed later.
    // This method returns the current priority value.
    private fun getUpdatePriority(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val priority = updateManger.getUpdatePriority()
                result.success(priority)
            } catch (e: Exception) {
                handleMethodException(e, result)
            }
        }
    }


    // Checks that the platform will allow the specified type of update.
    private fun isUpdateAllowed(call: MethodCall, result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val typeIndex = call.argument(IS_UPDATE_ALLOWED_TYPE_KEY) as Int?
                val type = PlayxAppUpdateType.fromUpdateType(typeIndex)
                val isUpdateAllowed = updateManger.isUpdateAllowed(type)
                result.success(isUpdateAllowed)
            } catch (e: Exception) {
                handleMethodException(e, result)
            }
        }
    }

    //Starts immediate update flow.
    //In the immediate flow, the method returns one of the following values:
    //Boolean [success]: The user accepted and the update succeeded (which, in practice, your app never should never receive because it already updated).
    //ActivityNotFoundException : When the user started the update flow from background.
    //PlayxRequestCanceledException : The user denied or canceled the update.
    //PlayxInAppUpdateFailed: The flow failed either during the user confirmation, the download, or the installation.
    private fun startImmediateUpdate(result: MethodChannel.Result) {
        startedImmediateUpdateResult = null
        coroutineScope.launch {
            try {

                if (activity == null) {
                    handleMethodException(ActivityNotFoundException(), result)
                    return@launch
                }
                startedImmediateUpdateResult = result
                val res= updateManger.startImmediateUpdate(activity!!)
                result.success(res)
            } catch (e: Exception) {
                handleMethodException(e, result)
            }
        }
    }

    //Starts Flexible update flow.
    //In the immediate flow, the method returns one of the following values:
    //Boolean [success]: The user accepted the request to update.
    //ActivityNotFoundException : When the user started the update flow from background.
    //PlayxRequestCanceledException : The user denied the request to update.
    //PlayxInAppUpdateFailed: Something failed during the request for user confirmation. For example, the user terminates the app before responding to the request.
    private fun startFlexibleUpdate(result: MethodChannel.Result) {
        startedFlexibleUpdateResult = null
        coroutineScope.launch {
            try {
                if (activity == null) {
                    handleMethodException(ActivityNotFoundException(), result)
                    return@launch
                }
                startedFlexibleUpdateResult = result
                val  res=   updateManger.startFlexibleUpdate(activity!!)
                result.success(res);
            } catch (e: Exception) {
                handleMethodException(e, result)
            }
        }
    }




    //Install a flexible update
    //When you detect the InstallStatus.DOWNLOADED state, you need to restart the app to install the update.
    //
    //Unlike with immediate updates, Google Play does not automatically trigger an app restart for a flexible update.
    // This is because during a flexible update, the user has an expectation to continue interacting with the app until they decide that they want to install the update.
    //
    //It is recommended that you provide a notification (or some other UI indication) to inform the user that the update is ready to install and request confirmation before restarting the app.
    private fun completeFlexibleUpdate(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val isUpdated = updateManger.completeFlexibleUpdate()
                result.success(isUpdated)
            } catch (e: Exception) {
                handleMethodException(e, result)
            }
        }

    }


    //Whether or not the flexible update is ready to install .
    private fun isFlexibleUpdateNeedToBeInstalled(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val isUpdateNeedToBeInstalled = updateManger.isFlexibleUpdateNeedToBeInstalled()
                result.success(isUpdateNeedToBeInstalled)
            } catch (e: Exception) {
                handleMethodException(e, result)
            }
        }

    }


    // refreshes app update manger
    //Each Update manger instance can be used only in a single call to this method.
    // If you need to call it multiple times - for instance, when retrying to start a flow in case of failure - you need to get a fresh Update manger.
    private fun refresh(result: MethodChannel.Result){
        val context = binding?.applicationContext
        if (context == null) {
            handleMethodException(ActivityNotFoundException(), result)
            return
        }
        updateManger.stopListening()
        updateManger = UpdateManger(context)
        downloadStatusEventChannel?.setStreamHandler(null)
        downloadStatusEventChannel?.setStreamHandler(DownloadStatusEventHandler(updateManger))

        result.success(true)

    }

    /**
     * Registers this instance as a method call handler on the given `messenger`.
     * Stops any previously started and unstopped calls.
     * This should be cleaned with [.stopListening] once the messenger is disposed of.
     */
    fun startListening(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        if (channel != null) stopListening()
        updateManger = UpdateManger(flutterPluginBinding.applicationContext)
        binding = flutterPluginBinding
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, PLAYX_METHOD_CHANNEL_NAME)
        channel?.setMethodCallHandler(this)
        downloadStatusEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, DOWNLOAD_EVENT_CHANNEL_NAME )
        downloadStatusEventChannel?.setStreamHandler(DownloadStatusEventHandler(updateManger))

    }

    /**
     * Clears this instance from listening to method calls.
     * Does nothing if [.startListening] hasn't been called, or if we're already stopped.
     */
    fun stopListening() {
        channel?.setMethodCallHandler(null)
        channel = null
        downloadStatusEventChannel?.setStreamHandler(null)
        downloadStatusEventChannel= null
        job.cancel()
        coroutineScope.cancel()
        updateManger.stopListening()
        binding = null
    }


    //attached to activity
    fun startListeningToActivity(binding: ActivityPluginBinding) {
        this.activity = binding.activity
    }


    fun stopListeningToActivity() {
        activity = null
    }

    fun handleOnResume() {
        updateManger.handleOnResume(activity)
        downloadStatusEventChannel?.setStreamHandler(DownloadStatusEventHandler(updateManger))

    }

    fun handleOnPause() {
        downloadStatusEventChannel?.setStreamHandler(null)


    }

    private fun handleMethodException(e: Exception, result: MethodChannel.Result) {
        if (e is PlayxUpdateException) {
            result.error(e.errorCode(), e.message, e)
        } else {
            result.error("DEFAULT_FAILURE_ERROR", e.message, e)
        }
    }



    companion object {
        const val PLAYX_METHOD_CHANNEL_NAME = "PLAYX_METHOD_CHANNEL_NAME"
        const val DOWNLOAD_EVENT_CHANNEL_NAME = "DOWNLOAD_EVENT_CHANNEL_NAME"

        const val GET_UPDATE_AVAILABILITY = "GET_UPDATE_AVAILABILITY"

        const val GET_UPDATE_STALENESS_DAYS = "GET_UPDATE_STALENESS_DAYS"

        const val GET_UPDATE_PRIORITY = "GET_UPDATE_PRIORITY"

        const val IS_UPDATE_ALLOWED = "IS_UPDATE_ALLOWED"
        const val IS_UPDATE_ALLOWED_TYPE_KEY = "IS_UPDATE_ALLOWED_TYPE_KEY"

        const val START_IMMEDIATE_UPDATE = "START_IMMEDIATE_UPDATE"
        const val START_FLEXIBLE_UPDATE = "START_FLEXIBLE_UPDATE"

        const val COMPLETE_FLEXIBLE_UPDATE = "COMPLETE_FLEXIBLE_UPDATE"

        const val IS_FLEXIBLE_UPDATE_NEED_TO_BE_INSTALLED =
            "IS_FLEXIBLE_UPDATE_NEED_TO_BE_INSTALLED"

        const val REFRESH_PLAYX_UPDATE ="REFRESH_PLAYX_UPDATE"
    }

}