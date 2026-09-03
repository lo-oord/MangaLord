package com.mlord.scrobbling.common.ui.selector.adapter

import com.mlord.core.ui.BaseListAdapter
import com.mlord.core.ui.list.OnListItemClickListener
import com.mlord.list.ui.adapter.ListItemType
import com.mlord.list.ui.adapter.ListStateHolderListener
import com.mlord.list.ui.adapter.loadingFooterAD
import com.mlord.list.ui.adapter.loadingStateAD
import com.mlord.list.ui.model.ListModel
import com.mlord.scrobbling.common.domain.model.ScrobblerManga

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
