package com.mlord.settings.tracker.categories

import com.mlord.core.model.FavouriteCategory
import com.mlord.core.ui.BaseListAdapter
import com.mlord.core.ui.list.OnListItemClickListener

class TrackerCategoriesConfigAdapter(
	listener: OnListItemClickListener<FavouriteCategory>,
) : BaseListAdapter<FavouriteCategory>() {

	init {
		delegatesManager.addDelegate(trackerCategoryAD(listener))
	}
}
