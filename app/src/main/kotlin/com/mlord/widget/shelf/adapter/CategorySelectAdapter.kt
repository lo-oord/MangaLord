package com.mlord.widget.shelf.adapter

import com.mlord.core.ui.BaseListAdapter
import com.mlord.core.ui.list.OnListItemClickListener
import com.mlord.widget.shelf.model.CategoryItem

class CategorySelectAdapter(
	clickListener: OnListItemClickListener<CategoryItem>
) : BaseListAdapter<CategoryItem>() {

	init {
		delegatesManager.addDelegate(categorySelectItemAD(clickListener))
	}
}
