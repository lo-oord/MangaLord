package com.mlord.app.app.favourites.ui.categories.adapter

import com.mlord.app.app.app.core.ui.ReorderableListAdapter
import com.mlord.app.app.app.favourites.ui.categories.FavouriteCategoriesListListener
import com.mlord.app.app.app.list.ui.adapter.ListItemType
import com.mlord.app.app.app.list.ui.adapter.ListStateHolderListener
import com.mlord.app.app.app.list.ui.adapter.emptyStateListAD
import com.mlord.app.app.app.list.ui.adapter.loadingStateAD
import com.mlord.app.app.app.list.ui.model.ListModel

class CategoriesAdapter(
	onItemClickListener: FavouriteCategoriesListListener,
	listListener: ListStateHolderListener,
) : ReorderableListAdapter<ListModel>() {

	init {
		addDelegate(ListItemType.CATEGORY_LARGE, categoryAD(onItemClickListener))
		addDelegate(ListItemType.NAV_ITEM, allCategoriesAD(onItemClickListener))
		addDelegate(ListItemType.STATE_EMPTY, emptyStateListAD(listListener))
		addDelegate(ListItemType.STATE_LOADING, loadingStateAD())
	}
}
