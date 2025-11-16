# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Keep typed navigation route models and generated Kotlin serialization metadata.
# Navigation Compose resolves route serializers at runtime in release builds.
# Use ** to include potential subpackages and avoid naming-coupled release regressions.
-keep class com.shamelagpt.android.presentation.navigation.** { *; }
-keep class com.shamelagpt.android.presentation.navigation.**$$serializer { *; }
-keepclassmembers class com.shamelagpt.android.presentation.navigation.** {
    public static ** serializer(...);
}

# Retrofit + R8 (full mode): preserve generic signatures and HTTP annotations so
# Retrofit can inspect suspend function Continuation<T> parameterized types.
-keepattributes Signature, InnerClasses, EnclosingMethod
-keepattributes RuntimeVisibleAnnotations, RuntimeVisibleParameterAnnotations, AnnotationDefault

# Keep Retrofit service interfaces and annotated members.
-if interface * { @retrofit2.http.* <methods>; }
-keep,allowobfuscation interface <1>
-keepclassmembers,allowshrinking,allowobfuscation interface <1> {
    @retrofit2.http.* <methods>;
}

# Retrofit inspects this class reflectively for suspend API methods.
-keep,allowobfuscation,allowshrinking class kotlin.coroutines.Continuation

# Stability-first: keep Retrofit service interface API surface intact.
-keep interface com.shamelagpt.android.data.remote.ApiService { *; }

# Gson DTO safety: release shrinking/obfuscation/merging can break Retrofit+Gson payload mapping.
# Keep API DTO models intact so request/response JSON contracts stay stable in release builds.
-keep class com.shamelagpt.android.data.remote.dto.** { *; }

# Gson generic parsing safety for TypeToken<List<...>> based flows.
-keep class * extends com.google.gson.reflect.TypeToken

# Source objects are persisted as JSON in Room converters/mappers.
-keep class com.shamelagpt.android.domain.model.Source { *; }
