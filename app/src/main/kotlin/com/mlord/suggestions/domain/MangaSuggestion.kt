package com.mlord.suggestions.domain

import androidx.annotation.FloatRange
import com.mlord.parsers.model.Manga

data class MangaSuggestion(
	val manga: Manga,
	@FloatRange(from = 0.0, to = 1.0)
	val relevance: Float,
)