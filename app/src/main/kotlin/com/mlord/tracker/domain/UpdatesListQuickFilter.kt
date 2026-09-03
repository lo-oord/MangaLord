package com.mlord.tracker.domain

import com.mlord.core.prefs.AppSettings
import com.mlord.favourites.domain.FavouritesRepository
import com.mlord.list.domain.ListFilterOption
import com.mlord.list.domain.MangaListQuickFilter
import javax.inject.Inject

class UpdatesListQuickFilter @Inject constructor(
	private val favouritesRepository: FavouritesRepository,
	settings: AppSettings,
) : MangaListQuickFilter(settings) {

	override suspend fun getAvailableFilterOptions(): List<ListFilterOption> =
		favouritesRepository.getMostUpdatedCategories(
			limit = 4,
		).map {
			ListFilterOption.Favorite(it)
		}
}
