// strings_tr.dart
// Reziphay — Turkish strings
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'app_localizations.dart';

class StringsTr implements AppLocalizations {
  const StringsTr();

  // ── Onboarding ──────────────────────────────────────────────────────────────
  @override String get appTagline           => 'Daha akıllı rezervasyon, daha iyi yaşam';
  @override String get onboardingPrompt     => 'Nasıl devam etmek istersiniz?';
  @override String get roleCustomer         => 'Müşteriyim';
  @override String get roleCustomerDesc     => 'Yakınındaki hizmetleri keşfet ve rezervasyon yap';
  @override String get roleProvider         => 'Hizmet Sağlayıcısıyım';
  @override String get roleProviderDesc     => 'Hizmetlerinizi ve rezervasyonlarınızı yönetin';
  @override String get languageModalTitle   => 'Dil';

  // ── Auth – Phone ─────────────────────────────────────────────────────────────
  @override String get phoneTitle           => 'Telefon numaranızı girin';
  @override String get phoneSubtitle        => 'Kimliğinizi doğrulamak için tek kullanımlık kod göndereceğiz';
  @override String get phoneLabel           => 'Telefon Numarası';
  @override String get phonePlaceholder     => 'XX 123 45 67';
  @override String get phoneSendCode        => 'Kod Gönder';
  @override String get phoneTerms           => 'Devam ederek Hizmet Koşullarımıza\nve Gizlilik Politikamıza kabul edersiniz';

  // ── Auth – OTP ───────────────────────────────────────────────────────────────
  @override String get otpTitle             => 'Numaranızı doğrulayın';
  @override String otpSubtitle(String p)    => '$p numarasına gönderilen 6 haneli kodu girin';
  @override String get otpVerify            => 'Doğrula';
  @override String get otpResend            => 'Kodu tekrar gönder';
  @override String otpResendIn(int s)       => '${s}s sonra tekrar gönder';
  @override String get otpInvalidCode       => 'Geçersiz kod. Tekrar deneyin.';
  @override String get otpResendFailed      => 'Kod gönderilemedi. Tekrar deneyin.';

  // ── Auth – Register ───────────────────────────────────────────────────────────
  @override String get registerTitle        => 'Neredeyse bitti!';
  @override String registerSubtitle(String p) => 'Telefon doğrulandı: $p';
  @override String get registerFullName     => 'Ad Soyad';
  @override String get registerFullNameHint => 'Tam adınız';
  @override String get registerEmail        => 'E-posta adresi';
  @override String get registerEmailHint    => 'sizin@email.com';
  @override String get registerCreateAccount => 'Hesap Oluştur';

  // ── Explore ──────────────────────────────────────────────────────────────────
  @override String greeting(String n)       => 'Merhaba, $n 👋';
  @override String get exploreSubtitle      => 'Yakınındaki en iyi hizmetleri bul';
  @override String get exploreSearch        => 'Hizmetler, markalar ara…';
  @override String get exploreNearMe        => 'Yakınımda';
  @override String get explorePopularBrands => 'Popüler Markalar';
  @override String get exploreFeatured      => 'Öne Çıkanlar';
  @override String get seeAll               => 'Tümünü gör';
  @override String get chipAll              => 'Tümü';
  @override String get badgeVip             => 'VIP';

  // ── Search ───────────────────────────────────────────────────────────────────
  @override String get searchTabServices    => 'Hizmetler';
  @override String get searchTabBrands      => 'Markalar';
  @override String get searchTabProviders   => 'Sağlayıcılar';
  @override String get searchHint           => 'Hizmetler, markalar ara…';
  @override String get searchStartTyping    => 'Aramak için yazmaya başlayın';
  @override String get searchNoServices     => 'Hizmet bulunamadı';
  @override String get searchNoBrands       => 'Marka bulunamadı';
  @override String get searchNoProviders    => 'Sağlayıcı bulunamadı';

  // ── Search Filters ───────────────────────────────────────────────────────────
  @override String get filtersTitle         => 'Filtreler';
  @override String get filtersReset         => 'Sıfırla';
  @override String get filtersSortBy        => 'Sırala';
  @override String get filtersPriceRange    => 'Fiyat aralığı';
  @override String get filtersApply         => 'Filtreleri Uygula';
  @override String get sortRelevance        => 'İlgililik';
  @override String get sortHighestRated     => 'En Yüksek Puanlı';
  @override String get sortNearestFirst     => 'En Yakın Önce';
  @override String get sortPriceLow         => 'Fiyat: Düşükten Yükseğe';
  @override String get sortPriceHigh        => 'Fiyat: Yüksekten Düşüğe';
  @override String get sortMostPopular      => 'En Popüler';

