package com.mlord.details.ui.scrobbling

import com.mlord.core.nav.AppRouter
import com.mlord.core.ui.BaseListAdapter
import com.mlord.list.ui.model.ListModel

class ScrollingInfoAdapter(
	router: AppRouter,
) : BaseListAdapter<ListModel>() {

	init {
		delegatesManager.addDelegate(scrobblingInfoAD(router))
	}
}
