# Sessiz: App Store metinleri (Türkçe taslak)

App Store Connect'te "App Information" ve sürüm sayfasına yapıştırılır. Karakter sınırları parantez içinde.

## Ad ve alt başlık
- **Ad (30):** Sessiz
- **Alt başlık (30):** Numara ve SMS engelleme

## Tanıtım metni (170)
Seçtiğin ve hazır listedeki spam numaraları, kurala uyan SMS'leri engelle. Numaraların iPhone'unda kalır, hesap gerekmez.

## Açıklama (4000)
Sessiz, Türkiye'deki spam arama ve SMS'lere karşı sade bir araçtır. Tüm spam'i otomatik yakalamaz: senin eklediğin numaraları ve kurallara uyan SMS'leri engeller.

ARAMALAR
Hazır spam listesi (Temel, Sıkı, Şüpheli) açılıp kapatılabilir. Banka, kargo ve operatör numaraları hazır listeden her zaman çıkarılır. Ayrıca engellemek istediğin numaraları kendin ekle. Numarayı 0555 123 45 67, +90 555 123 45 67 ya da 0850 gibi nasıl yazarsan yaz, Sessiz doğru biçime çevirir. Listedeki numaralar aradığında telefon çalmaz.

MESAJLAR
Rehberinde olmayan kişilerden gelen SMS ve MMS'ler kurallara göre filtrelenir. Bahis, çekiliş, borç tehdidi ve kısaltılmış link gibi hazır Türkçe kurallar gelir. Kendi kelimeni ekleyebilir, istediğin kuralı kapatabilirsin.

GÜVENLİ KURALLAR
Doğrulama kodları ve şifre mesajları her zaman geçer. Banka ve e-Devlet kodları kuralla engellenemez. Emin olamazsa Sessiz mesajı geçirir.

TEST ET
Bir mesajı yaz ya da yapıştır, Sessiz'in ne yapacağını ve hangi kuralın eşleştiğini gör.

GİZLİLİK
Numaraların, kuralların ve mesajların cihazından çıkmaz. Hesap, Sessiz'e ait sunucu ve istatistik toplama yoktur. Uygulamada Google AdMob reklamları gösterilir; reklamlar kişiselleştirilmez.

SINIRLAR
- iMessage mesajları filtrelenemez, sadece SMS ve MMS.
- Rehberindeki kişilerin mesajları filtrelenmez.
- iPhone engellenen arama ya da mesaj sayısını uygulamalara bildirmez, bu yüzden sayaç yoktur.
- Aramalarda sadece hazır listedeki ve senin eklediğin numaralar engellenir. Numara değiştiren aramalar geçebilir.
- SMS'te sadece kurallara uyan mesajlar engellenir, diğerleri geçer.
- Kurulum için Ayarlar'da arama engelleme ve SMS filtrelemeyi bir kez açman gerekir. Uygulama adımları gösterir.

## Anahtar kelimeler (100)
engelle,arama,sms,numara,filtre,rahatsız,reklam,kara liste

## Bu sürümde yenilikler
İlk sürüm.

## Destek ve gizlilik URL'leri
App Store Connect bir gizlilik politikası adresi (URL) ister. Hazır sayfa `docs/site/index.html`; bir web adresinde (ör. GitHub Pages) yayınlanmalıdır. Destek adresi için aynı sayfa ya da bir e-posta bağlantısı kullanılabilir.

## Gizlilik politikası
Yayınlanacak tam metin ve destek bölümü: [site/index.html](site/index.html). Yer tutucular (`[YAYINCI ADI]`, `[ADRES]`, `[DESTEK E-POSTASI]`) doldurulup herkese açık bir adreste yayınlanır; bu adres App Store Connect'te hem Privacy Policy URL hem Support URL olur. Unutulmaması gerekenler: [YAYIN-KONTROL-LISTESI.md](YAYIN-KONTROL-LISTESI.md).

## App Privacy (Apple'ın "veri toplama" anketi)
Uygulamada Google AdMob olduğu için "Data Not Collected" SEÇİLEMEZ. Anket, Google'ın "AdMob için App Store gizlilik beyanı" kılavuzuna göre doldurulur (reklam verisi, cihaz/kullanım verisi vb.). Uygulama takip izni (ATT) istemez ve reklam kimliğini kullanmaz; "Used to Track You" işaretlemesinin buna uyup uymadığı gönderimden önce Google kılavuzuyla teyit edilmeli. Reklam kapatılırsa (`ADS_ENABLED: "NO"`) anket "Data Not Collected" olarak sadeleşir.

## Yaş derecelendirmesi
Tüm sorulara "Hayır". Beklenen sonuç: 4+.

## Kategori
Birincil: Yardımcı Programlar (Utilities). İkincil: Üretkenlik (Productivity).

## İnceleme notu (App Review Information)
Uygulama iki iOS uzantısı kullanır: Call Directory (arama engelleme) ve Message Filter (SMS filtreleme). Test için Ayarlar > Uygulamalar > Telefon > Arama Engelleme ve Kimlik'ten "Sessiz Arama Engelleme"yi, Ayarlar > Mesajlar > Bilinmeyen ve Spam > SMS Filtreleme'den "Sessiz Mesaj Filtresi"ni açın. Uygulama hesap ya da ağ bağlantısı kullanmaz. Message Filter ve Call Directory uzantıları ağ erişimi istemez, reklam SDK'sı sadece ana uygulamadadır. Hazır spam numara listesi uygulamanın içindedir (internetten indirilmez); kaynakları ve son kontrol tarihi uygulamada "Hazır liste" ekranında yazar. Reklamlar sadece Numaralar ve Mesajlar sekmelerinin altında görünür.

## Ekran görüntüleri
Gerçek cihazdan alınmalı (TestFlight kurulumundan sonra): Durum, Numaralar (birkaç örnek numarayla), Mesajlar, Test et sonucu. En az 6,9 inç (iPhone 16/17 Pro Max sınıfı) ekran boyutu istenir. Gerçek olmayan istatistik ya da sahte sayaç içeren görsel kullanılmaz.
