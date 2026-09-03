package com.mlord.app.settings.search

import androidx.preference.PreferenceFragmentCompat
import com.mlord.app.app.list.ui.model.ListModel

data class SettingsItem(
	val key: String,
	val title: CharSequence,
	val breadcrumbs: List<String>,
	val fragmentClass: Class<out PreferenceFragmentCompat>,
) : ListModel {

	override fun areItemsTheSame(other: ListModel): Boolean {
		return other is SettingsItem && other.key == key && other.fragmentClass == fragmentClass
	}
}
