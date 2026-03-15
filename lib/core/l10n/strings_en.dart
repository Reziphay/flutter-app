// strings_en.dart
// Reziphay — English strings
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'app_localizations.dart';

class StringsEn implements AppLocalizations {
  const StringsEn();

  // ── Onboarding ──────────────────────────────────────────────────────────────
  @override String get appTagline           => 'Book smarter, live better';
  @override String get onboardingPrompt     => 'How would you like to continue?';
  @override String get roleCustomer         => "I'm a Customer";
  @override String get roleCustomerDesc     => 'Discover and book services near you';
  @override String get roleProvider         => "I'm a Service Provider";
  @override String get roleProviderDesc     => 'Manage your services and bookings';
  @override String get languageModalTitle   => 'Language';

  // ── Auth – Phone ─────────────────────────────────────────────────────────────
  @override String get phoneTitle           => 'Enter your phone number';
  @override String get phoneSubtitle        => "We'll send you a one-time code to verify your identity";
  @override String get phoneLabel           => 'Phone Number';
  @override String get phonePlaceholder     => 'XX 123 45 67';
  @override String get phoneSendCode        => 'Send Code';
  @override String get phoneTerms           => 'By continuing, you agree to our Terms of Service\nand Privacy Policy';

  // ── Auth – OTP ───────────────────────────────────────────────────────────────
  @override String get otpTitle             => 'Verify your number';
  @override String otpSubtitle(String p)    => 'Enter the 6-digit code sent to $p';
  @override String get otpVerify            => 'Verify';
  @override String get otpResend            => 'Resend Code';
  @override String otpResendIn(int s)       => 'Resend in ${s}s';
  @override String get otpInvalidCode       => 'Invalid code. Please try again.';
  @override String get otpResendFailed      => 'Failed to resend code. Please try again.';

  // ── Auth – Register ───────────────────────────────────────────────────────────
  @override String get registerTitle        => 'Almost there!';
  @override String registerSubtitle(String p) => 'Phone verified: $p';
  @override String get registerFullName     => 'Full Name';
  @override String get registerFullNameHint => 'Your full name';
  @override String get registerEmail        => 'Email Address';
  @override String get registerEmailHint    => 'your@email.com';
  @override String get registerCreateAccount => 'Create Account';

  // ── Explore ──────────────────────────────────────────────────────────────────
  @override String greeting(String n)       => 'Hello, $n 👋';
  @override String get exploreSubtitle      => 'Find the best services near you';
  @override String get exploreSearch        => 'Search services, brands…';
  @override String get exploreNearMe        => 'Near Me';
  @override String get explorePopularBrands => 'Popular Brands';
  @override String get exploreFeatured      => 'Featured';
  @override String get seeAll               => 'See all';
  @override String get chipAll              => 'All';
  @override String get badgeVip             => 'VIP';

  // ── Search ───────────────────────────────────────────────────────────────────
  @override String get searchTabServices    => 'Services';
  @override String get searchTabBrands      => 'Brands';
  @override String get searchTabProviders   => 'Providers';
  @override String get searchHint           => 'Search services, brands…';
  @override String get searchStartTyping    => 'Start typing to search';
  @override String get searchNoServices     => 'No services found';
  @override String get searchNoBrands       => 'No brands found';
  @override String get searchNoProviders    => 'No providers found';

  // ── Search Filters ───────────────────────────────────────────────────────────
  @override String get filtersTitle         => 'Filters';
  @override String get filtersReset         => 'Reset';
  @override String get filtersSortBy        => 'Sort by';
  @override String get filtersPriceRange    => 'Price range';
  @override String get filtersApply         => 'Apply Filters';
  @override String get sortRelevance        => 'Relevance';
  @override String get sortHighestRated     => 'Highest Rated';
  @override String get sortNearestFirst     => 'Nearest First';
  @override String get sortPriceLow         => 'Price: Low to High';
  @override String get sortPriceHigh        => 'Price: High to Low';
  @override String get sortMostPopular      => 'Most Popular';

  // ── Brand Detail ─────────────────────────────────────────────────────────────
  @override String get brandServices        => 'Services';
  @override String get brandNoServices      => 'No services yet';

