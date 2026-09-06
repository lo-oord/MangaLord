# ملاحظات فحص Manga Starz

تاريخ الفحص: 2026-09-06.

الموقع الرئيسي: https://starzmanga.com/

الملاحظات المؤكدة من الصفحات العامة:

| العنصر | النتيجة |
|---|---|
| اسم المصدر الظاهر | مانجا ستارز Mangastarz |
| نمط الصفحة | WordPress + Madara Manga على الأرجح، مع صفحات `/manga/{slug}/` و`/manga/{slug}/{chapter}/` |
| البحث | رابط WordPress search: `/?s=&post_type=wp-manga` |
| قائمة المانجا | `/manga/` |
| صفحة الفصل | مثال: `https://starzmanga.com/manga/im-the-brave-puppy-that-will-save-the-villainess/42/` |
| قائمة الفصول | محدد HTML يعرض 42، 41، 40 ... 1 وروابط الفصل السابق والمانجا |
| صور الفصل | صور مباشرة داخل الصفحة، مثال نطاق `https://tempmanhwa.starzmanga.com/manga/arb5/data/.../image-01.png` ثم JPG لباقي الصفحات |
| صورة الشعار | `https://starz.manga-starz.net/wp-content/uploads/starzmanga.png` |
| صور الأغلفة | نطاق `https://starz.starzmanga.com/wp-content/uploads/...` مع نسخ thumbnails ونسخ أصلية غالبًا |
| سلوك الصفحة | هناك زر Bookmark، تبديل الوضع، وروابط تسجيل الدخول؛ القارئ يجب أن يعتمد على الصور المباشرة مع ترويسة Referer عند الحاجة |

مثال صفحة فصل 42: العنوان `I’m the Brave Puppy That Will Save the Villainess الفصل 42 مترجم`، وتحتوي على 13 صورة مرتبة image-01 إلى image-13، مع روابط للفصول 42 إلى 1.

ملاحظة تنفيذية: يجب جعل محلل المصدر متحملًا لتغير امتداد الصور (`png`, `jpg`, `webp`) ولتغير نطاق CDN بين `tempmanhwa.starzmanga.com` و`starz.starzmanga.com`، كما يجب حفظ اسم المصدر `Manga Starz` في النموذج/واجهة معلومات المانجا بجانب الغلاف.
