// strings_ru.dart
// Reziphay — Russian strings
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'app_localizations.dart';

class StringsRu implements AppLocalizations {
  const StringsRu();

  // ── Onboarding ──────────────────────────────────────────────────────────────
  @override String get appTagline           => 'Умные записи, лучшая жизнь';
  @override String get onboardingPrompt     => 'Как вы хотите продолжить?';
  @override String get roleCustomer         => 'Я клиент';
  @override String get roleCustomerDesc     => 'Находите и бронируйте услуги рядом';
  @override String get roleProvider         => 'Я поставщик услуг';
  @override String get roleProviderDesc     => 'Управляйте своими услугами и бронированиями';
  @override String get languageModalTitle   => 'Язык';

  // ── Auth – Phone ─────────────────────────────────────────────────────────────
  @override String get phoneTitle           => 'Введите номер телефона';
  @override String get phoneSubtitle        => 'Мы отправим одноразовый код для подтверждения';
  @override String get phoneLabel           => 'Номер телефона';
  @override String get phonePlaceholder     => 'XX 123 45 67';
  @override String get phoneSendCode        => 'Отправить код';
  @override String get phoneTerms           => 'Продолжая, вы соглашаетесь с Условиями\nи Политикой конфиденциальности';

  // ── Auth – OTP ───────────────────────────────────────────────────────────────
  @override String get otpTitle             => 'Подтвердите номер';
  @override String otpSubtitle(String p)    => 'Введите 6-значный код, отправленный на $p';
  @override String get otpVerify            => 'Подтвердить';
  @override String get otpResend            => 'Отправить код повторно';
  @override String otpResendIn(int s)       => 'Повторная отправка через ${s}с';
  @override String get otpInvalidCode       => 'Неверный код. Попробуйте снова.';
  @override String get otpResendFailed      => 'Не удалось отправить код. Попробуйте снова.';

  // ── Auth – Register ───────────────────────────────────────────────────────────
  @override String get registerTitle        => 'Почти готово!';
  @override String registerSubtitle(String p) => 'Телефон подтверждён: $p';
  @override String get registerFullName     => 'Полное имя';
  @override String get registerFullNameHint => 'Ваше полное имя';
  @override String get registerEmail        => 'Адрес эл. почты';
  @override String get registerEmailHint    => 'ваш@email.com';
  @override String get registerCreateAccount => 'Создать аккаунт';

  // ── Explore ──────────────────────────────────────────────────────────────────
  @override String greeting(String n)       => 'Привет, $n 👋';
  @override String get exploreSubtitle      => 'Найдите лучшие услуги рядом';
  @override String get exploreSearch        => 'Поиск услуг, брендов…';
  @override String get exploreNearMe        => 'Рядом со мной';
  @override String get explorePopularBrands => 'Популярные бренды';
  @override String get exploreFeatured      => 'Рекомендуемое';
  @override String get seeAll               => 'Все';
  @override String get chipAll              => 'Все';
  @override String get badgeVip             => 'VIP';

  // ── Search ───────────────────────────────────────────────────────────────────
  @override String get searchTabServices    => 'Услуги';
  @override String get searchTabBrands      => 'Бренды';
  @override String get searchTabProviders   => 'Поставщики';
  @override String get searchHint           => 'Поиск услуг, брендов…';
  @override String get searchStartTyping    => 'Начните вводить текст для поиска';
  @override String get searchNoServices     => 'Услуги не найдены';
  @override String get searchNoBrands       => 'Бренды не найдены';
  @override String get searchNoProviders    => 'Поставщики не найдены';

  // ── Search Filters ───────────────────────────────────────────────────────────
  @override String get filtersTitle         => 'Фильтры';
  @override String get filtersReset         => 'Сбросить';
  @override String get filtersSortBy        => 'Сортировка';
  @override String get filtersPriceRange    => 'Ценовой диапазон';
  @override String get filtersApply         => 'Применить фильтры';
  @override String get sortRelevance        => 'Релевантность';
  @override String get sortHighestRated     => 'Высший рейтинг';
  @override String get sortNearestFirst     => 'Ближайшие';
  @override String get sortPriceLow         => 'Цена: от низкой к высокой';
  @override String get sortPriceHigh        => 'Цена: от высокой к низкой';
  @override String get sortMostPopular      => 'Самые популярные';

