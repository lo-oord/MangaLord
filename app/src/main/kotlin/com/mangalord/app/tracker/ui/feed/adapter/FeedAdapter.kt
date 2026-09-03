package com.mangalord.app.tracker.ui.feed.adapter

import android.content.Context
import com.mangalord.app.core.ui.BaseListAdapter
import com.mangalord.app.core.ui.list.OnListItemClickListener
import com.mangalord.app.core.ui.list.fastscroll.FastScroller
import com.mangalord.app.list.ui.adapter.ListItemType
import com.mangalord.app.list.ui.adapter.MangaListListener
import com.mangalord.app.list.ui.adapter.emptyStateListAD
import com.mangalord.app.list.ui.adapter.errorFooterAD
import com.mangalord.app.list.ui.adapter.errorStateListAD
import com.mangalord.app.list.ui.adapter.listHeaderAD
import com.mangalord.app.list.ui.adapter.loadingFooterAD
import com.mangalord.app.list.ui.adapter.loadingStateAD
import com.mangalord.app.list.ui.adapter.quickFilterAD
import com.mangalord.app.list.ui.model.ListModel
import com.mangalord.app.list.ui.size.ItemSizeResolver
import com.mangalord.app.tracker.ui.feed.model.FeedItem

class FeedAdapter(
	listener: MangaListListener,
	sizeResolver: ItemSizeResolver,
	feedClickListener: OnListItemClickListener<FeedItem>,
) : BaseListAdapter<ListModel>(), FastScroller.SectionIndexer {

	init {
		addDelegate(ListItemType.FEED, feedItemAD(feedClickListener))
		addDelegate(
			ListItemType.MANGA_NESTED_GROUP,
			updatedMangaAD(
				sizeResolver = sizeResolver,
				listener = listener,
				headerClickListener = listener,
			),
		)
		addDelegate(ListItemType.FOOTER_LOADING, loadingFooterAD())
		addDelegate(ListItemType.STATE_LOADING, loadingStateAD())
		addDelegate(ListItemType.FOOTER_ERROR, errorFooterAD(listener))
		addDelegate(ListItemType.STATE_ERROR, errorStateListAD(listener))
		addDelegate(ListItemType.HEADER, listHeaderAD(listener))
		addDelegate(ListItemType.STATE_EMPTY, emptyStateListAD(listener))
		addDelegate(ListItemType.QUICK_FILTER, quickFilterAD(listener))
	}

	override fun getSectionText(context: Context, position: Int): CharSequence? {
		return findHeader(position)?.getText(context)
	}
}
