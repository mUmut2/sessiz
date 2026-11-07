# Sessiz: yayın öncesi unutulmaması gerekenler

Hukuki danışmanlık değildir. Türkiye (KVKK, vergi) ve ticari konular için bir avukat/mali müşavir onayı alın.

Durum: [ ] yapılacak, [x] yapıldı

## A. Apple (reddedilme sebepleri)
- [ ] **Gizlilik politikası adresi (URL).** App Store Connect zorunlu tutar. Hazır sayfa: [docs/site/index.html](site/index.html). `[YAYINCI ADI]`, `[ADRES]`, `[DESTEK E-POSTASI]` yerleri doldurulmalı, sonra herkese açık bir adreste yayınlanmalı (aşağıda "Barındırma").
- [ ] **Destek adresi (Support URL).** Aynı sayfanın "Destek" bölümü kullanılabilir.
- [ ] **App Privacy anketi:** reklam var, "Data Not Collected" seçilemez. Google'ın AdMob için App Store gizlilik beyanı kılavuzuna göre doldurun. Politika sayfası ile anket birbirini tutmalı.
- [ ] **Yaş derecelendirmesi:** Apple anketi + AdMob'da reklam içerik derecesi (G/PG gibi) ayarı.
- [ ] **İnceleme notu** ([appstore-tr.md](appstore-tr.md)) uygulamaya yapıştırılır. İki uzantının nasıl açılacağı yazılı.
- [ ] **Ekran görüntüleri gerçek cihazdan**, test reklamı ("Test Ad") görünmeden alınmalı.
- [ ] **Gerçek reklam kimlikleri** (`ca-app-pub-3940256099942544` kalmamalı).
- [x] Şifreleme beyanı (`ITSAppUsesNonExemptEncryption: false`).
- [x] Gizlilik manifesti (`PrivacyInfo.xcprivacy`, UserDefaults sebebi CA92.1). Google SDK kendi manifestini getirir.
- [x] Takip izni yok: uygulama ATT penceresi göstermez, bu yüzden `NSUserTrackingUsageDescription` yok. Bunu değiştirirsen (kişiselleştirilmiş reklam) hem anket hem politika hem Info.plist değişir.
- [x] Hesap silme zorunluluğu yok (uygulamada hesap yok).

## B. Reklam (Google AdMob)
- [ ] **Avrupa kullanıcıları (AEA/Birleşik Krallık/İsviçre):** Google, bu bölgelerde reklam gösteren uygulamalardan onay penceresi (UMP/CMP) ister. Uygulamada yok. **Çözüm: App Store Connect > Pricing and Availability'de sadece Türkiye'yi seç.** Zaten arayüz tamamen Türkçe. Dünya çapında yayınlanacaksa önce onay penceresi eklenmeli.
- [ ] AdMob'da **Kumar/Bahis ve uygunsuz kategorileri engelle** (SETUP.md bölüm 7). Spam bahis SMS'lerine karşı bir uygulamada bahis reklamı çıkması hem itibar hem hukuk sorunu.
- [ ] AdMob **ödeme ve vergi bilgileri.** Gelir AdMob hesabının sahibine gider. AdMob hesabı Apple hesabından farklı bir kişi ya da şirket adına olacaksa, gelirin nasıl paylaşılacağı baştan yazılı netleştirilmeli. Gelirin vergilendirilmesi (şahıs/şirket, fatura) için mali müşavire danışın.
- [ ] İsteğe bağlı: `app-ads.txt` (kendi web sitenizde barındırılır, reklam sahtekârlığını azaltır). Sitenin ana alan adı gerekir.
- [ ] Reklamlar sadece Numaralar ve Mesajlar sekmelerinde; Apple'ın "reklam kullanıcıyı yanıltmamalı" kuralı için bunu bozma.

## C. Türkiye hukuku
- [ ] **KVKK:** Sessiz kişisel veri toplamıyor, cihaz dışına çıkarmıyor. Reklam verisini Google işler. Bu nedenle ayrı bir aydınlatma metni büyük ihtimalle gerekmez; politikadaki açık bilgilendirme yeterli olacak şekilde yazıldı. Bunu bir avukata doğrulatın.
- [ ] **VERBİS:** Sadece eşikleri aşan veri sorumluları için. Bu ölçekte beklenmez, avukat teyit etsin.
- [ ] **Hazır liste ve itibar:** Listedeki numaralar şirketlere ait 0850/0212/0312/0216 hatları; "spam" etiketi hatalı olabilir. Uygulama bunları "şikayet edilen numaralar" diye tanımlıyor, kesin hüküm vermiyor. Yanlış engelleme bildirimi için destek e-postası şart.
- [ ] Cep numaraları listede yok (KVKK). Eklenmemeli.
- [ ] Banka/kargo/operatör adları sadece "engellenmeyecekler" listesinde ve tanıtım metninde geçmiyor. Marka kullanımı gerekmedikçe artırma.

## D. Çerez politikası
Gerekmez. Bu bir iPhone uygulaması; çerez kullanmıyor. Politika sayfasında "çerez kullanmıyoruz" yazıyor. İleride web sitesine analiz ya da reklam eklenirse çerez bildirimi gerekir.

## E. Lisans ve içerik
- [ ] **symbuzzer/Turkish-Spam-Numbers (GPL-3.0)** listesi bilerek eklenmedi. Eklenecekse lisans/hukuk kararı gerekir.
- [ ] **Uygulama adı "Sessiz":** App Store'da müsait mi, Türk Patent ve Marka Kurumu'nda çakışan marka var mı kontrol edin.
- [ ] İkon (halka ve çizgi) jenerik bir şekil; yine de benzer ikon aramasını bir kez yapın.
- [ ] Google Mobile Ads SDK şartları kabul edilmiş olur (AdMob hesabı açılırken).

## F. Avrupa Birliği (sadece AB'de yayınlanırsa)
- [ ] Dijital Hizmetler Yasası (DSA) gereği "Trader" bilgisi (ad, adres, telefon, e-posta) App Store'da herkese görünür. Sadece Türkiye'de yayınlarsan bu adım ve yukarıdaki onay penceresi gündeme gelmez.

## G. Barındırma (politika sayfası)
Seçenekler:
1. Bu reponun `docs/` klasöründen GitHub Pages ile yayınlamak (Settings → Pages).
2. Kendi alan adında basit bir barındırma.
Adres hazır olunca App Store Connect'e hem Privacy Policy hem Support URL olarak girilir. (Repo herkese açık olduğundan GitHub Pages doğrudan kullanılabilir.)

## H. Uygulama içi
- [ ] Adres belli olunca Ayarlar sekmesine "Gizlilik politikası" bağlantısı eklenebilir (Apple zorunlu tutmaz ama iyi uygulama).
- [x] Ayarlar'daki gizlilik metni reklam açıkken reklamı söylüyor (`SettingsView`).
- [x] Sınırlar bölümü dürüst: iMessage, rehber, sayaç yok, numara değişimi.

## I. Gönderimden hemen önce son kontrol
1. Politika sayfasındaki yer tutucular dolu.
2. Politika, App Privacy anketi ve uygulamadaki Ayarlar metni aynı şeyi söylüyor.
3. Gerçek iPhone'da: arama engelleme, SMS filtresi, reklam görünümü, kuralları sıfırla çalışıyor.
4. TestFlight'ta "Test Ad" kalmadı.
5. Sadece Türkiye seçili.
