package io.sourcya.playx_version_update.core.model


enum class PlayxAppUpdateType {

    FLEXIBLE,
    IMMEDIATE;

    companion object {
        fun fromUpdateType(value: Int?): PlayxAppUpdateType? {
            if(value == null || value >= PlayxAppUpdateType.values().size) return null
            return  PlayxAppUpdateType.values()[value]
        }


    }
}