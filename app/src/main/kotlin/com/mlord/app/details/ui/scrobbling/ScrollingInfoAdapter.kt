package com.mlord.app.app.details.ui.scrobbling

import com.mlord.app.app.app.core.nav.AppRouter
import com.mlord.app.app.app.core.ui.BaseListAdapter
import com.mlord.app.app.app.list.ui.model.ListModel

class ScrollingInfoAdapter(
	router: AppRouter,
) : BaseListAdapter<ListModel>() {

	init {
		delegatesManager.addDelegate(scrobblingInfoAD(router))
	}
}
