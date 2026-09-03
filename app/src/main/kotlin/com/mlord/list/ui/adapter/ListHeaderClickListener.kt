package com.mlord.list.ui.adapter

import android.view.View
import com.mlord.list.ui.model.ListHeader

interface ListHeaderClickListener {

	fun onListHeaderClick(item: ListHeader, view: View)
}
