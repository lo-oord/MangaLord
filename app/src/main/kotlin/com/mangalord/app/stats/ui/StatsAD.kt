package com.mangalord.app.stats.ui

import android.content.res.ColorStateList
import com.hannesdorfmann.adapterdelegates4.dsl.adapterDelegateViewBinding
import com.mangalord.app.R
import com.mangalord.app.core.ui.list.OnListItemClickListener
import com.mangalord.app.core.util.MangaLordColors
import com.mangalord.app.databinding.ItemStatsBinding
import org.koitharu.kotatsu.parsers.model.Manga
import com.mangalord.app.stats.domain.StatsRecord

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
		binding.imageViewBadge.imageTintList = ColorStateList.valueOf(MangaLordColors.ofManga(context, item.manga))
		binding.root.isClickable = item.manga != null
	}
}
