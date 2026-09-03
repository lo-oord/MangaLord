package com.mlord.app.core.exceptions

import com.mlord.app.app.details.ui.pager.EmptyMangaReason
import org.koitharu.kotatsu.parsers.model.Manga

class EmptyMangaException(
    val reason: EmptyMangaReason?,
    val manga: Manga,
    cause: Throwable?
) : IllegalStateException(cause)
