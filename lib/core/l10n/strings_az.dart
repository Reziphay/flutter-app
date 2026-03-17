// strings_az.dart
// Reziphay — Azerbaijani strings
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'app_localizations.dart';

class StringsAz implements AppLocalizations {
  const StringsAz();

  // ── Onboarding ──────────────────────────────────────────────────────────────
  @override String get appTagline           => 'Daha ağıllı sifariş et, daha yaxşı yaşa';
  @override String get onboardingPrompt     => 'Necə davam etmək istəyirsiniz?';
  @override String get roleCustomer         => 'Müştəriyəm';
  @override String get roleCustomerDesc     => 'Yaxınlıqdakı xidmətləri kəşf edin və sifariş edin';
  @override String get roleProvider         => 'Xidmət Təminatçısıyam';
  @override String get roleProviderDesc     => 'Xidmətlərinizi və sifarişlərinizi idarə edin';
  @override String get languageModalTitle   => 'Dil';

  // ── Auth – Phone ─────────────────────────────────────────────────────────────
  @override String get phoneTitle           => 'Telefon nömrənizi daxil edin';
  @override String get phoneSubtitle        => 'Kimliyinizi təsdiqləmək üçün birdəfəlik kod göndərəcəyik';
  @override String get phoneLabel           => 'Telefon nömrəsi';
  @override String get phonePlaceholder     => 'XX 123 45 67';
  @override String get phoneSendCode        => 'Kod Göndər';
  @override String get phoneTerms           => 'Davam etməklə, Xidmət Şərtlərimizə\nvə Məxfilik Siyasətimizə razılıq verirsiniz';

  // ── Auth – OTP ───────────────────────────────────────────────────────────────
  @override String get otpTitle             => 'Nömrənizi təsdiqləyin';
  @override String otpSubtitle(String p)    => '$p nömrəsinə göndərilən 6 rəqəmli kodu daxil edin';
  @override String get otpVerify            => 'Təsdiqlə';
  @override String get otpResend            => 'Kodu yenidən göndər';
  @override String otpResendIn(int s)       => '${s}s sonra yenidən göndər';
  @override String get otpInvalidCode       => 'Yanlış kod. Yenidən cəhd edin.';
  @override String get otpResendFailed      => 'Kod göndərmək alınmadı. Yenidən cəhd edin.';

  // ── Auth – Register ───────────────────────────────────────────────────────────
  @override String get registerTitle        => 'Az qalıb!';
  @override String registerSubtitle(String p) => 'Telefon təsdiqləndi: $p';
  @override String get registerFullName     => 'Ad Soyad';
  @override String get registerFullNameHint => 'Tam adınız';
  @override String get registerEmail        => 'E-poçt ünvanı';
  @override String get registerEmailHint    => 'sizin@email.com';
  @override String get registerCreateAccount => 'Hesab Yarat';

  // ── Explore ──────────────────────────────────────────────────────────────────
  @override String greeting(String n)       => 'Salam, $n 👋';
  @override String get exploreSubtitle      => 'Yaxınlıqda ən yaxşı xidmətləri tapın';
  @override String get exploreSearch        => 'Xidmətlər, brendlər axtarın…';
  @override String get exploreNearMe        => 'Yaxınlıqda';
  @override String get explorePopularBrands => 'Populyar Brendlər';
  @override String get exploreFeatured      => 'Seçilmiş';
  @override String get seeAll               => 'Hamısına bax';
  @override String get chipAll              => 'Hamısı';
  @override String get badgeVip             => 'VIP';

  // ── Search ───────────────────────────────────────────────────────────────────
  @override String get searchTabServices    => 'Xidmətlər';
  @override String get searchTabBrands      => 'Brendlər';
  @override String get searchTabProviders   => 'Təminatçılar';
  @override String get searchHint           => 'Xidmətlər, brendlər axtarın…';
  @override String get searchStartTyping    => 'Axtarmaq üçün yazmağa başlayın';
  @override String get searchNoServices     => 'Xidmət tapılmadı';
  @override String get searchNoBrands       => 'Brend tapılmadı';
  @override String get searchNoProviders    => 'Təminatçı tapılmadı';

  // ── Search Filters ───────────────────────────────────────────────────────────
  @override String get filtersTitle         => 'Filtrlər';
  @override String get filtersReset         => 'Sıfırla';
  @override String get filtersSortBy        => 'Sıralama';
  @override String get filtersPriceRange    => 'Qiymət aralığı';
  @override String get filtersApply         => 'Filtrləri Tətbiq Et';
  @override String get sortRelevance        => 'Uyğunluq';
  @override String get sortHighestRated     => 'Ən Yüksək Reytinq';
  @override String get sortNearestFirst     => 'Ən Yaxın Əvvəl';
  @override String get sortPriceLow         => 'Qiymət: Aşağıdan Yuxarı';
  @override String get sortPriceHigh        => 'Qiymət: Yuxarıdan Aşağı';
  @override String get sortMostPopular      => 'Ən Populyar';

