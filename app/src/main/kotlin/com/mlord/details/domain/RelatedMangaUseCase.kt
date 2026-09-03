package com.mlord.details.domain

import com.mlord.core.parser.MangaRepository
import com.mlord.core.util.ext.printStackTraceDebug
import com.mlord.parsers.model.Manga
import com.mlord.parsers.util.runCatchingCancellable
import javax.inject.Inject

class RelatedMangaUseCase @Inject constructor(
	private val mangaRepositoryFactory: MangaRepository.Factory,
) {

	suspend operator fun invoke(seed: Manga) = runCatchingCancellable {
		mangaRepositoryFactory.create(seed.source).getRelated(seed)
	}.onFailure {
		it.printStackTraceDebug()
	}.getOrNull()
}
