package com.mlord.app.app.list.ui.adapter

import com.hannesdorfmann.adapterdelegates4.dsl.adapterDelegate
import com.mlord.app.app.app.R
import com.mlord.app.app.app.list.ui.model.ListModel
import com.mlord.app.app.app.list.ui.model.LoadingFooter

fun loadingFooterAD() = adapterDelegate<LoadingFooter, ListModel>(R.layout.item_loading_footer) {
}