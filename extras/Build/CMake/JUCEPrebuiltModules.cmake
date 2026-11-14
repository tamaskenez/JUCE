# ==================================================================================================
# Support for building JUCE modules as prebuilt static libraries.
#
# Modules listed in JUCE_PREBUILT_MODULES are created as STATIC libraries instead of INTERFACE
# libraries. juce_add_module still describes the module with `INTERFACE` usage requirements; once
# the module is fully described, _juce_finalise_prebuilt_module turns those into PUBLIC ones, so the
# library itself is compiled with exactly the settings its consumers will see.
#
# Library build-time configuration: every `Config: JUCE_*` option declared in the module header
# (plus the ones in _juce_prebuilt_extra_options_<module>) is exposed as a cache variable of the
# same name. Empty means the module header's default; 0/1 (or any CMake boolean) is added as a
# PUBLIC compile definition.
#
# Each prebuilt module also pushes a generated source file to its consumers, which fails to compile
# if the consumer defines any of these options differently.
#
# The libraries are installed into lib/<CONFIG> and exported as juce::<module> into
# JUCEPrebuiltTargets.cmake. Only headers and the generated check file are installed for them.
# ==================================================================================================

# The options are only offered when configuring JUCE itself, not in projects consuming the package.
if(PROJECT_NAME STREQUAL "JUCE")
    set(JUCE_PREBUILT_MODULES "" CACHE STRING
        "JUCE modules to build and install as prebuilt static libraries (e.g. juce_core)")

    option(JUCE_POSITION_INDEPENDENT_CODE
        "Build the prebuilt JUCE module libraries as position independent code" ON)

    option(JUCE_MSVC_STATIC_RUNTIME
        "Build the prebuilt JUCE module libraries against the static MSVC runtime" OFF)

    if(JUCE_PREBUILT_MODULES)
        if(JUCE_MSVC_STATIC_RUNTIME)
            set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
        else()
            set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
        endif()
    endif()
endif()

# Library build-time options which are not tagged `Config:` in the module header
set(_juce_prebuilt_extra_options_juce_product_unlocking JUCE_IN_APP_PURCHASES)

# Defaults which differ from the module header's: the JUCE CMake API disables these unless a target
# asks for them with NEEDS_CURL, NEEDS_WEB_BROWSER or NEEDS_OPENGL_ES.
if((CMAKE_SYSTEM_NAME STREQUAL "Linux") OR (CMAKE_SYSTEM_NAME MATCHES ".*BSD"))
    set(_juce_prebuilt_option_default_JUCE_USE_CURL 0)
    set(_juce_prebuilt_option_default_JUCE_WEB_BROWSER 0)
    set(_juce_prebuilt_option_default_JUCE_OPENGL_ES 0)
endif()

set(_juce_prebuilt_source_patterns
    PATTERN "*.c" EXCLUDE
    PATTERN "*.cc" EXCLUDE
    PATTERN "*.cpp" EXCLUDE
    PATTERN "*.cxx" EXCLUDE
    PATTERN "*.m" EXCLUDE
    PATTERN "*.mm" EXCLUDE
    PATTERN "*.s" EXCLUDE
    PATTERN "*.asm" EXCLUDE)

function(_juce_add_prebuilt_module_library target)
    add_library(${target} STATIC)
    # Collected as INTERFACE sources like for regular modules, moved to SOURCES when finalising
    target_sources(${target} INTERFACE ${ARGN})
    set_target_properties(${target} PROPERTIES POSITION_INDEPENDENT_CODE ${JUCE_POSITION_INDEPENDENT_CODE})
endfunction()

