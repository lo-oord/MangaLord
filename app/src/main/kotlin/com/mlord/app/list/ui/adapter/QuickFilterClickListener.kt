package com.mlord.app.app.list.ui.adapter

import com.mlord.app.app.app.list.domain.ListFilterOption

interface QuickFilterClickListener {

	fun onFilterOptionClick(option: ListFilterOption)
}
