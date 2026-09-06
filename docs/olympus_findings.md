# Olympus Staff findings

- Homepage: `https://olympustaff.com/`
- Site branding/logo found on details page: `https://olympustaff.com/images/TeamX.png`
- Search input has `id="search"`, site navigation links `/series` for manga list.
- Manga detail URLs use `/series/{slug}`. Example: `/series/unlimited-bacterimancer`.
- Chapter URLs use `/series/{slug}/{chapter-number}`. Example: `/series/unlimited-bacterimancer/1`.
- Detail page example title: `Unlimited Bacterimancer`.
- Detail page cover: `https://olympustaff.com/images/manga/08eeafc781e46f2223140eaa72f197a6.jpg`.
- Detail page exposes metadata in visible text: type, status, artist, genres, synopsis, and chapters. Example genres are linked under `/series?genre=...`; status is linked under `/series?status=...`.
- Chapter list is under the `#chapter-contact` section and contains links to `/series/{slug}/{number}`. A chapter entry includes title/number and thumbnail image under `/images/chapter/...`.
- Homepage listing includes series links under `/series/{slug}` and recent chapter links under `/series/{slug}/{number}`.
- Homepage search form uses the `search` input and a search button; the exact submitted URL/query still needs to be confirmed from HTML/network inspection. Parser should support both standard query/form variants.
- Existing app is a compact Flutter app: the source and models were colocated in the former source service; UI and in-memory History/Favorites are in `lib/screens/app_screen.dart`.
- Existing app does not currently persist History/Favorites despite the user requirement; implementation must add persistence while preserving existing UI/layout.
- Existing UI had source-specific Referer headers in cards, history, details, and reader; these were replaced with the Olympus Staff Referer.
