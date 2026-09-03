package com.mlord.search.ui.suggestion

import android.text.TextWatcher
import android.widget.TextView
import com.mlord.parsers.model.Manga
import com.mlord.parsers.model.MangaSource
import com.mlord.parsers.model.MangaTag
import com.mlord.search.domain.SearchKind

interface SearchSuggestionListener : TextWatcher, TextView.OnEditorActionListener {

	fun onMangaClick(manga: Manga)

	fun onQueryClick(query: String, kind: SearchKind, submit: Boolean)

	fun onSourceToggle(source: MangaSource, isEnabled: Boolean)

	fun onSourceClick(source: MangaSource)

	fun onTagClick(tag: MangaTag)
}
