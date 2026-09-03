package com.mlord.app.app.tracker.domain

import com.mlord.app.app.app.core.prefs.AppSettings
import com.mlord.app.app.app.favourites.domain.FavouritesRepository
import com.mlord.app.app.app.list.domain.ListFilterOption
import com.mlord.app.app.app.list.domain.MangaListQuickFilter
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
