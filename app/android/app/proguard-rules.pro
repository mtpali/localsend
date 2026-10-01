# Keep only native/JNI entry points; Flutter and plugins ship consumer keep rules.
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}
-keepattributes Signature,InnerClasses,EnclosingMethod,RuntimeVisibleAnnotations,AnnotationDefault
