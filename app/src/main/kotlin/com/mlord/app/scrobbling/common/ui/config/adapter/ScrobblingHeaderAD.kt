package com.mlord.app.scrobbling.common.ui.config.adapter

import androidx.core.view.isInvisible
import com.hannesdorfmann.adapterdelegates4.dsl.adapterDelegateViewBinding
import com.mlord.app.R
import com.mlord.app.databinding.ItemHeaderBinding
import com.mlord.app.list.ui.model.ListModel
import com.mlord.app.scrobbling.common.domain.model.ScrobblingStatus

fun scrobblingHeaderAD() = adapterDelegateViewBinding<ScrobblingStatus, ListModel, ItemHeaderBinding>(
	{ inflater, parent -> ItemHeaderBinding.inflate(inflater, parent, false) },
) {

	binding.buttonMore.isInvisible = true
	val strings = context.resources.getStringArray(R.array.scrobbling_statuses)

	bind {
		binding.textViewTitle.text = strings.getOrNull(item.ordinal)
	}
}
