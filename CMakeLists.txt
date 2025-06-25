# Set the minimum required CMake version for Qt6 features
cmake_minimum_required(VERSION 3.16)

# Set macOS deployment target if applicable
if(APPLE)
  set(CMAKE_OSX_DEPLOYMENT_TARGET "10.13" CACHE STRING "Minimum OS X deployment version for Qt6")
  set(HAVE_FLAG_SEARCH_PATHS_FIRST 0)
endif()

project(stremio VERSION "4.4.168")

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/CMakeModules/")

add_definitions(-DSTREMIO_SHELL_VERSION="${PROJECT_VERSION}" -DUNICODE -D_UNICODE)

# Set the C++ standard to 17, as required by Qt6
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

list(APPEND WEBENGINE_CONFIG use_proprietary_codecs)

# Define the list of source files
set(SOURCES
  main.cpp
  mpv.cpp
  stremioprocess.cpp
  screensaver.cpp
  systemtray.cpp
  razerchroma.cpp
  qclipboardproxy.cpp
  verifysig.c
  mainapplication.h
  autoupdater.cpp
  qml.qrc
)

set(MPV_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/deps/libmpv/include)
if(WIN32)
  list(APPEND SOURCES deps/chroma/chroma stremio.rc)
  set(MPV_LIBRARY_mpv ${CMAKE_CURRENT_SOURCE_DIR}/deps/libmpv/win32/mpv.lib)
endif()

if(APPLE)
  list(APPEND SOURCES images/stremio.icns)
  set_source_files_properties(images/stremio.icns PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
  set(MPV_LIBRARY_mpv ${CMAKE_CURRENT_SOURCE_DIR}/deps/lib/libmpv.dylib)
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,-rpath,@executable_path/../Frameworks")
  add_definitions("-pipe")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++ -arch x86_64")
  set(ENV{OPENSSL_ROOT_DIR} $ENV{OPENSSL_BIN_PATH})
endif()

set(QAPPLICATION_CLASS QApplication)
add_subdirectory(deps/singleapplication)

set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)

# Find Qt6 and its required components.
# Removed NetworkInformation as it's not found in this Qt version.
find_package(Qt6 REQUIRED COMPONENTS
    Widgets
    Network
    Qml
    Quick
    WebEngineCore
    WebEngineWidgets
    WebChannel
    DBus
    OpenGL
)
find_package(OpenSSL REQUIRED)
find_package(MPV REQUIRED)

if(APPLE)
  add_executable(${PROJECT_NAME} MACOSX_BUNDLE ${SOURCES})
  set_target_properties(${PROJECT_NAME} PROPERTIES
    BUNDLE True
    MACOSX_BUNDLE_ICON_FILE ${PROJECT_NAME}.icns
    MACOSX_BUNDLE_GUI_IDENTIFIER com.smartcodeltd.${PROJECT_NAME}
    MACOSX_BUNDLE_BUNDLE_EXECUTABLE_NAME ${PROJECT_NAME}
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/Info.plist
  )

  # Linking for macOS remains largely the same
  find_package(OpenGL)
  if(NOT OPENGL_FOUND)
    message(FATAL_ERROR "OpenGL is required on macOS for Qt6")
  endif()
  find_library(C_LIBRARY NAMES c REQUIRED)
  find_library(COREFOUNDATION_LIBRARY NAMES CoreFoundation REQUIRED)
  find_library(DISKARBITRATION_LIBRARY DiskArbitration REQUIRED)
  find_library(IOKIT_LIBRARY NAMES IOKit REQUIRED)
  find_library(AGL_LIBRARY NAMES AGL REQUIRED)
  target_link_libraries(${PROJECT_NAME} PRIVATE
    ${C_LIBRARY}
    ${COREFOUNDATION_LIBRARY}
    ${DISKARBITRATION_LIBRARY}
    ${IOKIT_LIBRARY}
    OpenGL::GL
    ${AGL_LIBRARY}
  )
else()
  add_executable(${PROJECT_NAME} ${SOURCES})
endif()

if(WIN32 AND CMAKE_BUILD_TYPE STREQUAL "Release")
  set_property(TARGET ${PROJECT_NAME} PROPERTY WIN32_EXECUTABLE true)
endif()

target_include_directories(${PROJECT_NAME} PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${MPV_INCLUDE_DIR}
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/deps/chroma>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/deps/chroma/ChromaSDK/inc>
)

# Link against the Qt6 targets.
# Removed Qt6::NetworkInformation
target_link_libraries(${PROJECT_NAME} PRIVATE
  Qt6::Qml
  Qt6::Quick
  Qt6::Network
  Qt6::Widgets
  Qt6::WebEngineCore
  Qt6::WebEngineWidgets
  Qt6::WebChannel
  Qt6::DBus
  Qt6::OpenGL
  SingleApplication
  OpenSSL::Crypto
  ${MPV_LIBRARY}
)

if(UNIX AND NOT APPLE)
  install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION opt/stremio)
endif()
