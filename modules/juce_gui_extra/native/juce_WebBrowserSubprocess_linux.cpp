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

// The only place reading JUCE_USE_EXTERNAL_TEMPORARY_SUBPROCESS, which juce_link_with_embedded_linux_subprocess
// sets on the consumer target (plugins using the web browser), along with the include path of the
// generated helper binary. With a prebuilt juce_gui_extra this file is compiled in the consumer
// project instead of the library.

#if ! JUCE_INTERNAL_WEB_BROWSER_SUBPROCESS_IN_MODULE
 #include <juce_gui_extra/juce_gui_extra.h>
#endif

#if JUCE_USE_EXTERNAL_TEMPORARY_SUBPROCESS
 #include "juce_LinuxSubprocessHelperBinaryData.h"
#endif

namespace juce::detail
{

#if ! JUCE_INTERNAL_WEB_BROWSER_SUBPROCESS_IN_MODULE
 // Declared like in juce_WebBrowserComponent_linux.cpp
 Span<const char> getEmbeddedLinuxSubprocessHelper();
#endif

// The juce_linux_subprocess_helper executable embedded in the binary, or empty if there's none
Span<const char> getEmbeddedLinuxSubprocessHelper()
{
   #if JUCE_USE_EXTERNAL_TEMPORARY_SUBPROCESS
    return { ::LinuxSubprocessHelperBinaryData::juce_linux_subprocess_helper,
             (size_t) ::LinuxSubprocessHelperBinaryData::juce_linux_subprocess_helperSize };
   #else
    return {};
   #endif
}

} // namespace juce::detail
