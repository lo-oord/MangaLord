package com.mlord.app.app.stats.ui

import android.content.res.ColorStateList
import com.hannesdorfmann.adapterdelegates4.dsl.adapterDelegateViewBinding
import com.mlord.app.app.app.R
import com.mlord.app.app.app.core.ui.list.OnListItemClickListener
import com.mlord.app.app.app.core.util.MlordColors
import com.mlord.app.app.app.databinding.ItemStatsBinding
import org.koitharu.kotatsu.parsers.model.Manga
import com.mlord.app.app.app.stats.domain.StatsRecord

fun statsAD(
	listener: OnListItemClickListener<Manga>,
) = adapterDelegateViewBinding<StatsRecord, StatsRecord, ItemStatsBinding>(
	{ layoutInflater, parent -> ItemStatsBinding.inflate(layoutInflater, parent, false) },
) {

	binding.root.setOnClickListener { v ->
		listener.onItemClick(item.manga ?: return@setOnClickListener, v)
	}

	bind {
		binding.textViewTitle.text = item.manga?.title ?: getString(R.string.other_manga)
		binding.textViewSummary.text = item.time.format(context.resources)
		binding.imageViewBadge.imageTintList = ColorStateList.valueOf(MlordColors.ofManga(context, item.manga))
		binding.root.isClickable = item.manga != null
	}
}