  // ── Brand Detail ─────────────────────────────────────────────────────────────
  @override String get brandServices        => 'Услуги';
  @override String get brandNoServices      => 'Услуг пока нет';
  @override String get showMore             => 'Подробнее';
  @override String get showLess             => 'Свернуть';
  @override String get brandOwnerLabel      => 'Владелец';

  // ── Common Actions ───────────────────────────────────────────────────────────
  @override String get cancel               => 'Отмена';
  @override String get activate             => 'Активировать';
  @override String get save                 => 'Сохранить';
  @override String get create               => 'Создать';
  @override String get archive              => 'Архивировать';
  @override String get reject               => 'Отклонить';
  @override String get accept               => 'Принять';
  @override String get tryAgain             => 'Повторить';
  @override String get somethingWentWrong   => 'Что-то пошло не так';
  @override String get genericError         => 'Что-то пошло не так. Повторите попытку.';

  // ── Profile (shared) ─────────────────────────────────────────────────────────
  @override String get editProfile          => 'Редактировать профиль';
  @override String get fullName             => 'Полное имя';
  @override String get email                => 'Эл. почта';
  @override String get phone                => 'Телефон';
  @override String get settings             => 'Настройки';
  @override String get logout               => 'Выйти';
  @override String get logoutTitle          => 'Выйти';
  @override String get logoutConfirm        => 'Вы уверены, что хотите выйти?';

  // ── UCR Profile ──────────────────────────────────────────────────────────────
  @override String get myFavorites              => 'Избранное';
  @override String get switchToProvider         => 'Переключиться на поставщика';
  @override String get becomeProvider           => 'Стать поставщиком услуг';
  @override String get profileBecomeProviderTitle   => 'Стать поставщиком услуг';
  @override String get profileBecomeProviderContent => 'Это активирует роль поставщика услуг в вашем аккаунте. Вы можете переключаться между режимами в любое время.';

  // ── USO Profile ──────────────────────────────────────────────────────────────
  @override String get roleServiceProvider  => 'Поставщик услуг';
  @override String get switchToCustomer     => 'Режим клиента';

  // ── Profile Edit ─────────────────────────────────────────────────────────────
  @override String get editProfileTitle     => 'Редактировать профиль';
  @override String get cropPhoto            => 'Обрезать фото';
  @override String get takePhoto            => 'Сделать фото';
  @override String get chooseFromLibrary    => 'Выбрать из галереи';
  @override String get removePhoto          => 'Удалить фото';
  @override String get emailDisabledNote    => 'Эл. почта и телефон не могут быть изменены здесь.';

  // ── Settings ─────────────────────────────────────────────────────────────────
  @override String get settingsTitle        => 'Настройки';
  @override String get appearance           => 'Внешний вид';
  @override String get theme                => 'Тема';
  @override String get language             => 'Язык';
  @override String get reservationReminders => 'Напоминания о бронировании';
  @override String get enableReminders      => 'Включить напоминания';
  @override String get remindMe             => 'Напомнить';
  @override String get minuteAbbr          => 'мин';
  @override String get hourAbbr            => 'ч';
  @override String get timePastError       => 'Нельзя выбрать прошедшее время. Пожалуйста, выберите будущее время.';

  // ── Reservations ─────────────────────────────────────────────────────────────
  @override String get reservationsTitle       => 'Бронирования';
  @override String get tabUpcoming             => 'Предстоящие';
  @override String get tabPast                 => 'Прошедшие';
  @override String get noReservations          => 'Бронирований нет';
  @override String get noReservationsSubtitle  => 'Просмотрите услуги и запишитесь на первый приём';
  @override String get statusPending           => 'В ожидании';
  @override String get statusConfirmed         => 'Подтверждено';
  @override String get statusRejected          => 'Отклонено';
  @override String get statusCancelled         => 'Отменено';
  @override String get statusChangeReq         => 'Изм. запрос';
  @override String get statusCompleted         => 'Завершено';
  @override String get statusNoShow            => 'Не явился';
  @override String get statusExpired           => 'Истекло';

