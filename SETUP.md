# Kurulum ve yayın adımları

Sırayla ilerleyin. Bölüm 1-2 derleme için yeterli; 3-6 test ve TestFlight için gerekli.

## 0. Önce değiştireceğin yer
`project.yml` dosyasının en üstündeki `settings.base` içinde 3 değer var:
- `BASE_BUNDLE_ID` (şimdi `com.umutsolmaz.sessiz`) — uygulama kimliği. Extension'lar bunun sonuna `.CallDirectory` ve `.MessageFilter` ekler.
- `APP_GROUP_ID` (şimdi `group.com.umutsolmaz.sessiz`) — uygulama ile extension'ların ortak klasörü.
- `DEVELOPMENT_TEAM` — Apple Developer hesabındaki 10 haneli Team ID (bölüm 3). İmzasız derlemede boş kalabilir.

Bu kimlikler Apple'da bir kez alınınca dünyada tektir; Başka bir geliştirici bu kimliği almışsa değiştirin. Yalnızca `project.yml` değişir, başka dosyaya dokunmak gerekmez.

## 1. Git ve GitHub CLI kurulumu
Git zaten kurulu. `gh` (GitHub'ın komut satırı aracı) yok. PowerShell'de:
```powershell
winget install --id GitHub.cli
```
Terminali kapat-aç, sonra:
```powershell
gh auth login
```
(GitHub.com → HTTPS → tarayıcıyla giriş seçeneklerini seç.) GitHub hesabın yoksa önce github.com'dan aç.

## 2. Repo oluşturma
Proje klasöründe:
```powershell
git init -b main
git add .
git commit -m "Faz 0: iskelet"
gh repo create sessiz --private --source=. --push
```
**Private seçildi.** Maliyet: GitHub ücretsiz planda ayda 2000 dakika verir, ama macOS 10 kat sayılır → ayda ~200 gerçek macOS dakikası. Bir iOS derlemesi ~10 dakika sürerse (=100 kredi) ayda yaklaşık 20 derleme eder. Bu yüzden:
- iOS derlemesi yalnızca `main`'e push'ta ve elle çalışır; ben değişiklikleri biriktirip tek seferde push ederim.
- Linux testleri (SpamCore) 1x sayılır, ucuzdur.
- Kalan dakikayı github.com/settings/billing sayfasından izle; limit gerçek rakamı orada yazar. Yetmezse repoyu public yapmak macOS dakikasını sınırsız ücretsiz yapar (ayarı sonradan değiştirebilirsin).

Push sonrası `Actions` sekmesinde iki workflow çalışır. Sonucu ben `gh` ile okurum.

## 3. Apple Developer hesabı
Yayın, ücretli bir Apple Developer üyeliği (yaklaşık 99 USD/yıl) gerektirir. Hesap sahibi (Account Holder) ya da Admin yetkili bir kullanıcı şunları yapar:
1. appstoreconnect.apple.com → **Users and Access** → **+** ile derlemeyi yönetecek kişiyi **Admin** rolüyle ekler (App ID, App Group ve API anahtarı oluşturmak için bu yetki gerekir). Davet edilen kişi iki adımlı doğrulamayı açar.
2. **Team ID**'yi (developer.apple.com/account → Membership details) `project.yml`'deki `DEVELOPMENT_TEAM`'e yazın.

Dikkat edilecekler:
- Uygulama App Store'da hesap sahibinin adıyla (veya şirketiyle) satıcı olarak görünür; gelir ve sorumluluk ona aittir. Uygulamayı sonradan başka hesaba devretmek mümkündür ama zahmetlidir.
- Bundle ID'ler hesabın ekibine kaydedilir; aynı ID başka bir hesapta kullanılamaz.
- Üyelik yıllık yenilenmezse uygulama mağazadan kalkar.

## 4. App ID'ler ve App Group (developer.apple.com → Certificates, Identifiers & Profiles)
1. **Identifiers → App Groups → +**: `group.com.umutsolmaz.sessiz` (project.yml'deki `APP_GROUP_ID` ile BİREBİR aynı).
2. **Identifiers → App IDs → + → App** üç kez, "Explicit" Bundle ID ile:
   - `com.umutsolmaz.sessiz`
   - `com.umutsolmaz.sessiz.CallDirectory`
   - `com.umutsolmaz.sessiz.MessageFilter`
3. Üçünde de Capabilities'ten **App Groups**'u işaretle, Configure ile yukarıdaki grubu seç, kaydet.
(Call Directory ve Message Filter için ayrı bir capability kutusu yoktur; extension olmaları yeterlidir.)

## 5. App Store Connect API anahtarı ve GitHub secret'ları (CI'ın TestFlight'a yüklemesi için)
1. appstoreconnect.apple.com → Users and Access → Integrations → App Store Connect API → anahtar oluştur (rol: App Manager). Bu ekranı Admin ya da hesap sahibi görür; yetkiniz yoksa hesap sahibi anahtarı oluşturup `.p8` dosyasını, Key ID'yi ve Issuer ID'yi güvenli bir yoldan (şifreli not, yüz yüze) iletmelidir. Düz metin olarak e-posta veya mesajla gönderilmemelidir.
2. `.p8` dosyasını bir kez indirebilirsin; Key ID ve Issuer ID'yi not al. Team ID: developer.apple.com → Membership details.
3. Bunları repoya KOYMA. 4 secret olarak GitHub'a gireceğiz. PowerShell'de (`.p8` dosyasının olduğu klasörde):
   ```powershell
   $gh = "C:\Program Files\GitHub CLI\gh.exe"
   & $gh secret set ASC_KEY_ID --repo mUmut2/sessiz          # sorunca Key ID'yi yapıştır
   & $gh secret set ASC_ISSUER_ID --repo mUmut2/sessiz       # Issuer ID
   & $gh secret set APPLE_TEAM_ID --repo mUmut2/sessiz       # 10 haneli Team ID
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("AuthKey_XXXX.p8")) | & $gh secret set ASC_KEY_P8_BASE64 --repo mUmut2/sessiz
   ```
   (Dosya adındaki XXXX yerine kendi Key ID'ni yaz. Secret'lar GitHub'da şifreli durur, sonradan okunamaz.)

## 6. TestFlight ve gerçek iPhone
- Simülatörde arama/SMS engelleme **çalışmaz**; gerçek iPhone şart.
- appstoreconnect.apple.com → Apps → + → New App: bundle id `com.umutsolmaz.sessiz`. (Önce bölüm 4'teki App ID'ler ve App Group oluşturulmuş olmalı.)
- Yükleme: GitHub → Actions → "TestFlight" → Run workflow. İş 10-15 dakika sürer; build numarası otomatik artar. Bittikten sonra App Store Connect → TestFlight'ta build görünür (Apple işlemesi birkaç dakika sürebilir).
- iPhone'una App Store'dan "TestFlight" uygulamasını kur; App Store Connect'te kendini "Internal Testing" grubuna ekle, build'i oradan yükle.
- Not: İç test (Internal) için Apple incelemesi gerekmez; dışarıdan test edenler için "Beta App Review" gerekir (genelde 1 gün).
- Denerken sırayla: (1) Durum sekmesinden arama engellemeyi aç, (2) Numaralar'a kendi ikinci numaranı ekle ve ondan ara, (3) SMS Filtreleme'yi aç, rehberinde olmayan bir numaradan "bahis bonus" yazan SMS gönder.

## 7. Reklam (Google AdMob)
Uygulamada Numaralar ve Mesajlar sekmelerinin altında bir banner reklam var. Şu an Google'ın herkese açık TEST kimlikleri kullanılıyor (reklam "Test Ad" yazar). Gerçek reklam için:
1. admob.google.com'da hesap aç (Google hesabıyla; ödeme ve vergi bilgisini kendin girersin).
2. Apps → Add app → iOS. Uygulama adı: Sessiz. Çıkan **App ID**'yi (`ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy`) not al.
3. Bu uygulamada Ad unit → Banner oluştur. Çıkan **Banner ad unit ID**'yi (`ca-app-pub-xxxxxxxxxxxxxxxx/zzzzzzzzzz`) not al.
4. AdMob → Blocking controls → Sensitive categories: "Kumar/Bahis", "Flört" ve istemediğin diğer kategorileri ENGELLE. (Spam bahis SMS'lerine karşı bir uygulamada bahis reklamı göstermek hem tuhaf hem de Türkiye'de yasa dışı.)
5. `project.yml` içindeki `ADMOB_APP_ID` ve `ADMOB_BANNER_UNIT_ID` değerlerini gerçekleriyle değiştir, push et.
6. Reklamları tamamen kapatmak istersen aynı yerde `ADS_ENABLED: "NO"` yap: reklam ve reklam metinleri kalkar.
7. Ödemeler AdMob hesabının sahibine gider. AdMob hesabı Apple hesabından farklı bir kişi veya şirket adına olabilir; vergi ve ödeme bilgisi AdMob hesabının sahibiyle girilir, gelir paylaşımı varsa baştan yazılı netleştirilmelidir.
