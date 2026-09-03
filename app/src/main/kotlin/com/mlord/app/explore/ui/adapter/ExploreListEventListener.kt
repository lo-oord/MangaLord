package com.mlord.app.app.explore.ui.adapter

import android.view.View
import com.mlord.app.app.app.list.ui.adapter.ListHeaderClickListener
import com.mlord.app.app.app.list.ui.adapter.ListStateHolderListener

interface ExploreListEventListener : ListStateHolderListener, View.OnClickListener, ListHeaderClickListener
