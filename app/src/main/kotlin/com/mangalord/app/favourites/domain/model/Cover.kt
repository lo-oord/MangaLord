package com.mangalord.app.favourites.domain.model

import com.mangalord.app.core.model.MangaSource

data class Cover(
	val url: String?,
	val source: String,
) {
	val mangaSource by lazy { MangaSource(source) }
}
