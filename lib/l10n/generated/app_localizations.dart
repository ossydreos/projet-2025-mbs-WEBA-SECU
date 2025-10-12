import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'My Mobility Services'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signup;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @reservations.
  ///
  /// In en, this message translates to:
  /// **'Reservations'**
  String get reservations;

  /// No description provided for @trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get trips;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @offers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get offers;

  /// No description provided for @customOffer.
  ///
  /// In en, this message translates to:
  /// **'Custom offer'**
  String get customOffer;

  /// No description provided for @createCustomOffer.
  ///
  /// In en, this message translates to:
  /// **'Create custom offer'**
  String get createCustomOffer;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get durationHours;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get durationMinutes;

  /// No description provided for @noteForDriver.
  ///
  /// In en, this message translates to:
  /// **'Note for driver'**
  String get noteForDriver;

  /// No description provided for @noteForDriverHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your specific needs...'**
  String get noteForDriverHint;

  /// No description provided for @createOffer.
  ///
  /// In en, this message translates to:
  /// **'Create offer'**
  String get createOffer;

  /// No description provided for @customOfferCreated.
  ///
  /// In en, this message translates to:
  /// **'Custom offer created successfully'**
  String get customOfferCreated;

  /// No description provided for @customOfferCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your offer has been sent to drivers. You will receive a notification as soon as a driver accepts with a price.'**
  String get customOfferCreatedMessage;

  /// No description provided for @proposedPrice.
  ///
  /// In en, this message translates to:
  /// **'Proposed price'**
  String get proposedPrice;

  /// No description provided for @driverMessage.
  ///
  /// In en, this message translates to:
  /// **'Driver message'**
  String get driverMessage;

  /// No description provided for @acceptOffer.
  ///
  /// In en, this message translates to:
  /// **'Accept offer'**
  String get acceptOffer;

  /// No description provided for @rejectOffer.
  ///
  /// In en, this message translates to:
  /// **'Reject offer'**
  String get rejectOffer;

  /// No description provided for @offerAccepted.
  ///
  /// In en, this message translates to:
  /// **'Offer accepted'**
  String get offerAccepted;

  /// No description provided for @offerRejected.
  ///
  /// In en, this message translates to:
  /// **'Offer rejected'**
  String get offerRejected;

  /// No description provided for @departure.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get departure;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @selectVehicle.
  ///
  /// In en, this message translates to:
  /// **'Select vehicle'**
  String get selectVehicle;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book now'**
  String get bookNow;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @reservationStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get reservationStatusPending;

  /// No description provided for @reservationStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get reservationStatusConfirmed;

  /// No description provided for @reservationStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get reservationStatusInProgress;

  /// No description provided for @reservationStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get reservationStatusCompleted;

  /// No description provided for @reservationStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get reservationStatusCancelled;

  /// No description provided for @customOfferStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get customOfferStatusPending;

  /// No description provided for @customOfferStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get customOfferStatusAccepted;

  /// No description provided for @customOfferStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get customOfferStatusRejected;

  /// No description provided for @customOfferStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get customOfferStatusConfirmed;

  /// No description provided for @customOfferStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get customOfferStatusInProgress;

  /// No description provided for @customOfferStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get customOfferStatusCompleted;

  /// No description provided for @customOfferStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get customOfferStatusCancelled;

  /// No description provided for @vehicleCategoryLuxe.
  ///
  /// In en, this message translates to:
  /// **'Luxury'**
  String get vehicleCategoryLuxe;

  /// No description provided for @vehicleCategoryVan.
  ///
  /// In en, this message translates to:
  /// **'Van'**
  String get vehicleCategoryVan;

  /// No description provided for @vehicleCategoryEconomique.
  ///
  /// In en, this message translates to:
  /// **'Economy'**
  String get vehicleCategoryEconomique;

  /// No description provided for @userRoleUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userRoleUser;

  /// No description provided for @userRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get userRoleAdmin;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get errorInvalidEmail;

  /// No description provided for @errorInvalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get errorInvalidPhoneNumber;

  /// No description provided for @errorEmptyField.
  ///
  /// In en, this message translates to:
  /// **'This field cannot be empty'**
  String get errorEmptyField;

  /// No description provided for @errorPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get errorPasswordTooShort;

  /// No description provided for @errorPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get errorPasswordsDoNotMatch;

  /// No description provided for @errorNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network connection error'**
  String get errorNetworkError;

  /// No description provided for @errorUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get errorUnknownError;

  /// No description provided for @successReservationCreated.
  ///
  /// In en, this message translates to:
  /// **'Reservation created successfully'**
  String get successReservationCreated;

  /// No description provided for @successReservationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Reservation updated'**
  String get successReservationUpdated;

  /// No description provided for @successProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get successProfileUpdated;

  /// No description provided for @successPasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get successPasswordChanged;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome 👋'**
  String get welcomeMessage;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @orSignUpWith.
  ///
  /// In en, this message translates to:
  /// **'or sign up with'**
  String get orSignUpWith;

  /// No description provided for @orSignInWith.
  ///
  /// In en, this message translates to:
  /// **'or sign in with'**
  String get orSignInWith;

  /// No description provided for @googleSoon.
  ///
  /// In en, this message translates to:
  /// **'Google: coming soon'**
  String get googleSoon;

  /// No description provided for @appleSoon.
  ///
  /// In en, this message translates to:
  /// **'Apple: coming soon'**
  String get appleSoon;

  /// No description provided for @facebookSoon.
  ///
  /// In en, this message translates to:
  /// **'Facebook: coming soon'**
  String get facebookSoon;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get logIn;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get personalInfo;

  /// No description provided for @editInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit information'**
  String get editInfo;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @myReservations.
  ///
  /// In en, this message translates to:
  /// **'My reservations'**
  String get myReservations;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @savedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Saved addresses'**
  String get savedAddresses;

  /// No description provided for @manageFavorites.
  ///
  /// In en, this message translates to:
  /// **'Manage favorite places'**
  String get manageFavorites;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @defaultCountryCode.
  ///
  /// In en, this message translates to:
  /// **'+1'**
  String get defaultCountryCode;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'ADMIN'**
  String get admin;

  /// No description provided for @administrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get administrator;

  /// No description provided for @loadingError.
  ///
  /// In en, this message translates to:
  /// **'Loading error'**
  String get loadingError;

  /// No description provided for @noUpcomingRides.
  ///
  /// In en, this message translates to:
  /// **'No upcoming rides'**
  String get noUpcomingRides;

  /// No description provided for @upcomingRidesWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Confirmed rides will appear here'**
  String get upcomingRidesWillAppear;

  /// No description provided for @noCompletedRides.
  ///
  /// In en, this message translates to:
  /// **'No completed rides'**
  String get noCompletedRides;

  /// No description provided for @rideHistoryWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Ride history will appear here'**
  String get rideHistoryWillAppear;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @adminLogoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Admin logout successful'**
  String get adminLogoutSuccess;

  /// No description provided for @disconnectButton.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnectButton;

  /// No description provided for @disconnection.
  ///
  /// In en, this message translates to:
  /// **'Disconnection'**
  String get disconnection;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @reviewPlannedTrip.
  ///
  /// In en, this message translates to:
  /// **'Review your planned trip'**
  String get reviewPlannedTrip;

  /// No description provided for @dateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get dateAndTime;

  /// No description provided for @modify.
  ///
  /// In en, this message translates to:
  /// **'Modify'**
  String get modify;

  /// No description provided for @route.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get route;

  /// No description provided for @pickupAddress.
  ///
  /// In en, this message translates to:
  /// **'Pickup address'**
  String get pickupAddress;

  /// No description provided for @dropoffAddress.
  ///
  /// In en, this message translates to:
  /// **'Drop-off address'**
  String get dropoffAddress;

  /// No description provided for @estimatedArrival.
  ///
  /// In en, this message translates to:
  /// **'Estimated arrival'**
  String get estimatedArrival;

  /// No description provided for @pickupTime.
  ///
  /// In en, this message translates to:
  /// **'Pickup time'**
  String get pickupTime;

  /// No description provided for @estimatedDuration.
  ///
  /// In en, this message translates to:
  /// **'Estimated duration'**
  String get estimatedDuration;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicle;

  /// No description provided for @passengers.
  ///
  /// In en, this message translates to:
  /// **'Passengers'**
  String get passengers;

  /// No description provided for @luggage.
  ///
  /// In en, this message translates to:
  /// **'Luggage'**
  String get luggage;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total price'**
  String get totalPrice;

  /// No description provided for @bookTrip.
  ///
  /// In en, this message translates to:
  /// **'Book trip'**
  String get bookTrip;

  /// No description provided for @applePay.
  ///
  /// In en, this message translates to:
  /// **'Apple Pay'**
  String get applePay;

  /// No description provided for @bankCard.
  ///
  /// In en, this message translates to:
  /// **'Bank card'**
  String get bankCard;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled'**
  String get locationServicesDisabled;

  /// No description provided for @locationPermissionNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Location permission not available'**
  String get locationPermissionNotAvailable;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionDeniedPermanently.
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied'**
  String get locationPermissionDeniedPermanently;

  /// No description provided for @unableToGetCurrentPosition.
  ///
  /// In en, this message translates to:
  /// **'Unable to get current position'**
  String get unableToGetCurrentPosition;

  /// No description provided for @reservationPending.
  ///
  /// In en, this message translates to:
  /// **'Reservation pending'**
  String get reservationPending;

  /// No description provided for @validateAndPayReservation.
  ///
  /// In en, this message translates to:
  /// **'Validate and pay reservation'**
  String get validateAndPayReservation;

  /// No description provided for @waitingDriverConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for driver confirmation'**
  String get waitingDriverConfirmation;

  /// No description provided for @counterOffer.
  ///
  /// In en, this message translates to:
  /// **'Counter offer'**
  String get counterOffer;

  /// No description provided for @toPay.
  ///
  /// In en, this message translates to:
  /// **'To pay'**
  String get toPay;

  /// No description provided for @waitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for confirmation'**
  String get waitingConfirmation;

  /// No description provided for @adminPhoneNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Admin phone not available'**
  String get adminPhoneNotAvailable;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @viewDetailsAndPay.
  ///
  /// In en, this message translates to:
  /// **'View details and pay'**
  String get viewDetailsAndPay;

  /// No description provided for @cancelReservationButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel reservation'**
  String get cancelReservationButton;

  /// No description provided for @cancelReservationConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this reservation?'**
  String get cancelReservationConfirmation;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel'**
  String get yesCancel;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @reservationCancelledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reservation cancelled successfully'**
  String get reservationCancelledSuccess;

  /// No description provided for @errorCancelling.
  ///
  /// In en, this message translates to:
  /// **'Error cancelling: {error}'**
  String errorCancelling(String error);

  /// No description provided for @paymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed'**
  String get paymentConfirmed;

  /// No description provided for @reservationDetails.
  ///
  /// In en, this message translates to:
  /// **'Reservation details'**
  String get reservationDetails;

  /// No description provided for @reservationNumber.
  ///
  /// In en, this message translates to:
  /// **'Reservation #{number}'**
  String reservationNumber(String number);

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @paymentDescription.
  ///
  /// In en, this message translates to:
  /// **'Payment will be made directly to the driver'**
  String get paymentDescription;

  /// No description provided for @cashPayment.
  ///
  /// In en, this message translates to:
  /// **'Cash payment'**
  String get cashPayment;

  /// No description provided for @confirmPayment.
  ///
  /// In en, this message translates to:
  /// **'Confirm payment'**
  String get confirmPayment;

  /// No description provided for @reservationCreationError.
  ///
  /// In en, this message translates to:
  /// **'Error creating reservation: {error}'**
  String reservationCreationError(String error);

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Feature coming soon'**
  String get featureComingSoon;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmation;

  /// No description provided for @logoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Logout successful'**
  String get logoutSuccess;

  /// No description provided for @logoutError.
  ///
  /// In en, this message translates to:
  /// **'Logout error: {error}'**
  String logoutError(String error);

  /// No description provided for @inbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inbox;

  /// No description provided for @cancelAllReservations.
  ///
  /// In en, this message translates to:
  /// **'Cancel all reservations'**
  String get cancelAllReservations;

  /// No description provided for @noReservationsWaitingPayment.
  ///
  /// In en, this message translates to:
  /// **'No reservations waiting for payment'**
  String get noReservationsWaitingPayment;

  /// No description provided for @reservationsCancelledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reservations cancelled successfully: {count}'**
  String reservationsCancelledSuccess(int count);

  /// No description provided for @testReservationCreated.
  ///
  /// In en, this message translates to:
  /// **'Test reservation created'**
  String get testReservationCreated;

  /// No description provided for @reservationAction.
  ///
  /// In en, this message translates to:
  /// **'Reservation action'**
  String get reservationAction;

  /// No description provided for @reservationRefused.
  ///
  /// In en, this message translates to:
  /// **'Reservation refused'**
  String get reservationRefused;

  /// No description provided for @propose.
  ///
  /// In en, this message translates to:
  /// **'Propose'**
  String get propose;

  /// No description provided for @courses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get courses;

  /// No description provided for @cancelRide.
  ///
  /// In en, this message translates to:
  /// **'Cancel ride'**
  String get cancelRide;

  /// No description provided for @cancelRideConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this ride?'**
  String get cancelRideConfirmation;

  /// No description provided for @management.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get management;

  /// No description provided for @fleetManagement.
  ///
  /// In en, this message translates to:
  /// **'Fleet management'**
  String get fleetManagement;

  /// No description provided for @manageVehicles.
  ///
  /// In en, this message translates to:
  /// **'Manage vehicles'**
  String get manageVehicles;

  /// No description provided for @manageVehiclesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add, edit or remove vehicles'**
  String get manageVehiclesSubtitle;

  /// No description provided for @promoCodes.
  ///
  /// In en, this message translates to:
  /// **'Promo codes'**
  String get promoCodes;

  /// No description provided for @createPromoCode.
  ///
  /// In en, this message translates to:
  /// **'Create promo code'**
  String get createPromoCode;

  /// No description provided for @createPromoCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create discount codes'**
  String get createPromoCodeSubtitle;

  /// No description provided for @activeCodes.
  ///
  /// In en, this message translates to:
  /// **'Active codes'**
  String get activeCodes;

  /// No description provided for @activeCodesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and manage active codes'**
  String get activeCodesSubtitle;

  /// No description provided for @administration.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get administration;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User management'**
  String get userManagement;

  /// No description provided for @userManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage users and permissions'**
  String get userManagementSubtitle;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @statisticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View app statistics'**
  String get statisticsSubtitle;

  /// No description provided for @vehicleManagement.
  ///
  /// In en, this message translates to:
  /// **'Vehicle management'**
  String get vehicleManagement;

  /// No description provided for @addVehicle.
  ///
  /// In en, this message translates to:
  /// **'Add vehicle'**
  String get addVehicle;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @postalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal code'**
  String get postalCode;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account settings'**
  String get accountSettings;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @paymentInfo.
  ///
  /// In en, this message translates to:
  /// **'Payment information'**
  String get paymentInfo;

  /// No description provided for @addPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Add payment method'**
  String get addPaymentMethod;

  /// No description provided for @defaultPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Default payment method'**
  String get defaultPaymentMethod;

  /// No description provided for @billingAddress.
  ///
  /// In en, this message translates to:
  /// **'Billing address'**
  String get billingAddress;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @defaultPickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Default pickup location'**
  String get defaultPickupLocation;

  /// No description provided for @defaultDestination.
  ///
  /// In en, this message translates to:
  /// **'Default destination'**
  String get defaultDestination;

  /// No description provided for @preferredVehicleType.
  ///
  /// In en, this message translates to:
  /// **'Preferred vehicle type'**
  String get preferredVehicleType;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help and support'**
  String get helpAndSupport;

  /// No description provided for @reportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get reportIssue;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get sendFeedback;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUs;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About the app'**
  String get aboutApp;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @buildNumber.
  ///
  /// In en, this message translates to:
  /// **'Build number'**
  String get buildNumber;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @signInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithApple;

  /// No description provided for @signInWithFacebook.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Facebook'**
  String get signInWithFacebook;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @signInInstead.
  ///
  /// In en, this message translates to:
  /// **'Sign in instead'**
  String get signInInstead;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get continueAsGuest;

  /// No description provided for @enableLocation.
  ///
  /// In en, this message translates to:
  /// **'Enable location'**
  String get enableLocation;

  /// No description provided for @allowLocationAccess.
  ///
  /// In en, this message translates to:
  /// **'Allow location access'**
  String get allowLocationAccess;

  /// No description provided for @locationRequired.
  ///
  /// In en, this message translates to:
  /// **'Location access is required for the app to work properly'**
  String get locationRequired;

  /// No description provided for @enableInSettings.
  ///
  /// In en, this message translates to:
  /// **'Enable in settings'**
  String get enableInSettings;

  /// No description provided for @bookingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmation'**
  String get bookingConfirmation;

  /// No description provided for @tripBooked.
  ///
  /// In en, this message translates to:
  /// **'Trip booked successfully'**
  String get tripBooked;

  /// No description provided for @bookingReference.
  ///
  /// In en, this message translates to:
  /// **'Booking reference'**
  String get bookingReference;

  /// No description provided for @driverAssigned.
  ///
  /// In en, this message translates to:
  /// **'Driver assigned'**
  String get driverAssigned;

  /// No description provided for @cancelReservation.
  ///
  /// In en, this message translates to:
  /// **'Cancel reservation'**
  String get cancelReservation;

  /// No description provided for @cancellationReason.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason'**
  String get cancellationReason;

  /// No description provided for @refundPolicy.
  ///
  /// In en, this message translates to:
  /// **'Refund policy'**
  String get refundPolicy;

  /// No description provided for @rateTrip.
  ///
  /// In en, this message translates to:
  /// **'Rate trip'**
  String get rateTrip;

  /// No description provided for @rateYourTrip.
  ///
  /// In en, this message translates to:
  /// **'Rate your trip'**
  String get rateYourTrip;

  /// No description provided for @howWasYourTrip.
  ///
  /// In en, this message translates to:
  /// **'How was your trip?'**
  String get howWasYourTrip;

  /// No description provided for @additionalComments.
  ///
  /// In en, this message translates to:
  /// **'Additional comments'**
  String get additionalComments;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit review'**
  String get submitReview;

  /// No description provided for @submitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit rating'**
  String get submitRating;

  /// No description provided for @tripCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trip completed'**
  String get tripCompleted;

  /// No description provided for @thankYouForRiding.
  ///
  /// In en, this message translates to:
  /// **'Thank you for riding with us!'**
  String get thankYouForRiding;

  /// No description provided for @receiptSent.
  ///
  /// In en, this message translates to:
  /// **'Receipt sent to your email'**
  String get receiptSent;

  /// No description provided for @emergencyMode.
  ///
  /// In en, this message translates to:
  /// **'Emergency mode'**
  String get emergencyMode;

  /// No description provided for @emergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency contacts'**
  String get emergencyContacts;

  /// No description provided for @callEmergency.
  ///
  /// In en, this message translates to:
  /// **'Call emergency'**
  String get callEmergency;

  /// No description provided for @shareLocation.
  ///
  /// In en, this message translates to:
  /// **'Share location'**
  String get shareLocation;

  /// No description provided for @emergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get emergencyContact;

  /// No description provided for @shareTrip.
  ///
  /// In en, this message translates to:
  /// **'Share trip'**
  String get shareTrip;

  /// No description provided for @tripShared.
  ///
  /// In en, this message translates to:
  /// **'Trip shared successfully'**
  String get tripShared;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @appUnderMaintenance.
  ///
  /// In en, this message translates to:
  /// **'App is under maintenance'**
  String get appUnderMaintenance;

  /// No description provided for @backSoon.
  ///
  /// In en, this message translates to:
  /// **'We\'ll be back soon'**
  String get backSoon;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get networkError;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @checkConnection.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection'**
  String get checkConnection;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get sessionExpired;

  /// No description provided for @pleaseSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again'**
  String get pleaseSignInAgain;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailable;

  /// No description provided for @newVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'A new version of the app is available'**
  String get newVersionAvailable;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Update later'**
  String get updateLater;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission required'**
  String get permissionRequired;

  /// No description provided for @cameraPermission.
  ///
  /// In en, this message translates to:
  /// **'Camera permission'**
  String get cameraPermission;

  /// No description provided for @storagePermission.
  ///
  /// In en, this message translates to:
  /// **'Storage permission'**
  String get storagePermission;

  /// No description provided for @microphonePermission.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission'**
  String get microphonePermission;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant permission'**
  String get grantPermission;

  /// No description provided for @uploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload photo'**
  String get uploadPhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get searchResults;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @tryDifferentKeywords.
  ///
  /// In en, this message translates to:
  /// **'Try different keywords'**
  String get tryDifferentKeywords;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @filterResults.
  ///
  /// In en, this message translates to:
  /// **'Filter results'**
  String get filterResults;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @list.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list;

  /// No description provided for @switchToMapView.
  ///
  /// In en, this message translates to:
  /// **'Switch to map view'**
  String get switchToMapView;

  /// No description provided for @switchToListView.
  ///
  /// In en, this message translates to:
  /// **'Switch to list view'**
  String get switchToListView;

  /// No description provided for @nearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearby;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share app'**
  String get shareApp;

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite friends'**
  String get inviteFriends;

  /// No description provided for @referralCode.
  ///
  /// In en, this message translates to:
  /// **'Referral code'**
  String get referralCode;

  /// No description provided for @tutorial.
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get tutorial;

  /// No description provided for @howToUse.
  ///
  /// In en, this message translates to:
  /// **'How to use'**
  String get howToUse;

  /// No description provided for @tips.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get tips;

  /// No description provided for @gettingStarted.
  ///
  /// In en, this message translates to:
  /// **'Getting started'**
  String get gettingStarted;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @testimonials.
  ///
  /// In en, this message translates to:
  /// **'Testimonials'**
  String get testimonials;

  /// No description provided for @promotion.
  ///
  /// In en, this message translates to:
  /// **'Promotion'**
  String get promotion;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @coupon.
  ///
  /// In en, this message translates to:
  /// **'Coupon'**
  String get coupon;

  /// No description provided for @offer.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get offer;

  /// No description provided for @specialOffer.
  ///
  /// In en, this message translates to:
  /// **'Special offer'**
  String get specialOffer;

  /// No description provided for @loyalty.
  ///
  /// In en, this message translates to:
  /// **'Loyalty'**
  String get loyalty;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewards;

  /// No description provided for @membership.
  ///
  /// In en, this message translates to:
  /// **'Membership'**
  String get membership;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get clearHistory;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @syncComplete.
  ///
  /// In en, this message translates to:
  /// **'Sync complete'**
  String get syncComplete;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncFailed;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @workingOffline.
  ///
  /// In en, this message translates to:
  /// **'Working offline'**
  String get workingOffline;

  /// No description provided for @connectionRestored.
  ///
  /// In en, this message translates to:
  /// **'Connection restored'**
  String get connectionRestored;

  /// No description provided for @battery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get battery;

  /// No description provided for @batteryLow.
  ///
  /// In en, this message translates to:
  /// **'Battery low'**
  String get batteryLow;

  /// No description provided for @batterySaver.
  ///
  /// In en, this message translates to:
  /// **'Battery saver'**
  String get batterySaver;

  /// No description provided for @optimizeBattery.
  ///
  /// In en, this message translates to:
  /// **'Optimize battery'**
  String get optimizeBattery;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @dataProtection.
  ///
  /// In en, this message translates to:
  /// **'Data protection'**
  String get dataProtection;

  /// No description provided for @encryption.
  ///
  /// In en, this message translates to:
  /// **'Encryption'**
  String get encryption;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @backupComplete.
  ///
  /// In en, this message translates to:
  /// **'Backup complete'**
  String get backupComplete;

  /// No description provided for @restoreComplete.
  ///
  /// In en, this message translates to:
  /// **'Restore complete'**
  String get restoreComplete;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System theme'**
  String get systemTheme;

  /// No description provided for @customTheme.
  ///
  /// In en, this message translates to:
  /// **'Custom theme'**
  String get customTheme;

  /// No description provided for @accessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibility;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontSize;

  /// No description provided for @contrast.
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get contrast;

  /// No description provided for @voiceOver.
  ///
  /// In en, this message translates to:
  /// **'Voice over'**
  String get voiceOver;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get afternoon;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @night.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get night;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @noReservations.
  ///
  /// In en, this message translates to:
  /// **'No reservations'**
  String get noReservations;

  /// No description provided for @noReservationsMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any reservations yet'**
  String get noReservationsMessage;

  /// No description provided for @noTrips.
  ///
  /// In en, this message translates to:
  /// **'No trips'**
  String get noTrips;

  /// No description provided for @noTripsMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any trips yet'**
  String get noTripsMessage;

  /// No description provided for @pickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Pickup location'**
  String get pickupLocation;

  /// No description provided for @dropoffLocation.
  ///
  /// In en, this message translates to:
  /// **'Drop-off location'**
  String get dropoffLocation;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get selectTime;

  /// No description provided for @estimatedPrice.
  ///
  /// In en, this message translates to:
  /// **'Estimated price'**
  String get estimatedPrice;

  /// No description provided for @vehicleDetails.
  ///
  /// In en, this message translates to:
  /// **'Vehicle details'**
  String get vehicleDetails;

  /// No description provided for @vehicleCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get vehicleCapacity;

  /// No description provided for @vehicleFeatures.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get vehicleFeatures;

  /// No description provided for @pricePerKm.
  ///
  /// In en, this message translates to:
  /// **'Price per km'**
  String get pricePerKm;

  /// No description provided for @creditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit card'**
  String get creditCard;

  /// No description provided for @paypal.
  ///
  /// In en, this message translates to:
  /// **'PayPal'**
  String get paypal;

  /// No description provided for @driverInfo.
  ///
  /// In en, this message translates to:
  /// **'Driver information'**
  String get driverInfo;

  /// No description provided for @driverName.
  ///
  /// In en, this message translates to:
  /// **'Driver name'**
  String get driverName;

  /// No description provided for @driverPhone.
  ///
  /// In en, this message translates to:
  /// **'Driver phone'**
  String get driverPhone;

  /// No description provided for @vehicleInfo.
  ///
  /// In en, this message translates to:
  /// **'Vehicle information'**
  String get vehicleInfo;

  /// No description provided for @tripStatus.
  ///
  /// In en, this message translates to:
  /// **'Trip status'**
  String get tripStatus;

  /// No description provided for @tripDetails.
  ///
  /// In en, this message translates to:
  /// **'Trip details'**
  String get tripDetails;

  /// No description provided for @tripHistory.
  ///
  /// In en, this message translates to:
  /// **'Trip history'**
  String get tripHistory;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notificationSettings;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushNotifications;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email notifications'**
  String get emailNotifications;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @locationServices.
  ///
  /// In en, this message translates to:
  /// **'Location services'**
  String get locationServices;

  /// No description provided for @searchLocation.
  ///
  /// In en, this message translates to:
  /// **'Search location'**
  String get searchLocation;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get currentLocation;

  /// No description provided for @recentLocations.
  ///
  /// In en, this message translates to:
  /// **'Recent locations'**
  String get recentLocations;

  /// No description provided for @savedLocations.
  ///
  /// In en, this message translates to:
  /// **'Saved locations'**
  String get savedLocations;

  /// No description provided for @addComment.
  ///
  /// In en, this message translates to:
  /// **'Add comment'**
  String get addComment;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @vehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get vehicles;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add user'**
  String get addUser;

  /// No description provided for @editUser.
  ///
  /// In en, this message translates to:
  /// **'Edit user'**
  String get editUser;

  /// No description provided for @deleteUser.
  ///
  /// In en, this message translates to:
  /// **'Delete user'**
  String get deleteUser;

  /// No description provided for @editVehicle.
  ///
  /// In en, this message translates to:
  /// **'Edit vehicle'**
  String get editVehicle;

  /// No description provided for @deleteVehicle.
  ///
  /// In en, this message translates to:
  /// **'Delete vehicle'**
  String get deleteVehicle;

  /// No description provided for @reservationManagement.
  ///
  /// In en, this message translates to:
  /// **'Reservation management'**
  String get reservationManagement;

  /// No description provided for @pendingReservations.
  ///
  /// In en, this message translates to:
  /// **'Pending reservations'**
  String get pendingReservations;

  /// No description provided for @confirmedReservations.
  ///
  /// In en, this message translates to:
  /// **'Confirmed reservations'**
  String get confirmedReservations;

  /// No description provided for @completedReservations.
  ///
  /// In en, this message translates to:
  /// **'Completed reservations'**
  String get completedReservations;

  /// No description provided for @totalTrips.
  ///
  /// In en, this message translates to:
  /// **'Total trips'**
  String get totalTrips;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total revenue'**
  String get totalRevenue;

  /// No description provided for @activeUsers.
  ///
  /// In en, this message translates to:
  /// **'Active users'**
  String get activeUsers;

  /// No description provided for @averageRating.
  ///
  /// In en, this message translates to:
  /// **'Average rating'**
  String get averageRating;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportData;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import data'**
  String get importData;

  /// No description provided for @backupData.
  ///
  /// In en, this message translates to:
  /// **'Backup data'**
  String get backupData;

  /// No description provided for @systemSettings.
  ///
  /// In en, this message translates to:
  /// **'System settings'**
  String get systemSettings;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get appSettings;

  /// No description provided for @serverSettings.
  ///
  /// In en, this message translates to:
  /// **'Server settings'**
  String get serverSettings;

  /// No description provided for @estimatedTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated time 15 min'**
  String get estimatedTime;

  /// No description provided for @availableVehicles.
  ///
  /// In en, this message translates to:
  /// **'Available vehicles'**
  String get availableVehicles;

  /// No description provided for @loadingVehicles.
  ///
  /// In en, this message translates to:
  /// **'Loading vehicles...'**
  String get loadingVehicles;

  /// No description provided for @pleaseRetry.
  ///
  /// In en, this message translates to:
  /// **'Please retry'**
  String get pleaseRetry;

  /// No description provided for @noVehicleAvailable.
  ///
  /// In en, this message translates to:
  /// **'No vehicle available'**
  String get noVehicleAvailable;

  /// No description provided for @pleaseRetryLater.
  ///
  /// In en, this message translates to:
  /// **'Please retry later'**
  String get pleaseRetryLater;

  /// No description provided for @backToSummary.
  ///
  /// In en, this message translates to:
  /// **'Back to summary'**
  String get backToSummary;

  /// No description provided for @planVehicle.
  ///
  /// In en, this message translates to:
  /// **'Plan {vehicle}'**
  String planVehicle(String vehicle);

  /// No description provided for @selectedVehicleNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'The selected vehicle is no longer available'**
  String get selectedVehicleNoLongerAvailable;

  /// No description provided for @selectedVehicleDeactivated.
  ///
  /// In en, this message translates to:
  /// **'The selected vehicle has been deactivated by the administrator'**
  String get selectedVehicleDeactivated;

  /// No description provided for @logoutDescription.
  ///
  /// In en, this message translates to:
  /// **'Disconnect from your account.'**
  String get logoutDescription;

  /// No description provided for @featureComingSoonDescription.
  ///
  /// In en, this message translates to:
  /// **'This feature will be available soon.'**
  String get featureComingSoonDescription;

  /// No description provided for @adminLogoutDescription.
  ///
  /// In en, this message translates to:
  /// **'Disconnect from your administrator account.'**
  String get adminLogoutDescription;

  /// No description provided for @adminLogoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to disconnect from your administrator account?'**
  String get adminLogoutConfirmation;

  /// No description provided for @vehicleName.
  ///
  /// In en, this message translates to:
  /// **'Vehicle name'**
  String get vehicleName;

  /// No description provided for @vehicleNameExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Economy Sedan'**
  String get vehicleNameExample;

  /// No description provided for @vehicleDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Vehicle description'**
  String get vehicleDescriptionHint;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @pricePerKmEuro.
  ///
  /// In en, this message translates to:
  /// **'Price per kilometer (CHF)'**
  String get pricePerKmEuro;

  /// No description provided for @priceExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1.50'**
  String get priceExample;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @reservationConfirmedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reservation confirmed successfully!'**
  String get reservationConfirmedSuccess;

  /// No description provided for @sendError.
  ///
  /// In en, this message translates to:
  /// **'❌ Sending error: {error}'**
  String sendError(String error);

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book your driver in seconds — modern, smooth and reliable.'**
  String get welcomeSubtitle;

  /// No description provided for @securePayment.
  ///
  /// In en, this message translates to:
  /// **'Secure Payment'**
  String get securePayment;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @bankCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Visa, Mastercard, American Express'**
  String get bankCardSubtitle;

  /// No description provided for @applePaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fast and secure payment'**
  String get applePaySubtitle;

  /// No description provided for @googlePay.
  ///
  /// In en, this message translates to:
  /// **'Google Pay'**
  String get googlePay;

  /// No description provided for @googlePaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fast and secure payment'**
  String get googlePaySubtitle;

  /// No description provided for @cardDetails.
  ///
  /// In en, this message translates to:
  /// **'Card Details'**
  String get cardDetails;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get payNow;

  /// No description provided for @processingPayment.
  ///
  /// In en, this message translates to:
  /// **'Processing payment...'**
  String get processingPayment;

  /// No description provided for @paymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful!'**
  String get paymentSuccess;

  /// No description provided for @paymentSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your reservation has been confirmed and paid successfully.'**
  String get paymentSuccessMessage;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @securePaymentInfo.
  ///
  /// In en, this message translates to:
  /// **'Your data is protected by 256-bit SSL encryption'**
  String get securePaymentInfo;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment Failed'**
  String get paymentFailed;

  /// No description provided for @paymentFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while processing your payment.'**
  String get paymentFailedMessage;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @cancelPayment.
  ///
  /// In en, this message translates to:
  /// **'Cancel Payment'**
  String get cancelPayment;

  /// No description provided for @refundRequest.
  ///
  /// In en, this message translates to:
  /// **'Refund Request'**
  String get refundRequest;

  /// No description provided for @refundReason.
  ///
  /// In en, this message translates to:
  /// **'Refund Reason'**
  String get refundReason;

  /// No description provided for @refundAmount.
  ///
  /// In en, this message translates to:
  /// **'Refund Amount'**
  String get refundAmount;

  /// No description provided for @requestRefund.
  ///
  /// In en, this message translates to:
  /// **'Request Refund'**
  String get requestRefund;

  /// No description provided for @refundSuccess.
  ///
  /// In en, this message translates to:
  /// **'Refund Requested'**
  String get refundSuccess;

  /// No description provided for @refundSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your refund request has been submitted.'**
  String get refundSuccessMessage;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistory;

  /// No description provided for @waitingForDriverConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for driver confirmation'**
  String get waitingForDriverConfirmation;

  /// No description provided for @waitingForConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for confirmation'**
  String get waitingForConfirmation;

  /// No description provided for @reservationProcessingMessage.
  ///
  /// In en, this message translates to:
  /// **'Your reservation is being processed. You cannot make a new reservation until it is confirmed.'**
  String get reservationProcessingMessage;

  /// No description provided for @waitingForPayment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for payment'**
  String get waitingForPayment;

  /// No description provided for @paymentRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Your reservation is confirmed! Please make the payment to finalize your trip.'**
  String get paymentRequiredMessage;

  /// No description provided for @transactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get transactionId;

  /// No description provided for @paymentDate.
  ///
  /// In en, this message translates to:
  /// **'Payment Date'**
  String get paymentDate;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @refunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get refunded;

  /// No description provided for @noPaymentHistory.
  ///
  /// In en, this message translates to:
  /// **'No Payment History'**
  String get noPaymentHistory;

  /// No description provided for @noPaymentHistoryMessage.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t made any payments yet.'**
  String get noPaymentHistoryMessage;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @favoriteTrips.
  ///
  /// In en, this message translates to:
  /// **'Favorite trips'**
  String get favoriteTrips;

  /// No description provided for @addFavoriteTrip.
  ///
  /// In en, this message translates to:
  /// **'Add Favorite Trip'**
  String get addFavoriteTrip;

  /// No description provided for @editFavoriteTrip.
  ///
  /// In en, this message translates to:
  /// **'Edit Favorite Trip'**
  String get editFavoriteTrip;

  /// No description provided for @tripName.
  ///
  /// In en, this message translates to:
  /// **'Trip Name'**
  String get tripName;

  /// No description provided for @enterTripName.
  ///
  /// In en, this message translates to:
  /// **'Enter trip name'**
  String get enterTripName;

  /// No description provided for @departureAddress.
  ///
  /// In en, this message translates to:
  /// **'Departure Address'**
  String get departureAddress;

  /// No description provided for @enterDepartureAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter departure address'**
  String get enterDepartureAddress;

  /// No description provided for @arrivalAddress.
  ///
  /// In en, this message translates to:
  /// **'Arrival Address'**
  String get arrivalAddress;

  /// No description provided for @enterArrivalAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter arrival address'**
  String get enterArrivalAddress;

  /// No description provided for @selectIcon.
  ///
  /// In en, this message translates to:
  /// **'Select Icon'**
  String get selectIcon;

  /// No description provided for @addTrip.
  ///
  /// In en, this message translates to:
  /// **'Add Trip'**
  String get addTrip;

  /// No description provided for @updateTrip.
  ///
  /// In en, this message translates to:
  /// **'Update Trip'**
  String get updateTrip;

  /// No description provided for @deleteTrip.
  ///
  /// In en, this message translates to:
  /// **'Delete Trip'**
  String get deleteTrip;

  /// No description provided for @tripAdded.
  ///
  /// In en, this message translates to:
  /// **'Trip added successfully'**
  String get tripAdded;

  /// No description provided for @tripUpdated.
  ///
  /// In en, this message translates to:
  /// **'Trip updated successfully'**
  String get tripUpdated;

  /// No description provided for @tripDeleted.
  ///
  /// In en, this message translates to:
  /// **'Trip deleted successfully'**
  String get tripDeleted;

  /// No description provided for @tripDuplicated.
  ///
  /// In en, this message translates to:
  /// **'Trip duplicated successfully'**
  String get tripDuplicated;

  /// No description provided for @deleteTripConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this favorite trip?'**
  String get deleteTripConfirmation;

  /// No description provided for @tripAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This trip already exists in your favorites'**
  String get tripAlreadyExists;

  /// No description provided for @searchFavoriteTrips.
  ///
  /// In en, this message translates to:
  /// **'Search favorite trips'**
  String get searchFavoriteTrips;

  /// No description provided for @noFavoriteTrips.
  ///
  /// In en, this message translates to:
  /// **'No favorite trips'**
  String get noFavoriteTrips;

  /// No description provided for @noFavoriteTripsDescription.
  ///
  /// In en, this message translates to:
  /// **'Add your frequent trips to find them quickly'**
  String get noFavoriteTripsDescription;

  /// No description provided for @addFirstFavoriteTrip.
  ///
  /// In en, this message translates to:
  /// **'Add your first trip'**
  String get addFirstFavoriteTrip;

  /// No description provided for @tripNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Trip name is required'**
  String get tripNameRequired;

  /// No description provided for @tripNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Trip name must be at least 2 characters'**
  String get tripNameTooShort;

  /// No description provided for @departureAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Departure address is required'**
  String get departureAddressRequired;

  /// No description provided for @departureAddressTooShort.
  ///
  /// In en, this message translates to:
  /// **'Departure address must be at least 5 characters'**
  String get departureAddressTooShort;

  /// No description provided for @arrivalAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Arrival address is required'**
  String get arrivalAddressRequired;

  /// No description provided for @arrivalAddressTooShort.
  ///
  /// In en, this message translates to:
  /// **'Arrival address must be at least 5 characters'**
  String get arrivalAddressTooShort;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @use.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get use;

  /// No description provided for @tapToOpen.
  ///
  /// In en, this message translates to:
  /// **'Tap to open'**
  String get tapToOpen;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error(String error);

  /// No description provided for @termsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditions;

  /// No description provided for @legalMentions.
  ///
  /// In en, this message translates to:
  /// **'Legal Mentions'**
  String get legalMentions;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// No description provided for @dataCollection.
  ///
  /// In en, this message translates to:
  /// **'Data Collection'**
  String get dataCollection;

  /// No description provided for @dataCollectionDescription.
  ///
  /// In en, this message translates to:
  /// **'We only collect data necessary for the operation of our mobility service: name, email, phone number, departure/arrival addresses, and geolocation data. This information is used exclusively to provide our transportation services.'**
  String get dataCollectionDescription;

  /// No description provided for @dataUsage.
  ///
  /// In en, this message translates to:
  /// **'Data Usage'**
  String get dataUsage;

  /// No description provided for @dataUsageDescription.
  ///
  /// In en, this message translates to:
  /// **'Your personal data is used to:\n• Facilitate booking and management of your trips\n• Communicate with you regarding your reservations\n• Improve the quality of our services\n• Comply with our legal obligations'**
  String get dataUsageDescription;

  /// No description provided for @dataSharing.
  ///
  /// In en, this message translates to:
  /// **'Data Sharing'**
  String get dataSharing;

  /// No description provided for @dataSharingDescription.
  ///
  /// In en, this message translates to:
  /// **'We never sell your personal data. We may share your information only with:\n• Drivers assigned to your trips (name and phone number)\n• Our service providers (payment, hosting) under confidentiality agreements\n• Authorities if required by law'**
  String get dataSharingDescription;

  /// No description provided for @dataSecurity.
  ///
  /// In en, this message translates to:
  /// **'Data Security'**
  String get dataSecurity;

  /// No description provided for @dataSecurityDescription.
  ///
  /// In en, this message translates to:
  /// **'We use advanced security measures to protect your data:\n• SSL/TLS encryption for all communications\n• Secure storage on certified servers\n• Restricted access to personal data\n• Regular security audits'**
  String get dataSecurityDescription;

  /// No description provided for @userRights.
  ///
  /// In en, this message translates to:
  /// **'Your Rights'**
  String get userRights;

  /// No description provided for @userRightsDescription.
  ///
  /// In en, this message translates to:
  /// **'In accordance with GDPR, you have the right to:\n• Access your personal data\n• Rectify incorrect information\n• Delete your account and data\n• Limit the processing of your data\n• Data portability\n• Object to processing'**
  String get userRightsDescription;

  /// No description provided for @contactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactInfo;

  /// No description provided for @contactInfoDescription.
  ///
  /// In en, this message translates to:
  /// **'For any questions regarding your personal data:\n• Email: privacy@mymobilityservices.com\n• Phone: +41 22 123 45 67\n• Address: 123 Rue de la Mobilité, 1200 Geneva, Switzerland'**
  String get contactInfoDescription;

  /// No description provided for @serviceDescription.
  ///
  /// In en, this message translates to:
  /// **'Service Description'**
  String get serviceDescription;

  /// No description provided for @serviceDescriptionText.
  ///
  /// In en, this message translates to:
  /// **'My Mobility Services is a private transportation booking platform. We connect users with professional drivers for personalized trips.'**
  String get serviceDescriptionText;

  /// No description provided for @userObligations.
  ///
  /// In en, this message translates to:
  /// **'User Obligations'**
  String get userObligations;

  /// No description provided for @userObligationsText.
  ///
  /// In en, this message translates to:
  /// **'By using our service, you agree to:\n• Provide accurate and up-to-date information\n• Respect drivers and equipment\n• Pay for services used within deadlines\n• Respect safety and civility rules\n• Not use the service for illegal purposes'**
  String get userObligationsText;

  /// No description provided for @companyObligations.
  ///
  /// In en, this message translates to:
  /// **'Our Obligations'**
  String get companyObligations;

  /// No description provided for @companyObligationsText.
  ///
  /// In en, this message translates to:
  /// **'We commit to:\n• Provide quality and secure service\n• Respect your privacy and data\n• Maintain platform availability\n• Ensure driver training and verification\n• Provide responsive customer support'**
  String get companyObligationsText;

  /// No description provided for @paymentTerms.
  ///
  /// In en, this message translates to:
  /// **'Payment Terms'**
  String get paymentTerms;

  /// No description provided for @paymentTermsText.
  ///
  /// In en, this message translates to:
  /// **'• Payment is made before the start of the trip\n• We accept bank cards, Apple Pay, Google Pay and cash payment\n• Prices are calculated based on distance and vehicle type\n• No hidden fees, all costs are transparent'**
  String get paymentTermsText;

  /// No description provided for @cancellationPolicy.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Policy'**
  String get cancellationPolicy;

  /// No description provided for @cancellationPolicyText.
  ///
  /// In en, this message translates to:
  /// **'• Free cancellation up to 30 minutes before the trip\n• Cancellation between 30 min and 5 min: 50% of the amount\n• Cancellation less than 5 min before: 100% of the amount\n• In case of driver cancellation: full refund'**
  String get cancellationPolicyText;

  /// No description provided for @liabilityLimitation.
  ///
  /// In en, this message translates to:
  /// **'Liability Limitation'**
  String get liabilityLimitation;

  /// No description provided for @liabilityLimitationText.
  ///
  /// In en, this message translates to:
  /// **'Our liability is limited to the transaction amount. We are not responsible for delays due to traffic conditions, force majeure events, or actions of independent drivers.'**
  String get liabilityLimitationText;

  /// No description provided for @disputeResolution.
  ///
  /// In en, this message translates to:
  /// **'Dispute Resolution'**
  String get disputeResolution;

  /// No description provided for @disputeResolutionText.
  ///
  /// In en, this message translates to:
  /// **'In case of dispute, we favor amicable resolution. If necessary, Swiss courts will have jurisdiction. We adhere to Swiss consumer mediation services.'**
  String get disputeResolutionText;

  /// No description provided for @companyInfo.
  ///
  /// In en, this message translates to:
  /// **'Company Information'**
  String get companyInfo;

  /// No description provided for @companyInfoText.
  ///
  /// In en, this message translates to:
  /// **'My Mobility Services SA\nUID: CHE-123.456.789\nCommercial Register: Geneva\nShare capital: 50,000 CHF\nVAT: CHE-123.456.789 MWST'**
  String get companyInfoText;

  /// No description provided for @publisherInfo.
  ///
  /// In en, this message translates to:
  /// **'Website Publisher'**
  String get publisherInfo;

  /// No description provided for @publisherInfoText.
  ///
  /// In en, this message translates to:
  /// **'Publication director: Jean Dupont\nEmail: contact@mymobilityservices.com\nPhone: +41 22 123 45 67\nAddress: 123 Rue de la Mobilité, 1200 Geneva, Switzerland'**
  String get publisherInfoText;

  /// No description provided for @hostingInfo.
  ///
  /// In en, this message translates to:
  /// **'Hosting'**
  String get hostingInfo;

  /// No description provided for @hostingInfoText.
  ///
  /// In en, this message translates to:
  /// **'The site is hosted by:\nGoogle Cloud Platform\n1600 Amphitheatre Parkway\nMountain View, CA 94043, USA\nISO 27001 certified'**
  String get hostingInfoText;

  /// No description provided for @intellectualProperty.
  ///
  /// In en, this message translates to:
  /// **'Intellectual Property'**
  String get intellectualProperty;

  /// No description provided for @intellectualPropertyText.
  ///
  /// In en, this message translates to:
  /// **'All elements of this site (texts, images, logos, design) are protected by copyright. Any reproduction without authorization is prohibited. The application and its database are intellectual works protected by the Intellectual Property Code.'**
  String get intellectualPropertyText;

  /// No description provided for @applicableLaw.
  ///
  /// In en, this message translates to:
  /// **'Applicable Law'**
  String get applicableLaw;

  /// No description provided for @applicableLawText.
  ///
  /// In en, this message translates to:
  /// **'These terms are subject to Swiss law. In case of dispute, Swiss courts will have sole jurisdiction. The reference language is French.'**
  String get applicableLawText;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @reservationType.
  ///
  /// In en, this message translates to:
  /// **'Reservation type'**
  String get reservationType;

  /// No description provided for @selectAtLeastOneReservation.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one reservation'**
  String get selectAtLeastOneReservation;

  /// No description provided for @generatingPdf.
  ///
  /// In en, this message translates to:
  /// **'Generating PDF... ({count} reservations)'**
  String generatingPdf(int count);

  /// No description provided for @noDataFound.
  ///
  /// In en, this message translates to:
  /// **'No data found for selected reservations'**
  String get noDataFound;

  /// No description provided for @pdfExportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'PDF exported successfully!'**
  String get pdfExportedSuccessfully;

  /// No description provided for @exportError.
  ///
  /// In en, this message translates to:
  /// **'Export error: {error}'**
  String exportError(String error);

  /// No description provided for @createTestReservation.
  ///
  /// In en, this message translates to:
  /// **'🧪 Create test reservation'**
  String get createTestReservation;

  /// No description provided for @testError.
  ///
  /// In en, this message translates to:
  /// **'❌ Test error: {error}'**
  String testError(String error);

  /// No description provided for @cancellationError.
  ///
  /// In en, this message translates to:
  /// **'Cancellation error: {error}'**
  String cancellationError(String error);

  /// No description provided for @offerCancelledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Offer cancelled successfully'**
  String get offerCancelledSuccess;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @offerRefused.
  ///
  /// In en, this message translates to:
  /// **'Offer refused'**
  String get offerRefused;

  /// No description provided for @refuse.
  ///
  /// In en, this message translates to:
  /// **'Refuse'**
  String get refuse;

  /// No description provided for @contactClient.
  ///
  /// In en, this message translates to:
  /// **'Contact client'**
  String get contactClient;

  /// No description provided for @paymentRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Payment request sent to client'**
  String get paymentRequestSent;

  /// No description provided for @sendCounterOffer.
  ///
  /// In en, this message translates to:
  /// **'Send counter offer'**
  String get sendCounterOffer;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Information updated successfully!'**
  String get profileUpdatedSuccess;

  /// No description provided for @userProfile.
  ///
  /// In en, this message translates to:
  /// **'User profile'**
  String get userProfile;

  /// No description provided for @searchByNameOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email'**
  String get searchByNameOrEmail;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @noReservationsOrOffers.
  ///
  /// In en, this message translates to:
  /// **'No reservations or offers'**
  String get noReservationsOrOffers;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages'**
  String get noMessages;

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get newMessage;

  /// No description provided for @promoCodeExample.
  ///
  /// In en, this message translates to:
  /// **'Ex: Promo Code 20'**
  String get promoCodeExample;

  /// No description provided for @promoCodeIdExample.
  ///
  /// In en, this message translates to:
  /// **'Ex: Promo20'**
  String get promoCodeIdExample;

  /// No description provided for @chooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get chooseDate;

  /// No description provided for @usageLimitExample.
  ///
  /// In en, this message translates to:
  /// **'Ex: 100'**
  String get usageLimitExample;

  /// No description provided for @codeCreated.
  ///
  /// In en, this message translates to:
  /// **'Code created'**
  String get codeCreated;

  /// No description provided for @promoCodeCreated.
  ///
  /// In en, this message translates to:
  /// **'Promo code created'**
  String get promoCodeCreated;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @writeMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message...'**
  String get writeMessage;

  /// No description provided for @ticketFinished.
  ///
  /// In en, this message translates to:
  /// **'This ticket is finished. Open a new message.'**
  String get ticketFinished;

  /// No description provided for @conversationFinished.
  ///
  /// In en, this message translates to:
  /// **'This conversation is finished.'**
  String get conversationFinished;

  /// No description provided for @callError.
  ///
  /// In en, this message translates to:
  /// **'Call error: {error}'**
  String callError(String error);

  /// No description provided for @fullNameExample.
  ///
  /// In en, this message translates to:
  /// **'Ex: John Doe'**
  String get fullNameExample;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @emailExample.
  ///
  /// In en, this message translates to:
  /// **'Ex: john.doe@email.com'**
  String get emailExample;

  /// No description provided for @phoneExample.
  ///
  /// In en, this message translates to:
  /// **'Ex: 612345678'**
  String get phoneExample;

  /// No description provided for @searchCountry.
  ///
  /// In en, this message translates to:
  /// **'Search for a country...'**
  String get searchCountry;

  /// No description provided for @passwordExample.
  ///
  /// In en, this message translates to:
  /// **'Ex: MyPassword123!'**
  String get passwordExample;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get enterEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// No description provided for @priceInChf.
  ///
  /// In en, this message translates to:
  /// **'Price in CHF'**
  String get priceInChf;

  /// No description provided for @optionalMessageForClient.
  ///
  /// In en, this message translates to:
  /// **'Optional message for client...'**
  String get optionalMessageForClient;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @explainRefundReason.
  ///
  /// In en, this message translates to:
  /// **'Explain the reason for refund...'**
  String get explainRefundReason;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @maxPassengers.
  ///
  /// In en, this message translates to:
  /// **'Max passengers'**
  String get maxPassengers;

  /// No description provided for @four.
  ///
  /// In en, this message translates to:
  /// **'4'**
  String get four;

  /// No description provided for @maxLuggage.
  ///
  /// In en, this message translates to:
  /// **'Max luggage'**
  String get maxLuggage;

  /// No description provided for @two.
  ///
  /// In en, this message translates to:
  /// **'2'**
  String get two;

  /// No description provided for @imageUrl.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get imageUrl;

  /// No description provided for @imageUrlExample.
  ///
  /// In en, this message translates to:
  /// **'https://example.com/image.jpg'**
  String get imageUrlExample;

  /// No description provided for @enterPromoCode.
  ///
  /// In en, this message translates to:
  /// **'Enter your promo code'**
  String get enterPromoCode;

  /// No description provided for @promoCodeApplied.
  ///
  /// In en, this message translates to:
  /// **'Promo code applied'**
  String get promoCodeApplied;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @uberNotificationDemo.
  ///
  /// In en, this message translates to:
  /// **'Uber Notification Demo'**
  String get uberNotificationDemo;

  /// No description provided for @launchDemo.
  ///
  /// In en, this message translates to:
  /// **'Launch demo'**
  String get launchDemo;

  /// No description provided for @uberNotificationTest.
  ///
  /// In en, this message translates to:
  /// **'Uber Notification Test'**
  String get uberNotificationTest;

  /// No description provided for @explainChange.
  ///
  /// In en, this message translates to:
  /// **'Explain the change...'**
  String get explainChange;

  /// No description provided for @explainScheduleChange.
  ///
  /// In en, this message translates to:
  /// **'Explain the reason for schedule change...'**
  String get explainScheduleChange;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @deselectTrip.
  ///
  /// In en, this message translates to:
  /// **'Deselect this trip'**
  String get deselectTrip;

  /// No description provided for @selectTrip.
  ///
  /// In en, this message translates to:
  /// **'Select this trip'**
  String get selectTrip;

  /// No description provided for @arrival.
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get arrival;

  /// No description provided for @tripDescription.
  ///
  /// In en, this message translates to:
  /// **'Trip from {fromAddress} to {toAddress}, status {status}, departure {startAt}{arrivalInfo}, price {priceFormatted}'**
  String tripDescription(
    String fromAddress,
    String toAddress,
    String status,
    String startAt,
    String arrivalInfo,
    String priceFormatted,
  );

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @selectedPeriod.
  ///
  /// In en, this message translates to:
  /// **'Selected period'**
  String get selectedPeriod;

  /// No description provided for @label.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get label;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @accountDisabled.
  ///
  /// In en, this message translates to:
  /// **'Account disabled'**
  String get accountDisabled;

  /// No description provided for @noAccountForEmail.
  ///
  /// In en, this message translates to:
  /// **'No account for this email'**
  String get noAccountForEmail;

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get incorrectPassword;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password too weak'**
  String get weakPassword;

  /// No description provided for @noNetworkConnection.
  ///
  /// In en, this message translates to:
  /// **'No network connection'**
  String get noNetworkConnection;

  /// No description provided for @phoneAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This phone number is already in use'**
  String get phoneAlreadyInUse;

  /// No description provided for @minimum8Characters.
  ///
  /// In en, this message translates to:
  /// **'Minimum 8 characters'**
  String get minimum8Characters;

  /// No description provided for @debugCountry.
  ///
  /// In en, this message translates to:
  /// **'DEBUG - Country: {country}'**
  String debugCountry(String country);

  /// No description provided for @debugPhone.
  ///
  /// In en, this message translates to:
  /// **'DEBUG - Phone: {phone}'**
  String debugPhone(String phone);

  /// No description provided for @debugFullPhone.
  ///
  /// In en, this message translates to:
  /// **'DEBUG - Full phone: {fullPhone}'**
  String debugFullPhone(String fullPhone);

  /// No description provided for @debugCode.
  ///
  /// In en, this message translates to:
  /// **'DEBUG - Code: {code}'**
  String debugCode(String code);

  /// No description provided for @calculateDistanceAndArrival.
  ///
  /// In en, this message translates to:
  /// **'Calculate distance and estimated arrival time'**
  String get calculateDistanceAndArrival;

  /// No description provided for @calculationError.
  ///
  /// In en, this message translates to:
  /// **'Calculation error'**
  String get calculationError;

  /// No description provided for @decodePolyline.
  ///
  /// In en, this message translates to:
  /// **'Decode polyline'**
  String get decodePolyline;

  /// No description provided for @departureMarker.
  ///
  /// In en, this message translates to:
  /// **'departure'**
  String get departureMarker;

  /// No description provided for @destinationMarker.
  ///
  /// In en, this message translates to:
  /// **'destination'**
  String get destinationMarker;

  /// No description provided for @routePolyline.
  ///
  /// In en, this message translates to:
  /// **'route'**
  String get routePolyline;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get personalInformation;

  /// No description provided for @notProvidedShort.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvidedShort;

  /// No description provided for @myFavoriteTrips.
  ///
  /// In en, this message translates to:
  /// **'My favorite trips'**
  String get myFavoriteTrips;

  /// No description provided for @cancelAllPendingReservations.
  ///
  /// In en, this message translates to:
  /// **'Cancel all pending reservations'**
  String get cancelAllPendingReservations;

  /// No description provided for @notificationTest.
  ///
  /// In en, this message translates to:
  /// **'Notification test'**
  String get notificationTest;

  /// No description provided for @testClient.
  ///
  /// In en, this message translates to:
  /// **'Test client'**
  String get testClient;

  /// No description provided for @premiumSedan.
  ///
  /// In en, this message translates to:
  /// **'Premium sedan'**
  String get premiumSedan;

  /// No description provided for @pendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending requests'**
  String get pendingRequests;

  /// No description provided for @reservation.
  ///
  /// In en, this message translates to:
  /// **'Reservation'**
  String get reservation;

  /// No description provided for @cancelOffer.
  ///
  /// In en, this message translates to:
  /// **'Cancel offer'**
  String get cancelOffer;

  /// No description provided for @noPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get noPendingRequests;

  /// No description provided for @noResultsForSelectedFilters.
  ///
  /// In en, this message translates to:
  /// **'No results for selected filters'**
  String get noResultsForSelectedFilters;

  /// No description provided for @tryModifyingFilterCriteria.
  ///
  /// In en, this message translates to:
  /// **'Try modifying your filtering criteria'**
  String get tryModifyingFilterCriteria;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @customRequest.
  ///
  /// In en, this message translates to:
  /// **'Custom request'**
  String get customRequest;

  /// No description provided for @recentMessage.
  ///
  /// In en, this message translates to:
  /// **'Recent message'**
  String get recentMessage;

  /// No description provided for @supportConversation.
  ///
  /// In en, this message translates to:
  /// **'Support conversation'**
  String get supportConversation;

  /// No description provided for @weUsuallyRespondInMinutes.
  ///
  /// In en, this message translates to:
  /// **'We usually respond in a few minutes'**
  String get weUsuallyRespondInMinutes;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @mustBeConnectedToSeeNotifications.
  ///
  /// In en, this message translates to:
  /// **'You must be connected to see notifications'**
  String get mustBeConnectedToSeeNotifications;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @errorLoadingNotifications.
  ///
  /// In en, this message translates to:
  /// **'Error loading notifications'**
  String get errorLoadingNotifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @allNotificationsMarkedAsRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications have been marked as read'**
  String get allNotificationsMarkedAsRead;

  /// No description provided for @errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading'**
  String get errorLoading;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @refund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refund;

  /// No description provided for @onlinePayment.
  ///
  /// In en, this message translates to:
  /// **'Online payment'**
  String get onlinePayment;

  /// No description provided for @offerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Offer not found'**
  String get offerNotFound;

  /// No description provided for @offerAlreadyProcessed.
  ///
  /// In en, this message translates to:
  /// **'This offer has already been processed or cancelled'**
  String get offerAlreadyProcessed;

  /// No description provided for @chf.
  ///
  /// In en, this message translates to:
  /// **'CHF'**
  String get chf;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connectionError;

  /// No description provided for @errorLoadingCompletedRides.
  ///
  /// In en, this message translates to:
  /// **'Error loading completed rides'**
  String get errorLoadingCompletedRides;

  /// No description provided for @yourCompletedRidesWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your completed rides will appear here'**
  String get yourCompletedRidesWillAppearHere;

  /// No description provided for @resetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get resetFilters;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @noVehicles.
  ///
  /// In en, this message translates to:
  /// **'No vehicles'**
  String get noVehicles;

  /// No description provided for @startByAddingVehicle.
  ///
  /// In en, this message translates to:
  /// **'Start by adding a vehicle'**
  String get startByAddingVehicle;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @newVehicle.
  ///
  /// In en, this message translates to:
  /// **'New vehicle'**
  String get newVehicle;

  /// No description provided for @noUsers.
  ///
  /// In en, this message translates to:
  /// **'No users'**
  String get noUsers;

  /// No description provided for @noCodesAtTheMoment.
  ///
  /// In en, this message translates to:
  /// **'No codes at the moment'**
  String get noCodesAtTheMoment;

  /// No description provided for @expires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expires;

  /// No description provided for @noExpiration.
  ///
  /// In en, this message translates to:
  /// **'No expiration'**
  String get noExpiration;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get requiredField;

  /// No description provided for @fixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get fixed;

  /// No description provided for @percentage.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get percentage;

  /// No description provided for @invalidValue.
  ///
  /// In en, this message translates to:
  /// **'Invalid value'**
  String get invalidValue;

  /// No description provided for @expirationDate.
  ///
  /// In en, this message translates to:
  /// **'Expiration date'**
  String get expirationDate;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @maxUsers.
  ///
  /// In en, this message translates to:
  /// **'Maximum number of users'**
  String get maxUsers;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @managePromoCodes.
  ///
  /// In en, this message translates to:
  /// **'Manage promo codes'**
  String get managePromoCodes;

  /// No description provided for @viewProfilesAndReservations.
  ///
  /// In en, this message translates to:
  /// **'View profiles and reservations'**
  String get viewProfilesAndReservations;

  /// No description provided for @rideChat.
  ///
  /// In en, this message translates to:
  /// **'Ride chat'**
  String get rideChat;

  /// No description provided for @noMessagesAtTheMoment.
  ///
  /// In en, this message translates to:
  /// **'No messages at the moment'**
  String get noMessagesAtTheMoment;

  /// No description provided for @reopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get reopen;

  /// No description provided for @pleaseFillAllCardFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all card fields'**
  String get pleaseFillAllCardFields;

  /// No description provided for @unsupportedPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Unsupported payment method'**
  String get unsupportedPaymentMethod;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @atLeast30MinutesInAdvance.
  ///
  /// In en, this message translates to:
  /// **'At least 30 minutes in advance'**
  String get atLeast30MinutesInAdvance;

  /// No description provided for @selectDesiredTime.
  ///
  /// In en, this message translates to:
  /// **'Select desired time'**
  String get selectDesiredTime;

  /// No description provided for @dateNotDefined.
  ///
  /// In en, this message translates to:
  /// **'Date not defined'**
  String get dateNotDefined;

  /// No description provided for @waitingForAcceptance.
  ///
  /// In en, this message translates to:
  /// **'Waiting for acceptance'**
  String get waitingForAcceptance;

  /// No description provided for @toBeDefined.
  ///
  /// In en, this message translates to:
  /// **'To be defined'**
  String get toBeDefined;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @validateAndPay.
  ///
  /// In en, this message translates to:
  /// **'Validate and pay'**
  String get validateAndPay;

  /// No description provided for @notDefined.
  ///
  /// In en, this message translates to:
  /// **'Not defined'**
  String get notDefined;

  /// No description provided for @missingPriceOnOffer.
  ///
  /// In en, this message translates to:
  /// **'Missing price on offer'**
  String get missingPriceOnOffer;

  /// No description provided for @userNotConnected.
  ///
  /// In en, this message translates to:
  /// **'User not connected'**
  String get userNotConnected;

  /// No description provided for @offerDetails.
  ///
  /// In en, this message translates to:
  /// **'Offer details'**
  String get offerDetails;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @unknownClient.
  ///
  /// In en, this message translates to:
  /// **'Unknown client'**
  String get unknownClient;

  /// No description provided for @tripInformation.
  ///
  /// In en, this message translates to:
  /// **'Trip information'**
  String get tripInformation;

  /// No description provided for @selectedVehicle.
  ///
  /// In en, this message translates to:
  /// **'Selected vehicle'**
  String get selectedVehicle;

  /// No description provided for @serviceDuration.
  ///
  /// In en, this message translates to:
  /// **'Service duration'**
  String get serviceDuration;

  /// No description provided for @startDateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Start date and time'**
  String get startDateAndTime;

  /// No description provided for @tripSummary.
  ///
  /// In en, this message translates to:
  /// **'Trip summary'**
  String get tripSummary;

  /// No description provided for @destinationAddress.
  ///
  /// In en, this message translates to:
  /// **'Destination address'**
  String get destinationAddress;

  /// No description provided for @promoCode.
  ///
  /// In en, this message translates to:
  /// **'Promo code'**
  String get promoCode;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @createReservation.
  ///
  /// In en, this message translates to:
  /// **'Create reservation'**
  String get createReservation;

  /// No description provided for @reservationCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reservation created successfully! ID: {reservationId}'**
  String reservationCreatedSuccess(Object reservationId);

  /// No description provided for @promoCodeUsed.
  ///
  /// In en, this message translates to:
  /// **'Promo code used: {code}'**
  String promoCodeUsed(Object code);

  /// No description provided for @jan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get jan;

  /// No description provided for @feb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get feb;

  /// No description provided for @mar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get mar;

  /// No description provided for @apr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get apr;

  /// No description provided for @jun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get jun;

  /// No description provided for @jul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get jul;

  /// No description provided for @aug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get aug;

  /// No description provided for @sep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get sep;

  /// No description provided for @oct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get oct;

  /// No description provided for @nov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get nov;

  /// No description provided for @dec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get dec;

  /// No description provided for @errorCalculatingArrivalTime.
  ///
  /// In en, this message translates to:
  /// **'Error calculating arrival time'**
  String get errorCalculatingArrivalTime;

  /// No description provided for @reservationSavedWithVehicle.
  ///
  /// In en, this message translates to:
  /// **'Reservation saved with vehicle: {vehicleName}'**
  String reservationSavedWithVehicle(Object vehicleName);

  /// No description provided for @reservationCreatedWithId.
  ///
  /// In en, this message translates to:
  /// **'Reservation created with ID: {reservationId}'**
  String reservationCreatedWithId(Object reservationId);

  /// No description provided for @youAlreadyHavePendingOffer.
  ///
  /// In en, this message translates to:
  /// **'You already have a pending offer. Please wait for the driver\'s response.'**
  String get youAlreadyHavePendingOffer;

  /// No description provided for @setDefaultTime30MinutesFromNow.
  ///
  /// In en, this message translates to:
  /// **'Set default time 30 minutes from now'**
  String get setDefaultTime30MinutesFromNow;

  /// No description provided for @fallbackToLocalTime.
  ///
  /// In en, this message translates to:
  /// **'Fallback to local time if timezone database not initialized'**
  String get fallbackToLocalTime;

  /// No description provided for @useCachedPositionOrGeneva.
  ///
  /// In en, this message translates to:
  /// **'Use cached position or Geneva as default'**
  String get useCachedPositionOrGeneva;

  /// No description provided for @useCachedPositionIfRecent.
  ///
  /// In en, this message translates to:
  /// **'Use cached position if recent (< 5 min)'**
  String get useCachedPositionIfRecent;

  /// No description provided for @useGenevaAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Use Geneva as default (faster than geolocation)'**
  String get useGenevaAsDefault;

  /// No description provided for @getPositionInBackground.
  ///
  /// In en, this message translates to:
  /// **'Get position in background for next call'**
  String get getPositionInBackground;

  /// No description provided for @googlePlacesAutocompleteUrl.
  ///
  /// In en, this message translates to:
  /// **'Google Places Autocomplete URL'**
  String get googlePlacesAutocompleteUrl;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageFrench;

  /// No description provided for @componentsSwitzerlandFirst.
  ///
  /// In en, this message translates to:
  /// **'Switzerland first'**
  String get componentsSwitzerlandFirst;

  /// No description provided for @sessionToken.
  ///
  /// In en, this message translates to:
  /// **'Session token'**
  String get sessionToken;

  /// No description provided for @locationParam.
  ///
  /// In en, this message translates to:
  /// **'Location parameter'**
  String get locationParam;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get apiKey;

  /// No description provided for @statusOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get statusOk;

  /// No description provided for @predictions.
  ///
  /// In en, this message translates to:
  /// **'Predictions'**
  String get predictions;

  /// No description provided for @sortSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Sort suggestions'**
  String get sortSuggestions;

  /// No description provided for @swissAddresses.
  ///
  /// In en, this message translates to:
  /// **'Swiss addresses'**
  String get swissAddresses;

  /// No description provided for @switzerland.
  ///
  /// In en, this message translates to:
  /// **'Switzerland'**
  String get switzerland;

  /// No description provided for @geneva.
  ///
  /// In en, this message translates to:
  /// **'Geneva'**
  String get geneva;

  /// No description provided for @zurich.
  ///
  /// In en, this message translates to:
  /// **'Zurich'**
  String get zurich;

  /// No description provided for @bern.
  ///
  /// In en, this message translates to:
  /// **'Bern'**
  String get bern;

  /// No description provided for @lausanne.
  ///
  /// In en, this message translates to:
  /// **'Lausanne'**
  String get lausanne;

  /// No description provided for @backgroundGeolocationFailed.
  ///
  /// In en, this message translates to:
  /// **'Background geolocation failed'**
  String get backgroundGeolocationFailed;

  /// No description provided for @googlePlacesDetailsUrl.
  ///
  /// In en, this message translates to:
  /// **'Google Places Details URL'**
  String get googlePlacesDetailsUrl;

  /// No description provided for @placeId.
  ///
  /// In en, this message translates to:
  /// **'Place ID'**
  String get placeId;

  /// No description provided for @fieldsGeometry.
  ///
  /// In en, this message translates to:
  /// **'Geometry fields'**
  String get fieldsGeometry;

  /// No description provided for @result.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get result;

  /// No description provided for @geometry.
  ///
  /// In en, this message translates to:
  /// **'Geometry'**
  String get geometry;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @useZurichTimeForValidation.
  ///
  /// In en, this message translates to:
  /// **'Use Zurich time for validation'**
  String get useZurichTimeForValidation;

  /// No description provided for @departureCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Departure coordinates'**
  String get departureCoordinates;

  /// No description provided for @destinationCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Destination coordinates'**
  String get destinationCoordinates;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get startTime;

  /// No description provided for @selectStartTime.
  ///
  /// In en, this message translates to:
  /// **'Select start time for your offer'**
  String get selectStartTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get endTime;

  /// No description provided for @selectEndTime.
  ///
  /// In en, this message translates to:
  /// **'Select end time for your offer'**
  String get selectEndTime;

  /// No description provided for @selectValidAddress.
  ///
  /// In en, this message translates to:
  /// **'Select a valid address'**
  String get selectValidAddress;

  /// No description provided for @offerCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Offer created successfully!'**
  String get offerCreatedSuccessfully;

  /// No description provided for @offerCreationError.
  ///
  /// In en, this message translates to:
  /// **'Error creating offer'**
  String get offerCreationError;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get fillAllFields;

  /// No description provided for @selectValidDate.
  ///
  /// In en, this message translates to:
  /// **'Please select a valid date'**
  String get selectValidDate;

  /// No description provided for @selectValidTime.
  ///
  /// In en, this message translates to:
  /// **'Please select a valid time'**
  String get selectValidTime;

  /// No description provided for @selectDepartureAddress.
  ///
  /// In en, this message translates to:
  /// **'Please select a departure address'**
  String get selectDepartureAddress;

  /// No description provided for @selectDestinationAddress.
  ///
  /// In en, this message translates to:
  /// **'Please select a destination address'**
  String get selectDestinationAddress;

  /// No description provided for @selectVehicleType.
  ///
  /// In en, this message translates to:
  /// **'Please select a vehicle type'**
  String get selectVehicleType;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get addNote;

  /// No description provided for @vehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle type'**
  String get vehicleType;

  /// No description provided for @endDateAndTime.
  ///
  /// In en, this message translates to:
  /// **'End date and time'**
  String get endDateAndTime;

  /// No description provided for @createOfferButton.
  ///
  /// In en, this message translates to:
  /// **'Create offer'**
  String get createOfferButton;

  /// No description provided for @errorLoadingVehicles.
  ///
  /// In en, this message translates to:
  /// **'Error loading vehicles'**
  String get errorLoadingVehicles;

  /// No description provided for @noVehiclesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No vehicles available at the moment'**
  String get noVehiclesAvailable;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
