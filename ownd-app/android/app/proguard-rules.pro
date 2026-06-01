# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# uCrop (Image Cropper)
# Rules kept for safety, but dontwarn removed as we added dependencies
-keep class com.yalantis.ucrop** { *; }
-keep interface com.yalantis.ucrop** { *; }

# Flutter Play Store handling
# Dependencies added (play:core), but keeping generic Flutter keep rules is fine.

# OkHttp Optional Crypto Backends (Conscrypt, BouncyCastle, OpenJSSE)
# These are strictly optional runtime checks by OkHttp. 
# The correct "fix" is to tell R8 we intentionally don't include them.
# Adding the libraries would unnecessarily increase APK size by several MBs.
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
