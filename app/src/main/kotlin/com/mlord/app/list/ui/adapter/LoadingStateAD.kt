package com.mlord.app.list.ui.adapter

import com.hannesdorfmann.adapterdelegates4.dsl.adapterDelegate
import com.mlord.app.app.R
import com.mlord.app.app.list.ui.model.ListModel
import com.mlord.app.app.list.ui.model.LoadingState

fun loadingStateAD() = adapterDelegate<LoadingState, ListModel>(R.layout.item_loading_state) {
}