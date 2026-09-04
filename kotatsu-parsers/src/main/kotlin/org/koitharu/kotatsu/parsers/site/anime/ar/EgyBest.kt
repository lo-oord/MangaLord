package org.koitharu.kotatsu.parsers.site.anime.ar

import okhttp3.Headers
import org.jsoup.nodes.Document
import org.jsoup.parser.Parser
import org.koitharu.kotatsu.parsers.MangaLoaderContext
import org.koitharu.kotatsu.parsers.MangaSourceParser
import org.koitharu.kotatsu.parsers.config.ConfigKey
import org.koitharu.kotatsu.parsers.core.PagedMangaParser
import org.koitharu.kotatsu.parsers.model.AnimeStream
import org.koitharu.kotatsu.parsers.model.ContentRating
import org.koitharu.kotatsu.parsers.model.ContentType
import org.koitharu.kotatsu.parsers.model.Manga
import org.koitharu.kotatsu.parsers.model.MangaChapter
import org.koitharu.kotatsu.parsers.model.MangaListFilter
import org.koitharu.kotatsu.parsers.model.MangaListFilterCapabilities
import org.koitharu.kotatsu.parsers.model.MangaListFilterOptions
import org.koitharu.kotatsu.parsers.model.MangaParserSource
import org.koitharu.kotatsu.parsers.model.RATING_UNKNOWN
import org.koitharu.kotatsu.parsers.model.SortOrder
import org.koitharu.kotatsu.parsers.util.attrAsRelativeUrlOrNull
import org.koitharu.kotatsu.parsers.util.generateUid
import org.koitharu.kotatsu.parsers.util.parseHtml
import org.koitharu.kotatsu.parsers.util.parseRaw
import org.koitharu.kotatsu.parsers.util.toAbsoluteUrl
import org.koitharu.kotatsu.parsers.util.urlEncoded
import java.util.EnumSet

