package com.mlord.app.backups.ui.restore

import com.hannesdorfmann.adapterdelegates4.dsl.adapterDelegateViewBinding
import com.mlord.app.core.ui.BaseListAdapter
import com.mlord.app.core.ui.list.OnListItemClickListener
import com.mlord.app.core.util.ext.setChecked
import com.mlord.app.databinding.ItemCheckableMultipleBinding
import com.mlord.app.list.ui.ListModelDiffCallback.Companion.PAYLOAD_CHECKED_CHANGED
import com.mlord.app.list.ui.adapter.ListItemType

class BackupSectionsAdapter(
	clickListener: OnListItemClickListener<BackupSectionModel>,
) : BaseListAdapter<BackupSectionModel>() {

	init {
		addDelegate(ListItemType.NAV_ITEM, backupSectionAD(clickListener))
	}
}

private fun backupSectionAD(
	clickListener: OnListItemClickListener<BackupSectionModel>,
) = adapterDelegateViewBinding<BackupSectionModel, BackupSectionModel, ItemCheckableMultipleBinding>(
	{ layoutInflater, parent -> ItemCheckableMultipleBinding.inflate(layoutInflater, parent, false) },
) {

	binding.root.setOnClickListener { v ->
		clickListener.onItemClick(item, v)
	}

	bind { payloads ->
		with(binding.root) {
			setText(item.titleResId)
			setChecked(item.isChecked, PAYLOAD_CHECKED_CHANGED in payloads)
			isEnabled = item.isEnabled
		}
	}
}
