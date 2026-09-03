package com.mlord.history.domain.model

import com.mlord.core.model.MangaHistory
import com.mlord.parsers.model.Manga

data class MangaWithHistory(
	val manga: Manga,
	val history: MangaHistory
)