  // ── Brand Detail ─────────────────────────────────────────────────────────────
  @override String get brandServices        => 'Xidmətlər';
  @override String get brandNoServices      => 'Hələ xidmət yoxdur';
  @override String get showMore             => 'Daha çox';
  @override String get showLess             => 'Daha az';
  @override String get brandOwnerLabel      => 'Sahibi';

  // ── Common Actions ───────────────────────────────────────────────────────────
  @override String get cancel               => 'İmtina';
  @override String get activate             => 'Aktivləşdir';
  @override String get save                 => 'Saxla';
  @override String get create               => 'Yarat';
  @override String get archive              => 'Arxivlə';
  @override String get reject               => 'Rədd et';
  @override String get accept               => 'Qəbul et';
  @override String get tryAgain             => 'Yenidən cəhd et';
  @override String get somethingWentWrong   => 'Xəta baş verdi';
  @override String get genericError         => 'Xəta baş verdi. Yenidən cəhd edin.';

  // ── Profile (shared) ─────────────────────────────────────────────────────────
  @override String get editProfile          => 'Profili Düzənlə';
  @override String get fullName             => 'Ad Soyad';
  @override String get email                => 'E-poçt';
  @override String get phone                => 'Telefon';
  @override String get settings             => 'Parametrlər';
  @override String get logout               => 'Çıxış';
  @override String get logoutTitle          => 'Çıxış';
  @override String get logoutConfirm        => 'Çıxmaq istədiyinizə əminsinizmi?';

  // ── UCR Profile ──────────────────────────────────────────────────────────────
  @override String get myFavorites              => 'Sevimlilər';
  @override String get switchToProvider         => 'Xidmət Təminatçısına keç';
  @override String get becomeProvider           => 'Xidmət Təminatçısı Ol';
  @override String get profileBecomeProviderTitle   => 'Xidmət Təminatçısı Ol';
  @override String get profileBecomeProviderContent => 'Bu, hesabınızda Xidmət Təminatçısı rolunu aktivləşdirəcək. İstənilən vaxt rejimlər arasında keçid edə bilərsiniz.';

  // ── USO Profile ──────────────────────────────────────────────────────────────
  @override String get roleServiceProvider  => 'Xidmət Təminatçısı';
  @override String get switchToCustomer     => 'Müştəri Rejiminə keç';

  // ── Profile Edit ─────────────────────────────────────────────────────────────
  @override String get editProfileTitle     => 'Profili Düzənlə';
  @override String get cropPhoto            => 'Şəkli kəs';
  @override String get takePhoto            => 'Foto çək';
  @override String get chooseFromLibrary    => 'Qalereyadan seç';
  @override String get removePhoto          => 'Fotoşəkli sil';
  @override String get emailDisabledNote    => 'E-poçt və telefon nömrəsi burada dəyişdirilə bilməz.';

  // ── Settings ─────────────────────────────────────────────────────────────────
  @override String get settingsTitle        => 'Parametrlər';
  @override String get appearance           => 'Görünüş';
  @override String get theme                => 'Tema';
  @override String get language             => 'Dil';
  @override String get reservationReminders => 'Rezervasiya Xatırlatmaları';
  @override String get enableReminders      => 'Xatırlatmaları Aktivləşdir';
  @override String get remindMe             => 'Xatırlat';
  @override String get minuteAbbr          => 'dəq';
  @override String get hourAbbr            => 'saat';
  @override String get timePastError       => 'Keçmiş vaxt seçilə bilməz. Zəhmət olmasa gələcək vaxt seçin.';

  // ── Reservations ─────────────────────────────────────────────────────────────
  @override String get reservationsTitle       => 'Rezervasiyalar';
  @override String get tabUpcoming             => 'Gələcək';
  @override String get tabPast                 => 'Keçmiş';
  @override String get noReservations          => 'Rezervasiya yoxdur';
  @override String get noReservationsSubtitle  => 'Xidmətlərə baxın və ilk görüşünüzü sifariş edin';
  @override String get statusPending           => 'Gözləmədə';
  @override String get statusConfirmed         => 'Təsdiqlənib';
  @override String get statusRejected          => 'Rədd edilib';
  @override String get statusCancelled         => 'Ləğv edilib';
  @override String get statusChangeReq         => 'Dəyişiklik';
  @override String get statusCompleted         => 'Tamamlandı';
  @override String get statusNoShow            => 'Gəlmədi';
  @override String get statusExpired           => 'Müddəti bitdi';

