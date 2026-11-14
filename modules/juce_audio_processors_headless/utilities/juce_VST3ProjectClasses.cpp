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

// The only place reading JUCE_VST3_COMPONENT_CLASS and JUCE_VST3_COMPATIBLE_CLASSES, which describe
// the consumer's own plugin. With a prebuilt juce_audio_processors_headless this file is compiled in
// the consumer project instead of the library. The VST3 manifest helper includes it directly.

#if ! JUCE_INTERNAL_VST3_INTERFACE_ONLY
 #include <juce_audio_processors_headless/juce_audio_processors_headless.h>
#endif

namespace juce::detail
{

std::optional<VST3Interface::Id> getVST3ComponentClass()
{
   #ifdef JUCE_VST3_COMPONENT_CLASS
    return VST3Interface::hexStringToId (JUCE_VST3_COMPONENT_CLASS);
   #else
    return {};
   #endif
}

std::optional<std::vector<VST3Interface::Id>> getVST3CompatibleClasses()
{
   #ifdef JUCE_VST3_COMPATIBLE_CLASSES
    return std::vector<VST3Interface::Id> { JUCE_VST3_COMPATIBLE_CLASSES };
   #else
    return {};
   #endif
}

} // namespace juce::detail
