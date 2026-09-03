package com.mangalord.app.settings.tracker.categories

import com.mangalord.app.core.model.FavouriteCategory
import com.mangalord.app.core.ui.BaseListAdapter
import com.mangalord.app.core.ui.list.OnListItemClickListener

class TrackerCategoriesConfigAdapter(
	listener: OnListItemClickListener<FavouriteCategory>,
) : BaseListAdapter<FavouriteCategory>() {

	init {
		delegatesManager.addDelegate(trackerCategoryAD(listener))
	}
}
