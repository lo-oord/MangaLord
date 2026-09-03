package com.mlord.app.settings.sources.adapter

import com.mlord.app.app.core.ui.list.OnTipCloseListener
import com.mlord.app.app.settings.sources.model.SourceConfigItem

interface SourceConfigListener : OnTipCloseListener<SourceConfigItem.Tip> {

	fun onItemSettingsClick(item: SourceConfigItem.SourceItem)

	fun onItemLiftClick(item: SourceConfigItem.SourceItem)

	fun onItemShortcutClick(item: SourceConfigItem.SourceItem)

	fun onItemPinClick(item: SourceConfigItem.SourceItem)

	fun onItemEnabledChanged(item: SourceConfigItem.SourceItem, isEnabled: Boolean)
}
