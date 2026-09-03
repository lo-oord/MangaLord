package com.mlord.app.explore.ui.adapter

import android.view.View
import com.mlord.app.app.list.ui.adapter.ListHeaderClickListener
import com.mlord.app.app.list.ui.adapter.ListStateHolderListener

interface ExploreListEventListener : ListStateHolderListener, View.OnClickListener, ListHeaderClickListener
