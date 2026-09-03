package com.mangalord.app.list.ui.adapter

import android.view.View
import com.mangalord.app.list.ui.model.ListHeader

interface ListHeaderClickListener {

	fun onListHeaderClick(item: ListHeader, view: View)
}
