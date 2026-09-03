package com.mlord.core.parser

import com.mlord.core.cache.MemoryContentCache
import com.mlord.core.model.TestMangaSource
import com.mlord.parsers.MangaLoaderContext

@Suppress("unused")
class TestMangaRepository(
	private val loaderContext: MangaLoaderContext,
	cache: MemoryContentCache
) : EmptyMangaRepository(TestMangaSource)
