package com.mlord.app.favourites.ui.categories.select.adapter

import androidx.core.text.buildSpannedString
import com.hannesdorfmann.adapterdelegates4.dsl.adapterDelegateViewBinding
import com.mlord.app.R
import com.mlord.app.core.model.appendIcon
import com.mlord.app.core.ui.list.OnListItemClickListener
import com.mlord.app.databinding.ItemCategoryCheckableBinding
import com.mlord.app.favourites.ui.categories.select.model.MangaCategoryItem
import com.mlord.app.list.ui.ListModelDiffCallback
import com.mlord.app.list.ui.model.ListModel

fun mangaCategoryAD(
	clickListener: OnListItemClickListener<MangaCategoryItem>,
) = adapterDelegateViewBinding<MangaCategoryItem, ListModel, ItemCategoryCheckableBinding>(
	{ inflater, parent -> ItemCategoryCheckableBinding.inflate(inflater, parent, false) },
) {

	itemView.setOnClickListener {
		clickListener.onItemClick(item, itemView)
	}

	bind { payloads ->
		binding.checkBox.checkedState = item.checkedState
		if (ListModelDiffCallback.PAYLOAD_CHECKED_CHANGED !in payloads) {
			binding.checkBox.text = buildSpannedString {
				append(item.category.title)
				if (item.isTrackerEnabled && item.category.isTrackingEnabled) {
					append(' ')
					appendIcon(binding.checkBox, R.drawable.ic_notification)
				}
				if (!item.category.isVisibleInLibrary) {
					append(' ')
					appendIcon(binding.checkBox, R.drawable.ic_eye_off)
				}
			}
			binding.checkBox.jumpDrawablesToCurrentState()
		}
	}
}