  // ── Reservation Detail ───────────────────────────────────────────────────────
  @override String get reservationTitle        => 'Бронирование';
  @override String get cancelReservationTitle  => 'Отменить бронирование';
  @override String get cancelReservationContent => 'Вы уверены, что хотите отменить бронирование?';
  @override String get cancelReasonHint        => 'Причина (необязательно)';
  @override String get keepIt                  => 'Оставить';
  @override String get cancelBooking           => 'Отменить бронирование';
  @override String get dateTime                => 'Дата и время';
  @override String get endTime                 => 'Время окончания';
  @override String get price                   => 'Цена';
  @override String get providerLabel           => 'Поставщик';
  @override String get yourNote                => 'Ваша заметка';
  @override String get rejectionReason         => 'Причина отказа';
  @override String get cancellationReason      => 'Причина отмены';
  @override String get freeCancellation        => 'Бесплатная отмена доступна';
  @override String get checkinQr               => 'QR для регистрации';
  @override String get bookingId               => 'ID бронирования';
  @override String get bookedOn                => 'Дата записи';
  @override String get reservationCancelled    => 'Бронирование отменено';

  // ── Incoming Reservations ────────────────────────────────────────────────────
  @override String get incomingTitle           => 'Входящие';
  @override String get incomingSubtitle        => 'Управляйте записями';
  @override String get tabPending              => 'В ожидании';
  @override String get tabConfirmed            => 'Подтверждённые';
  @override String get noPendingRequests       => 'Нет ожидающих запросов';
  @override String get noConfirmedBookings     => 'Нет подтверждённых записей';
  @override String get reservationAccepted     => 'Бронирование принято ✓';
  @override String get rejectReservationTitle  => 'Отклонить бронирование';
  @override String get reservationRejected     => 'Бронирование отклонено';

  // ── My Services ──────────────────────────────────────────────────────────────
  @override String get myServicesTitle         => 'Мои услуги';
  @override String get myServicesSubtitle      => 'Управляйте услугами';
  @override String get noServicesYet           => 'Услуг пока нет';
  @override String get noServicesSubtitle      => 'Нажмите +, чтобы добавить первую услугу и начать принимать бронирования.';
  @override String get archiveServiceTitle     => 'Архивировать услугу';
  @override String get archiveServiceContent   => 'Услуга будет деактивирована и скрыта от клиентов. Вы можете восстановить её позже.';
  @override String get failedToArchive         => 'Ошибка архивации. Попробуйте снова.';

  // ── Create / Edit Service ────────────────────────────────────────────────────
  @override String get newService              => 'Новая услуга';
  @override String get editService             => 'Редактировать услугу';
  @override String get servicePhoto            => 'Фото услуги';
  @override String get basicInfo               => 'Основная информация';
  @override String get serviceName             => 'НАЗВАНИЕ УСЛУГИ';
  @override String get serviceNameHint         => 'напр. Стрижка, Лечение зубов';
  @override String get nameRequired            => 'Название обязательно';
  @override String get descriptionLabel        => 'ОПИСАНИЕ';
  @override String get descriptionHint         => 'Описание (необязательно)';
  @override String get brandLabel              => 'БРЕНД';
  @override String get categoryLabel           => 'КАТЕГОРИЯ';
  @override String get none                    => 'Нет';
  @override String get pricingSection          => 'Цены';
  @override String get priceLabel              => 'ЦЕНА';
  @override String get priceHint               => 'Оставьте пустым, если бесплатно';
  @override String get bookingSettings         => 'Настройки бронирования';
  @override String get serviceType             => 'ТИП УСЛУГИ';
  @override String get solo                    => 'Один';
  @override String get multi                   => 'Группа';
  @override String get approvalMode            => 'РЕЖИМ ПОДТВЕРЖДЕНИЯ';
  @override String get manual                  => 'Вручную';
  @override String get autoApproval            => 'Автоматически';
  @override String get weeklySchedule          => 'Еженедельное расписание';
  @override String get waitingTime             => 'ВРЕМЯ ОЖИДАНИЯ';
  @override String get minAdvance              => 'МИН. ПРЕДВАРИТЕЛЬНОЕ БРОНИРОВАНИЕ';
  @override String get maxAdvance              => 'МАКС. ПРЕДВАРИТЕЛЬНОЕ БРОНИРОВАНИЕ';
  @override String get freeCancellationDeadline => 'ДЕДЛАЙН БЕСПЛАТНОЙ ОТМЕНЫ';
  @override String get fieldRequired           => 'Обязательное поле';
  @override String get enterNumber             => 'Введите число';
  @override String get selectBrand             => 'Выбрать бренд';
  @override String get selectCategory          => 'Выбрать категорию';
  @override String get addServicePhoto         => 'Добавить фото услуги';
  @override String get tapToChoose             => 'Нажмите для выбора из галереи или камеры';
  @override String get changePhoto             => 'Изменить фото';
  @override String get cameraAccessDenied      => 'Доступ к камере запрещён. Разрешите в Настройках.';
  @override String get photoLibraryAccessDenied => 'Доступ к галерее запрещён. Разрешите в Настройках.';

