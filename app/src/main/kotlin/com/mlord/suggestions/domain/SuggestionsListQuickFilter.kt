package com.mlord.suggestions.domain

import com.mlord.core.prefs.AppSettings
import com.mlord.list.domain.ListFilterOption
import com.mlord.list.domain.MangaListQuickFilter
import javax.inject.Inject

class SuggestionsListQuickFilter @Inject constructor(
	private val settings: AppSettings,
	private val suggestionRepository: SuggestionRepository,
) : MangaListQuickFilter(settings) {

	override suspend fun getAvailableFilterOptions(): List<ListFilterOption> = buildList(6) {
		suggestionRepository.getTopTags(5).mapTo(this) {
			ListFilterOption.Tag(it)
		}
		if (!settings.isNsfwContentDisabled && !settings.isSuggestionsExcludeNsfw) {
			add(ListFilterOption.Macro.NSFW)
			add(ListFilterOption.SFW)
		}
		suggestionRepository.getTopSources(3).mapTo(this) {
			ListFilterOption.Source(it)
		}
	}
}
