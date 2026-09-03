package com.mlord.app.history.data

import dagger.Reusable
import com.mlord.app.core.db.MangaDatabase
import com.mlord.app.core.db.entity.toManga
import com.mlord.app.core.db.entity.toMangaTags
import com.mlord.app.history.domain.model.MangaWithHistory
import com.mlord.app.list.domain.ListFilterOption
import com.mlord.app.list.domain.ListSortOrder
import com.mlord.app.local.data.index.LocalMangaIndex
import com.mlord.app.local.domain.LocalObserveMapper
import org.koitharu.kotatsu.parsers.model.Manga
import javax.inject.Inject

@Reusable
class HistoryLocalObserver @Inject constructor(
	localMangaIndex: LocalMangaIndex,
	private val db: MangaDatabase,
) : LocalObserveMapper<HistoryWithManga, MangaWithHistory>(localMangaIndex) {

	fun observeAll(
		order: ListSortOrder,
		filterOptions: Set<ListFilterOption>,
		limit: Int
	) = db.getHistoryDao().observeAll(order, filterOptions, limit).mapToLocal()

	override fun toManga(e: HistoryWithManga) = e.manga.toManga(e.tags.toMangaTags(), null)

	override fun toResult(e: HistoryWithManga, manga: Manga) = MangaWithHistory(
		manga = manga,
		history = e.history.toMangaHistory(),
	)
}
