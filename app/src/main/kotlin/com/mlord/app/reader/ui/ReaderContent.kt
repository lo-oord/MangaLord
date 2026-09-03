package com.mlord.app.reader.ui

import com.mlord.app.reader.ui.pager.ReaderPage

data class ReaderContent(
	val pages: List<ReaderPage>,
	val state: ReaderState?
)