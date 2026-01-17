# Keep TensorFlow Lite and its GPU delegate
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.**

# Handle RenderScript missing classes
-dontwarn android.renderscript.**

# Common Flutter/Supabase keep rules (optional but recommended)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }