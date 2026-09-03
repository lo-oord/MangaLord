package com.mangalord.app.bookmarks.ui.adapter

import android.content.Context
import com.mangalord.app.bookmarks.domain.Bookmark
import com.mangalord.app.core.ui.BaseListAdapter
import com.mangalord.app.core.ui.list.OnListItemClickListener
import com.mangalord.app.core.ui.list.fastscroll.FastScroller
import com.mangalord.app.list.ui.adapter.ListHeaderClickListener
import com.mangalord.app.list.ui.adapter.ListItemType
import com.mangalord.app.list.ui.adapter.emptyStateListAD
import com.mangalord.app.list.ui.adapter.errorStateListAD
import com.mangalord.app.list.ui.adapter.listHeaderAD
import com.mangalord.app.list.ui.adapter.loadingFooterAD
import com.mangalord.app.list.ui.adapter.loadingStateAD
import com.mangalord.app.list.ui.model.ListModel

class BookmarksAdapter(
	clickListener: OnListItemClickListener<Bookmark>,
	headerClickListener: ListHeaderClickListener?,
) : BaseListAdapter<ListModel>(), FastScroller.SectionIndexer {

	init {
		addDelegate(ListItemType.PAGE_THUMB, bookmarkLargeAD(clickListener))
		addDelegate(ListItemType.HEADER, listHeaderAD(headerClickListener))
		addDelegate(ListItemType.STATE_ERROR, errorStateListAD(null))
		addDelegate(ListItemType.FOOTER_LOADING, loadingFooterAD())
		addDelegate(ListItemType.STATE_LOADING, loadingStateAD())
		addDelegate(ListItemType.STATE_EMPTY, emptyStateListAD(null))
	}

	override fun getSectionText(context: Context, position: Int): CharSequence? {
		return findHeader(position)?.getText(context)
	}
}
