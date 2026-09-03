package com.mangalord.app.explore.ui.adapter

import android.view.View
import com.mangalord.app.list.ui.adapter.ListHeaderClickListener
import com.mangalord.app.list.ui.adapter.ListStateHolderListener

interface ExploreListEventListener : ListStateHolderListener, View.OnClickListener, ListHeaderClickListener
