# DormDeal

DormDeal is a Flutter app for buying and selling items within a college
community.

## Local setup

1. Install Flutter and run `flutter pub get`.
2. Run the app with `flutter run`.

Push notification sending and email delivery must be implemented by a trusted
backend or Firebase Cloud Function. Never put FCM service-account keys, SMTP
passwords, or other server credentials in this Flutter application or its
assets. If a credential has previously been exposed, revoke it and create a
replacement.
