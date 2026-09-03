package com.mangalord.app.history.ui

import android.content.Context
import com.mangalord.app.core.ui.list.fastscroll.FastScroller
import com.mangalord.app.list.ui.adapter.MangaListAdapter
import com.mangalord.app.list.ui.adapter.MangaListListener
import com.mangalord.app.list.ui.size.ItemSizeResolver

class HistoryListAdapter(
	listener: MangaListListener,
	sizeResolver: ItemSizeResolver,
) : MangaListAdapter(listener, sizeResolver), FastScroller.SectionIndexer {

	override fun getSectionText(context: Context, position: Int): CharSequence? {
		return findHeader(position)?.getText(context)
	}
}
