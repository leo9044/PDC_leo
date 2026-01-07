#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "CommonAPI-SomeIP" for configuration "Release"
set_property(TARGET CommonAPI-SomeIP APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(CommonAPI-SomeIP PROPERTIES
  IMPORTED_LINK_INTERFACE_LIBRARIES_RELEASE "CommonAPI;vsomeip3"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/libCommonAPI-SomeIP.so.3.2.4"
  IMPORTED_SONAME_RELEASE "libCommonAPI-SomeIP.so.3.2.4"
  )

list(APPEND _IMPORT_CHECK_TARGETS CommonAPI-SomeIP )
list(APPEND _IMPORT_CHECK_FILES_FOR_CommonAPI-SomeIP "${_IMPORT_PREFIX}/lib/libCommonAPI-SomeIP.so.3.2.4" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
