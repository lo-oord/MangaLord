package com.mlord.app.bookmarks.ui.adapter

import com.hannesdorfmann.adapterdelegates4.dsl.adapterDelegateViewBinding
import com.mlord.app.app.bookmarks.domain.Bookmark
import com.mlord.app.app.core.ui.list.AdapterDelegateClickListenerAdapter
import com.mlord.app.app.core.ui.list.OnListItemClickListener
import com.mlord.app.app.databinding.ItemBookmarkLargeBinding
import com.mlord.app.app.list.ui.model.ListModel

fun bookmarkLargeAD(
	clickListener: OnListItemClickListener<Bookmark>,
) = adapterDelegateViewBinding<Bookmark, ListModel, ItemBookmarkLargeBinding>(
	{ inflater, parent -> ItemBookmarkLargeBinding.inflate(inflater, parent, false) },
) {
	AdapterDelegateClickListenerAdapter(this, clickListener).attach(itemView)

	bind {
		binding.imageViewThumb.setImageAsync(item)
		binding.progressView.setProgress(item.percent, false)
	}
}
