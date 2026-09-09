# Supabase setup

MangaLord uses Supabase Auth, Postgres, and Storage. Firebase is not required.

Build with:

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY \
  --dart-define=SUPABASE_REDIRECT_SCHEME=com.mangalord.app
```

Never put the Supabase service-role key in the app. Only the public anon key belongs in a client build.

## Supabase Dashboard

Enable Email and Google under Authentication > Providers. For Google, configure the OAuth client and add `com.mangalord.app://oauthredirect` as a mobile redirect URL. Add the same URL to Supabase Authentication > URL Configuration. Create a public Storage bucket named `profile-images` and configure its policies so authenticated users can read and write only their own `{user.id}/...` objects.

Run `supabase/schema.sql` in the SQL editor. Its Row Level Security policies limit profiles, favorites, and history to the authenticated user who owns the row.

## Test

Test email registration/login, Google browser OAuth, session persistence, logout, password reset, profile updates, profile image upload, and favorite/history synchronization on two devices. When no profile photo exists, the account screen displays a black avatar. Existing local favorites and history remain intact.
