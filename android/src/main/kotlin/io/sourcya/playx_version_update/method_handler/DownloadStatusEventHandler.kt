package io.sourcya.playx_version_update.method_handler

import io.flutter.plugin.common.EventChannel
import io.sourcya.playx_version_update.core.manger.UpdateManger
import io.sourcya.playx_version_update.core.model.DownloadInfo
import io.sourcya.playx_version_update.core.model.DownloadStatus
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch

class DownloadStatusEventHandler (private val updateManger: UpdateManger) : EventChannel.StreamHandler {


    private var eventSink : EventChannel.EventSink? = null
    private var job:Job? = null
    private val coroutineScope = CoroutineScope(Dispatchers.Main )



    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        job= coroutineScope.launch {
            updateManger.getDownloadInfoStateFlow().collectLatest {
                events?.success(it.toJson())
            }
        }
    }


    override fun onCancel(arguments: Any?) {
        eventSink= null
        job?.cancel()
        job= null
    }



}