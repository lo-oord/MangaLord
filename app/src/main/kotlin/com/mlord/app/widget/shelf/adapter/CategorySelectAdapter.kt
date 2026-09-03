package com.mlord.app.widget.shelf.adapter

import com.mlord.app.core.ui.BaseListAdapter
import com.mlord.app.core.ui.list.OnListItemClickListener
import com.mlord.app.widget.shelf.model.CategoryItem

class CategorySelectAdapter(
	clickListener: OnListItemClickListener<CategoryItem>
) : BaseListAdapter<CategoryItem>() {

	init {
		delegatesManager.addDelegate(categorySelectItemAD(clickListener))
	}
}
