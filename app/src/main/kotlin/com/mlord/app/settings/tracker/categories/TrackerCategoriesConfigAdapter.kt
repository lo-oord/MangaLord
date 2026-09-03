package com.mlord.app.settings.tracker.categories

import com.mlord.app.core.model.FavouriteCategory
import com.mlord.app.core.ui.BaseListAdapter
import com.mlord.app.core.ui.list.OnListItemClickListener

class TrackerCategoriesConfigAdapter(
	listener: OnListItemClickListener<FavouriteCategory>,
) : BaseListAdapter<FavouriteCategory>() {

	init {
		delegatesManager.addDelegate(trackerCategoryAD(listener))
	}
}
