package com.mlord.favourites.ui.categories

import android.view.View
import androidx.recyclerview.widget.RecyclerView
import com.mlord.core.model.FavouriteCategory
import com.mlord.core.ui.list.OnListItemClickListener

interface FavouriteCategoriesListListener : OnListItemClickListener<FavouriteCategory?> {

	fun onDragHandleTouch(holder: RecyclerView.ViewHolder): Boolean

	fun onEditClick(item: FavouriteCategory, view: View)

	fun onShowAllClick(isChecked: Boolean)
}
