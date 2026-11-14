/*
  ==============================================================================

   This file is part of the JUCE framework.
   Copyright (c) Raw Material Software Limited

   JUCE is an open source framework subject to commercial or open source
   licensing.

   By downloading, installing, or using the JUCE framework, or combining the
   JUCE framework with any other source code, object code, content or any other
   copyrightable work, you agree to the terms of the JUCE End User Licence
   Agreement, and all incorporated terms including the JUCE Privacy Policy and
   the JUCE Website Terms of Service, as applicable, which will bind you. If you
   do not agree to the terms of these agreements, we will not license the JUCE
   framework to you, and you must discontinue the installation or download
   process and cease use of the JUCE framework.

   JUCE End User Licence Agreement: https://juce.com/legal/juce-9-licence/
   JUCE Privacy Policy: https://juce.com/juce-privacy-policy
   JUCE Website Terms of Service: https://juce.com/juce-website-terms-of-service/

   Or:

   You may also use this code under the terms of the AGPLv3:
   https://www.gnu.org/licenses/agpl-3.0.en.html

   THE JUCE FRAMEWORK IS PROVIDED "AS IS" WITHOUT ANY WARRANTY, AND ALL
   WARRANTIES, WHETHER EXPRESSED OR IMPLIED, INCLUDING WARRANTY OF
   MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE, ARE DISCLAIMED.

  ==============================================================================
*/

// The value of JUCE_PUSH_NOTIFICATIONS_ACTIVITY is the app's own activity class, so with a prebuilt
// juce_gui_basics this file is compiled in the consumer project instead of the library.

#ifdef JUCE_PUSH_NOTIFICATIONS_ACTIVITY

#if ! JUCE_INTERNAL_PUSH_NOTIFICATIONS_ACTIVITY_IN_MODULE
 #include <juce_gui_basics/juce_gui_basics.h>
#endif

namespace juce
{

#if ! JUCE_INTERNAL_PUSH_NOTIFICATIONS_ACTIVITY_IN_MODULE
 // Declared like in juce_Windowing_android.cpp
 #if JUCE_PUSH_NOTIFICATIONS && JUCE_MODULE_AVAILABLE_juce_gui_extra
  bool juce_handleNotificationIntent (void*);
 #endif

 #if JUCE_IN_APP_PURCHASES && JUCE_MODULE_AVAILABLE_juce_product_unlocking
  void juce_handleOnResume();
 #else
  static void juce_handleOnResume() {}
 #endif
#endif

 struct JuceActivityNewIntentListener
 {
     #define JNI_CLASS_MEMBERS(METHOD, STATICMETHOD, FIELD, STATICFIELD, CALLBACK) \
      CALLBACK (appNewIntent, "appNewIntent", "(Landroid/content/Intent;)V") \
      CALLBACK (appOnResume,  "appOnResume",  "()V")

      DECLARE_JNI_CLASS (JavaActivity, JUCE_PUSH_NOTIFICATIONS_ACTIVITY)
     #undef JNI_CLASS_MEMBERS

     static void JNICALL appNewIntent (JNIEnv*, jobject /*activity*/, jobject intentData)
     {
         juce_handleNotificationIntent (static_cast<void*> (intentData));
     }

     static void JNICALL appOnResume (JNIEnv*, jobject)
     {
         juce_handleOnResume();
     }
 };

} // namespace juce

#endif
