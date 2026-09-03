package com.mlord.app.scrobbling.common.ui.config.adapter

import com.mlord.app.app.core.ui.BaseListAdapter
import com.mlord.app.app.core.ui.list.OnListItemClickListener
import com.mlord.app.app.list.ui.adapter.ListItemType
import com.mlord.app.app.list.ui.adapter.emptyStateListAD
import com.mlord.app.app.list.ui.model.ListModel
import com.mlord.app.app.scrobbling.common.domain.model.ScrobblingInfo

class ScrobblingMangaAdapter(
	clickListener: OnListItemClickListener<ScrobblingInfo>,
) : BaseListAdapter<ListModel>() {

	init {
		addDelegate(ListItemType.HEADER, scrobblingHeaderAD())
		addDelegate(ListItemType.STATE_EMPTY, emptyStateListAD(null))
		addDelegate(ListItemType.MANGA_SCROBBLING, scrobblingMangaAD(clickListener))
	}
}
