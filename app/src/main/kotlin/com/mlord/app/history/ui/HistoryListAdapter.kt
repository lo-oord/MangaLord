package com.mlord.app.app.history.ui

import android.content.Context
import com.mlord.app.app.app.core.ui.list.fastscroll.FastScroller
import com.mlord.app.app.app.list.ui.adapter.MangaListAdapter
import com.mlord.app.app.app.list.ui.adapter.MangaListListener
import com.mlord.app.app.app.list.ui.size.ItemSizeResolver

class HistoryListAdapter(
	listener: MangaListListener,
	sizeResolver: ItemSizeResolver,
) : MangaListAdapter(listener, sizeResolver), FastScroller.SectionIndexer {

	override fun getSectionText(context: Context, position: Int): CharSequence? {
		return findHeader(position)?.getText(context)
	}
}
