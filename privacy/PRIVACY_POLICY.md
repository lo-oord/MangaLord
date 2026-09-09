# MangaLord Privacy Policy

**Effective date:** September 9, 2026

This Privacy Policy explains how MangaLord handles information when you use the MangaLord application. It is based on the current application implementation and may be updated when the application’s data practices change.

## 1. Introduction

MangaLord is a cross-platform application for discovering and reading manga and browsing anime-related content. The application can be used as a guest. An account is needed only for account-based synchronization features such as favorites and history.

## 2. Information We May Collect

MangaLord handles only the information needed to provide the features that you use. Depending on your choices, this may include:

| Category | Information | Why it is used |
|---|---|---|
| Account information | Email address, account identifier, display name, optional biography, and optional profile image | Creating and maintaining your account and showing your profile |
| Authentication information | Sign-in state and authentication metadata provided by Supabase Auth or an enabled OAuth provider | Signing you in, maintaining a session, and protecting account data |
| User content and preferences | Favorites, reading history, selected language, notification preference, enabled content sources, downloads, and playback or reading progress | Providing library, history, preference, offline, player, and reader features |
| Technical requests | Network requests required to retrieve content, images, chapters, episodes, and metadata from enabled external sources | Displaying content requested by you |

MangaLord does not intentionally request or collect payment card information, government identifiers, contacts, precise location, microphone recordings, or camera recordings.

## 3. Account Information and Authentication

You may browse MangaLord without creating an account. If you create an account, MangaLord uses Supabase Auth for email/password authentication and the authentication methods enabled for the project, including Google OAuth where configured.

The account profile may contain your email address, display name, optional biography, and optional profile image. A profile image is uploaded only when you choose to select one.

Email verification may be required before an account can be used. Authentication credentials are handled by the authentication provider; MangaLord does not store your password in the application database.

## 4. User Data, Favorites, and History

When you are signed in, MangaLord may synchronize your favorites and reading history with the MangaLord Supabase project. These records are associated with your account identifier and are protected by row-level access policies so that a user can access only their own records through the application.

When you use MangaLord as a guest, favorites and history may be stored locally on your device. Local records remain on the device until you remove them, clear the application data, or uninstall the application.

## 5. Local Storage

MangaLord uses device-local storage for application preferences and feature data, including language selection, notification preference, enabled source selections, downloaded items, favorites and history used in guest mode, and player or reader progress. Downloaded media and related files may also be stored in locations allowed by the operating system and the permissions granted to the application.

MangaLord requests storage and notification permissions only where required by the relevant platform feature. You can manage these permissions through your device settings.

## 6. App Usage and Diagnostics

The current MangaLord implementation does not include a dedicated analytics, advertising, crash-reporting, or user-tracking service. It does not intentionally create behavioral profiles for advertising.

The application may write technical messages to local development or platform logs when an error occurs. These logs are controlled by the operating system and are not intentionally uploaded by MangaLord as an analytics dataset.

## 7. Data Storage and Security

Account-related data, synchronized profiles, favorites, and history are stored in the MangaLord Supabase project. Profile images, when uploaded, are stored in the project’s `profile-images` storage bucket.

MangaLord uses authenticated access and database row-level security for account data. No method of transmission or storage is completely secure, so you should use a strong password and avoid sharing your account credentials.

## 8. Third-Party Services

MangaLord uses the following categories of third-party services:

| Service category | Purpose |
|---|---|
| Supabase Auth | Account registration, email authentication, session management, and configured OAuth authentication |
| Supabase Database and Storage | Synchronized profiles, favorites, history, and optional profile images |
| External content sources | Manga, anime, chapter, episode, image, and metadata requests initiated when you browse or search content |
| Operating-system services | Local storage, file access, notifications, and media playback |

Third-party services process information according to their own terms and privacy policies. MangaLord does not control the privacy practices, availability, or content of external services.

## 9. External Content Sources

MangaLord retrieves content and metadata from external sources selected or enabled in the application. Current source integrations include services such as AzoraFly, MeshManga, Hijala, and Olympus Staff, together with other source endpoints used by the application’s source adapters. These sources may receive ordinary network request information, such as your IP address, as part of serving web requests. MangaLord does not claim ownership of external content.

External source availability and content may change independently of MangaLord. You should review the privacy policies and terms of any external service that you access through the application.

## 10. Cookies and Tracking

MangaLord is a native application and does not use website cookies in the application itself. The application does not intentionally use advertising identifiers or cross-service tracking for advertising.

An external website or OAuth provider opened from the application may use cookies or similar technologies under its own policy.

## 11. Data Retention and Deletion

Synchronized account data is retained while the account or the relevant records remain active. You can remove local data by deleting it within the application where supported, clearing the application data, or uninstalling the application.

