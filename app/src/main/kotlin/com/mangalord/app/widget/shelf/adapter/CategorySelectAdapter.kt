package com.mangalord.app.widget.shelf.adapter

import com.mangalord.app.core.ui.BaseListAdapter
import com.mangalord.app.core.ui.list.OnListItemClickListener
import com.mangalord.app.widget.shelf.model.CategoryItem

class CategorySelectAdapter(
	clickListener: OnListItemClickListener<CategoryItem>
) : BaseListAdapter<CategoryItem>() {

	init {
		delegatesManager.addDelegate(categorySelectItemAD(clickListener))
	}
}
