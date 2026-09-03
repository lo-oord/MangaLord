package com.mangalord.app.scrobbling.common.ui.config.adapter

import com.mangalord.app.core.ui.BaseListAdapter
import com.mangalord.app.core.ui.list.OnListItemClickListener
import com.mangalord.app.list.ui.adapter.ListItemType
import com.mangalord.app.list.ui.adapter.emptyStateListAD
import com.mangalord.app.list.ui.model.ListModel
import com.mangalord.app.scrobbling.common.domain.model.ScrobblingInfo

class ScrobblingMangaAdapter(
	clickListener: OnListItemClickListener<ScrobblingInfo>,
) : BaseListAdapter<ListModel>() {

	init {
		addDelegate(ListItemType.HEADER, scrobblingHeaderAD())
		addDelegate(ListItemType.STATE_EMPTY, emptyStateListAD(null))
		addDelegate(ListItemType.MANGA_SCROBBLING, scrobblingMangaAD(clickListener))
	}
}
