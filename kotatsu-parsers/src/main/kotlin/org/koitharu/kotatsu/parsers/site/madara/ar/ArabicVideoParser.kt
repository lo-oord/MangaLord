package org.koitharu.kotatsu.parsers.site.madara.ar

import org.koitharu.kotatsu.parsers.MangaLoaderContext
import org.koitharu.kotatsu.parsers.model.AnimeStream
import org.koitharu.kotatsu.parsers.model.MangaChapter
import org.koitharu.kotatsu.parsers.site.madara.MadaraParser
import org.koitharu.kotatsu.parsers.util.parseHtml
import org.koitharu.kotatsu.parsers.util.toAbsoluteUrl

internal abstract class ArabicVideoParser(
    context: MangaLoaderContext,
    source: org.koitharu.kotatsu.parsers.model.MangaParserSource,
    domain: String,
    pageSize: Int = 12,
) : MadaraParser(context, source, domain, pageSize) {

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
