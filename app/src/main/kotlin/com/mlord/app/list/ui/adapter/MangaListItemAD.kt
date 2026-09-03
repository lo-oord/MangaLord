package com.mlord.app.list.ui.adapter

import androidx.core.view.isVisible
import com.hannesdorfmann.adapterdelegates4.dsl.adapterDelegateViewBinding
import com.mlord.app.core.ui.list.AdapterDelegateClickListenerAdapter
import com.mlord.app.core.ui.list.OnListItemClickListener
import com.mlord.app.core.util.ext.setTooltipCompat
import com.mlord.app.core.util.ext.textAndVisible
import com.mlord.app.databinding.ItemMangaListBinding
import com.mlord.app.list.ui.model.ListModel
import com.mlord.app.list.ui.model.MangaCompactListModel
import com.mlord.app.list.ui.model.MangaListModel

fun mangaListItemAD(
	clickListener: OnListItemClickListener<MangaListModel>,
) = adapterDelegateViewBinding<MangaCompactListModel, ListModel, ItemMangaListBinding>(
	{ inflater, parent -> ItemMangaListBinding.inflate(inflater, parent, false) },
) {

	AdapterDelegateClickListenerAdapter(this, clickListener).attach(itemView)

	bind {
		itemView.setTooltipCompat(item.getSummary(context))
		binding.textViewTitle.text = item.title
		binding.textViewSubtitle.textAndVisible = item.subtitle
		binding.imageViewCover.setImageAsync(item.coverUrl, item.manga)
		binding.badge.number = item.counter
		binding.badge.isVisible = item.counter > 0
	}
}
