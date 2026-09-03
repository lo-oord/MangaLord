package com.mlord.app.details.ui.scrobbling

import com.mlord.app.core.nav.AppRouter
import com.mlord.app.core.ui.BaseListAdapter
import com.mlord.app.list.ui.model.ListModel

class ScrollingInfoAdapter(
	router: AppRouter,
) : BaseListAdapter<ListModel>() {

	init {
		delegatesManager.addDelegate(scrobblingInfoAD(router))
	}
}
