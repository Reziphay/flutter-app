// app_localizations.dart
// Reziphay — Abstract localization base + delegate + context extension
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'dart:async';
import 'package:flutter/widgets.dart';

import 'strings_az.dart';
import 'strings_en.dart';
import 'strings_ru.dart';
import 'strings_tr.dart';

// ── Abstract class ────────────────────────────────────────────────────────────

abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  // ── Onboarding ──────────────────────────────────────────────────────────────
  String get appTagline;
  String get onboardingPrompt;
  String get roleCustomer;
  String get roleCustomerDesc;
  String get roleProvider;
  String get roleProviderDesc;
  String get languageModalTitle;

  // ── Auth – Phone ─────────────────────────────────────────────────────────────
  String get phoneTitle;
  String get phoneSubtitle;
  String get phoneLabel;
  String get phonePlaceholder;
  String get phoneSendCode;
  String get phoneTerms;

  // ── Auth – OTP ───────────────────────────────────────────────────────────────
  String get otpTitle;
  String otpSubtitle(String phone);
  String get otpVerify;
  String get otpResend;
  String otpResendIn(int seconds);
  String get otpInvalidCode;
  String get otpResendFailed;

  // ── Auth – Register ───────────────────────────────────────────────────────────
  String get registerTitle;
  String registerSubtitle(String phone);
  String get registerFullName;
  String get registerFullNameHint;
  String get registerEmail;
  String get registerEmailHint;
  String get registerCreateAccount;

  // ── Explore ──────────────────────────────────────────────────────────────────
  String greeting(String name);
  String get exploreSubtitle;
  String get exploreSearch;
  String get exploreNearMe;
  String get explorePopularBrands;
  String get exploreFeatured;
  String get seeAll;
  String get chipAll;
  String get badgeVip;

  // ── Search ───────────────────────────────────────────────────────────────────
  String get searchTabServices;
  String get searchTabBrands;
  String get searchTabProviders;
  String get searchHint;
  String get searchStartTyping;
  String get searchNoServices;
  String get searchNoBrands;
  String get searchNoProviders;

  // ── Search Filters ───────────────────────────────────────────────────────────
  String get filtersTitle;
  String get filtersReset;
  String get filtersSortBy;
  String get filtersPriceRange;
  String get filtersApply;
  String get sortRelevance;
  String get sortHighestRated;
  String get sortNearestFirst;
  String get sortPriceLow;
  String get sortPriceHigh;
  String get sortMostPopular;

  // ── Brand Detail ─────────────────────────────────────────────────────────────
  String get brandServices;
  String get brandNoServices;
  String get showMore;
  String get showLess;
  String get brandOwnerLabel;

  // ── Common Actions ───────────────────────────────────────────────────────────
  String get cancel;
  String get activate;
  String get save;
  String get create;
  String get archive;
  String get reject;
  String get accept;
  String get tryAgain;
  String get somethingWentWrong;
  String get genericError;

  // ── Profile (shared) ─────────────────────────────────────────────────────────
  String get editProfile;
  String get fullName;
  String get email;
  String get phone;
  String get settings;
  String get logout;
  String get logoutTitle;
  String get logoutConfirm;

  // ── UCR Profile ──────────────────────────────────────────────────────────────
  String get myFavorites;
  String get switchToProvider;
  String get becomeProvider;
  String get profileBecomeProviderTitle;
  String get profileBecomeProviderContent;

  // ── USO Profile ──────────────────────────────────────────────────────────────
  String get roleServiceProvider;
  String get switchToCustomer;

  // ── Profile Edit ─────────────────────────────────────────────────────────────
  String get editProfileTitle;
  String get cropPhoto;
  String get takePhoto;
  String get chooseFromLibrary;
  String get removePhoto;
  String get emailDisabledNote;

  // ── Settings ─────────────────────────────────────────────────────────────────
  String get settingsTitle;
  String get appearance;
  String get theme;
  String get language;
  String get reservationReminders;
  String get enableReminders;
  String get remindMe;
  String get minuteAbbr;
  String get hourAbbr;
  String get timePastError;
  String manualApprovalLeadTimeError(int minutes);

  // ── Reservations ─────────────────────────────────────────────────────────────
  String get reservationsTitle;
  String get tabUpcoming;
  String get tabPast;
  String get noReservations;
  String get noReservationsSubtitle;
  String get statusPending;
  String get statusConfirmed;
  String get statusRejected;
  String get statusCancelled;
  String get statusChangeReq;
  String get statusCompleted;
  String get statusNoShow;
  String get statusExpired;

  // ── Reservation Detail ───────────────────────────────────────────────────────
  String get reservationTitle;
  String get cancelReservationTitle;
  String get cancelReservationContent;
  String get cancelReasonHint;
  String get keepIt;
  String get cancelBooking;
  String get dateTime;
  String get endTime;
  String get price;
  String get providerLabel;
  String get yourNote;
  String get rejectionReason;
  String get cancellationReason;
  String get freeCancellation;
  String get checkinQr;
  String get bookingId;
  String get bookedOn;
  String get reservationCancelled;

  // ── Incoming Reservations (USO) ──────────────────────────────────────────────
  String get incomingTitle;
  String get incomingSubtitle;
  String get tabPending;
  String get tabConfirmed;
  String get tabHistory;
  String get noPendingRequests;
  String get noConfirmedBookings;
  String get noHistoryItems;
  String get reservationAccepted;
  String get rejectReservationTitle;
  String get reservationRejected;

  // ── My Services (USO) ────────────────────────────────────────────────────────
  String get myServicesTitle;
  String get myServicesSubtitle;
  String get noServicesYet;
  String get noServicesSubtitle;
  String get archiveServiceTitle;
  String get archiveServiceContent;
  String get failedToArchive;

  // ── Create / Edit Service ────────────────────────────────────────────────────
  String get newService;
  String get editService;
  String get servicePhoto;
  String get basicInfo;
  String get serviceName;
  String get serviceNameHint;
  String get nameRequired;
  String get descriptionLabel;
  String get descriptionHint;
  String get brandLabel;
  String get categoryLabel;
  String get none;
  String get pricingSection;
  String get priceLabel;
  String get priceHint;
  String get bookingSettings;
  String get serviceType;
  String get solo;
  String get multi;
  String get approvalMode;
  String get manual;
  String get autoApproval;
  String get weeklySchedule;
  String get waitingTime;
  String get minAdvance;
  String get maxAdvance;
  String get freeCancellationDeadline;
  String get fieldRequired;
  String get enterNumber;
  String get selectBrand;
  String get selectCategory;
  String get addServicePhoto;
  String get tapToChoose;
  String get changePhoto;
  String get cameraAccessDenied;
  String get photoLibraryAccessDenied;

  // ── Service Detail ───────────────────────────────────────────────────────────
  String get about;
  String get brandDetailLabel;
  String get location;
  String get booking;
  String get instantConfirmation;
  String get requiresApproval;
  String get bookNow;
  String get requestBooking;
  String get reservationCreated;
  String get awaitingApproval;
  String get ownerChangeRequest;
  String get changeRequestDetails;
  String get acceptChange;
  String get rejectChange;
  String get changeRequestAccepted;
  String get changeRequestRejected;

  // ── Create Reservation Sheet ─────────────────────────────────────────────────
  String get sheetBookNow;
  String get sheetRequestBooking;
  String get sheetDate;
  String get sheetTime;
  String get sheetNoteHint;
  String get sheetConfirmBooking;
  String get sheetSendRequest;

  // ── Provider Profile ─────────────────────────────────────────────────────────
  String get providerProfile;
  String get providerNotFound;

  // ── Navigation ───────────────────────────────────────────────────────────────
  String get navExplore;
  String get navReservations;
  String get navNotifications;
  String get navProfile;
  String get navIncoming;
  String get navMyServices;
  String get navMyBrands;
  String get notificationsComingSoon;

  // ── My Brands (USO) ──────────────────────────────────────────────────────────
  String get myBrands;
  String get noBrandsTitle;
  String get noBrandsSubtitle;
  String get createBrand;
  String get brandName;
  String get brandNameHint;
  String get brandEmail;
  String get brandEmailHint;
  String get brandPhone;
  String get brandPhoneHint;
  String get brandCreated;
  String get brandDeleted;
  String get deleteBrand;
  String get deleteBrandConfirm;
  String get verifyPhone;
  String get verifyPhoneSubtitle;
  String get otpSentTo;
  String get verifyAndCreate;
  String get editBrand;
  String get brandUpdated;
  String get phoneNotEditable;
  String get brandDescription;
  String get brandDescriptionHint;
  String get brandLocation;
  String get brandLocationHint;
  String get brandWebsite;
  String get brandWebsiteHint;
  String get invalidUrl;
}

// ── Delegate ──────────────────────────────────────────────────────────────────

class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  static const _supported = ['az', 'en', 'ru', 'tr'];

  @override
  bool isSupported(Locale locale) =>
      _supported.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      switch (locale.languageCode) {
        'en' => const StringsEn(),
        'ru' => const StringsRu(),
        'tr' => const StringsTr(),
        _    => const StringsAz(),
      };

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

// ── Extension ─────────────────────────────────────────────────────────────────

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
