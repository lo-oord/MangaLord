package org.koitharu.kotatsu.parsers.site.madara.ar

import org.koitharu.kotatsu.parsers.MangaLoaderContext
import org.koitharu.kotatsu.parsers.model.AnimeStream
import org.koitharu.kotatsu.parsers.model.ContentRating
import org.koitharu.kotatsu.parsers.model.RATING_UNKNOWN
import org.koitharu.kotatsu.parsers.model.Manga
import org.jsoup.nodes.Document
import org.koitharu.kotatsu.parsers.model.MangaChapter
import org.koitharu.kotatsu.parsers.model.MangaListFilter
import org.koitharu.kotatsu.parsers.model.SortOrder
import org.koitharu.kotatsu.parsers.site.madara.MadaraParser
import org.koitharu.kotatsu.parsers.util.generateUid
import org.koitharu.kotatsu.parsers.util.parseHtml
import org.koitharu.kotatsu.parsers.util.attrAsRelativeUrlOrNull
import org.koitharu.kotatsu.parsers.util.toAbsoluteUrl

internal abstract class ArabicVideoParser(
    context: MangaLoaderContext,
    source: org.koitharu.kotatsu.parsers.model.MangaParserSource,
    domain: String,
    pageSize: Int = 12,
) : MadaraParser(context, source, domain, pageSize) {

    override val selectTestAsync: String = ":root"

    override suspend fun getListPage(page: Int, order: SortOrder, filter: MangaListFilter): List<Manga> {
        val query = filter.query?.trim().orEmpty()
        val url = if (query.isNotEmpty()) {
            val encoded = java.net.URLEncoder.encode(query, Charsets.UTF_8.name())
            if (domain == "animedar.net") {
                if (page <= searchPaginator.firstPage) "https://$domain/?s=$encoded"
                else "https://$domain/page/$page/?s=$encoded"
            } else if (page <= searchPaginator.firstPage) "https://$domain/?s=$encoded"
            else "https://$domain/page/$page/?s=$encoded"
        } else {
            if (domain == "animedar.net") {
                if (page <= paginator.firstPage) "https://$domain/$listUrl"
                else "https://$domain/$listUrl?page=$page"
            } else if (page <= paginator.firstPage) "https://$domain/$listUrl"
            else "https://$domain/$listUrl/page/$page/"
        }
        return parseMangaList(webClient.httpGet(url).parseHtml())
    }

    override fun parseMangaList(doc: Document): List<Manga> {
        if (domain == "animedar.net") return parseAnimeDarList(doc)
        val path = if (domain == "animedar.net") "/anime-p/" else "/animes/"
        return doc.select("div.anime-card, article.anime-card, article.bs, .anime-card").mapNotNull { card ->
            val link = card.selectFirst("a[href*='$path']") ?: return@mapNotNull null
            val href = link.attrAsRelativeUrlOrNull("href") ?: return@mapNotNull null
            val title = card.selectFirst("h2, h3, h4, .title, .anime-title")?.text()?.trim()
                ?.takeIf(String::isNotEmpty)
                ?: link.attr("title").trim().takeIf(String::isNotEmpty)
                ?: return@mapNotNull null
            val image = card.selectFirst("img")
            val cover = sequenceOf(
                image?.attr("src"), image?.attr("data-src"), image?.attr("data-lazy-src"),
                image?.attr("data-original"),
            ).mapNotNull { it?.trim() }.firstOrNull(String::isNotEmpty)
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

    private fun parseAnimeDarList(doc: Document): List<Manga> = doc.select("article.bs").mapNotNull { card ->
        val link = card.selectFirst(".bsx > a[href*='/anime-p/']") ?: return@mapNotNull null
        val href = link.attrAsRelativeUrlOrNull("href") ?: return@mapNotNull null
        val title = card.selectFirst(".tt h2, .tt")?.text()?.trim()
            ?.takeIf(String::isNotEmpty) ?: link.attr("title").trim().takeIf(String::isNotEmpty)
            ?: return@mapNotNull null
        val image = card.selectFirst("img.ts-post-image, img")
        val cover = image?.let(::coverUrl)
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
    }.distinctBy(Manga::id)

    override suspend fun getChapters(manga: Manga, doc: Document): List<MangaChapter> {
        if (domain == "animedar.net") return parseAnimeDarChapters(manga, doc)
        val direct = doc.select("a[href*='/episodes/']")
        val seasonPages = if (direct.isEmpty()) {
            doc.select("a[href*='/seasons/']").mapNotNull { season ->
                val href = season.attrAsRelativeUrlOrNull("href") ?: return@mapNotNull null
                webClient.httpGet(href.toAbsoluteUrl(domain)).parseHtml()
            }
        } else {
            emptyList()
        }
        val links = (direct + seasonPages.flatMap { it.select("a[href*='/episodes/']") })
            .mapNotNull { it.attrAsRelativeUrlOrNull("href") }
            .distinct()
        return links.mapIndexed { index, href ->
            val element = (direct + seasonPages.flatMap { it.select("a[href*='/episodes/']") })
                .firstOrNull { it.attrAsRelativeUrlOrNull("href") == href }
            val title = element?.text()?.trim().orEmpty().ifBlank { "Episode ${index + 1}" }
            val number = Regex("(?:episode|الحلقة)[^0-9]*(\\d+)", RegexOption.IGNORE_CASE)
                .find(title)?.groupValues?.getOrNull(1)?.toFloatOrNull() ?: (index + 1).toFloat()
            MangaChapter(
                id = generateUid(href),
                title = title,
                number = number,
                volume = 0,
                url = href,
                uploadDate = 0L,
                source = source,
                scanlator = null,
                branch = null,
            )
        }.sortedBy { it.number }
    }

    private fun parseAnimeDarChapters(manga: Manga, doc: Document): List<MangaChapter> {
        val groups = doc.select("#ServerList1 .divv11")
        val labels = doc.select("#EpList1 .CSB")
        return groups.mapIndexed { index, _ ->
            val number = (index + 1).toFloat()
            val title = labels.getOrNull(index)?.text()?.trim().takeIf { !it.isNullOrBlank() }
                ?: "الحلقة ${index + 1}"
            val url = "${manga.url.trimEnd('/')}?episode=${index + 1}"
            MangaChapter(
                id = generateUid(url),
                title = title,
                number = number,
                volume = 0,
                url = url,
                uploadDate = 0L,
                source = source,
                scanlator = "AnimeLek",
                branch = null,
            )
        }
    }

    protected suspend fun extractDirectStreams(chapter: MangaChapter): List<AnimeStream> {
        val page = webClient.httpGet(chapter.url.toAbsoluteUrl(domain)).parseHtml()
        if (domain == "animedar.net") return extractAnimeDarStreams(page, chapter)
        val selectors = "video source[src], video[src], source[src], iframe[src], a[href], [data-video], [data-src], [data-url]"
        return page.select(selectors)
            .mapNotNull { element ->
                val rawUrl = sequenceOf(
                    element.attr("src"), element.attr("href"), element.attr("data-video"),
                    element.attr("data-src"), element.attr("data-url"),
                ).map(String::trim).firstOrNull(String::isNotEmpty) ?: return@mapNotNull null
                val url = rawUrl.toAbsoluteUrl(domain)
                val lower = url.lowercase()
                if (!lower.contains(".m3u8") && !lower.contains(".mp4") && !lower.contains(".m4v")) {
                    return@mapNotNull null
                }
                val quality = element.attr("label").ifBlank { element.attr("data-quality") }
                    .ifBlank { element.attr("title") }.takeIf(String::isNotBlank)
                AnimeStream(
                    name = quality?.let { "${source.title} • $it" } ?: source.title,
                    url = url,
                    headers = mapOf("Referer" to "https://$domain/"),
                    quality = quality,
                )
            }
            .distinctBy(AnimeStream::url)
    }

    private fun extractAnimeDarStreams(page: Document, chapter: MangaChapter): List<AnimeStream> {
        val episode = Regex("[?&]episode=(\\d+)").find(chapter.url)?.groupValues?.getOrNull(1)
            ?.toIntOrNull()?.coerceAtLeast(1) ?: 1
        val group = page.select("#ServerList1 .divv11").getOrNull(episode - 1) ?: return emptyList()
        return group.select("li[data]").mapNotNull { server ->
            val id = server.attr("data").trim().takeIf(String::isNotEmpty) ?: return@mapNotNull null
            val type = server.attr("type").ifBlank { server.className() }.lowercase()
			val url = when {
				type.contains("videa") && id.startsWith("http") -> id
				type.contains("videa") -> "https://videa.hu/player?v=$id"
				type.contains("asnwish") -> "https://asnwish.com/e/$id"
				type.contains("mp4upload") -> "https://www.mp4upload.com/embed-$id.html"
				type.contains("4shared") -> when {
					id.startsWith("http") -> id
					id.startsWith("s:/") -> id.replaceFirst("s:/", "https://")
					id.startsWith("//") -> "https:$id"
					else -> "https://$id"
				}
				type.contains("mega") -> if (id.startsWith("http")) id else "https://mega.nz/embed/$id"
				type.contains("vidshare") -> "https://vidshare.tv/embed-$id.html"
				type.contains("vidbem") -> "https://vidbem.com/embed-$id.html"
				type.contains("vidbam") -> "https://vidbam.org/embed-$id.html"
				type.contains("samaup") -> "https://samaup.cc/embed-$id.html"
				type.contains("segavid") -> "https://segavid.com/embed-$id.html"
				type.contains("sendvid") -> "https://sendvid.com/embed/$id"
				type.contains("vidfast") -> "https://vidfast.co/embed-$id.html"
				type.contains("clipwatching") -> "https://clipwatching.com/embed-$id.html"
				type.contains("dood") -> "https://dood.so/e/$id"
				else -> return@mapNotNull null
            }
			val quality = server.attr("quality-data").trim().takeIf(String::isNotEmpty)
			AnimeStream(
				name = "AnimeLek • ${server.text().trim().ifEmpty { type }}${quality?.let { " • $it" }.orEmpty()}",
                url = url,
                headers = mapOf("Referer" to chapter.url.toAbsoluteUrl(domain)),
                quality = quality,
            )
        }.distinctBy(AnimeStream::url)
    }

    private fun coverUrl(image: org.jsoup.nodes.Element): String? = sequenceOf(
        image.attr("data-src"), image.attr("data-lazy-src"), image.attr("data-original"), image.attr("src"),
    ).map { it.trim() }.firstOrNull(String::isNotEmpty)?.let { raw ->
        // WordPress image proxy URLs are unreliable for Android clients; use the origin image URL.
        raw.replace(Regex("https?://i\\d+\\.wp\\.com/animedar\\.net/"), "https://animedar.net/")
            .toAbsoluteUrl(domain)
    }
}