# Wraps paths under the module source directory so that they are relocated to the install
# location in the exported target.
function(_juce_make_relocatable_include_dirs target base_path install_path)
    get_target_property(dirs ${target} INTERFACE_INCLUDE_DIRECTORIES)

    if(NOT dirs)
        return()
    endif()

    set(result)

    foreach(dir IN LISTS dirs)
        string(FIND "${dir}" "${base_path}" pos)

        if(pos EQUAL 0)
            string(LENGTH "${base_path}" base_length)
            string(SUBSTRING "${dir}" ${base_length} -1 suffix)
            list(APPEND result "$<BUILD_INTERFACE:${dir}>")

            if(install_path)
                list(APPEND result "$<INSTALL_INTERFACE:${install_path}${suffix}>")
            endif()
        else()
            list(APPEND result "${dir}")
        endif()
    endforeach()

    set_target_properties(${target} PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${result}")
endfunction()

function(_juce_finalise_prebuilt_module target module_header base_path install_path)
    get_filename_component(module_path "${module_header}" DIRECTORY)

    # Library build-time options --------------------------------------------------------------
    file(STRINGS "${module_header}" config_lines REGEX "Config: *JUCE_[A-Za-z0-9_]+")
    set(option_names)

    foreach(line IN LISTS config_lines)
        string(REGEX MATCH "JUCE_[A-Za-z0-9_]+" option_name "${line}")
        list(APPEND option_names ${option_name})
    endforeach()

    list(APPEND option_names ${_juce_prebuilt_extra_options_${target}})
    list(REMOVE_DUPLICATES option_names)

    set(check_source
        "// Generated by JUCEPrebuiltModules.cmake. Compiled in every project linking the prebuilt\n"
        "// ${target} library, verifies that the project doesn't change its library build-time options.\n\n")

    foreach(option_name IN LISTS option_names)
        set(${option_name} "${_juce_prebuilt_option_default_${option_name}}" CACHE STRING
            "${target} option (0 or 1); empty means the default from the module header")
        set_property(CACHE ${option_name} PROPERTY STRINGS ";0;1")

        set(value "${${option_name}}")

        if(NOT "${value}" STREQUAL "")
            if(value)
                set(value 1)
            else()
                set(value 0)
            endif()

            target_compile_definitions(${target} INTERFACE "${option_name}=${value}")
        endif()

        set(prebuilt_value_${option_name} "${value}")

        if("${value}" STREQUAL "")
            string(APPEND check_source
                "#ifdef ${option_name}\n"
                " #error \"${option_name} is defined, but the prebuilt ${target} library uses the module's default. Set it when building JUCE instead: -D${option_name}=...\"\n"
                "#endif\n\n")
        else()
            string(APPEND check_source
                "#if ! defined (${option_name}) || (${option_name}) != ${value}\n"
                " #error \"The prebuilt ${target} library was built with ${option_name}=${value}. Set it when building JUCE instead: -D${option_name}=...\"\n"
                "#endif\n\n")
        endif()
    endforeach()

    # Dependencies of options which are added by _juce_link_optional_libraries for source modules
    if((CMAKE_SYSTEM_NAME STREQUAL "Linux") OR (CMAKE_SYSTEM_NAME MATCHES ".*BSD"))
        # JUCE_USE_CURL and JUCE_WEB_BROWSER default to 1 in the module headers
        if((target STREQUAL "juce_core") AND NOT (prebuilt_value_JUCE_USE_CURL STREQUAL "0"))
            target_link_libraries(${target} INTERFACE juce::pkgconfig_JUCE_CURL_LINUX_DEPS)
        endif()

        if((target STREQUAL "juce_gui_extra") AND NOT (prebuilt_value_JUCE_WEB_BROWSER STREQUAL "0"))
            target_link_libraries(${target} INTERFACE juce::pkgconfig_JUCE_BROWSER_LINUX_DEPS)
        endif()

        if((target STREQUAL "juce_opengl") AND (prebuilt_value_JUCE_OPENGL_ES STREQUAL "1"))
            target_link_libraries(${target} INTERFACE juce::pkgconfig_JUCE_GLES_LINUX_DEPS)
        endif()
    elseif(APPLE)
        if((target STREQUAL "juce_product_unlocking") AND (prebuilt_value_JUCE_IN_APP_PURCHASES STREQUAL "1"))
            _juce_link_frameworks(${target} INTERFACE StoreKit)
        endif()
    endif()

    # INTERFACE -> PUBLIC: the library is built with the same usage requirements as its consumers
    foreach(prop IN ITEMS
            COMPILE_DEFINITIONS
            COMPILE_OPTIONS
            COMPILE_FEATURES
            INCLUDE_DIRECTORIES
            LINK_DIRECTORIES
            LINK_OPTIONS
            LINK_LIBRARIES)
        get_target_property(values ${target} INTERFACE_${prop})

        if(values)
            set_property(TARGET ${target} APPEND PROPERTY ${prop} "${values}")
        endif()
    endforeach()

    get_target_property(sources ${target} INTERFACE_SOURCES)

    if(sources)
        target_sources(${target} PRIVATE ${sources})
        set_target_properties(${target} PROPERTIES INTERFACE_SOURCES "")
    endif()

    _juce_make_relocatable_include_dirs(${target} "${base_path}" "${install_path}")

    # The option check is the only source the consumers compile ---------------------------------
    set(check_file_name "prebuilt_config_check.cpp")
    set(check_file "${CMAKE_CURRENT_BINARY_DIR}/${target}/${check_file_name}")
    string(CONCAT check_source ${check_source})
    file(CONFIGURE OUTPUT "${check_file}" CONTENT "${check_source}" @ONLY)

    target_sources(${target} INTERFACE "$<BUILD_INTERFACE:${check_file}>")

    if(install_path)
        target_sources(${target} INTERFACE
            "$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/${install_path}/${target}/${check_file_name}>")

        install(DIRECTORY "${module_path}" DESTINATION "${install_path}" ${_juce_prebuilt_source_patterns})
        install(FILES "${check_file}" DESTINATION "${install_path}/${target}")
    endif()

    set_property(GLOBAL APPEND PROPERTY _juce_prebuilt_module_targets ${target})
endfunction()

# Called from the top-level JUCE CMakeLists.txt after all modules have been added.
function(_juce_install_prebuilt_modules install_destination)
    get_property(targets GLOBAL PROPERTY _juce_prebuilt_module_targets)

    if(NOT targets)
        return()
    endif()

    # Helper targets the libraries depend on are exported along with them. JUCEConfig.cmake also
    # creates them in consumer projects, so the exported copies get distinct names.
    set(helper_targets)

    foreach(target IN LISTS targets)
        get_target_property(link_libs ${target} INTERFACE_LINK_LIBRARIES)

        foreach(lib IN LISTS link_libs)
            if(lib MATCHES "^(juce::)?(juce_atomic_wrapper|pkgconfig_.+)$")
                list(APPEND helper_targets ${CMAKE_MATCH_2})
            endif()
        endforeach()
    endforeach()

    list(REMOVE_DUPLICATES helper_targets)

    foreach(helper IN LISTS helper_targets)
        set_target_properties(${helper} PROPERTIES EXPORT_NAME prebuilt_${helper})
    endforeach()

    install(TARGETS ${targets} ${helper_targets}
        EXPORT JUCEPrebuiltTargets
        ARCHIVE DESTINATION "lib/$<CONFIG>")

    install(EXPORT JUCEPrebuiltTargets
        NAMESPACE juce::
        DESTINATION "${install_destination}")

    export(EXPORT JUCEPrebuiltTargets
        NAMESPACE juce::
        FILE "${JUCE_BINARY_DIR}/JUCEPrebuiltTargets.cmake")
endfunction()