  // ── Common Actions ───────────────────────────────────────────────────────────
  @override String get cancel               => 'Cancel';
  @override String get activate             => 'Activate';
  @override String get save                 => 'Save';
  @override String get create               => 'Create';
  @override String get archive              => 'Archive';
  @override String get reject               => 'Reject';
  @override String get accept               => 'Accept';
  @override String get tryAgain             => 'Try again';
  @override String get somethingWentWrong   => 'Something went wrong';
  @override String get genericError         => 'Something went wrong. Please try again.';

  // ── Profile (shared) ─────────────────────────────────────────────────────────
  @override String get editProfile          => 'Edit Profile';
  @override String get fullName             => 'Full Name';
  @override String get email                => 'Email';
  @override String get phone                => 'Phone';
  @override String get settings             => 'Settings';
  @override String get logout               => 'Log out';
  @override String get logoutTitle          => 'Log out';
  @override String get logoutConfirm        => 'Are you sure you want to log out?';

  // ── UCR Profile ──────────────────────────────────────────────────────────────
  @override String get myFavorites              => 'My Favorites';
  @override String get switchToProvider         => 'Switch to Service Provider';
  @override String get becomeProvider           => 'Become a Service Provider';
  @override String get profileBecomeProviderTitle   => 'Become a Service Provider';
  @override String get profileBecomeProviderContent => 'This will activate the Service Provider role on your account. You can switch between Customer and Provider modes at any time.';

  // ── USO Profile ──────────────────────────────────────────────────────────────
  @override String get roleServiceProvider  => 'Service Provider';
  @override String get switchToCustomer     => 'Switch to Customer Mode';

  // ── Profile Edit ─────────────────────────────────────────────────────────────
  @override String get editProfileTitle     => 'Edit Profile';
  @override String get cropPhoto            => 'Crop photo';
  @override String get takePhoto            => 'Take a photo';
  @override String get chooseFromLibrary    => 'Choose from library';
  @override String get removePhoto          => 'Remove photo';
  @override String get emailDisabledNote    => 'Email and phone number cannot be changed here.';

  // ── Settings ─────────────────────────────────────────────────────────────────
  @override String get settingsTitle        => 'Settings';
  @override String get appearance           => 'Appearance';
  @override String get theme                => 'Theme';
  @override String get language             => 'Language';
  @override String get reservationReminders => 'Reservation Reminders';
  @override String get enableReminders      => 'Enable Reminders';
  @override String get remindMe             => 'Remind me';

  // ── Reservations ─────────────────────────────────────────────────────────────
  @override String get reservationsTitle       => 'Reservations';
  @override String get tabUpcoming             => 'Upcoming';
  @override String get tabPast                 => 'Past';
  @override String get noReservations          => 'No reservations here';
  @override String get noReservationsSubtitle  => 'Browse services and book your first appointment';
  @override String get statusPending           => 'Pending';
  @override String get statusConfirmed         => 'Confirmed';
  @override String get statusRejected          => 'Rejected';
  @override String get statusCancelled         => 'Cancelled';
  @override String get statusChangeReq         => 'Change Req.';
  @override String get statusCompleted         => 'Completed';
  @override String get statusNoShow            => 'No Show';
  @override String get statusExpired           => 'Expired';

  // ── Reservation Detail ───────────────────────────────────────────────────────
  @override String get reservationTitle        => 'Reservation';
  @override String get cancelReservationTitle  => 'Cancel Reservation';
  @override String get cancelReservationContent => 'Are you sure you want to cancel this reservation?';
  @override String get cancelReasonHint        => 'Reason (optional)';
  @override String get keepIt                  => 'Keep it';
  @override String get cancelBooking           => 'Cancel booking';
  @override String get dateTime                => 'Date & Time';
  @override String get endTime                 => 'End Time';
  @override String get price                   => 'Price';
  @override String get providerLabel           => 'Provider';
  @override String get yourNote                => 'Your Note';
  @override String get rejectionReason         => 'Rejection Reason';
  @override String get cancellationReason      => 'Cancellation Reason';
  @override String get freeCancellation        => 'Free cancellation available';
  @override String get checkinQr               => 'Check-in QR';
  @override String get bookingId               => 'Booking ID';
  @override String get bookedOn                => 'Booked on';
  @override String get reservationCancelled    => 'Reservation cancelled';

