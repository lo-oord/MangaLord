package com.mlord.core.exceptions

import com.mlord.details.ui.pager.EmptyMangaReason
import com.mlord.parsers.model.Manga

class EmptyMangaException(
    val reason: EmptyMangaReason?,
    val manga: Manga,
    cause: Throwable?
) : IllegalStateException(cause)