  // ── Brand Detail ─────────────────────────────────────────────────────────────
  @override String get brandServices        => 'Hizmetler';
  @override String get brandNoServices      => 'Henüz hizmet yok';
  @override String get showMore             => 'Daha fazla';
  @override String get showLess             => 'Daha az';
  @override String get brandOwnerLabel      => 'Sahip';

  // ── Common Actions ───────────────────────────────────────────────────────────
  @override String get cancel               => 'İptal';
  @override String get activate             => 'Etkinleştir';
  @override String get save                 => 'Kaydet';
  @override String get create               => 'Oluştur';
  @override String get archive              => 'Arşivle';
  @override String get reject               => 'Reddet';
  @override String get accept               => 'Kabul Et';
  @override String get tryAgain             => 'Tekrar dene';
  @override String get somethingWentWrong   => 'Bir şeyler yanlış gitti';
  @override String get genericError         => 'Bir şeyler yanlış gitti. Tekrar deneyin.';

  // ── Profile (shared) ─────────────────────────────────────────────────────────
  @override String get editProfile          => 'Profili Düzenle';
  @override String get fullName             => 'Ad Soyad';
  @override String get email                => 'E-posta';
  @override String get phone                => 'Telefon';
  @override String get settings             => 'Ayarlar';
  @override String get logout               => 'Çıkış Yap';
  @override String get logoutTitle          => 'Çıkış Yap';
  @override String get logoutConfirm        => 'Çıkış yapmak istediğinizden emin misiniz?';

  // ── UCR Profile ──────────────────────────────────────────────────────────────
  @override String get myFavorites              => 'Favorilerim';
  @override String get switchToProvider         => 'Hizmet Sağlayıcısına Geç';
  @override String get becomeProvider           => 'Hizmet Sağlayıcısı Ol';
  @override String get profileBecomeProviderTitle   => 'Hizmet Sağlayıcısı Ol';
  @override String get profileBecomeProviderContent => 'Bu, hesabınızda Hizmet Sağlayıcısı rolünü etkinleştirecek. İstediğiniz zaman modlar arasında geçiş yapabilirsiniz.';

  // ── USO Profile ──────────────────────────────────────────────────────────────
  @override String get roleServiceProvider  => 'Hizmet Sağlayıcısı';
  @override String get switchToCustomer     => 'Müşteri Moduna Geç';

  // ── Profile Edit ─────────────────────────────────────────────────────────────
  @override String get editProfileTitle     => 'Profili Düzenle';
  @override String get cropPhoto            => 'Fotoğrafı kırp';
  @override String get takePhoto            => 'Fotoğraf çek';
  @override String get chooseFromLibrary    => 'Galeriden seç';
  @override String get removePhoto          => 'Fotoğrafı kaldır';
  @override String get emailDisabledNote    => 'E-posta ve telefon numarası burada değiştirilemez.';

  // ── Settings ─────────────────────────────────────────────────────────────────
  @override String get settingsTitle        => 'Ayarlar';
  @override String get appearance           => 'Görünüm';
  @override String get theme                => 'Tema';
  @override String get language             => 'Dil';
  @override String get reservationReminders => 'Rezervasyon Hatırlatıcıları';
  @override String get enableReminders      => 'Hatırlatıcıları Etkinleştir';
  @override String get remindMe             => 'Hatırlat';
  @override String get minuteAbbr          => 'dk';
  @override String get hourAbbr            => 'sa';
  @override String get timePastError       => 'Geçmiş saat seçilemez. Lütfen gelecekteki bir saat seçin.';
  @override String manualApprovalLeadTimeError(int minutes) => 'Bu hizmet manuel onay gerektiriyor. En az $minutes dk önceden rezervasyon yapın.';

  // ── Reservations ─────────────────────────────────────────────────────────────
  @override String get reservationsTitle       => 'Rezervasyonlar';
  @override String get tabUpcoming             => 'Yaklaşan';
  @override String get tabPast                 => 'Geçmiş';
  @override String get noReservations          => 'Rezervasyon yok';
  @override String get noReservationsSubtitle  => 'Hizmetlere göz atın ve ilk randevunuzu alın';
  @override String get statusPending           => 'Beklemede';
  @override String get statusConfirmed         => 'Onaylandı';
  @override String get statusRejected          => 'Reddedildi';
  @override String get statusCancelled         => 'İptal edildi';
  @override String get statusChangeReq         => 'Değişiklik';
  @override String get statusCompleted         => 'Tamamlandı';
  @override String get statusNoShow            => 'Gelmedi';
  @override String get statusExpired           => 'Süresi doldu';