To request deletion of synchronized account information, contact the project maintainer through the [MangaLord GitHub repository](https://github.com/lo-oord/MangaLord). Requests may require enough information to identify the relevant account, but you should not send your password or other secret credentials.

Some information may remain temporarily in backups or security logs where retention is required for operational or legal reasons.

## 12. Your Rights and Choices

Depending on your location and applicable law, you may have rights to request access to, correction of, or deletion of your personal information, or to object to or restrict certain processing. You may also choose not to create an account and may control application permissions through your device settings.

To exercise a privacy request, use the contact method in Section 15. We may need to verify the request before acting on it.

## 13. Children’s Privacy

MangaLord is not directed specifically at children. We do not intentionally collect personal information from children. If you believe that a child has provided personal information through MangaLord, contact the project maintainer so the information can be reviewed and deleted where appropriate.

## 14. Changes to This Privacy Policy

This policy may be updated when MangaLord adds, removes, or changes a feature or service. The effective date at the top of this page will identify the latest version. Continued use of MangaLord after an update means that you have had an opportunity to review the updated policy.

## 15. Contact Information

For privacy questions, access requests, correction requests, or deletion requests, contact the MangaLord project maintainer through the [MangaLord GitHub repository](https://github.com/lo-oord/MangaLord). No separate email address is published in the current project materials.

---

# سياسة خصوصية MangaLord

**تاريخ السريان:** 9 سبتمبر 2026

توضح هذه السياسة طريقة تعامل تطبيق MangaLord مع المعلومات عند استخدامه. وقد أُعدت بناءً على التنفيذ الحالي للتطبيق، وقد تتغير عند تغيير ممارسات البيانات أو إضافة خدمات جديدة.

## 1. مقدمة

MangaLord تطبيق متعدد المنصات لاكتشاف وقراءة المانجا وتصفح المحتوى المرتبط بالأنمي. يمكن استخدام التطبيق كزائر، ولا يلزم إنشاء حساب إلا للاستفادة من مزايا المزامنة المرتبطة بالحساب، مثل المفضلة والسجل.

## 2. المعلومات التي قد نتعامل معها

يتعامل MangaLord مع المعلومات اللازمة لتقديم المزايا التي تختار استخدامها فقط. وقد تشمل ذلك البريد الإلكتروني، ومعرّف الحساب، واسم العرض، والنبذة الاختيارية، وصورة الملف الشخصي الاختيارية، وحالة تسجيل الدخول، والمفضلة، وسجل القراءة، وإعدادات اللغة والإشعارات، والمصادر المفعّلة، والتنزيلات، وتقدم القراءة أو التشغيل.

تُحفظ بعض هذه البيانات محليًا على جهازك، بينما تتم مزامنة الملف الشخصي والمفضلة والسجل عند تسجيل الدخول. لا يطلب MangaLord عمدًا بيانات البطاقات البنكية أو أرقام الهوية الحكومية أو جهات الاتصال أو الموقع الدقيق أو تسجيلات الميكروفون أو تسجيلات الكاميرا.

## 3. الحساب والمصادقة

يمكنك تصفح MangaLord دون إنشاء حساب. عند إنشاء حساب، يستخدم التطبيق Supabase Auth لتسجيل الدخول بالبريد وكلمة المرور، وطرق المصادقة المفعّلة للمشروع، بما في ذلك Google OAuth عند تهيئته.

قد يتضمن الملف الشخصي البريد الإلكتروني واسم العرض والنبذة الاختيارية وصورة الملف الشخصي الاختيارية. لا تُرفع صورة الملف الشخصي إلا إذا اخترت تحديدها. وقد يتطلب الحساب تأكيد البريد الإلكتروني قبل استخدامه.

## 4. بيانات المستخدم والمفضلة والسجل

عند تسجيل الدخول، قد يزامن MangaLord المفضلة وسجل القراءة مع مشروع Supabase الخاص بالتطبيق. ترتبط هذه السجلات بمعرّف حسابك وتحميها سياسات وصول تمنع المستخدم من الوصول إلى سجلات المستخدمين الآخرين من خلال التطبيق.

عند استخدام التطبيق كزائر، قد تُحفظ المفضلة والسجلات محليًا على جهازك. وتبقى هذه البيانات حتى تحذفها أو تمسح بيانات التطبيق أو تزيل التطبيق.

## 5. التخزين المحلي

يستخدم MangaLord التخزين المحلي لإعدادات التطبيق والبيانات المرتبطة بالمزايا، ومنها اللغة، وإعدادات الإشعارات، والمصادر المفعّلة، والتنزيلات، وبيانات المفضلة والسجل في وضع الزائر، وتقدم المشغل أو القارئ. وقد تُحفظ الوسائط المنزّلة والملفات المرتبطة بها في المواقع التي يسمح بها نظام التشغيل والأذونات التي تمنحها للتطبيق.

## 6. الاستخدام والتشخيص

لا يتضمن التنفيذ الحالي للتطبيق خدمة مستقلة للتحليلات أو الإعلانات أو تقارير الأعطال أو تتبع المستخدمين. ولا ينشئ التطبيق عمدًا ملفات سلوكية للإعلانات.

قد يكتب التطبيق رسائل تقنية في سجلات النظام عند حدوث خطأ. وتخضع هذه السجلات لنظام التشغيل ولا يرفعها MangaLord عمدًا كبيانات تحليلات.

## 7. تخزين البيانات وأمانها

تُخزن بيانات الحساب والملفات الشخصية والمفضلة والسجل المتزامنة في مشروع Supabase الخاص بـ MangaLord. وعند رفع صورة شخصية، تُخزن في مساحة التخزين `profile-images`.

يستخدم MangaLord الوصول الموثق وأمن الصفوف لبيانات الحساب. ومع ذلك، لا توجد وسيلة نقل أو تخزين آمنة بشكل مطلق، لذلك يُنصح باستخدام كلمة مرور قوية وعدم مشاركة بيانات الحساب.

## 8. الخدمات الخارجية

يستخدم MangaLord Supabase للمصادقة وقاعدة البيانات والتخزين، ويستخدم مصادر محتوى خارجية عند تصفح أو البحث عن المحتوى، إضافة إلى خدمات نظام التشغيل للتخزين المحلي والملفات والإشعارات وتشغيل الوسائط. تخضع الخدمات الخارجية لسياساتها وشروطها الخاصة، ولا يتحكم MangaLord في ممارساتها أو توافرها أو محتواها.

## 9. مصادر المحتوى الخارجية

يجلب MangaLord المحتوى والبيانات الوصفية من المصادر الخارجية المفعّلة في التطبيق، ومن بينها حاليًا خدمات مثل AzoraFly وMeshManga وHijala وOlympus Staff، إضافة إلى نقاط وصول أخرى تستخدمها موائمات المصادر. قد تستقبل هذه الخدمات معلومات الشبكة المعتادة، مثل عنوان IP، عند تنفيذ الطلبات. ولا يدّعي MangaLord ملكية المحتوى الخارجي.

## 10. ملفات تعريف الارتباط والتتبع

MangaLord تطبيق أصلي ولا يستخدم ملفات تعريف الارتباط داخل التطبيق نفسه، ولا يستخدم عمدًا معرّفات إعلانية أو تتبعًا مشتركًا بين الخدمات لأغراض إعلانية. وقد يستخدم موقع خارجي أو مزود OAuth ملفات تعريف ارتباط وفقًا لسياسته الخاصة.

## 11. الاحتفاظ بالبيانات وحذفها

تُحتفظ بيانات الحساب المتزامنة ما دام الحساب أو السجلات المرتبطة به نشطة. ويمكن حذف البيانات المحلية من داخل التطبيق حيثما كان ذلك مدعومًا، أو عبر مسح بيانات التطبيق، أو إزالة التطبيق.

لطلب حذف معلومات الحساب المتزامنة، تواصل مع مسؤول المشروع عبر [مستودع MangaLord على GitHub](https://github.com/lo-oord/MangaLord). لا ترسل كلمة المرور أو أي بيانات سرية ضمن الطلب.

## 12. حقوقك وخياراتك

وفقًا لموقعك والقوانين المطبقة، قد يحق لك طلب الوصول إلى معلوماتك الشخصية أو تصحيحها أو حذفها، أو الاعتراض على معالجة معينة أو تقييدها. ويمكنك اختيار عدم إنشاء حساب والتحكم في أذونات التطبيق من إعدادات جهازك.

## 13. خصوصية الأطفال

لا يستهدف MangaLord الأطفال تحديدًا، ولا نجمع عمدًا معلومات شخصية من الأطفال. إذا اعتقدت أن طفلًا قدم معلومات شخصية عبر التطبيق، فتواصل مع مسؤول المشروع لمراجعتها وحذفها عند الاقتضاء.

## 14. التغييرات على سياسة الخصوصية

قد نحدّث هذه السياسة عند إضافة ميزة أو خدمة أو تغييرها أو إزالتها. يوضح تاريخ السريان في أعلى الصفحة أحدث نسخة من السياسة.

## 15. التواصل

للاستفسارات المتعلقة بالخصوصية أو طلبات الوصول أو التصحيح أو الحذف، تواصل مع مسؤول المشروع عبر [مستودع MangaLord على GitHub](https://github.com/lo-oord/MangaLord). لا يوجد عنوان بريد إلكتروني منفصل منشور ضمن مواد المشروع الحالية.

## أساس إعداد هذه السياسة

أُعدت هذه السياسة بمراجعة كود المصادقة، ومخطط Supabase، والتخزين المحلي، وأذونات النظام، وموائمات مصادر المحتوى الموجودة في مستودع MangaLord. وهي لا تثبت ممارسات لا تظهر في التنفيذ الحالي.
