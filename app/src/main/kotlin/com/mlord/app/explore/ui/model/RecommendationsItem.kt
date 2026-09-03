package com.mlord.app.app.explore.ui.model

import com.mlord.app.app.app.list.ui.model.ListModel
import com.mlord.app.app.app.list.ui.model.MangaCompactListModel

data class RecommendationsItem(
	val manga: List<MangaCompactListModel>
) : ListModel {

	override fun areItemsTheSame(other: ListModel): Boolean {
		return other is RecommendationsItem
	}
}
