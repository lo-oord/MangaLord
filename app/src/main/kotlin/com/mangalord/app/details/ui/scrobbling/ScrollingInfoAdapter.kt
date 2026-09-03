package com.mangalord.app.details.ui.scrobbling

import com.mangalord.app.core.nav.AppRouter
import com.mangalord.app.core.ui.BaseListAdapter
import com.mangalord.app.list.ui.model.ListModel

class ScrollingInfoAdapter(
	router: AppRouter,
) : BaseListAdapter<ListModel>() {

	init {
		delegatesManager.addDelegate(scrobblingInfoAD(router))
	}
}
