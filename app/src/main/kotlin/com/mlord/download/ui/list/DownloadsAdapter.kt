package com.mlord.download.ui.list

import androidx.lifecycle.LifecycleOwner
import com.mlord.core.ui.BaseListAdapter
import com.mlord.list.ui.adapter.ListItemType
import com.mlord.list.ui.adapter.emptyStateListAD
import com.mlord.list.ui.adapter.listHeaderAD
import com.mlord.list.ui.adapter.loadingStateAD
import com.mlord.list.ui.model.ListModel

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
