
## فحص القائمة العامة
صفحة `https://movie-box.co/web/movie` تعرض عدداً كبيراً من روابط `/detail/...`، لكن صور البطاقات الأولى في DOM لا تحتوي `src` أو `srcset` وقت الفحص؛ وهذا يفسر عدم ظهور الغلاف في القائمة. يجب استخراج الصور من بيانات SSR/API أو خصائص lazy-load بعد hydration، وليس الاعتماد على `img[src]` فقط. نموذج البحث ظاهر في الصفحة، ويحتاج parser إلى استخدام endpoint API/مسار بحث الموقع بدلاً من `?keyword=` غير المؤكد.

## فحص Movie Box الحالي
صفحة `/web/movie` تُحمّل تطبيق Nuxt من `spa.aoneroom.com` وتستخدم صور الأغلفة من `pbcdnw.aoneroom.com/image/...` بصيغة webp. روابط التفاصيل تظهر بصيغة `/detail/{slug}{id}`، بينما صور عناصر القائمة لا تكون دائماً داخل `img[src]` وقت القراءة الأولية. لذلك يجب الاعتماد على بيانات SSR/API أو استخراج خصائص Nuxt/JSON، وعدم الاقتصار على محددات HTML التقليدية.

## بيانات SSR الفعلية
بيانات `window.__NUXT__.data` تحتوي على `operatingList` وبداخلها 351 عنصراً، وتوفر لكل عمل `subject.title` و`subject.cover.url` و`subject.detailPath` و`subject.subjectId`، بينما عناصر القائمة لا تحتوي بالضرورة على `img[src]`. الحل الصحيح للقائمة هو قراءة JSON/SSR أو endpoint القائمة، ثم إنشاء Manga من هذه الحقول وإسناد `coverUrl` مباشرة من `subject.cover.url`.

## API مؤكدة من الشبكة
صفحة Movie Box تستدعي `GET /wefeed-h5api-bff/tab-operating?tabId=ONEROOM_MOVIE&host=movie-box.co` للقائمة، وتستدعي `GET /wefeed-h5api-bff/subject/trending?tabId=ONEROOM_MOVIE&page=1&perPage=18` للأعمال الرائجة. كما تستدعي `POST /wefeed-h5api-bff/subject/search` للبحث (body يحوي keyword وpage وperPage وsubjectType). يجب نقل MovieBoxParser إلى هذه الـ API بدلاً من HTML و`keyword` query.
