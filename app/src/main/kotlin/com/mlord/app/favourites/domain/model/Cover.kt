package com.mlord.app.favourites.domain.model

import com.mlord.app.app.core.model.MangaSource

data class Cover(
	val url: String?,
	val source: String,
) {
	val mangaSource by lazy { MangaSource(source) }
}
