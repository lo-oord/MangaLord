package com.mlord.app.app.history.domain.model

import com.mlord.app.app.app.core.model.MangaHistory
import org.koitharu.kotatsu.parsers.model.Manga

data class MangaWithHistory(
	val manga: Manga,
	val history: MangaHistory
)
