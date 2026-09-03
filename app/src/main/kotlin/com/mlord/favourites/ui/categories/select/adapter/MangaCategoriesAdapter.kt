package com.mlord.favourites.ui.categories.select.adapter

import com.mlord.core.ui.BaseListAdapter
import com.mlord.core.ui.list.OnListItemClickListener
import com.mlord.favourites.ui.categories.select.model.MangaCategoryItem
import com.mlord.list.ui.adapter.ListItemType
import com.mlord.list.ui.adapter.emptyStateListAD
import com.mlord.list.ui.adapter.loadingStateAD
import com.mlord.list.ui.model.ListModel

class MangaCategoriesAdapter(
	clickListener: OnListItemClickListener<MangaCategoryItem>,
) : BaseListAdapter<ListModel>() {

	init {
		addDelegate(ListItemType.NAV_ITEM, mangaCategoryAD(clickListener))
		addDelegate(ListItemType.STATE_LOADING, loadingStateAD())
		addDelegate(ListItemType.STATE_EMPTY, emptyStateListAD(null))
	}
}
