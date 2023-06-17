package io.sourcya.playx_version_update
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.LifecycleOwner

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.HiddenLifecycleReference
import io.sourcya.playx_version_update.method_handler.PlayxMethodCallHandler

/** PlayxVersionUpdatePlugin */
class PlayxVersionUpdatePlugin : FlutterPlugin, ActivityAware, LifecycleEventObserver {

    private var playxMethodCallHandler: PlayxMethodCallHandler? = null

    private var lifecycle:Lifecycle? = null
    private var activityBinding: ActivityPluginBinding? =null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        playxMethodCallHandler = PlayxMethodCallHandler().apply {
            startListening(flutterPluginBinding)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        playxMethodCallHandler?.stopListening()
        playxMethodCallHandler = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding= binding
        playxMethodCallHandler?.startListeningToActivity(binding)
        playxMethodCallHandler?.let { binding.addActivityResultListener(it) }
        lifecycle = (binding.lifecycle as HiddenLifecycleReference).lifecycle
        lifecycle?.addObserver(this)


    }

    override fun onDetachedFromActivity() {
        activityBinding= null
        playxMethodCallHandler?.stopListeningToActivity()
        playxMethodCallHandler?.let { activityBinding?.removeActivityResultListener(it) }
        lifecycle?.removeObserver(this)

    }


    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()

    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)

    }


    //handle lifecycle of the app used to handle onPause and onResume
    override fun onStateChanged(source: LifecycleOwner, event: Lifecycle.Event) {
        if(event == Lifecycle.Event.ON_RESUME) playxMethodCallHandler?.handleOnResume()
        else if (event == Lifecycle.Event.ON_PAUSE) playxMethodCallHandler?.handleOnPause()
    }

}
