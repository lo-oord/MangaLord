package com.mlord.app.list.ui.adapter

import com.mlord.app.list.domain.ListFilterOption

interface QuickFilterClickListener {

	fun onFilterOptionClick(option: ListFilterOption)
}
