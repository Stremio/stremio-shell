cmake_minimum_required(VERSION 3.13)
project(stremio)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/CMakeModules/")

add_definitions(-DSTREMIO_SHELL_VERSION="4.4.120")

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

list(APPEND WEBENGINE_CONFIG use_proprietary_codecs)

set(QAPPLICATION_CLASS QApplication)
add_subdirectory(deps/singleapplication)

set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)

find_package(Qt${QT_DEFAULT_MAJOR_VERSION} COMPONENTS Widgets Network Qml Quick WebEngine WebChannel DBus REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(MPV REQUIRED)

include_directories(${CMAKE_CURRENT_SOURCE_DIR} ${MPV_INCLUDE_DIR} deps/libmpv/include)

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

add_executable(stremio ${SOURCES})

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

install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION opt/stremio)