@MangaSourceParser("EGYBEST", "EgyBest", "ar", ContentType.ANIME)
internal class EgyBest(context: MangaLoaderContext) : PagedMangaParser(
    context = context,
    source = MangaParserSource.EGYBEST,
    pageSize = PAGE_SIZE,
    searchPageSize = PAGE_SIZE,
) {

    override val configKeyDomain = ConfigKey.Domain(DEFAULT_DOMAIN)

    override val availableSortOrders: Set<SortOrder> = EnumSet.of(
        SortOrder.NEWEST,
        SortOrder.UPDATED,
        SortOrder.RATING,
        SortOrder.ALPHABETICAL,
    )

    override val filterCapabilities = MangaListFilterCapabilities(isSearchSupported = true)

    override suspend fun getFilterOptions() = MangaListFilterOptions()

    override suspend fun getListPage(
        page: Int,
        order: SortOrder,
        filter: MangaListFilter,
    ): List<Manga> {
        val query = filter.query?.trim().orEmpty()
        val path = if (query.isEmpty()) {
            "/anime-movies-series?page=$page"
        } else {
            "/search?q=${query.urlEncoded()}&page=$page"
        }
        val document = webClient.httpGet(path.toAbsoluteUrl(domain)).parseHtml()
        return parseCards(document).distinctBy(Manga::id)
    }

    override suspend fun getDetails(manga: Manga): Manga {
        val document = webClient.httpGet(manga.url.toAbsoluteUrl(domain)).parseHtml()
        val raw = document.html()
        val title = document.selectFirst("h1")?.text()?.trim().orEmpty().ifBlank { manga.title }
        val cover = document.selectFirst("meta[property=og:image]")?.attr("content")
            ?.trim()?.takeIf(String::isNotEmpty) ?: manga.coverUrl
        val description = document.select("p").map { it.text().trim() }
            .filter { it.length > 80 }
            .maxByOrNull(String::length)
            ?: manga.description
        val chapters = parseEpisodes(raw).ifEmpty { parseMovieChapter(raw) }
        return manga.copy(
            title = title,
            publicUrl = manga.url.toAbsoluteUrl(domain),
            coverUrl = cover,
            largeCoverUrl = cover,
            description = description,
            chapters = chapters,
        )
    }

    override suspend fun getPages(chapter: MangaChapter) = emptyList<org.koitharu.kotatsu.parsers.model.MangaPage>()

    override suspend fun getVideoStreams(chapter: MangaChapter): List<AnimeStream> {
        val watchUrl = chapter.url.toAbsoluteUrl(domain)
        val raw = runCatching { webClient.httpGet(watchUrl).parseRaw() }.getOrNull() ?: return emptyList()
        val decoded = Parser.unescapeEntities(raw, false).replace("\\/", "/")
        val urls = EMBED_URL.findAll(decoded).map { it.groupValues[1] }.distinct().toList()
        return urls.mapIndexed { index, url ->
            val mediaUrl = resolveMediaUrl(url) ?: url
            AnimeStream(
                name = "EgyBest • ${qualityFor(index, urls.size)}",
                url = mediaUrl,
                headers = mapOf("Referer" to watchUrl, "User-Agent" to USER_AGENT),
                quality = qualityFor(index, urls.size),
            )
        }
    }

    private suspend fun resolveMediaUrl(embedUrl: String): String? {
        val raw = runCatching {
            webClient.httpGet(
                embedUrl,
                Headers.Builder().add("Referer", "https://$domain/").add("User-Agent", USER_AGENT).build(),
            ).parseRaw()
        }.getOrNull() ?: return null
        val decoded = Parser.unescapeEntities(raw, false).replace("\\/", "/")
        return Regex("https?://[^\\s\\\"'<>]+?\\.(?:m3u8|mp4)(?:\\?[^\\s\\\"'<>]*)?", RegexOption.IGNORE_CASE)
            .find(decoded)?.value?.trimEnd('\\', '"', '\'', ')', ']')
    }

    private fun parseCards(document: Document): List<Manga> {
        return document.select("a[href*='/titles/']").mapNotNull { link ->
            val href = link.attrAsRelativeUrlOrNull("href") ?: return@mapNotNull null
            val title = link.text().trim().takeIf(String::isNotEmpty)
                ?: link.selectFirst("img")?.attr("alt")?.trim()
                ?: return@mapNotNull null
            val image = link.selectFirst("img") ?: link.parent()?.selectFirst("img")
            val cover = image?.let {
                sequenceOf(it.attr("src"), it.attr("data-src"), it.attr("data-lazy-src"))
                    .map(String::trim).firstOrNull(String::isNotEmpty)
            }
            Manga(
                id = generateUid(href),
                title = title,
                altTitles = emptySet(),
                url = href,
                publicUrl = href.toAbsoluteUrl(domain),
                rating = RATING_UNKNOWN,
                coverUrl = cover,
                tags = emptySet(),
                state = null,
                authors = emptySet(),
                description = null,
                source = source,
                contentRating = ContentRating.SAFE,
            )
        }
    }

    private fun parseEpisodes(raw: String): List<MangaChapter> {
        return EPISODE.findAll(raw).mapNotNull { match ->
            val number = match.groupValues[1].toFloatOrNull() ?: return@mapNotNull null
            val videoId = match.groupValues[2].toLongOrNull() ?: return@mapNotNull null
            val url = "/watch/$videoId"
            MangaChapter(
                id = generateUid(url),
                title = "الحلقة ${if (number % 1f == 0f) number.toInt() else number}",
                number = number,
                volume = 0,
                url = url,
                uploadDate = 0L,
                source = source,
                scanlator = "EgyBest",
                branch = null,
            )
        }.distinctBy(MangaChapter::id).sortedBy(MangaChapter::number).toList()
    }

    private fun parseMovieChapter(raw: String): List<MangaChapter> {
        val titleId = TITLE_ID.find(raw)?.groupValues?.getOrNull(1) ?: return emptyList()
        val videoId = PRIMARY_VIDEO.find(raw)?.groupValues?.getOrNull(1) ?: return emptyList()
        if (videoId == "null") return emptyList()
        val url = "/watch/$videoId"
        return listOf(
            MangaChapter(
                id = generateUid(url),
                title = "الفيلم",
                number = 1f,
                volume = 0,
                url = url,
                uploadDate = 0L,
                source = source,
                scanlator = "EgyBest",
                branch = titleId,
            ),
        )
    }

    private fun qualityFor(index: Int, count: Int): String = when {
        count >= 3 && index == 0 -> "1080p"
        count >= 2 && index == 1 -> "720p"
        else -> "HD"
    }

    private companion object {
        const val DEFAULT_DOMAIN = "www.egybest.co.in"
        const val PAGE_SIZE = 24
        const val USER_AGENT = "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36"
        val EMBED_URL = Regex("""https?://egybestvid\.com/[^\"'\\\s]+""", RegexOption.IGNORE_CASE)
        val EPISODE = Regex("episode_number\\\"\\s*:\\s*(\\d+(?:\\.\\d+)?).*?primary_video\\\"\\s*:\\s*\\{\\\"id\\\":(\\d+)", setOf(RegexOption.IGNORE_CASE, RegexOption.DOT_MATCHES_ALL))
        val PRIMARY_VIDEO = Regex("primary_video\\\"\\s*:\\s*\\{\\\"id\\\":(\\d+)")
        val TITLE_ID = Regex("\\\"id\\\":(\\d+),\\\"name\\\":\\\".*?\\\",\\\"release_date", RegexOption.DOT_MATCHES_ALL)
    }
}