  // ── Incoming Reservations ────────────────────────────────────────────────────
  @override String get incomingTitle           => 'Incoming';
  @override String get incomingSubtitle        => 'Manage your bookings';
  @override String get tabPending              => 'Pending';
  @override String get tabConfirmed            => 'Confirmed';
  @override String get noPendingRequests       => 'No pending requests';
  @override String get noConfirmedBookings     => 'No confirmed bookings';
  @override String get reservationAccepted     => 'Reservation accepted ✓';
  @override String get rejectReservationTitle  => 'Reject Reservation';
  @override String get reservationRejected     => 'Reservation rejected';

  // ── My Services ──────────────────────────────────────────────────────────────
  @override String get myServicesTitle         => 'My Services';
  @override String get myServicesSubtitle      => 'Manage your services';
  @override String get noServicesYet           => 'No services yet';
  @override String get noServicesSubtitle      => 'Tap + to add your first service and start receiving bookings.';
  @override String get archiveServiceTitle     => 'Archive Service';
  @override String get archiveServiceContent   => 'This service will be deactivated and hidden from customers. You can re-activate it later.';
  @override String get failedToArchive         => 'Failed to archive. Please try again.';

  // ── Create / Edit Service ────────────────────────────────────────────────────
  @override String get newService              => 'New Service';
  @override String get editService             => 'Edit Service';
  @override String get servicePhoto            => 'Service Photo';
  @override String get basicInfo               => 'Basic Info';
  @override String get serviceName             => 'SERVICE NAME';
  @override String get serviceNameHint         => 'e.g. Haircut, Dental Cleaning';
  @override String get nameRequired            => 'Name is required';
  @override String get descriptionLabel        => 'DESCRIPTION';
  @override String get descriptionHint         => 'Optional description';
  @override String get brandLabel              => 'BRAND';
  @override String get categoryLabel           => 'CATEGORY';
  @override String get none                    => 'None';
  @override String get pricingSection          => 'Pricing';
  @override String get priceLabel              => 'PRICE';
  @override String get priceHint               => 'Leave empty if free';
  @override String get bookingSettings         => 'Booking Settings';
  @override String get serviceType             => 'SERVICE TYPE';
  @override String get solo                    => 'Solo';
  @override String get multi                   => 'Multi';
  @override String get approvalMode            => 'APPROVAL MODE';
  @override String get manual                  => 'Manual';
  @override String get autoApproval            => 'Auto';
  @override String get weeklySchedule          => 'Weekly Schedule';
  @override String get waitingTime             => 'WAITING TIME';
  @override String get minAdvance              => 'MIN ADVANCE BOOKING';
  @override String get maxAdvance              => 'MAX ADVANCE BOOKING';
  @override String get freeCancellationDeadline => 'FREE CANCELLATION DEADLINE';
  @override String get fieldRequired           => 'Required';
  @override String get enterNumber             => 'Enter a number';
  @override String get selectBrand             => 'Select Brand';
  @override String get selectCategory          => 'Select Category';
  @override String get addServicePhoto         => 'Add Service Photo';
  @override String get tapToChoose             => 'Tap to choose from library or camera';
  @override String get changePhoto             => 'Change photo';
  @override String get cameraAccessDenied      => 'Camera access denied. Please allow it in Settings.';
  @override String get photoLibraryAccessDenied => 'Photo library access denied. Please allow it in Settings.';

  // ── Service Detail ───────────────────────────────────────────────────────────
  @override String get about                   => 'About';
  @override String get brandDetailLabel        => 'Brand';
  @override String get location                => 'Location';
  @override String get booking                 => 'Booking';
  @override String get instantConfirmation     => 'Instant confirmation';
  @override String get requiresApproval        => 'Requires approval';
  @override String get bookNow                 => 'Book Now';
  @override String get requestBooking          => 'Request Booking';
  @override String get reservationCreated      => 'Reservation created!';

  // ── Navigation ───────────────────────────────────────────────────────────────
  @override String get navExplore              => 'Explore';
  @override String get navReservations         => 'Reservations';
  @override String get navNotifications        => 'Notifications';
  @override String get navProfile              => 'Profile';
  @override String get navIncoming             => 'Incoming';
  @override String get navMyServices           => 'My Services';
  @override String get notificationsComingSoon => 'Coming soon';
}
