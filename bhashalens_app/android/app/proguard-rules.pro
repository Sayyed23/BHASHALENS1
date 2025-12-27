# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }

# Prevent specific warnings
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**

# Specific classes mentioned in error logs (defensive)
-keep class com.google.mlkit.vision.text.** { *; }

# Play Core (Deferred Components)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

