package org.koitharu.kotatsu.parsers.site.madara.ar

import org.koitharu.kotatsu.parsers.MangaLoaderContext
import org.koitharu.kotatsu.parsers.model.AnimeStream
import org.koitharu.kotatsu.parsers.model.ContentRating
import org.koitharu.kotatsu.parsers.model.RATING_UNKNOWN
import org.koitharu.kotatsu.parsers.model.Manga
import org.jsoup.nodes.Document
import org.koitharu.kotatsu.parsers.model.MangaChapter
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

    override fun parseMangaList(doc: Document): List<Manga> {
        val path = if (domain == "animedar.net") "/anime-p/" else "/animes/"
        return doc.select("div.anime-card, article.anime-card, .anime-card").mapNotNull { card ->
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

    override suspend fun getChapters(manga: Manga, doc: Document): List<MangaChapter> {
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
                uploadDate = null,
                source = source,
                scanlator = null,
                branch = null,
            )
        }.sortedBy { it.number }
    }

    protected suspend fun extractDirectStreams(chapter: MangaChapter): List<AnimeStream> {
        val page = webClient.httpGet(chapter.url.toAbsoluteUrl(domain)).parseHtml()
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
}