  // ── Reservation Detail ───────────────────────────────────────────────────────
  @override String get reservationTitle        => 'Rezervasyon';
  @override String get cancelReservationTitle  => 'Rezervasyonu İptal Et';
  @override String get cancelReservationContent => 'Rezervasyonu iptal etmek istediğinizden emin misiniz?';
  @override String get cancelReasonHint        => 'Sebep (isteğe bağlı)';
  @override String get keepIt                  => 'Vazgeç';
  @override String get cancelBooking           => 'Rezervasyonu iptal et';
  @override String get dateTime                => 'Tarih & Saat';
  @override String get endTime                 => 'Bitiş zamanı';
  @override String get price                   => 'Fiyat';
  @override String get providerLabel           => 'Sağlayıcı';
  @override String get yourNote                => 'Notunuz';
  @override String get rejectionReason         => 'Ret sebebi';
  @override String get cancellationReason      => 'İptal sebebi';
  @override String get freeCancellation        => 'Ücretsiz iptal mevcut';
  @override String get checkinQr               => 'Check-in QR';
  @override String get bookingId               => 'Rezervasyon ID';
  @override String get bookedOn                => 'Rezervasyon tarihi';
  @override String get reservationCancelled    => 'Rezervasyon iptal edildi';

  // ── Incoming Reservations ────────────────────────────────────────────────────
  @override String get incomingTitle           => 'Gelen';
  @override String get incomingSubtitle        => 'Rezervasyonlarınızı yönetin';
  @override String get tabPending              => 'Beklemede';
  @override String get tabConfirmed            => 'Onaylananlar';
  @override String get noPendingRequests       => 'Bekleyen istek yok';
  @override String get noConfirmedBookings     => 'Onaylanan rezervasyon yok';
  @override String get reservationAccepted     => 'Rezervasyon kabul edildi ✓';
  @override String get rejectReservationTitle  => 'Rezervasyonu Reddet';
  @override String get reservationRejected     => 'Rezervasyon reddedildi';

  // ── My Services ──────────────────────────────────────────────────────────────
  @override String get myServicesTitle         => 'Hizmetlerim';
  @override String get myServicesSubtitle      => 'Hizmetlerinizi yönetin';
  @override String get noServicesYet           => 'Henüz hizmet yok';
  @override String get noServicesSubtitle      => 'İlk hizmetinizi eklemek için + düğmesine dokunun.';
  @override String get archiveServiceTitle     => 'Hizmeti Arşivle';
  @override String get archiveServiceContent   => 'Bu hizmet devre dışı bırakılacak ve müşterilerden gizlenecek. Daha sonra yeniden etkinleştirebilirsiniz.';
  @override String get failedToArchive         => 'Arşivleme başarısız oldu. Tekrar deneyin.';

  // ── Create / Edit Service ────────────────────────────────────────────────────
  @override String get newService              => 'Yeni Hizmet';
  @override String get editService             => 'Hizmeti Düzenle';
  @override String get servicePhoto            => 'Hizmet Fotoğrafı';
  @override String get basicInfo               => 'Temel Bilgiler';
  @override String get serviceName             => 'HİZMET ADI';
  @override String get serviceNameHint         => 'örn. Saç Kesimi, Diş Tedavisi';
  @override String get nameRequired            => 'Ad zorunludur';
  @override String get descriptionLabel        => 'AÇIKLAMA';
  @override String get descriptionHint         => 'İsteğe bağlı açıklama';
  @override String get brandLabel              => 'MARKA';
  @override String get categoryLabel           => 'KATEGORİ';
  @override String get none                    => 'Yok';
  @override String get pricingSection          => 'Fiyatlandırma';
  @override String get priceLabel              => 'FİYAT';
  @override String get priceHint               => 'Ücretsizse boş bırakın';
  @override String get bookingSettings         => 'Rezervasyon Ayarları';
  @override String get serviceType             => 'HİZMET TÜRÜ';
  @override String get solo                    => 'Tek';
  @override String get multi                   => 'Grup';
  @override String get approvalMode            => 'ONAY MODU';
  @override String get manual                  => 'Manuel';
  @override String get autoApproval            => 'Otomatik';
  @override String get weeklySchedule          => 'Haftalık Program';
  @override String get waitingTime             => 'BEKLEME SÜRESİ';
  @override String get minAdvance              => 'MİN ÖN REZERVASYON';
  @override String get maxAdvance              => 'MAKS ÖN REZERVASYON';
  @override String get freeCancellationDeadline => 'ÜCRETSİZ İPTAL SON TARİHİ';
  @override String get fieldRequired           => 'Zorunlu alan';
  @override String get enterNumber             => 'Bir sayı girin';
  @override String get selectBrand             => 'Marka Seç';
  @override String get selectCategory          => 'Kategori Seç';
  @override String get addServicePhoto         => 'Hizmet Fotoğrafı Ekle';
  @override String get tapToChoose             => 'Galeriden veya kameradan seçmek için dokunun';
  @override String get changePhoto             => 'Fotoğrafı değiştir';
  @override String get cameraAccessDenied      => 'Kamera erişimi reddedildi. Lütfen Ayarlardan izin verin.';
  @override String get photoLibraryAccessDenied => 'Galeri erişimi reddedildi. Lütfen Ayarlardan izin verin.';

