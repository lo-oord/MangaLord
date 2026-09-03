package com.mlord.app.app.settings.storage.directories

import com.mlord.app.app.app.list.ui.model.ListModel
import java.io.File

data class DirectoryConfigModel(
    val title: String,
    val path: File,
    val isDefault: Boolean,
    val isAppPrivate: Boolean,
    val isAccessible: Boolean,
    val size: Long,
    val available: Long,
) : ListModel {

    override fun areItemsTheSame(other: ListModel): Boolean {
        return other is DirectoryConfigModel && path == other.path
    }
}
