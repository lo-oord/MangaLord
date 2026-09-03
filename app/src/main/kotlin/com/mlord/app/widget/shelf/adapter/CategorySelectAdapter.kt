package com.mlord.app.app.widget.shelf.adapter

import com.mlord.app.app.app.core.ui.BaseListAdapter
import com.mlord.app.app.app.core.ui.list.OnListItemClickListener
import com.mlord.app.app.app.widget.shelf.model.CategoryItem

class CategorySelectAdapter(
	clickListener: OnListItemClickListener<CategoryItem>
) : BaseListAdapter<CategoryItem>() {

	init {
		delegatesManager.addDelegate(categorySelectItemAD(clickListener))
	}
}
