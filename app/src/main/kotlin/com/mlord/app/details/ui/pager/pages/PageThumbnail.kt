package com.mlord.app.app.details.ui.pager.pages

import com.mlord.app.app.app.list.ui.model.ListModel
import com.mlord.app.app.app.reader.ui.pager.ReaderPage

data class PageThumbnail(
	val isCurrent: Boolean,
	val page: ReaderPage,
) : ListModel {

	val number
		get() = page.index + 1

	override fun areItemsTheSame(other: ListModel): Boolean {
		return other is PageThumbnail && page == other.page
	}
}