  // ── Service Detail ───────────────────────────────────────────────────────────
  @override String get about                   => 'Hakkında';
  @override String get brandDetailLabel        => 'Marka';
  @override String get location                => 'Konum';
  @override String get booking                 => 'Rezervasyon';
  @override String get instantConfirmation     => 'Anında onay';
  @override String get requiresApproval        => 'Onay gerektirir';
  @override String get bookNow                 => 'Şimdi Rezervasyon Yap';
  @override String get requestBooking          => 'Rezervasyon İste';
  @override String get reservationCreated      => 'Rezervasyon oluşturuldu!';

  // ── Create Reservation Sheet ─────────────────────────────────────────────────
  @override String get sheetBookNow            => 'Şimdi Rezervasyon Yap';
  @override String get sheetRequestBooking     => 'Rezervasyon İste';
  @override String get sheetDate               => 'Tarih';
  @override String get sheetTime               => 'Saat';
  @override String get sheetNoteHint           => 'Not ekle (isteğe bağlı)';
  @override String get sheetConfirmBooking     => 'Rezervasyonu Onayla';
  @override String get sheetSendRequest        => 'İstek Gönder';

  // ── Provider Profile ─────────────────────────────────────────────────────────
  @override String get providerProfile         => 'Hizmet Sağlayıcı';
  @override String get providerNotFound        => 'Hizmet sağlayıcı bulunamadı.';

  // ── Navigation ───────────────────────────────────────────────────────────────
  @override String get navExplore              => 'Keşfet';
  @override String get navReservations         => 'Rezervasyonlar';
  @override String get navNotifications        => 'Bildirimler';
  @override String get navProfile              => 'Profil';
  @override String get navIncoming             => 'Gelen';
  @override String get navMyServices           => 'Hizmetlerim';
  @override String get navMyBrands             => 'Markalarım';
  @override String get notificationsComingSoon => 'Yakında…';

  // ── My Brands (USO) ──────────────────────────────────────────────────────────
  @override String get myBrands             => 'Markalarım';
  @override String get noBrandsTitle        => 'Henüz Marka Yok';
  @override String get noBrandsSubtitle     => 'Hizmetlerinizi birleşik bir kimlik altında yönetmek için marka oluşturun.';
  @override String get createBrand          => 'Marka Oluştur';
  @override String get brandName            => 'Marka Adı';
  @override String get brandNameHint        => 'örn. Bella Studio';
  @override String get brandEmail           => 'Marka E-postası';
  @override String get brandEmailHint       => 'iletisim@marka.com (isteğe bağlı)';
  @override String get brandPhone           => 'Marka Telefonu';
  @override String get brandPhoneHint       => '+994 50 000 00 00';
  @override String get brandCreated         => 'Marka başarıyla oluşturuldu';
  @override String get brandDeleted         => 'Marka kaldırıldı';
  @override String get deleteBrand          => 'Markayı Kaldır';
  @override String get deleteBrandConfirm   => 'Bu markayı kaldırmak istediğinizden emin misiniz?';
  @override String get verifyPhone          => 'Telefonu Doğrula';
  @override String get verifyPhoneSubtitle  => 'Marka telefon numaranıza gönderilen kodu girin.';
  @override String get otpSentTo            => 'Kod gönderildi:';
  @override String get verifyAndCreate      => 'Doğrula ve Oluştur';
  @override String get editBrand            => 'Markayı Düzenle';
  @override String get brandUpdated         => 'Marka başarıyla güncellendi';
  @override String get phoneNotEditable     => 'Telefon numarası doğrulamadan sonra değiştirilemez.';
  @override String get brandDescription     => 'Açıklama';
  @override String get brandDescriptionHint => 'Müşterilere markanız hakkında bilgi verin…';
  @override String get brandLocation        => 'Konum';
  @override String get brandLocationHint    => 'örn. Bakü, Azerbaycan';
  @override String get brandWebsite         => 'Web sitesi';
  @override String get brandWebsiteHint     => 'https://ornek.com';
  @override String get invalidUrl           => 'Geçerli bir URL girin';
}
