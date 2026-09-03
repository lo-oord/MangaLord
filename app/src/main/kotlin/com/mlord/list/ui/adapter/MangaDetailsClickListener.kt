package com.mlord.list.ui.adapter

import android.view.View
import com.mlord.core.ui.list.OnListItemClickListener
import com.mlord.list.ui.model.MangaListModel
import com.mlord.parsers.model.Manga
import com.mlord.parsers.model.MangaTag

interface MangaDetailsClickListener : OnListItemClickListener<MangaListModel> {

	fun onReadClick(manga: Manga, view: View)

	fun onTagClick(manga: Manga, tag: MangaTag, view: View)
}
