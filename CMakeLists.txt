cmake_minimum_required(VERSION 3.13)
# set(CMAKE_CONFIGURATION_TYPES "Release" CACHE STRING "" FORCE)
project(stremio VERSION "4.4.120")

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/CMakeModules/")

add_definitions(-DSTREMIO_SHELL_VERSION="${PROJECT_VERSION}"  -DUNICODE -D_UNICODE)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

list(APPEND WEBENGINE_CONFIG use_proprietary_codecs)
set(SOURCES
  main
  mpv
  stremioprocess
  screensaver
  systemtray
  razerchroma
  qclipboardproxy
  verifysig
  mainapplication
  autoupdater
  qml.qrc
)

set(MPV_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/deps/libmpv/include)
if(WIN32)
  list(APPEND SOURCES deps/chroma/chroma stremio.rc)
  set(QT_DEFAULT_MAJOR_VERSION 5)
  set(ENV{Qt5_DIR} C:/Qt/5.12.3/msvc2017)
  set(MPV_LIBRARY_mpv ${CMAKE_CURRENT_SOURCE_DIR}/deps/libmpv/win32/mpv.lib)
endif()

if(APPLE)
  list(APPEND SOURCES images/stremio.icns)
  set_source_files_properties(images/stremio.icns PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
  set(MPV_LIBRARY_mpv ${CMAKE_CURRENT_SOURCE_DIR}/deps/lib/libmpv.dylib)
  list(APPEND CMAKE_EXE_LINKER_FLAGS "-framework CoreFoundation -framework IOKit -lc")
  set(ENV{OPENSSL_ROOT_DIR} $ENV{OPENSSL_BIN_PATH})
endif()

set(QAPPLICATION_CLASS QApplication)
add_subdirectory(deps/singleapplication)

set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)

find_package(Qt${QT_DEFAULT_MAJOR_VERSION} COMPONENTS Widgets Network Qml Quick WebEngine WebChannel DBus REQUIRED)
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

target_link_libraries(${PROJECT_NAME} LINK_PUBLIC
  Qt5::Qml
  Qt5::Quick
  Qt5::Network
  Qt5::Widgets
  Qt5::WebEngine
  Qt5::WebChannel
  Qt5::DBus
  SingleApplication::SingleApplication
  OpenSSL::Crypto
  ${MPV_LIBRARY}
)

if(UNIX AND NOT APPLE)
install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION opt/stremio)
endif()
