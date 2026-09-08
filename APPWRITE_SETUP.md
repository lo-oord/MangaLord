# Appwrite setup for MangaLord

The Flutter client is configured for project `6a9ff222002ab1073f0f` at `https://sgp.cloud.appwrite.io/v1`.

Create one database with ID `MangaLordDB`, then create these collections with the exact IDs below:

| Collection ID | Required attributes | Permissions |
|---|---|---|
| `Favorites` | `userId` string, `mangaId` string, `title` string, `cover` string, `sourceKey` string, `sourceName` string, `author` string, `genre` string, `description` string, `chapters` integer, `status` string, `lastChapterNumber` string, `lastChapterAt` string, `lastNotifiedChapterNumber` string, `chapterItems` string (JSON), `updatedAt` datetime/string | No public access; documents are created with `read/write` permission for `Role.user(userId)` |
| `History` | `userId` string, `mangaId` string, `title` string, `cover` string, `sourceKey` string, `sourceName` string, `author` string, `genre` string, `description` string, `chapters` integer, `status` string, `lastChapterNumber` string, `lastChapterAt` string, `lastNotifiedChapterNumber` string, `chapterItems` string (JSON), `updatedAt` datetime/string | No public access; documents are created with `read/write` permission for `Role.user(userId)` |

Enable Google under **Auth → Settings → OAuth2 Providers**. Register the Android package `com.mangalord.app` and the iOS bundle identifier in the Appwrite project. Add the callback URL `appwrite-callback-6a9ff222002ab1073f0f://success` as an allowed platform/deep-link URL where required by the Appwrite console.

The app never includes an Appwrite API key. Database IDs, collection IDs, and attributes must exist in the Appwrite console before cloud synchronization can succeed.
