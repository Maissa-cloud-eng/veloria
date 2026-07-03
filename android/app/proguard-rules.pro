# Empêcher R8/ProGuard de supprimer ou renommer les classes Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Ignorer les avertissements liés à ces bibliothèques
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Garder les classes nécessaires pour Flutter et les Plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
# Correction spécifique pour l'erreur Google Play Core / SplitCompat
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**