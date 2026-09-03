package com.mlord.explore.ui.model

import com.mlord.core.model.MangaSourceInfo
import com.mlord.list.ui.model.ListModel
import com.mlord.parsers.util.longHashCode

data class MangaSourceItem(
	val source: MangaSourceInfo,
	val isGrid: Boolean,
) : ListModel {

	val id: Long = source.name.longHashCode()

	override fun areItemsTheSame(other: ListModel): Boolean {
		return other is MangaSourceItem && other.source == source
	}
}
