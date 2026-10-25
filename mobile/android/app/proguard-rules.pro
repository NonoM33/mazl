# Règles R8 de la release Android (isMinifyEnabled = true).
# Android n'est pas publié en v1 : ce fichier garde le build de release sain.

# --- Flutter ---------------------------------------------------------------
# Les composants différés de Flutter citent Play Core, absent de l'app.
-dontwarn com.google.android.play.core.**

# --- flutter_local_notifications -------------------------------------------
# Le plugin sérialise ses notifications avec Gson, qui lit les types
# génériques par réflexion (règles de l'exemple officiel de Gson).
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# --- OneSignal (notifications push) ----------------------------------------
-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.**

# --- Lecture NFC des passeports (flutter_nfc_kit, via dmrtd) ----------------
# Le plugin s'appuie sur les classes android.nfc.tech.* et leurs noms.
-keep class im.nfc.flutter_nfc_kit.** { *; }
