package com.mangalord.app.tracker.domain

import com.mangalord.app.core.prefs.AppSettings
import com.mangalord.app.favourites.domain.FavouritesRepository
import com.mangalord.app.list.domain.ListFilterOption
import com.mangalord.app.list.domain.MangaListQuickFilter
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
