package com.mlord.core.model.parcelable

import android.os.Parcel
import kotlinx.parcelize.Parceler
import com.mlord.core.model.MangaSource
import com.mlord.parsers.model.MangaSource

class MangaSourceParceler : Parceler<MangaSource> {

	override fun create(parcel: Parcel): MangaSource = MangaSource(parcel.readString())

	override fun MangaSource.write(parcel: Parcel, flags: Int) {
		parcel.writeString(name)
	}
}
