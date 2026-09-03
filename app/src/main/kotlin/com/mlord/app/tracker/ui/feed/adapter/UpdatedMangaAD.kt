package com.mlord.app.app.tracker.ui.feed.adapter

import com.hannesdorfmann.adapterdelegates4.dsl.adapterDelegateViewBinding
import com.mlord.app.app.app.R
import com.mlord.app.app.app.core.ui.BaseListAdapter
import com.mlord.app.app.app.core.ui.list.OnListItemClickListener
import com.mlord.app.app.app.databinding.ItemListGroupBinding
import com.mlord.app.app.app.list.ui.adapter.ListHeaderClickListener
import com.mlord.app.app.app.list.ui.adapter.ListItemType
import com.mlord.app.app.app.list.ui.adapter.mangaGridItemAD
import com.mlord.app.app.app.list.ui.model.ListHeader
import com.mlord.app.app.app.list.ui.model.ListModel
import com.mlord.app.app.app.list.ui.model.MangaListModel
import com.mlord.app.app.app.list.ui.size.ItemSizeResolver
import com.mlord.app.app.app.tracker.ui.feed.model.UpdatedMangaHeader

fun updatedMangaAD(
	sizeResolver: ItemSizeResolver,
	listener: OnListItemClickListener<MangaListModel>,
	headerClickListener: ListHeaderClickListener,
) = adapterDelegateViewBinding<UpdatedMangaHeader, ListModel, ItemListGroupBinding>(
	{ layoutInflater, parent -> ItemListGroupBinding.inflate(layoutInflater, parent, false) },
) {

	val adapter = BaseListAdapter<ListModel>()
		.addDelegate(ListItemType.MANGA_GRID, mangaGridItemAD(sizeResolver, listener))
	binding.recyclerView.adapter = adapter
	binding.buttonMore.setOnClickListener { v ->
		headerClickListener.onListHeaderClick(ListHeader(0, payload = item), v)
	}
	binding.textViewTitle.setText(R.string.updates)
	binding.buttonMore.setText(R.string.more)

	bind {
		adapter.items = item.list
	}
}