  // ── Reservation Detail ───────────────────────────────────────────────────────
  @override String get reservationTitle        => 'Rezervasiya';
  @override String get cancelReservationTitle  => 'Rezervasiyanı Ləğv Et';
  @override String get cancelReservationContent => 'Rezervasiyanı ləğv etmək istədiyinizə əminsinizmi?';
  @override String get cancelReasonHint        => 'Səbəb (istəyə görə)';
  @override String get keepIt                  => 'Saxla';
  @override String get cancelBooking           => 'Rezervasiyanı ləğv et';
  @override String get dateTime                => 'Tarix & Saat';
  @override String get endTime                 => 'Bitmə vaxtı';
  @override String get price                   => 'Qiymət';
  @override String get providerLabel           => 'Təminatçı';
  @override String get yourNote                => 'Qeydləriniz';
  @override String get rejectionReason         => 'Rədd etmə səbəbi';
  @override String get cancellationReason      => 'Ləğv etmə səbəbi';
  @override String get freeCancellation        => 'Pulsuz ləğv etmə mövcuddur';
  @override String get checkinQr               => 'Check-in QR';
  @override String get bookingId               => 'Rezervasiya ID';
  @override String get bookedOn                => 'Sifariş tarixi';
  @override String get reservationCancelled    => 'Rezervasiya ləğv edildi';

  // ── Incoming Reservations ────────────────────────────────────────────────────
  @override String get incomingTitle           => 'Daxil olan';
  @override String get incomingSubtitle        => 'Sifarişlərinizi idarə edin';
  @override String get tabPending              => 'Gözləyən';
  @override String get tabConfirmed            => 'Təsdiqlənmiş';
  @override String get noPendingRequests       => 'Gözləyən sorğu yoxdur';
  @override String get noConfirmedBookings     => 'Təsdiqlənmiş sifariş yoxdur';
  @override String get reservationAccepted     => 'Rezervasiya qəbul edildi ✓';
  @override String get rejectReservationTitle  => 'Rezervasiyanı Rədd et';
  @override String get reservationRejected     => 'Rezervasiya rədd edildi';

  // ── My Services ──────────────────────────────────────────────────────────────
  @override String get myServicesTitle         => 'Xidmətlərim';
  @override String get myServicesSubtitle      => 'Xidmətlərinizi idarə edin';
  @override String get noServicesYet           => 'Hələ xidmət yoxdur';
  @override String get noServicesSubtitle      => 'İlk xidmətinizi əlavə etmək üçün + düyməsinə toxunun.';
  @override String get archiveServiceTitle     => 'Xidməti Arxivlə';
  @override String get archiveServiceContent   => 'Bu xidmət deaktivləşdiriləcək və müştərilərdən gizlədiləcək. Sonradan yenidən aktiv edə bilərsiniz.';
  @override String get failedToArchive         => 'Arxivləmə uğursuz oldu. Yenidən cəhd edin.';

  // ── Create / Edit Service ────────────────────────────────────────────────────
  @override String get newService              => 'Yeni Xidmət';
  @override String get editService             => 'Xidməti Düzənlə';
  @override String get servicePhoto            => 'Xidmət Fotosu';
  @override String get basicInfo               => 'Əsas Məlumat';
  @override String get serviceName             => 'XİDMƏT ADI';
  @override String get serviceNameHint         => 'məs. Saç Kəsimi, Diş Müalicəsi';
  @override String get nameRequired            => 'Ad tələb olunur';
  @override String get descriptionLabel        => 'AÇIQLAMA';
  @override String get descriptionHint         => 'İstəyə görə açıqlama';
  @override String get brandLabel              => 'BREND';
  @override String get categoryLabel           => 'KATEQORİYA';
  @override String get none                    => 'Yoxdur';
  @override String get pricingSection          => 'Qiymətləndirmə';
  @override String get priceLabel              => 'QİYMƏT';
  @override String get priceHint               => 'Pulsuzsa boş buraxın';
  @override String get bookingSettings         => 'Sifariş Parametrləri';
  @override String get serviceType             => 'XİDMƏT NÖVܤ';
  @override String get solo                    => 'Tək';
  @override String get multi                   => 'Çoxlu';
  @override String get approvalMode            => 'TƏSDİQ REJIMI';
  @override String get manual                  => 'Əl ilə';
  @override String get autoApproval            => 'Avtomatik';
  @override String get weeklySchedule          => 'Həftəlik Cədvəl';
  @override String get waitingTime             => 'GÖZLƏMƏ MÜDDƏTİ';
  @override String get minAdvance              => 'MİN ƏVVƏLCƏDƏN SİFARİŞ';
  @override String get maxAdvance              => 'MAK ƏVVƏLCƏDƏN SİFARİŞ';
  @override String get freeCancellationDeadline => 'PULSUZ LƏĞVETMƏ SON TARİXİ';
  @override String get fieldRequired           => 'Tələb olunur';
  @override String get enterNumber             => 'Rəqəm daxil edin';
  @override String get selectBrand             => 'Brend Seçin';
  @override String get selectCategory          => 'Kateqoriya Seçin';
  @override String get addServicePhoto         => 'Xidmət Fotosu Əlavə Et';
  @override String get tapToChoose             => 'Qalereyadan və ya kameradan seçmək üçün toxunun';
  @override String get changePhoto             => 'Fotoşəkli dəyiş';
  @override String get cameraAccessDenied      => 'Kamera icazəsi rədd edilib. Zəhmət olmasa Parametrlərdən icazə verin.';
  @override String get photoLibraryAccessDenied => 'Qalereya icazəsi rədd edilib. Zəhmət olmasa Parametrlərdən icazə verin.';

