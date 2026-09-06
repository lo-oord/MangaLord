# Team X source findings

The active Team X manga website is `https://olympustaff.com/`. The page title and branding identify the site as Team-X, and the logo used by the source is `https://olympustaff.com/images/TeamX.png`.

Team X exposes manga detail URLs as `/series/{slug}` and chapter URLs as `/series/{slug}/{chapter-number}`. The search form submits to `/search` with the GET parameter `keyword`; pagination uses the `page` parameter. The manga listing is available on the homepage and under `/series`.

The source implementation in `lib/services/team_x_source.dart` performs HTTP requests with a MangaLord User-Agent, HTML Accept headers, Arabic/English language preferences, a Team X Referer, a 20-second timeout, and HTTP status validation. It parses HTML using the existing `http` and `html` dependencies.

The parser extracts titles, canonical URLs, cover images, descriptions, author/artist metadata, genres, status, chapter URLs, and chapter page images. Image extraction supports `srcset`, `data-src`, `data-lazy-src`, `data-original`, and `src`, resolves relative URLs against the Team X base URI, removes duplicates and decorative assets, and preserves document order.

The UI remains in `lib/screens/app_screen.dart`; it now uses `TeamXSource`, `TeamXManga`, and `TeamXChapter`. Existing Home, Search, Details, Reader, History, Favorites, Refresh, Settings, and Manga Sources screens are retained without layout redesign. The local History and Favorites persistence continues to use the existing SharedPreferences integration.
