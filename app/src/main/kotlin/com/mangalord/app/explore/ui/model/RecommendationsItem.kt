package com.mangalord.app.explore.ui.model

import com.mangalord.app.list.ui.model.ListModel
import com.mangalord.app.list.ui.model.MangaCompactListModel

data class RecommendationsItem(
	val manga: List<MangaCompactListModel>
) : ListModel {

	override fun areItemsTheSame(other: ListModel): Boolean {
		return other is RecommendationsItem
	}
}
