// endpoints.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

enum OtpPurpose {
  authenticate('AUTHENTICATE'),
  login('LOGIN'),
  register('REGISTER'),
  verifyPhone('VERIFY_PHONE');

  const OtpPurpose(this.value);
  final String value;
}

abstract final class Endpoints {
  static const String _base = 'http://localhost:3000/api/v1';
  static String get baseUrl => _base;

  // Auth
  static const String requestPhoneOtp      = '/auth/request-phone-otp';
  static const String verifyPhoneOtp       = '/auth/verify-phone-otp';
  static const String completeRegistration = '/auth/complete-registration';
  static const String refreshToken         = '/auth/refresh';
  static const String logout               = '/auth/logout';
  static const String authMe               = '/auth/me';

  // User
  static const String userMe       = '/users/me';
  static const String userMeAvatar = '/users/me/avatar';
  static const String activateUso  = '/users/me/activate-uso';
  static const String getRoles     = '/users/me/roles';
  static const String switchRole   = '/users/me/switch-role';

  // Discovery & Search
  static const String search         = '/search';
  static const String nearbyServices = '/services/nearby';
  static const String serviceOwners  = '/service-owners';
  static const String services       = '/services';
  static const String brands         = '/brands';
  static const String categories     = '/categories';

  static String serviceById(String id) => '/services/$id';
  static String brandById(String id)   => '/brands/$id';

  // Reservations — UCR
  static const String reservations          = '/reservations';
  static const String myReservations        = '/reservations/my';
  static String reservationById(String id)  => '/reservations/$id';
  static String cancelReservation(String id)=> '/reservations/$id/cancel-by-customer';

  // Reservations — USO
  static const String incomingReservations      = '/reservations/incoming';
  static const String incomingReservationStats  = '/reservations/incoming/stats';
  static String acceptReservation(String id)    => '/reservations/$id/accept';
  static String rejectReservation(String id)    => '/reservations/$id/reject';
  static String cancelByOwner(String id)        => '/reservations/$id/cancel-by-owner';
  static String completeManually(String id)     => '/reservations/$id/complete-manually';

  // Services — USO (CRUD)
  static const String myServices              = '/services/mine';
  static const String createService           = '/services';
  static String updateService(String id)      => '/services/$id';
  static String archiveService(String id)     => '/services/$id';
  static String serviceAvailRules(String id)  => '/services/$id/availability-rules';
  static String serviceAvailExceptions(String id) => '/services/$id/availability-exceptions';
  static String servicePhotos(String id)      => '/services/$id/photos';
  static String deleteServicePhoto(String id, String photoId) => '/services/$id/photos/$photoId';

  // Brands — USO
  static const String myBrands    = '/brands/mine';
  static const String createBrand = '/brands';
  static String updateBrand(String id)  => '/brands/$id';
  static String deleteBrand(String id)  => '/brands/$id';
  static String uploadBrandLogo(String id) => '/brands/$id/logo';

  // Favorites — UCR
  static const String favoriteBrands   = '/users/me/favorites/brands';
  static const String favoriteOwners   = '/users/me/favorites/owners';
  static const String favoriteServices = '/users/me/favorites/services';
  static String addFavoriteBrand(String id)      => '/users/me/favorites/brands/$id';
  static String removeFavoriteBrand(String id)   => '/users/me/favorites/brands/$id';
  static String favoriteBrandStatus(String id)   => '/users/me/favorites/brands/$id/status';
  static String addFavoriteOwner(String id)      => '/users/me/favorites/owners/$id';
  static String removeFavoriteOwner(String id)   => '/users/me/favorites/owners/$id';
  static String favoriteOwnerStatus(String id)   => '/users/me/favorites/owners/$id/status';
  static String addFavoriteService(String id)    => '/users/me/favorites/services/$id';
  static String removeFavoriteService(String id) => '/users/me/favorites/services/$id';
  static String favoriteServiceStatus(String id) => '/users/me/favorites/services/$id/status';
}
