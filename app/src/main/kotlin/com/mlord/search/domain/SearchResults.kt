package com.mlord.search.domain

import com.mlord.parsers.model.Manga
import com.mlord.parsers.model.MangaListFilter
import com.mlord.parsers.model.SortOrder

data class SearchResults(
	val listFilter: MangaListFilter,
	val sortOrder: SortOrder,
	val manga: List<Manga>,
)
