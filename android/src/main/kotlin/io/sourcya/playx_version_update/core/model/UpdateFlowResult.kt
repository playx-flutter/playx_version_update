package io.sourcya.playx_version_update.core.model

import android.app.Activity
import com.google.android.play.core.install.model.ActivityResult

/**
 * Translates the result code of `AppUpdateManager.startUpdateFlow` into the outcome reported to
 * Dart.
 *
 * - [Activity.RESULT_OK]: the user accepted the update.
 * - [Activity.RESULT_CANCELED]: the user denied or cancelled it.
 * - [ActivityResult.RESULT_IN_APP_UPDATE_FAILED]: the flow failed.
 */
object UpdateFlowResult {

    /**
     * Returns `true` when the user accepted the update.
     *
     * @throws PlayxUpdateCanceledException if the user denied or cancelled the update.
     * @throws PlayxInAppUpdateFailedException if the flow failed (or returned an unknown code).
     */
    fun toStarted(resultCode: Int): Boolean = when (resultCode) {
        Activity.RESULT_OK -> true
        Activity.RESULT_CANCELED -> throw PlayxUpdateCanceledException()
        ActivityResult.RESULT_IN_APP_UPDATE_FAILED -> throw PlayxInAppUpdateFailedException()
        else -> throw PlayxInAppUpdateFailedException()
    }
}
