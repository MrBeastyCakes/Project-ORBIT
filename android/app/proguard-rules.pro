# Hive generated adapters
-keep class io.hivedb.** { *; }
-keepclassmembers class * extends io.hivedb.hive.HiveObject { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Flutter embedding
-keep class ** extends io.flutter.embedding.engine.FlutterEngine { *; }
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# flutter_quill
-keep class com.google.** { *; }
-dontwarn com.google.**

# Gson (used by some plugins)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep R8 from stripping serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
