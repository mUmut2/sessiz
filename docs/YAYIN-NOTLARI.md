# Sessiz: yayın notları

Sessiz'i App Store'a göndermeden önce bilinmesi ve kontrol edilmesi gerekenler.

## Uygulama ne yapar, ne yapmaz (yayın metinleri buna uymalı)
- iPhone'da spam arama ve SMS engelleme. Tamamen cihaz içi; hesap, sunucu, analitik, ağ erişimi YOK.
- **Aramalar:** sadece kullanıcının listeye eklediği numaraları engeller (CallKit Call Directory). Bilinmeyen spam numarayı kendi tanımaz.
- **SMS:** sadece rehberde olmayan göndericilerden gelen SMS/MMS'i, kelime ve gönderen kurallarına göre filtreler (Message Filter). iMessage filtrelenemez. Doğrulama kodları ve banka/e-Devlet mesajları her zaman geçer. Emin değilse geçirir.
- **Hazır spam listesi** (uygulama içinde gömülü, `BuiltInSpamList.swift`): Temel (3 numara), Sıkı (4 dar blok, ~31.000 numara), Şüpheli (15 numara). Banka/kargo/operatör numaraları izin listesindedir ve hazır listeden hep çıkarılır (testle korunur). Cep numarası yok.
- **Reklam:** Google AdMob banner, sadece Numaralar ve Mesajlar sekmelerinin altında. Tek bayrak: `project.yml` > `ADS_ENABLED`. Şu an Google'ın TEST kimlikleri var; App Store'a gitmeden gerçek kimlikler girilmeli (SETUP.md bölüm 7).
- Engellenen sayısı gösterilmez (iOS vermez). Sahte istatistik yok.
- "Tamamen engeller" gibi bir iddia hiçbir yerde olmamalı.

## Kontrol listesi
1. `docs/appstore-tr.md`: metinler yukarıdaki sınırlara uyuyor mu? Abartılı vaat var mı?
2. `docs/appstore-tr.md` gizlilik metni, uygulamanın gerçekte yaptığıyla örtüşüyor mu? (Ağ kodu yok: `grep -ri "URLSession" App Extensions Packages` boş dönmeli.)
3. App Privacy anketi: reklam açıkken "Data Not Collected" OLAMAZ; Google'ın AdMob gizlilik beyanı kılavuzuna göre doldurulur. `ADS_ENABLED: "NO"` ise "Data Not Collected".
4. `project.yml` içindeki bundle id / App Group / Team ID bu hesaba uygun mu? Değiştirilecek tek yer `settings.base` (BASE_BUNDLE_ID, APP_GROUP_ID). Değişirse `SETUP.md` bölüm 4'teki App ID'ler yeniden aynı adlarla oluşturulmalı.
5. Uygulama içi metinler Türkçe ve dürüst mü? (Durum, Mesajlar, Ayarlar > Sınırlar.)
6. TestFlight'ta gerçek iPhone ile dene (SETUP.md bölüm 6): arama engelleme, SMS filtresi, kuralları sıfırla. Denenmeden yayınlama: hiçbir şey şu ana kadar gerçek cihazda test edilmedi.
7. İnceleme notu (`docs/appstore-tr.md`, "İnceleme notu") App Review alanına yapıştırılır.
8. Ekran görüntüleri gerçek cihazdan, sahte sayaç/istatistik içermeden alınır.

9. **Reklam kimlikleri gerçek mi?** `project.yml` içinde `ca-app-pub-3940256099942544` ile başlayan kimlik KALMAMALI (TestFlight iş akışı uyarı verir).
10. AdMob'da "Kumar / Bahis" ve diğer uygunsuz reklam kategorileri engellenmiş mi? (SETUP.md bölüm 7)
11. Hazır listeyi doğrula: `Packages/SpamCore/Sources/SpamCore/BuiltInSpamList.swift`. Numaralar herkese açık şikayet kayıtlarından elle seçildi, 6-12 ayda bir gözden geçirilmeli; yanlış pozitif riski var.

## Bilinen riskler
- Hazır liste küçük: GPL-3.0 lisanslı symbuzzer/Turkish-Spam-Numbers listesi lisans sorunu yüzünden eklenmedi. Eklenecekse önce lisans/hukuk kararı gerekir.
- Reklam SDK'sı (Google Mobile Ads 13.12.0) gerçek cihazda denenmedi.
- Ayarlar yolları iOS 26'da farklı olabilir: Aramalar > Arama Engelleme ve Kimlik; Mesajlar > Bilinmeyen ve Spam > SMS Filtreleme. Farklıysa `App/Sources/StatusView.swift` en üstündeki metinler düzeltilir.
- Hazır kelime paketinde ("bonus", "tıkla") meşru mesajları yakalama riski var (`DefaultRules.pack`).
- TestFlight iş akışı (`.github/workflows/testflight.yml`) hiç çalıştırılmadı; ilk koşuda hata verebilir, Actions logundan düzeltilir.
- Apple, hiçbir engelleme uygulaması için "tam engelleme" iddiasını kabul etmez; metinlerdeki daraltılmış ifadeleri koru.

## Yayın öncesi tam liste
`docs/YAYIN-KONTROL-LISTESI.md` (gizlilik, reklam, KVKK, Avrupa, barındırma). Önce onu gözden geçir.

## Yayın adımları
SETUP.md bölüm 3-6, sonra App Store Connect'te sürümü "Submit for Review" ile gönder.
