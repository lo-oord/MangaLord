package org.koitharu.kotatsu.parsers.site.madara.ar

import org.jsoup.nodes.Document
import org.jsoup.nodes.Element
import org.json.JSONObject
import org.koitharu.kotatsu.parsers.MangaLoaderContext
import org.koitharu.kotatsu.parsers.MangaSourceParser
import org.koitharu.kotatsu.parsers.model.AnimeStream
import org.koitharu.kotatsu.parsers.model.ContentType
import org.koitharu.kotatsu.parsers.model.Manga
import org.koitharu.kotatsu.parsers.model.MangaChapter
import org.koitharu.kotatsu.parsers.model.MangaListFilter
import org.koitharu.kotatsu.parsers.model.SortOrder
import org.koitharu.kotatsu.parsers.model.MangaParserSource
import org.koitharu.kotatsu.parsers.model.MangaPage
import org.koitharu.kotatsu.parsers.model.MangaState
import org.koitharu.kotatsu.parsers.model.RATING_UNKNOWN
import org.koitharu.kotatsu.parsers.site.madara.MadaraParser
import org.koitharu.kotatsu.parsers.util.generateUid
import org.koitharu.kotatsu.parsers.util.parseHtml
import org.koitharu.kotatsu.parsers.util.parseJson
import org.koitharu.kotatsu.parsers.util.toAbsoluteUrl

@MangaSourceParser("MOVIE_BOX", "Movie Box", "", ContentType.MOVIES_SERIES)
internal class MovieBox(context: MangaLoaderContext) :
    MadaraParser(context, MangaParserSource.MOVIE_BOX, "movie-box.co") {

    override val listUrl = "web/movie"

    override suspend fun getListPage(page: Int, order: SortOrder, filter: MangaListFilter): List<Manga> {
        val query = filter.query?.trim().orEmpty()
        val json = webClient.httpGet(
            "https://h5-api.aoneroom.com/wefeed-h5api-bff/tab-operating?tabId=ONEROOM_MOVIE&host=movie-box.co",
        ).parseJson()
        val subjects = collectSubjects(json)
        return subjects.asSequence()
            .filter { query.isBlank() || it.optString("title").contains(query, ignoreCase = true) }
            .mapNotNull(::subjectToManga)
            .distinctBy(Manga::url)
            .toList()
    }

    override fun parseMangaList(doc: Document): List<Manga> = doc.select("a[href*='/detail/']")
        .mapNotNull(::parseCard)
        .distinctBy(Manga::url)

    private fun collectSubjects(json: JSONObject): List<JSONObject> {
        val result = ArrayList<JSONObject>()
        val operating = json.optJSONObject("data")?.optJSONArray("operatingList") ?: return result
        for (i in 0 until operating.length()) {
            val row = operating.optJSONObject(i) ?: continue
            val direct = row.optJSONArray("subjects")
            if (direct != null) {
                for (j in 0 until direct.length()) direct.optJSONObject(j)?.let(result::add)
            }
            val bannerItems = row.optJSONObject("banner")?.optJSONArray("items")
            if (bannerItems != null) {
                for (j in 0 until bannerItems.length()) {
                    val subject = bannerItems.optJSONObject(j)?.optJSONObject("subject")
                    subject?.let(result::add)
                }
            }
        }
        return result
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
        val json = webClient.httpGet("https://h5-api.aoneroom.com/wefeed-h5api-bff/detail?detailPath=$detailPath").parseJson()
        val subject = json.optJSONObject("data")?.optJSONObject("subject") ?: return manga
        val subjectId = subject.optString("subjectId").takeIf { it.isNotBlank() } ?: return manga
        val title = subject.optString("title").takeIf { it.isNotBlank() } ?: manga.title
        val coverObject = subject.optJSONObject("cover")
        val cover = listOf(
            coverObject?.optString("url"),
            coverObject?.optString("thumbnail"),
            subject.optString("coverUrl"),
        ).firstOrNull { !it.isNullOrBlank() } ?: manga.coverUrl
        val chapter = MangaChapter(
            id = generateUid("$subjectId:$detailPath:1:1"), title = title, number = 1f, volume = 0,
            url = "/detail/$detailPath?subjectId=$subjectId&se=1&ep=1", scanlator = null,
            uploadDate = 0L, branch = null, source = source,
        )
        val tags = subject.optString("genre").split(',').map { it.trim() }.filter { it.isNotEmpty() }
            .mapNotNull { genre ->
                createMangaTag(Element("a").attr("href", "/genre/$genre").text(genre))
            }.toSet()
        return manga.copy(
            title = title, publicUrl = manga.url.toAbsoluteUrl(domain), coverUrl = cover,
            largeCoverUrl = cover, description = subject.optString("description").takeIf { it.isNotBlank() },
            chapters = listOf(chapter), tags = tags,
        )
    }

    override suspend fun getPages(chapter: MangaChapter): List<MangaPage> = emptyList()

    override suspend fun getVideoStreams(chapter: MangaChapter): List<AnimeStream> {
        val query = chapter.url.substringAfter('?', "").split('&').mapNotNull { part ->
            part.split('=', limit = 2).takeIf { it.size == 2 }?.let { it[0] to it[1] }
        }.toMap()
        val subjectId = query["subjectId"] ?: return emptyList()
        val detailPath = chapter.url.substringAfter("/detail/").substringBefore('?')
        val playUrl = "https://h5-api.aoneroom.com/wefeed-h5api-bff/subject/play?subjectId=$subjectId&se=${query["se"] ?: "1"}&ep=${query["ep"] ?: "1"}&detailPath=$detailPath"
        val data = webClient.httpGet(playUrl).parseJson().optJSONObject("data") ?: return emptyList()
        val streams = data.optJSONArray("streams") ?: return emptyList()
        return buildList {
            for (index in 0 until streams.length()) {
                val item = streams.optJSONObject(index) ?: continue
                val url = item.optString("url").takeIf { it.startsWith("http") } ?: continue
                val quality = item.optString("resolutions").takeIf { it.isNotBlank() }
                add(AnimeStream(
                    name = quality?.let { "Movie Box • ${it}p" } ?: "Movie Box • ${index + 1}",
                    url = url, headers = mapOf("Referer" to "https://movie-box.co/"), quality = quality,
                ))
            }
        }.distinctBy(AnimeStream::url)
    }
}
