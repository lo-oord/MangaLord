package com.mlord.app.download.ui.list

import androidx.lifecycle.LifecycleOwner
import com.mlord.app.core.ui.BaseListAdapter
import com.mlord.app.list.ui.adapter.ListItemType
import com.mlord.app.list.ui.adapter.emptyStateListAD
import com.mlord.app.list.ui.adapter.listHeaderAD
import com.mlord.app.list.ui.adapter.loadingStateAD
import com.mlord.app.list.ui.model.ListModel

class DownloadsAdapter(
	lifecycleOwner: LifecycleOwner,
	listener: DownloadItemListener,
) : BaseListAdapter<ListModel>() {

	init {
		addDelegate(ListItemType.DOWNLOAD, downloadItemAD(lifecycleOwner, listener))
		addDelegate(ListItemType.STATE_LOADING, loadingStateAD())
		addDelegate(ListItemType.STATE_EMPTY, emptyStateListAD(null))
		addDelegate(ListItemType.HEADER, listHeaderAD(null))
	}
}
