package com.mangalord.app.list.ui.adapter

import com.mangalord.app.list.domain.ListFilterOption

interface QuickFilterClickListener {

	fun onFilterOptionClick(option: ListFilterOption)
}
