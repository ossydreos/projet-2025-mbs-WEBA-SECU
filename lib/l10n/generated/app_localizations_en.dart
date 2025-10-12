// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'My Mobility Services';

  @override
  String get welcome => 'Welcome';

  @override
  String get login => 'Sign in';

  @override
  String get signup => 'Sign up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get home => 'Home';

  @override
  String get reservations => 'Reservations';

  @override
  String get trips => 'Trips';

  @override
  String get profile => 'Profile';

  @override
  String get offers => 'Offers';

  @override
  String get customOffer => 'Custom offer';

  @override
  String get createCustomOffer => 'Create custom offer';

  @override
  String get duration => 'Duration';

  @override
  String get durationHours => 'Hours';

  @override
  String get durationMinutes => 'Minutes';

  @override
  String get noteForDriver => 'Note for driver';

  @override
  String get noteForDriverHint => 'Describe your specific needs...';

  @override
  String get createOffer => 'Create offer';

  @override
  String get customOfferCreated => 'Custom offer created successfully';

  @override
  String get customOfferCreatedMessage =>
      'Your offer has been sent to drivers. You will receive a notification as soon as a driver accepts with a price.';

  @override
  String get proposedPrice => 'Proposed price';

  @override
  String get driverMessage => 'Driver message';

  @override
  String get acceptOffer => 'Accept offer';

  @override
  String get rejectOffer => 'Reject offer';

  @override
  String get offerAccepted => 'Offer accepted';

  @override
  String get offerRejected => 'Offer rejected';

  @override
  String get departure => 'Departure';

  @override
  String get destination => 'Destination';

  @override
  String get selectVehicle => 'Select vehicle';

  @override
  String get bookNow => 'Book now';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get loading => 'Loading...';

  @override
  String get retry => 'Retry';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get reservationStatusPending => 'Pending';

  @override
  String get reservationStatusConfirmed => 'Confirmed';

  @override
  String get reservationStatusInProgress => 'In progress';

  @override
  String get reservationStatusCompleted => 'Completed';

  @override
  String get reservationStatusCancelled => 'Cancelled';

  @override
  String get customOfferStatusPending => 'Pending';

  @override
  String get customOfferStatusAccepted => 'Accepted';

  @override
  String get customOfferStatusRejected => 'Rejected';

  @override
  String get customOfferStatusConfirmed => 'Confirmed';

  @override
  String get customOfferStatusInProgress => 'In progress';

  @override
  String get customOfferStatusCompleted => 'Completed';

  @override
  String get customOfferStatusCancelled => 'Cancelled';

  @override
  String get vehicleCategoryLuxe => 'Luxury';

  @override
  String get vehicleCategoryVan => 'Van';

  @override
  String get vehicleCategoryEconomique => 'Economy';

  @override
  String get userRoleUser => 'User';

  @override
  String get userRoleAdmin => 'Administrator';

  @override
  String get errorInvalidEmail => 'Invalid email';

  @override
  String get errorInvalidPhoneNumber => 'Invalid phone number';

  @override
  String get errorEmptyField => 'This field cannot be empty';

  @override
  String get errorPasswordTooShort => 'Password must be at least 6 characters';

  @override
  String get errorPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get errorNetworkError => 'Network connection error';

  @override
  String get errorUnknownError => 'An unknown error occurred';

  @override
  String get successReservationCreated => 'Reservation created successfully';

  @override
  String get successReservationUpdated => 'Reservation updated';

  @override
  String get successProfileUpdated => 'Profile updated';

  @override
  String get successPasswordChanged => 'Password changed';

  @override
  String get welcomeMessage => 'Welcome 👋';

  @override
  String get getStarted => 'Get started';

  @override
  String get orSignUpWith => 'or sign up with';

  @override
  String get orSignInWith => 'or sign in with';

  @override
  String get googleSoon => 'Google: coming soon';

  @override
  String get appleSoon => 'Apple: coming soon';

  @override
  String get facebookSoon => 'Facebook: coming soon';

  @override
  String get logIn => 'Sign in';

  @override
  String get personalInfo => 'Personal information';

  @override
  String get editInfo => 'Edit information';

  @override
  String get fullName => 'Full name';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get menu => 'Menu';

  @override
  String get myReservations => 'My reservations';

  @override
  String get history => 'History';

  @override
  String get payments => 'Payments';

  @override
  String get help => 'Help';

  @override
  String get location => 'Location';

  @override
  String get savedAddresses => 'Saved addresses';

  @override
  String get manageFavorites => 'Manage favorite places';

  @override
  String get notifications => 'Notifications';

  @override
  String get user => 'User';

  @override
  String get notProvided => 'Not provided';

  @override
  String get defaultCountryCode => '+1';

  @override
  String get admin => 'ADMIN';

  @override
  String get administrator => 'Administrator';

  @override
  String get loadingError => 'Loading error';

  @override
  String get noUpcomingRides => 'No upcoming rides';

  @override
  String get upcomingRidesWillAppear => 'Confirmed rides will appear here';

  @override
  String get noCompletedRides => 'No completed rides';

  @override
  String get rideHistoryWillAppear => 'Ride history will appear here';

  @override
  String get schedule => 'Schedule';

  @override
  String get finish => 'Finish';

  @override
  String get adminLogoutSuccess => 'Admin logout successful';

  @override
  String get disconnectButton => 'Disconnect';

  @override
  String get disconnection => 'Disconnection';

  @override
  String get guest => 'Guest';

  @override
  String get reviewPlannedTrip => 'Review your planned trip';

  @override
  String get dateAndTime => 'Date and time';

  @override
  String get modify => 'Modify';

  @override
  String get route => 'Route';

  @override
  String get pickupAddress => 'Pickup address';

  @override
  String get dropoffAddress => 'Drop-off address';

  @override
  String get estimatedArrival => 'Estimated arrival';

  @override
  String get pickupTime => 'Pickup time';

  @override
  String get estimatedDuration => 'Estimated duration';

  @override
  String get distance => 'Distance';

  @override
  String get vehicle => 'Vehicle';

  @override
  String get passengers => 'Passengers';

  @override
  String get luggage => 'Luggage';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get totalPrice => 'Total price';

  @override
  String get bookTrip => 'Book trip';

  @override
  String get applePay => 'Apple Pay';

  @override
  String get bankCard => 'Bank Card';

  @override
  String get cash => 'Cash';

  @override
  String get locationServicesDisabled => 'Location services are disabled';

  @override
  String get locationPermissionNotAvailable =>
      'Location permission not available';

  @override
  String get locationPermissionDenied => 'Location permission denied';

  @override
  String get locationPermissionDeniedPermanently =>
      'Location permission permanently denied';

  @override
  String get unableToGetCurrentPosition => 'Unable to get current position';

  @override
  String get reservationPending => 'Reservation pending';

  @override
  String get validateAndPayReservation => 'Validate and pay reservation';

  @override
  String get waitingDriverConfirmation => 'Waiting for driver confirmation';

  @override
  String get counterOffer => 'Counter offer';

  @override
  String get toPay => 'To pay';

  @override
  String get waitingConfirmation => 'Waiting for confirmation';

  @override
  String get adminPhoneNotAvailable => 'Admin phone not available';

  @override
  String get call => 'Call';

  @override
  String get message => 'Message';

  @override
  String get viewDetailsAndPay => 'View details and pay';

  @override
  String get cancelReservationButton => 'Cancel reservation';

  @override
  String get cancelReservationConfirmation =>
      'Are you sure you want to cancel this reservation?';

  @override
  String get yesCancel => 'Yes, cancel';

  @override
  String get client => 'client';

  @override
  String get reservationCancelledSuccess =>
      'Reservation cancelled successfully';

  @override
  String errorCancelling(String error) {
    return 'Error cancelling: $error';
  }

  @override
  String get paymentConfirmed => 'Payment confirmed';

  @override
  String get reservationDetails => 'Reservation details';

  @override
  String reservationNumber(String number) {
    return 'Reservation #$number';
  }

  @override
  String get note => 'Note';

  @override
  String get payment => 'Payment';

  @override
  String get paymentDescription =>
      'Payment will be made directly to the driver';

  @override
  String get cashPayment => 'Cash payment';

  @override
  String get confirmPayment => 'Confirm payment';

  @override
  String reservationCreatedSuccess(String id) {
    return 'Reservation created successfully! ID: $id';
  }

  @override
  String reservationCreationError(String error) {
    return 'Error creating reservation: $error';
  }

  @override
  String get account => 'Account';

  @override
  String get featureComingSoon => 'Feature coming soon';

  @override
  String get logoutConfirmation => 'Are you sure you want to log out?';

  @override
  String get logoutSuccess => 'Logout successful';

  @override
  String logoutError(String error) {
    return 'Logout error: $error';
  }

  @override
  String get inbox => 'Inbox';

  @override
  String get cancelAllReservations => 'Cancel all reservations';

  @override
  String get noReservationsWaitingPayment =>
      'No reservations waiting for payment';

  @override
  String reservationsCancelledSuccess(int count) {
    return 'Reservations cancelled successfully: $count';
  }

  @override
  String get testReservationCreated => 'Test reservation created';

  @override
  String get reservationAction => 'Reservation action';

  @override
  String get reservationRefused => 'Reservation refused';

  @override
  String get propose => 'Propose';

  @override
  String get courses => 'Courses';

  @override
  String get cancelRide => 'Cancel ride';

  @override
  String get cancelRideConfirmation =>
      'Are you sure you want to cancel this ride?';

  @override
  String get management => 'Management';

  @override
  String get fleetManagement => 'Fleet management';

  @override
  String get manageVehicles => 'Manage vehicles';

  @override
  String get manageVehiclesSubtitle => 'Add, edit or remove vehicles';

  @override
  String get promoCodes => 'Promo codes';

  @override
  String get createPromoCode => 'Create promo code';

  @override
  String get createPromoCodeSubtitle => 'Create discount codes';

  @override
  String get activeCodes => 'Active codes';

  @override
  String get activeCodesSubtitle => 'View and manage active codes';

  @override
  String get administration => 'Administration';

  @override
  String get userManagement => 'User management';

  @override
  String get userManagementSubtitle => 'Manage users and permissions';

  @override
  String get statistics => 'Statistics';

  @override
  String get statisticsSubtitle => 'View app statistics';

  @override
  String get vehicleManagement => 'Vehicle management';

  @override
  String get addVehicle => 'Add vehicle';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get address => 'Address';

  @override
  String get city => 'City';

  @override
  String get postalCode => 'Postal code';

  @override
  String get country => 'Country';

  @override
  String get accountSettings => 'Account settings';

  @override
  String get changePassword => 'Change password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get paymentInfo => 'Payment information';

  @override
  String get addPaymentMethod => 'Add payment method';

  @override
  String get defaultPaymentMethod => 'Default payment method';

  @override
  String get billingAddress => 'Billing address';

  @override
  String get preferences => 'Preferences';

  @override
  String get defaultPickupLocation => 'Default pickup location';

  @override
  String get defaultDestination => 'Default destination';

  @override
  String get preferredVehicleType => 'Preferred vehicle type';

  @override
  String get helpAndSupport => 'Help and support';

  @override
  String get reportIssue => 'Report an issue';

  @override
  String get sendFeedback => 'Send feedback';

  @override
  String get contactUs => 'Contact us';

  @override
  String get aboutApp => 'About the app';

  @override
  String get version => 'Version';

  @override
  String get buildNumber => 'Build number';

  @override
  String get developer => 'Developer';

  @override
  String get legal => 'Legal';

  @override
  String get licenses => 'Licenses';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get signInWithFacebook => 'Sign in with Facebook';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get createAccount => 'Create account';

  @override
  String get signInInstead => 'Sign in instead';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get continueAsGuest => 'Continue as guest';

  @override
  String get enableLocation => 'Enable location';

  @override
  String get allowLocationAccess => 'Allow location access';

  @override
  String get locationRequired =>
      'Location access is required for the app to work properly';

  @override
  String get enableInSettings => 'Enable in settings';

  @override
  String get bookingConfirmation => 'Booking confirmation';

  @override
  String get tripBooked => 'Trip booked successfully';

  @override
  String get bookingReference => 'Booking reference';

  @override
  String get driverAssigned => 'Driver assigned';

  @override
  String get cancelReservation => 'Cancel reservation';

  @override
  String get cancellationReason => 'Cancellation reason';

  @override
  String get refundPolicy => 'Refund policy';

  @override
  String get rateTrip => 'Rate trip';

  @override
  String get rateYourTrip => 'Rate your trip';

  @override
  String get howWasYourTrip => 'How was your trip?';

  @override
  String get additionalComments => 'Additional comments';

  @override
  String get submitReview => 'Submit review';

  @override
  String get submitRating => 'Submit rating';

  @override
  String get tripCompleted => 'Trip completed';

  @override
  String get thankYouForRiding => 'Thank you for riding with us!';

  @override
  String get receiptSent => 'Receipt sent to your email';

  @override
  String get emergencyMode => 'Emergency mode';

  @override
  String get emergencyContacts => 'Emergency contacts';

  @override
  String get callEmergency => 'Call emergency';

  @override
  String get shareLocation => 'Share location';

  @override
  String get emergencyContact => 'Emergency contact';

  @override
  String get shareTrip => 'Share trip';

  @override
  String get tripShared => 'Trip shared successfully';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get appUnderMaintenance => 'App is under maintenance';

  @override
  String get backSoon => 'We\'ll be back soon';

  @override
  String get networkError => 'Network error';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get checkConnection => 'Please check your connection';

  @override
  String get sessionExpired => 'Session expired';

  @override
  String get pleaseSignInAgain => 'Please sign in again';

  @override
  String get updateAvailable => 'Update available';

  @override
  String get newVersionAvailable => 'A new version of the app is available';

  @override
  String get updateNow => 'Update now';

  @override
  String get updateLater => 'Update later';

  @override
  String get permissionRequired => 'Permission required';

  @override
  String get cameraPermission => 'Camera permission';

  @override
  String get storagePermission => 'Storage permission';

  @override
  String get microphonePermission => 'Microphone permission';

  @override
  String get grantPermission => 'Grant permission';

  @override
  String get uploadPhoto => 'Upload photo';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get search => 'Search';

  @override
  String get searchResults => 'Search results';

  @override
  String get noResults => 'No results found';

  @override
  String get tryDifferentKeywords => 'Try different keywords';

  @override
  String get filter => 'Filter';

  @override
  String get sortBy => 'Sort by';

  @override
  String get filterResults => 'Filter results';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get map => 'Map';

  @override
  String get list => 'List';

  @override
  String get switchToMapView => 'Switch to map view';

  @override
  String get switchToListView => 'Switch to list view';

  @override
  String get nearby => 'Nearby';

  @override
  String get popular => 'Popular';

  @override
  String get recommended => 'Recommended';

  @override
  String get recent => 'Recent';

  @override
  String get share => 'Share';

  @override
  String get shareApp => 'Share app';

  @override
  String get inviteFriends => 'Invite friends';

  @override
  String get referralCode => 'Referral code';

  @override
  String get tutorial => 'Tutorial';

  @override
  String get howToUse => 'How to use';

  @override
  String get tips => 'Tips';

  @override
  String get gettingStarted => 'Getting started';

  @override
  String get feedback => 'Feedback';

  @override
  String get rating => 'Rating';

  @override
  String get review => 'Review';

  @override
  String get testimonials => 'Testimonials';

  @override
  String get promotion => 'Promotion';

  @override
  String get discount => 'Discount';

  @override
  String get coupon => 'Coupon';

  @override
  String get offer => 'Offer';

  @override
  String get specialOffer => 'Special offer';

  @override
  String get loyalty => 'Loyalty';

  @override
  String get points => 'Points';

  @override
  String get rewards => 'Rewards';

  @override
  String get membership => 'Membership';

  @override
  String get archive => 'Archive';

  @override
  String get clear => 'Clear';

  @override
  String get clearHistory => 'Clear history';

  @override
  String get sync => 'Sync';

  @override
  String get syncing => 'Syncing...';

  @override
  String get syncComplete => 'Sync complete';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get offline => 'Offline';

  @override
  String get online => 'Online';

  @override
  String get workingOffline => 'Working offline';

  @override
  String get connectionRestored => 'Connection restored';

  @override
  String get battery => 'Battery';

  @override
  String get batteryLow => 'Battery low';

  @override
  String get batterySaver => 'Battery saver';

  @override
  String get optimizeBattery => 'Optimize battery';

  @override
  String get security => 'Security';

  @override
  String get privacy => 'Privacy';

  @override
  String get dataProtection => 'Data protection';

  @override
  String get encryption => 'Encryption';

  @override
  String get backup => 'Backup';

  @override
  String get restore => 'Restore';

  @override
  String get backupComplete => 'Backup complete';

  @override
  String get restoreComplete => 'Restore complete';

  @override
  String get theme => 'Theme';

  @override
  String get lightMode => 'Light mode';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get systemTheme => 'System theme';

  @override
  String get customTheme => 'Custom theme';

  @override
  String get accessibility => 'Accessibility';

  @override
  String get fontSize => 'Font size';

  @override
  String get contrast => 'Contrast';

  @override
  String get voiceOver => 'Voice over';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get price => 'Price';

  @override
  String get status => 'Status';

  @override
  String get actions => 'Actions';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get view => 'View';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get ok => 'OK';

  @override
  String get done => 'Done';

  @override
  String get morning => 'Morning';

  @override
  String get afternoon => 'Afternoon';

  @override
  String get evening => 'Evening';

  @override
  String get night => 'Night';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get thisWeek => 'This week';

  @override
  String get thisMonth => 'This month';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get january => 'January';

  @override
  String get february => 'February';

  @override
  String get march => 'March';

  @override
  String get april => 'April';

  @override
  String get may => 'May';

  @override
  String get june => 'June';

  @override
  String get july => 'July';

  @override
  String get august => 'August';

  @override
  String get september => 'September';

  @override
  String get october => 'October';

  @override
  String get november => 'November';

  @override
  String get december => 'December';

  @override
  String get noReservations => 'No reservations';

  @override
  String get noReservationsMessage => 'You don\'t have any reservations yet';

  @override
  String get noTrips => 'No trips';

  @override
  String get noTripsMessage => 'You don\'t have any trips yet';

  @override
  String get pickupLocation => 'Pickup location';

  @override
  String get dropoffLocation => 'Drop-off location';

  @override
  String get selectDate => 'Select date';

  @override
  String get selectTime => 'Select time';

  @override
  String get estimatedPrice => 'Estimated price';

  @override
  String get vehicleDetails => 'Vehicle details';

  @override
  String get vehicleCapacity => 'Capacity';

  @override
  String get vehicleFeatures => 'Features';

  @override
  String get pricePerKm => 'Price per km';

  @override
  String get creditCard => 'Credit card';

  @override
  String get paypal => 'PayPal';

  @override
  String get driverInfo => 'Driver information';

  @override
  String get driverName => 'Driver name';

  @override
  String get driverPhone => 'Driver phone';

  @override
  String get vehicleInfo => 'Vehicle information';

  @override
  String get tripStatus => 'Trip status';

  @override
  String get tripDetails => 'Trip details';

  @override
  String get tripHistory => 'Trip history';

  @override
  String get notificationSettings => 'Notification settings';

  @override
  String get pushNotifications => 'Push notifications';

  @override
  String get emailNotifications => 'Email notifications';

  @override
  String get support => 'Support';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get faq => 'FAQ';

  @override
  String get termsOfService => 'Terms of service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get language => 'Language';

  @override
  String get locationServices => 'Location services';

  @override
  String get searchLocation => 'Search location';

  @override
  String get currentLocation => 'Current location';

  @override
  String get recentLocations => 'Recent locations';

  @override
  String get savedLocations => 'Saved locations';

  @override
  String get addComment => 'Add comment';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get users => 'Users';

  @override
  String get vehicles => 'Vehicles';

  @override
  String get reports => 'Reports';

  @override
  String get analytics => 'Analytics';

  @override
  String get addUser => 'Add user';

  @override
  String get editUser => 'Edit user';

  @override
  String get deleteUser => 'Delete user';

  @override
  String get editVehicle => 'Edit vehicle';

  @override
  String get deleteVehicle => 'Delete vehicle';

  @override
  String get reservationManagement => 'Reservation management';

  @override
  String get pendingReservations => 'Pending reservations';

  @override
  String get confirmedReservations => 'Confirmed reservations';

  @override
  String get completedReservations => 'Completed reservations';

  @override
  String get totalTrips => 'Total trips';

  @override
  String get totalRevenue => 'Total revenue';

  @override
  String get activeUsers => 'Active users';

  @override
  String get averageRating => 'Average rating';

  @override
  String get exportData => 'Export data';

  @override
  String get importData => 'Import data';

  @override
  String get backupData => 'Backup data';

  @override
  String get systemSettings => 'System settings';

  @override
  String get appSettings => 'App settings';

  @override
  String get serverSettings => 'Server settings';

  @override
  String get estimatedTime => 'Estimated time 15 min';

  @override
  String get availableVehicles => 'Available vehicles';

  @override
  String get loadingVehicles => 'Loading vehicles...';

  @override
  String get pleaseRetry => 'Please retry';

  @override
  String get noVehicleAvailable => 'No vehicle available';

  @override
  String get pleaseRetryLater => 'Please retry later';

  @override
  String get backToSummary => 'Back to summary';

  @override
  String planVehicle(String vehicle) {
    return 'Plan $vehicle';
  }

  @override
  String get selectedVehicleNoLongerAvailable =>
      'The selected vehicle is no longer available';

  @override
  String get selectedVehicleDeactivated =>
      'The selected vehicle has been deactivated by the administrator';

  @override
  String get logoutDescription => 'Disconnect from your account.';

  @override
  String get featureComingSoonDescription =>
      'This feature will be available soon.';

  @override
  String get adminLogoutDescription =>
      'Disconnect from your administrator account.';

  @override
  String get adminLogoutConfirmation =>
      'Do you really want to disconnect from your administrator account?';

  @override
  String get vehicleName => 'Vehicle name';

  @override
  String get vehicleNameExample => 'e.g. Economy Sedan';

  @override
  String get vehicleDescriptionHint => 'Vehicle description';

  @override
  String get category => 'Category';

  @override
  String get pricePerKmEuro => 'Price per kilometer (CHF)';

  @override
  String get priceExample => 'e.g. 1.50';

  @override
  String get create => 'Create';

  @override
  String get reservationConfirmedSuccess =>
      'Reservation confirmed successfully!';

  @override
  String sendError(String error) {
    return '❌ Sending error: $error';
  }

  @override
  String get welcomeSubtitle =>
      'Book your driver in seconds — modern, smooth and reliable.';

  @override
  String get securePayment => 'Secure Payment';

  @override
  String get orderSummary => 'Order Summary';

  @override
  String get bankCardSubtitle => 'Visa, Mastercard, American Express';

  @override
  String get applePaySubtitle => 'Fast and secure payment';

  @override
  String get googlePay => 'Google Pay';

  @override
  String get googlePaySubtitle => 'Fast and secure payment';

  @override
  String get cardDetails => 'Card Details';

  @override
  String get payNow => 'Pay now';

  @override
  String get processingPayment => 'Processing payment...';

  @override
  String get paymentSuccess => 'Payment Successful!';

  @override
  String get paymentSuccessMessage =>
      'Your reservation has been confirmed and paid successfully.';

  @override
  String get continueText => 'Continue';

  @override
  String get securePaymentInfo =>
      'Your data is protected by 256-bit SSL encryption';

  @override
  String get paymentFailed => 'Payment Failed';

  @override
  String get paymentFailedMessage =>
      'An error occurred while processing your payment.';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get cancelPayment => 'Cancel Payment';

  @override
  String get refundRequest => 'Refund Request';

  @override
  String get refundReason => 'Refund Reason';

  @override
  String get refundAmount => 'Refund Amount';

  @override
  String get requestRefund => 'Request Refund';

  @override
  String get refundSuccess => 'Refund Requested';

  @override
  String get refundSuccessMessage => 'Your refund request has been submitted.';

  @override
  String get paymentHistory => 'Payment History';

  @override
  String get waitingForDriverConfirmation => 'Waiting for driver confirmation';

  @override
  String get waitingForConfirmation => 'Waiting for confirmation';

  @override
  String get reservationProcessingMessage =>
      'Your reservation is being processed. You cannot make a new reservation until it is confirmed.';

  @override
  String get waitingForPayment => 'Waiting for payment';

  @override
  String get paymentRequiredMessage =>
      'Your reservation is confirmed! Please make the payment to finalize your trip.';

  @override
  String get transactionId => 'Transaction ID';

  @override
  String get paymentDate => 'Payment Date';

  @override
  String get paymentStatus => 'Payment Status';

  @override
  String get paid => 'Paid';

  @override
  String get pending => 'Pending';

  @override
  String get failed => 'Failed';

  @override
  String get refunded => 'Refunded';

  @override
  String get noPaymentHistory => 'No Payment History';

  @override
  String get noPaymentHistoryMessage => 'You haven\'t made any payments yet.';

  @override
  String get total => 'Total';

  @override
  String get favoriteTrips => 'Favorite Trips';

  @override
  String get addFavoriteTrip => 'Add Favorite Trip';

  @override
  String get editFavoriteTrip => 'Edit Favorite Trip';

  @override
  String get tripName => 'Trip Name';

  @override
  String get enterTripName => 'Enter trip name';

  @override
  String get departureAddress => 'Departure Address';

  @override
  String get enterDepartureAddress => 'Enter departure address';

  @override
  String get arrivalAddress => 'Arrival Address';

  @override
  String get enterArrivalAddress => 'Enter arrival address';

  @override
  String get selectIcon => 'Select Icon';

  @override
  String get addTrip => 'Add Trip';

  @override
  String get updateTrip => 'Update Trip';

  @override
  String get deleteTrip => 'Delete Trip';

  @override
  String get tripAdded => 'Trip added successfully';

  @override
  String get tripUpdated => 'Trip updated successfully';

  @override
  String get tripDeleted => 'Trip deleted successfully';

  @override
  String get tripDuplicated => 'Trip duplicated successfully';

  @override
  String get deleteTripConfirmation =>
      'Are you sure you want to delete this favorite trip?';

  @override
  String get tripAlreadyExists => 'This trip already exists in your favorites';

  @override
  String get searchFavoriteTrips => 'Search favorite trips';

  @override
  String get noFavoriteTrips => 'No favorite trips';

  @override
  String get noFavoriteTripsDescription =>
      'Add your frequent trips to find them quickly';

  @override
  String get addFirstFavoriteTrip => 'Add your first trip';

  @override
  String get tripNameRequired => 'Trip name is required';

  @override
  String get tripNameTooShort => 'Trip name must be at least 2 characters';

  @override
  String get departureAddressRequired => 'Departure address is required';

  @override
  String get departureAddressTooShort =>
      'Departure address must be at least 5 characters';

  @override
  String get arrivalAddressRequired => 'Arrival address is required';

  @override
  String get arrivalAddressTooShort =>
      'Arrival address must be at least 5 characters';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get use => 'Use';

  @override
  String get tapToOpen => 'Tap to open';

  @override
  String error(String error) {
    return 'Error: $error';
  }

  @override
  String get termsConditions => 'Terms & Conditions';

  @override
  String get legalMentions => 'Legal Mentions';

  @override
  String get lastUpdated => 'Last updated';

  @override
  String get dataCollection => 'Data Collection';

  @override
  String get dataCollectionDescription =>
      'We only collect data necessary for the operation of our mobility service: name, email, phone number, departure/arrival addresses, and geolocation data. This information is used exclusively to provide our transportation services.';

  @override
  String get dataUsage => 'Data Usage';

  @override
  String get dataUsageDescription =>
      'Your personal data is used to:\n• Facilitate booking and management of your trips\n• Communicate with you regarding your reservations\n• Improve the quality of our services\n• Comply with our legal obligations';

  @override
  String get dataSharing => 'Data Sharing';

  @override
  String get dataSharingDescription =>
      'We never sell your personal data. We may share your information only with:\n• Drivers assigned to your trips (name and phone number)\n• Our service providers (payment, hosting) under confidentiality agreements\n• Authorities if required by law';

  @override
  String get dataSecurity => 'Data Security';

  @override
  String get dataSecurityDescription =>
      'We use advanced security measures to protect your data:\n• SSL/TLS encryption for all communications\n• Secure storage on certified servers\n• Restricted access to personal data\n• Regular security audits';

  @override
  String get userRights => 'Your Rights';

  @override
  String get userRightsDescription =>
      'In accordance with GDPR, you have the right to:\n• Access your personal data\n• Rectify incorrect information\n• Delete your account and data\n• Limit the processing of your data\n• Data portability\n• Object to processing';

  @override
  String get contactInfo => 'Contact';

  @override
  String get contactInfoDescription =>
      'For any questions regarding your personal data:\n• Email: privacy@mymobilityservices.com\n• Phone: +41 22 123 45 67\n• Address: 123 Rue de la Mobilité, 1200 Geneva, Switzerland';

  @override
  String get serviceDescription => 'Service Description';

  @override
  String get serviceDescriptionText =>
      'My Mobility Services is a private transportation booking platform. We connect users with professional drivers for personalized trips.';

  @override
  String get userObligations => 'User Obligations';

  @override
  String get userObligationsText =>
      'By using our service, you agree to:\n• Provide accurate and up-to-date information\n• Respect drivers and equipment\n• Pay for services used within deadlines\n• Respect safety and civility rules\n• Not use the service for illegal purposes';

  @override
  String get companyObligations => 'Our Obligations';

  @override
  String get companyObligationsText =>
      'We commit to:\n• Provide quality and secure service\n• Respect your privacy and data\n• Maintain platform availability\n• Ensure driver training and verification\n• Provide responsive customer support';

  @override
  String get paymentTerms => 'Payment Terms';

  @override
  String get paymentTermsText =>
      '• Payment is made before the start of the trip\n• We accept bank cards, Apple Pay, Google Pay and cash payment\n• Prices are calculated based on distance and vehicle type\n• No hidden fees, all costs are transparent';

  @override
  String get cancellationPolicy => 'Cancellation Policy';

  @override
  String get cancellationPolicyText =>
      '• Free cancellation up to 30 minutes before the trip\n• Cancellation between 30 min and 5 min: 50% of the amount\n• Cancellation less than 5 min before: 100% of the amount\n• In case of driver cancellation: full refund';

  @override
  String get liabilityLimitation => 'Liability Limitation';

  @override
  String get liabilityLimitationText =>
      'Our liability is limited to the transaction amount. We are not responsible for delays due to traffic conditions, force majeure events, or actions of independent drivers.';

  @override
  String get disputeResolution => 'Dispute Resolution';

  @override
  String get disputeResolutionText =>
      'In case of dispute, we favor amicable resolution. If necessary, Swiss courts will have jurisdiction. We adhere to Swiss consumer mediation services.';

  @override
  String get companyInfo => 'Company Information';

  @override
  String get companyInfoText =>
      'My Mobility Services SA\nUID: CHE-123.456.789\nCommercial Register: Geneva\nShare capital: 50,000 CHF\nVAT: CHE-123.456.789 MWST';

  @override
  String get publisherInfo => 'Website Publisher';

  @override
  String get publisherInfoText =>
      'Publication director: Jean Dupont\nEmail: contact@mymobilityservices.com\nPhone: +41 22 123 45 67\nAddress: 123 Rue de la Mobilité, 1200 Geneva, Switzerland';

  @override
  String get hostingInfo => 'Hosting';

  @override
  String get hostingInfoText =>
      'The site is hosted by:\nGoogle Cloud Platform\n1600 Amphitheatre Parkway\nMountain View, CA 94043, USA\nISO 27001 certified';

  @override
  String get intellectualProperty => 'Intellectual Property';

  @override
  String get intellectualPropertyText =>
      'All elements of this site (texts, images, logos, design) are protected by copyright. Any reproduction without authorization is prohibited. The application and its database are intellectual works protected by the Intellectual Property Code.';

  @override
  String get applicableLaw => 'Applicable Law';

  @override
  String get applicableLawText =>
      'These terms are subject to Swiss law. In case of dispute, Swiss courts will have sole jurisdiction. The reference language is French.';

  @override
  String get filters => 'Filters';

  @override
  String get period => 'Period';

  @override
  String get reservationType => 'Reservation type';

  @override
  String get selectAtLeastOneReservation =>
      'Please select at least one reservation';

  @override
  String generatingPdf(int count) {
    return 'Generating PDF... ($count reservations)';
  }

  @override
  String get noDataFound => 'No data found for selected reservations';

  @override
  String get pdfExportedSuccessfully => 'PDF exported successfully!';

  @override
  String exportError(String error) {
    return 'Export error: $error';
  }

  @override
  String get createTestReservation => '🧪 Create test reservation';

  @override
  String testError(String error) {
    return '❌ Test error: $error';
  }

  @override
  String cancellationError(String error) {
    return 'Cancellation error: $error';
  }

  @override
  String get offerCancelledSuccess => 'Offer cancelled successfully';

  @override
  String get manage => 'Manage';

  @override
  String get offerRefused => 'Offer refused';

  @override
  String get refuse => 'Refuse';

  @override
  String get contactClient => 'Contact client';

  @override
  String get paymentRequestSent => 'Payment request sent to client';

  @override
  String get sendCounterOffer => 'Send counter offer';

  @override
  String get profileUpdatedSuccess => 'Information updated successfully!';

  @override
  String get userProfile => 'User profile';

  @override
  String get searchByNameOrEmail => 'Search by name or email';

  @override
  String get userNotFound => 'User not found';

  @override
  String get noReservationsOrOffers => 'No reservations or offers';

  @override
  String get messages => 'Messages';

  @override
  String get noMessages => 'No messages';

  @override
  String get newMessage => 'New message';

  @override
  String get promoCodeExample => 'Ex: Promo Code 20';

  @override
  String get promoCodeIdExample => 'Ex: Promo20';

  @override
  String get chooseDate => 'Choose a date';

  @override
  String get usageLimitExample => 'Ex: 100';

  @override
  String get codeCreated => 'Code created';

  @override
  String get promoCodeCreated => 'Promo code created';

  @override
  String get chat => 'Chat';

  @override
  String get writeMessage => 'Write a message...';

  @override
  String get ticketFinished => 'This ticket is finished. Open a new message.';

  @override
  String get conversationFinished => 'This conversation is finished.';

  @override
  String callError(String error) {
    return 'Call error: $error';
  }

  @override
  String get fullNameExample => 'Ex: John Doe';

  @override
  String get emailAddress => 'Email address';

  @override
  String get emailExample => 'Ex: john.doe@email.com';

  @override
  String get phoneExample => 'Ex: 612345678';

  @override
  String get searchCountry => 'Search for a country...';

  @override
  String get passwordExample => 'Ex: MyPassword123!';

  @override
  String get enterEmail => 'Enter email';

  @override
  String get enterPassword => 'Enter password';

  @override
  String get priceInChf => 'Price in CHF';

  @override
  String get optionalMessageForClient => 'Optional message for client...';

  @override
  String get phone => 'Phone';

  @override
  String get explainRefundReason => 'Explain the reason for refund...';

  @override
  String get description => 'Description';

  @override
  String get maxPassengers => 'Max passengers';

  @override
  String get four => '4';

  @override
  String get maxLuggage => 'Max luggage';

  @override
  String get two => '2';

  @override
  String get imageUrl => 'Image URL';

  @override
  String get imageUrlExample => 'https://example.com/image.jpg';

  @override
  String get enterPromoCode => 'Enter your promo code';

  @override
  String get promoCodeApplied => 'Promo code applied';

  @override
  String get apply => 'Apply';

  @override
  String get uberNotificationDemo => 'Uber Notification Demo';

  @override
  String get launchDemo => 'Launch demo';

  @override
  String get uberNotificationTest => 'Uber Notification Test';

  @override
  String get explainChange => 'Explain the change...';

  @override
  String get explainScheduleChange =>
      'Explain the reason for schedule change...';

  @override
  String get sort => 'Sort';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get completed => 'Completed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get unknown => 'Unknown';

  @override
  String get deselectTrip => 'Deselect this trip';

  @override
  String get selectTrip => 'Select this trip';

  @override
  String get arrival => 'Arrival';

  @override
  String tripDescription(
    String fromAddress,
    String toAddress,
    String status,
    String startAt,
    String arrivalInfo,
    String priceFormatted,
  ) {
    return 'Trip from $fromAddress to $toAddress, status $status, departure $startAt$arrivalInfo, price $priceFormatted';
  }

  @override
  String get inProgress => 'In progress';

  @override
  String get start => 'Start';

  @override
  String get end => 'End';

  @override
  String get selectedPeriod => 'Selected period';

  @override
  String get label => 'Label';
}
