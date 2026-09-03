package com.mlord.list.ui.model

import com.mlord.core.ui.model.MangaOverride
import com.mlord.parsers.model.Manga

data class MangaCompactListModel(
	override val manga: Manga,
	override val override: MangaOverride?,
	val subtitle: String,
	override val counter: Int,
) : MangaListModel()
