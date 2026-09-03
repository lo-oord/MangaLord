package com.mlord.settings.sources.catalog

import android.content.Context
import com.mlord.core.model.getTitle
import com.mlord.core.ui.BaseListAdapter
import com.mlord.core.ui.list.OnListItemClickListener
import com.mlord.core.ui.list.fastscroll.FastScroller
import com.mlord.list.ui.adapter.ListItemType
import com.mlord.list.ui.adapter.loadingStateAD
import com.mlord.list.ui.model.ListModel

class SourcesCatalogAdapter(
	listener: OnListItemClickListener<SourceCatalogItem.Source>,
) : BaseListAdapter<ListModel>(), FastScroller.SectionIndexer {

	init {
		addDelegate(ListItemType.CHAPTER_LIST, sourceCatalogItemSourceAD(listener))
		addDelegate(ListItemType.HINT_EMPTY, sourceCatalogItemHintAD())
		addDelegate(ListItemType.STATE_LOADING, loadingStateAD())
	}

	override fun getSectionText(context: Context, position: Int): CharSequence? {
		return (items.getOrNull(position) as? SourceCatalogItem.Source)?.source?.getTitle(context)?.take(1)
	}
}
