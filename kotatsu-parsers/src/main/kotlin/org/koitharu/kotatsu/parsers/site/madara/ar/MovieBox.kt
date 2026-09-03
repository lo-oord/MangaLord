package org.koitharu.kotatsu.parsers.site.madara.ar

import java.security.MessageDigest
import okhttp3.Headers
import okhttp3.HttpUrl.Companion.toHttpUrl
import org.json.JSONArray
import org.json.JSONObject
import org.jsoup.nodes.Document
import org.jsoup.nodes.Element
import org.koitharu.kotatsu.parsers.MangaLoaderContext
import org.koitharu.kotatsu.parsers.MangaSourceParser
import org.koitharu.kotatsu.parsers.model.AnimeStream
import org.koitharu.kotatsu.parsers.model.ContentType
import org.koitharu.kotatsu.parsers.model.Manga
import org.koitharu.kotatsu.parsers.model.MangaChapter
import org.koitharu.kotatsu.parsers.model.MangaListFilter
import org.koitharu.kotatsu.parsers.model.MangaPage
import org.koitharu.kotatsu.parsers.model.MangaParserSource
import org.koitharu.kotatsu.parsers.model.MangaState
import org.koitharu.kotatsu.parsers.model.RATING_UNKNOWN
import org.koitharu.kotatsu.parsers.model.SortOrder
import org.koitharu.kotatsu.parsers.site.madara.MadaraParser
import org.koitharu.kotatsu.parsers.util.generateUid
import org.koitharu.kotatsu.parsers.util.parseHtml
import org.koitharu.kotatsu.parsers.util.parseJson
import org.koitharu.kotatsu.parsers.util.toAbsoluteUrl

