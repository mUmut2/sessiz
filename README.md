# Sessiz

iPhone için spam arama ve SMS engelleyici. Türkiye'deki kullanıcılar için yapıldı, arayüz Türkçe.

Hesap yok, kendi sunucusu yok, istatistik toplamıyor. Numaralar, kurallar ve mesajlar telefondan çıkmaz. Tek istisna reklam: uygulamada Google AdMob banner'ı var (aşağıda).

## Ne yapar

**Aramalar**
- Engellemek istediğin numaraları listeye eklersin. Türkiye formatları anlaşılır: `0555 123 45 67`, `+90 555 123 45 67`, `0850…`, boşluk, tire ve parantez fark etmez.
- İstersen hazır spam listesini açarsın: Temel, Sıkı, Şüpheli. Banka, kargo ve operatör numaraları hazır listeden her zaman çıkarılır.
- Engelleme iOS'un Call Directory özelliğiyle çalışır.

**Mesajlar**
- Rehberinde olmayan göndericilerden gelen SMS ve MMS'ler, anahtar kelime ve gönderen adı kurallarıyla süzülür.
- Hazır Türkçe kural paketi var, kapatılabilir. Kendi kelimeni de ekleyebilirsin.
- Doğrulama kodları ve banka ile e-Devlet mesajları her zaman geçer, kuralla engellenemez. Emin olmadığı mesajı engellemez.
- "Test et" ekranında bir mesaj yazıp sonucu ve hangi kuralın çalıştığını görürsün.
- Eşleştirme Türkçe'ye uygun: `İ/ı`, büyük küçük harf ve aksan fark etmez.

## Sınırlar

Her spam'i engellemez. Bunu uygulamanın içinde de söylüyor.

- iMessage filtrelenemez. Sadece SMS ve MMS.
- Rehberdeki kişilerin mesajları filtrelenmez.
- Aramalar sadece listedeki numaralara göre engellenir. Numara değiştiren arayan geçebilir.
- Kaç mesaj ya da arama engellendiği iOS tarafından uygulamaya bildirilmez, bu yüzden sayaç yok.
- Uzantıların açık olup olmadığı koddan okunamaz, kurulum ekranında kullanıcı işaretler.

## Nasıl çalışıyor

| Parça | Görev |
|---|---|
| `App` | SwiftUI uygulaması: Durum, Numaralar, Mesajlar, Ayarlar |
| `Extensions/CallDirectory` | Numara listesini iOS'a verir (CallKit) |
| `Extensions/MessageFilter` | Gelen SMS'e karar verir (`ILMessageFilterExtension`), ağ erişimi yok |
| `Packages/SpamCore` | Numara normalizasyonu, kural motoru, hazır liste. Sadece Foundation kullanır, Linux'ta test edilir |

Uygulama ile uzantılar bir App Group klasörü üzerinden JSON ve metin dosyalarıyla konuşur. Mesaj filtresi o klasöre yazamaz, sadece okur.

## Geliştirme

Yerelde Mac gerekmez; derleme ve testler GitHub Actions'ta çalışır:

- `spamcore.yml`: Linux'ta `swift test`
- `ios-build.yml`: macOS'ta imzasız `xcodebuild`
- `testflight.yml`: elle çalıştırılır, imzalar ve TestFlight'a yükler

`.xcodeproj` dosyası repoda yok. [XcodeGen](https://github.com/yonaskolb/XcodeGen) ile `project.yml`'den üretiliyor. Bundle id, App Group ve Team ID tek yerde, `project.yml` içindeki `settings.base` altında.

Yerelde sadece çekirdeği test etmek için (Swift gerekir):

```bash
cd Packages/SpamCore
swift test
```

Kurulum adımları (Apple hesabı, sertifika, TestFlight, AdMob) [SETUP.md](SETUP.md) içinde.

## Reklam

Numaralar ve Mesajlar sekmelerinin altında Google AdMob banner'ı gösterilir. Kişiselleştirilmez, takip izni istenmez. `project.yml` içindeki `ADS_ENABLED` ile tamamen kapatılabilir, kapatınca reklam ve reklam metinleri kalkar. Depodaki kimlikler Google'ın herkese açık test kimlikleridir.

## Durum

- Çekirdek mantık birim testlerle kapsanıyor, iOS derlemesi CI'da yeşil.
- Gerçek bir iPhone'da henüz denenmedi. Uzantıların açılması, App Group paylaşımı ve reklam gösterimi cihazda doğrulanacak.
- App Store'a gönderilmedi.

## Gizlilik

Politika ve destek sayfası: [docs/site/index.html](docs/site/index.html). Yayın öncesi kontrol listesi: [docs/YAYIN-KONTROL-LISTESI.md](docs/YAYIN-KONTROL-LISTESI.md) ve [docs/YAYIN-NOTLARI.md](docs/YAYIN-NOTLARI.md).

## Lisans

Tüm hakları saklıdır. Kaynak kod incelemek için açıktır; yeniden kullanım için lisans verilmemiştir.
