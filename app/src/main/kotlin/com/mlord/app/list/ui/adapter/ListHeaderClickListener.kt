package com.mlord.app.app.list.ui.adapter

import android.view.View
import com.mlord.app.app.app.list.ui.model.ListHeader

interface ListHeaderClickListener {

	fun onListHeaderClick(item: ListHeader, view: View)
}
