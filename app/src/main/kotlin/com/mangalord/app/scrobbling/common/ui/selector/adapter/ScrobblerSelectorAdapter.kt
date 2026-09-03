package com.mangalord.app.scrobbling.common.ui.selector.adapter

import com.mangalord.app.core.ui.BaseListAdapter
import com.mangalord.app.core.ui.list.OnListItemClickListener
import com.mangalord.app.list.ui.adapter.ListItemType
import com.mangalord.app.list.ui.adapter.ListStateHolderListener
import com.mangalord.app.list.ui.adapter.loadingFooterAD
import com.mangalord.app.list.ui.adapter.loadingStateAD
import com.mangalord.app.list.ui.model.ListModel
import com.mangalord.app.scrobbling.common.domain.model.ScrobblerManga

class ScrobblerSelectorAdapter(
	clickListener: OnListItemClickListener<ScrobblerManga>,
	stateHolderListener: ListStateHolderListener,
) : BaseListAdapter<ListModel>() {

	init {
		addDelegate(ListItemType.STATE_LOADING, loadingStateAD())
		addDelegate(ListItemType.MANGA_SCROBBLING, scrobblingMangaAD(clickListener))
		addDelegate(ListItemType.FOOTER_LOADING, loadingFooterAD())
		addDelegate(ListItemType.HINT_EMPTY, scrobblerHintAD(stateHolderListener))
	}
}