@MangaSourceParser("MOVIE_BOX", "Movie Box", "", ContentType.MOVIES_SERIES)
internal class MovieBox(context: MangaLoaderContext) :
    MadaraParser(context, MangaParserSource.MOVIE_BOX, "movie-box.co") {

    private companion object {
        const val API = "https://h5-api.aoneroom.com/wefeed-h5api-bff"
        const val SITE = "https://movie-box.co/"
        const val MOVIE_SUBJECT_TYPE = 1
        const val SERIES_SUBJECT_TYPE = 2
    }

    override val listUrl = "web/movie"

    override suspend fun getListPage(page: Int, order: SortOrder, filter: MangaListFilter): List<Manga> {
        val query = filter.query?.trim().orEmpty()
        val subjects = if (query.isBlank()) {
            val json = apiGet("/tab-operating?tabId=ONEROOM_MOVIE&host=movie-box.co")
            collectSubjects(json)
        } else {
            println("MovieBox Search: keyword='$query', page=$page")
            val body = JSONObject()
                .put("keyword", query)
                .put("page", page)
                .put("perPage", 18)
                .put("subjectType", 0)
            val json = webClient.httpPost(
                "$API/subject/search".toHttpUrl(), body, apiHeaders(json = true),
            ).parseJson()
            collectSearchSubjects(json)
        }
        return subjects.asSequence()
            .mapNotNull(::subjectToManga)
            .distinctBy(Manga::url)
            .toList()
    }

    override fun parseMangaList(doc: Document): List<Manga> = doc.select("a[href*='/detail/']")
        .mapNotNull(::parseCard)
        .distinctBy(Manga::url)

    private suspend fun apiGet(path: String): JSONObject = webClient.httpGet(
        "$API$path".toHttpUrl(), apiHeaders(),
    ).parseJson()

    private fun apiHeaders(json: Boolean = false): Headers = Headers.Builder()
        .add("Accept", "application/json")
        .apply { if (json) add("Content-Type", "application/json; charset=utf-8") }
        .add("Referer", SITE)
        .add("Origin", "https://movie-box.co")
        .add("X-Request-Lang", "en")
        .add("X-Client-Info", "{\"timezone\":\"UTC\"}")
        .add("X-Client-Token", anonymousClientToken())
        .add("X-Vip-Restrict", "1")
        .build()

    private fun anonymousClientToken(): String {
        val timestamp = System.currentTimeMillis() / 1000L
        val reversed = timestamp.toString().reversed()
        val digest = MessageDigest.getInstance("MD5")
            .digest(reversed.toByteArray())
            .joinToString("") { "%02x".format(it) }
        return "$timestamp,$digest"
    }

    private fun collectSubjects(json: JSONObject): List<JSONObject> {
        val result = ArrayList<JSONObject>()
        val operating = json.optJSONObject("data")?.optJSONArray("operatingList") ?: return result
        for (i in 0 until operating.length()) {
            val row = operating.optJSONObject(i) ?: continue
            row.optJSONArray("subjects")?.appendObjectsTo(result)
            row.optJSONObject("banner")?.optJSONArray("items")?.let { items ->
                for (j in 0 until items.length()) {
                    items.optJSONObject(j)?.optJSONObject("subject")?.let(result::add)
                }
            }
        }
        return result
    }

    private fun collectSearchSubjects(json: JSONObject): List<JSONObject> {
        val data = json.optJSONObject("data") ?: return emptyList()
        return sequenceOf("subjectList", "subjects", "list")
            .mapNotNull(data::optJSONArray)
            .firstOrNull()
            ?.let { array -> buildList { array.appendObjectsTo(this) } }
            .orEmpty()
    }

    private fun JSONArray.appendObjectsTo(target: MutableList<JSONObject>) {
        for (i in 0 until length()) optJSONObject(i)?.let(target::add)
    }

    private fun subjectToManga(subject: JSONObject): Manga? {
        val detailPath = subject.optString("detailPath").takeIf { it.isNotBlank() } ?: return null
        val title = subject.optString("title").takeIf { it.isNotBlank() } ?: return null
        val cover = subject.optJSONObject("cover")?.optString("url")?.takeIf { it.isNotBlank() }
        val url = "/detail/$detailPath"
        return Manga(
            id = generateUid(url), url = url, publicUrl = url.toAbsoluteUrl(domain),
            altTitles = emptySet(), title = title, authors = emptySet(), coverUrl = cover,
            tags = emptySet(), rating = subject.optString("imdbRatingValue").toFloatOrNull() ?: RATING_UNKNOWN,
            state = MangaState.FINISHED, contentRating = null, source = source,
        )
    }

    private fun parseCard(element: Element): Manga? {
        val url = element.attr("href").trim().takeIf { it.startsWith("/detail/") } ?: return null
        val title = element.text().trim().takeIf { it.isNotEmpty() } ?: return null
        val imageElement = element.selectFirst("img") ?: element.parent()?.selectFirst("img")
        val image = imageElement?.let {
            listOf("src", "data-src", "data-original", "data-lazy-src", "data-image").asSequence()
                .map { attribute -> it.attr(attribute).trim() }
                .firstOrNull(String::isNotEmpty)
                ?: it.attr("srcset").substringBefore(',').trim().substringBefore(' ')
        }
        return Manga(
            id = generateUid(url), url = url, publicUrl = url.toAbsoluteUrl(domain),
            altTitles = emptySet(), title = title, authors = emptySet(),
            coverUrl = image?.takeIf { it.isNotBlank() }?.toAbsoluteUrl(domain),
            tags = emptySet(), rating = RATING_UNKNOWN, state = MangaState.FINISHED,
            contentRating = null, source = source,
        )
    }

    override suspend fun getDetails(manga: Manga): Manga {
        val detailPath = manga.url.substringAfter("/detail/").substringBefore('?')
        println("MovieBox Details: loading detailPath='$detailPath'")
        val json = apiGet("/detail?detailPath=$detailPath")
        val data = json.optJSONObject("data") ?: error("MovieBox Details failed: data missing")
        val subject = data.optJSONObject("subject") ?: error("MovieBox Details failed: subject missing")
        val subjectId = subject.optString("subjectId").takeIf { it.isNotBlank() }
            ?: error("MovieBox Subject ID missing for '$detailPath'")
        val title = subject.optString("title").takeIf { it.isNotBlank() } ?: manga.title
        val coverObject = subject.optJSONObject("cover")
        val cover = listOf(
            coverObject?.optString("url"), coverObject?.optString("thumbnail"), subject.optString("coverUrl"),
        ).firstOrNull { !it.isNullOrBlank() } ?: manga.coverUrl
        val chapters = if (subject.optInt("subjectType") == MOVIE_SUBJECT_TYPE) {
            listOf(createChapter(subjectId, detailPath, title, 0, 0, null))
        } else {
            createSeriesChapters(data.optJSONObject("resource"), subjectId, detailPath, title)
        }
        println("MovieBox Details: subject ID=$subjectId, chapters=${chapters.size}")
        val tags = subject.optString("genre").split(',').map { it.trim() }.filter { it.isNotEmpty() }
            .mapNotNull { genre -> createMangaTag(Element("a").attr("href", "/genre/$genre").text(genre)) }
            .toSet()
        return manga.copy(
            title = title, publicUrl = manga.url.toAbsoluteUrl(domain), coverUrl = cover,
            largeCoverUrl = cover, description = subject.optString("description").takeIf { it.isNotBlank() },
            chapters = chapters, tags = tags,
        )
    }

    private fun createSeriesChapters(
        resource: JSONObject?, subjectId: String, detailPath: String, title: String,
    ): List<MangaChapter> {
        val seasons = resource?.optJSONArray("seasons") ?: return listOf(
            createChapter(subjectId, detailPath, title, 1, 1, "Season 1"),
        )
        return buildList {
            for (i in 0 until seasons.length()) {
                val season = seasons.optJSONObject(i) ?: continue
                val se = season.optInt("se", i + 1)
                val maxEp = season.optInt("maxEp", 0)
                for (ep in 1..maxEp) {
                    add(createChapter(subjectId, detailPath, title, se, ep, "Season $se"))
                }
            }
        }.ifEmpty { listOf(createChapter(subjectId, detailPath, title, 1, 1, "Season 1")) }
    }

    private fun createChapter(
        subjectId: String, detailPath: String, title: String, season: Int, episode: Int, branch: String?,
    ) = MangaChapter(
        id = generateUid("$subjectId:$detailPath:$season:$episode"),
        title = if (season == 0) title else "Season $season · Episode $episode",
        number = episode.toFloat(), volume = season,
        url = "/detail/$detailPath?subjectId=$subjectId&se=$season&ep=$episode",
        scanlator = null, uploadDate = 0L, branch = branch, source = source,
    )

    override suspend fun getPages(chapter: MangaChapter): List<MangaPage> = emptyList()

    override suspend fun getVideoStreams(chapter: MangaChapter): List<AnimeStream> {
        val query = chapter.url.substringAfter('?', "").split('&').mapNotNull { part ->
            part.split('=', limit = 2).takeIf { it.size == 2 }?.let { it[0] to it[1] }
        }.toMap()
        val subjectId = query["subjectId"]?.takeIf { it.isNotBlank() }
            ?: error("MovieBox Stream resolution failed: Subject ID missing")
        val season = query["se"] ?: "0"
        val episode = query["ep"] ?: "0"
        val detailPath = chapter.url.substringAfter("/detail/").substringBefore('?')
        val url = "$API/subject/play".toHttpUrl().newBuilder()
            .addQueryParameter("subjectId", subjectId)
            .addQueryParameter("se", season)
            .addQueryParameter("ep", episode)
            .addQueryParameter("detailPath", detailPath)
            .addQueryParameter("streamSignType", "1")
            .build()
        println("MovieBox Resolve: subject ID=$subjectId, season=$season, episode=$episode")
        val data = webClient.httpGet(url, apiHeaders()).parseJson()
            .optJSONObject("data") ?: error("MovieBox Stream resolution failed: data missing")
        val result = buildList {
            addStreams(data.optJSONArray("streams"), this)
            addStreams(data.optJSONArray("hls"), this)
            addStreams(data.optJSONArray("dash"), this)
        }.distinctBy(AnimeStream::url)
        if (result.isEmpty()) error("MovieBox Empty stream list for season=$season episode=$episode")
        println("MovieBox Resolve: selected ${result.size} stream(s): ${result.joinToString { it.name }}")
        return result
    }

    private fun addStreams(array: JSONArray?, target: MutableList<AnimeStream>) {
        if (array == null) return
        for (index in 0 until array.length()) {
            val item = array.opt(index)
            val json = item as? JSONObject
            val url = when (item) {
                is String -> item
                is JSONObject -> item.optString("url").ifBlank {
                    item.optJSONObject("videoAddress")?.optString("url").orEmpty()
                }
                else -> ""
            }.takeIf { it.startsWith("http", ignoreCase = true) } ?: continue
            val quality = json?.let {
                when {
                    it.has("resolution") -> it.optInt("resolution").takeIf { value -> value > 0 }?.toString()
                    it.optString("resolutions").isNotBlank() -> it.optString("resolutions").removeSuffix("p")
                    it.optString("definition").isNotBlank() -> it.optString("definition").removeSuffix("p")
                    else -> null
                }
            }
            target += AnimeStream(
                name = quality?.let { "Movie Box • ${it}p" } ?: "Movie Box • ${index + 1}",
                url = url, headers = mapOf("Referer" to SITE, "Origin" to "https://movie-box.co"), quality = quality,
            )
        }
    }
}