  // ── Service Detail ───────────────────────────────────────────────────────────
  @override String get about                   => 'Haqqında';
  @override String get brandDetailLabel        => 'Brend';
  @override String get location                => 'Ünvan';
  @override String get booking                 => 'Sifariş';
  @override String get instantConfirmation     => 'Ani təsdiq';
  @override String get requiresApproval        => 'Təsdiq tələb edir';
  @override String get bookNow                 => 'İndi Sifariş Et';
  @override String get requestBooking          => 'Sifariş Et';
  @override String get reservationCreated      => 'Rezervasiya yaradıldı!';

  // ── Create Reservation Sheet ─────────────────────────────────────────────────
  @override String get sheetBookNow            => 'İndi Sifariş Et';
  @override String get sheetRequestBooking     => 'Sifariş Et';
  @override String get sheetDate               => 'Tarix';
  @override String get sheetTime               => 'Vaxt';
  @override String get sheetNoteHint           => 'Qeyd əlavə et (istəyə bağlı)';
  @override String get sheetConfirmBooking     => 'Sifarişi Təsdiqlə';
  @override String get sheetSendRequest        => 'Sorğu Göndər';

  // ── Provider Profile ─────────────────────────────────────────────────────────
  @override String get providerProfile         => 'Xidmət Təminatçısı';
  @override String get providerNotFound        => 'Təminatçı tapılmadı.';

  // ── Navigation ───────────────────────────────────────────────────────────────
  @override String get navExplore              => 'Kəşf et';
  @override String get navReservations         => 'Rezervasiyalar';
  @override String get navNotifications        => 'Bildirişlər';
  @override String get navProfile              => 'Profil';
  @override String get navIncoming             => 'Daxil olan';
  @override String get navMyServices           => 'Xidmətlərim';
  @override String get navMyBrands             => 'Brandlərim';
  @override String get notificationsComingSoon => 'Tezliklə…';

  // ── My Brands (USO) ──────────────────────────────────────────────────────────
  @override String get myBrands             => 'Brandlərim';
  @override String get noBrandsTitle        => 'Hələ Brand Yoxdur';
  @override String get noBrandsSubtitle     => 'Xidmətlərinizi vahid bir ad altında idarə etmək üçün brand yaradın.';
  @override String get createBrand          => 'Brand Yarat';
  @override String get brandName            => 'Brand Adı';
  @override String get brandNameHint        => 'məs. Bella Studio';
  @override String get brandEmail           => 'Brand E-poçtu';
  @override String get brandEmailHint       => 'elesimac@brand.com (istəyə görə)';
  @override String get brandPhone           => 'Brand Telefonu';
  @override String get brandPhoneHint       => '+994 50 000 00 00';
  @override String get brandCreated         => 'Brand uğurla yaradıldı';
  @override String get brandDeleted         => 'Brand silindi';
  @override String get deleteBrand          => 'Brandu Sil';
  @override String get deleteBrandConfirm   => 'Bu brandu silmək istədiyinizə əminsiniz?';
  @override String get verifyPhone          => 'Telefonu Doğrula';
  @override String get verifyPhoneSubtitle  => 'Brand telefon nömrəsinə göndərilən kodu daxil edin.';
  @override String get otpSentTo            => 'Kod göndərildi:';
  @override String get verifyAndCreate      => 'Doğrula və Yarat';
  @override String get editBrand            => 'Brandu Redaktə Et';
  @override String get brandUpdated         => 'Brand uğurla yeniləndi';
  @override String get phoneNotEditable     => 'Telefon nömrəsi doğrulamadan sonra dəyişdirilə bilməz.';
  @override String get brandDescription     => 'Təsvir';
  @override String get brandDescriptionHint => 'Brendiniz haqqında müştərilərə məlumat verin…';
  @override String get brandLocation        => 'Ünvan';
  @override String get brandLocationHint    => 'məs. Bakı, Azərbaycan';
  @override String get brandWebsite         => 'Vebsayt';
  @override String get brandWebsiteHint     => 'https://nümunə.com';
  @override String get invalidUrl           => 'Düzgün URL daxil edin';
}
