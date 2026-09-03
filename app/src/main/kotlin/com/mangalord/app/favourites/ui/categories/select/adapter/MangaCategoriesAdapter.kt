package com.mangalord.app.favourites.ui.categories.select.adapter

import com.mangalord.app.core.ui.BaseListAdapter
import com.mangalord.app.core.ui.list.OnListItemClickListener
import com.mangalord.app.favourites.ui.categories.select.model.MangaCategoryItem
import com.mangalord.app.list.ui.adapter.ListItemType
import com.mangalord.app.list.ui.adapter.emptyStateListAD
import com.mangalord.app.list.ui.adapter.loadingStateAD
import com.mangalord.app.list.ui.model.ListModel

class MangaCategoriesAdapter(
	clickListener: OnListItemClickListener<MangaCategoryItem>,
) : BaseListAdapter<ListModel>() {

	init {
		addDelegate(ListItemType.NAV_ITEM, mangaCategoryAD(clickListener))
		addDelegate(ListItemType.STATE_LOADING, loadingStateAD())
		addDelegate(ListItemType.STATE_EMPTY, emptyStateListAD(null))
	}
}
