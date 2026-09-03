package com.mlord.app.details.ui.pager.pages

import android.content.Context
import com.mlord.app.app.core.ui.BaseListAdapter
import com.mlord.app.app.core.ui.list.OnListItemClickListener
import com.mlord.app.app.core.ui.list.fastscroll.FastScroller
import com.mlord.app.app.list.ui.adapter.ListItemType
import com.mlord.app.app.list.ui.adapter.listHeaderAD
import com.mlord.app.app.list.ui.model.ListModel

class PageThumbnailAdapter(
	clickListener: OnListItemClickListener<PageThumbnail>,
) : BaseListAdapter<ListModel>(), FastScroller.SectionIndexer {

	init {
		addDelegate(ListItemType.PAGE_THUMB, pageThumbnailAD(clickListener))
		addDelegate(ListItemType.HEADER, listHeaderAD(null))
	}

	override fun getSectionText(context: Context, position: Int): CharSequence? {
		return findHeader(position)?.getText(context)
	}
}
