package com.mangalord.app.list.ui.adapter

import com.hannesdorfmann.adapterdelegates4.dsl.adapterDelegate
import com.mangalord.app.R
import com.mangalord.app.list.ui.model.ListModel
import com.mangalord.app.list.ui.model.LoadingState

fun loadingStateAD() = adapterDelegate<LoadingState, ListModel>(R.layout.item_loading_state) {
}