  // ── Service Detail ───────────────────────────────────────────────────────────
  @override String get about                   => 'О услуге';
  @override String get brandDetailLabel        => 'Бренд';
  @override String get location                => 'Местоположение';
  @override String get booking                 => 'Бронирование';
  @override String get instantConfirmation     => 'Мгновенное подтверждение';
  @override String get requiresApproval        => 'Требует подтверждения';
  @override String get bookNow                 => 'Забронировать';
  @override String get requestBooking          => 'Запросить запись';
  @override String get reservationCreated      => 'Бронирование создано!';

  // ── Create Reservation Sheet ─────────────────────────────────────────────────
  @override String get sheetBookNow            => 'Забронировать';
  @override String get sheetRequestBooking     => 'Запросить запись';
  @override String get sheetDate               => 'Дата';
  @override String get sheetTime               => 'Время';
  @override String get sheetNoteHint           => 'Добавить заметку (необязательно)';
  @override String get sheetConfirmBooking     => 'Подтвердить';
  @override String get sheetSendRequest        => 'Отправить запрос';

  // ── Provider Profile ─────────────────────────────────────────────────────────
  @override String get providerProfile         => 'Профиль исполнителя';
  @override String get providerNotFound        => 'Исполнитель не найден.';

  // ── Navigation ───────────────────────────────────────────────────────────────
  @override String get navExplore              => 'Обзор';
  @override String get navReservations         => 'Записи';
  @override String get navNotifications        => 'Уведомления';
  @override String get navProfile              => 'Профиль';
  @override String get navIncoming             => 'Входящие';
  @override String get navMyServices           => 'Мои услуги';
  @override String get navMyBrands             => 'Мои бренды';
  @override String get notificationsComingSoon => 'Скоро…';

  // ── My Brands (USO) ──────────────────────────────────────────────────────────
  @override String get myBrands             => 'Мои бренды';
  @override String get noBrandsTitle        => 'Брендов пока нет';
  @override String get noBrandsSubtitle     => 'Создайте бренд для управления услугами под единым именем.';
  @override String get createBrand          => 'Создать бренд';
  @override String get brandName            => 'Название бренда';
  @override String get brandNameHint        => 'напр. Bella Studio';
  @override String get brandEmail           => 'Email бренда';
  @override String get brandEmailHint       => 'contact@brand.com (необязательно)';
  @override String get brandPhone           => 'Телефон бренда';
  @override String get brandPhoneHint       => '+994 50 000 00 00';
  @override String get brandCreated         => 'Бренд успешно создан';
  @override String get brandDeleted         => 'Бренд удалён';
  @override String get deleteBrand          => 'Удалить бренд';
  @override String get deleteBrandConfirm   => 'Вы уверены, что хотите удалить этот бренд?';
  @override String get verifyPhone          => 'Подтвердить телефон';
  @override String get verifyPhoneSubtitle  => 'Введите код, отправленный на телефон бренда.';
  @override String get otpSentTo            => 'Код отправлен на';
  @override String get verifyAndCreate      => 'Подтвердить и создать';
  @override String get editBrand            => 'Редактировать бренд';
  @override String get brandUpdated         => 'Бренд успешно обновлён';
  @override String get phoneNotEditable     => 'Номер телефона нельзя изменить после верификации.';
  @override String get brandDescription     => 'Описание';
  @override String get brandDescriptionHint => 'Расскажите клиентам о вашем бренде…';
  @override String get brandLocation        => 'Местоположение';
  @override String get brandLocationHint    => 'напр. Баку, Азербайджан';
  @override String get brandWebsite         => 'Сайт';
  @override String get brandWebsiteHint     => 'https://example.com';
  @override String get invalidUrl           => 'Введите корректный URL';
}
