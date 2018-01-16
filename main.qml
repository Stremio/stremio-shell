import QtQuick 2.7
import QtWebEngine 1.4
import QtWebChannel 1.0
import QtQuick.Window 2.2 // for Window instead of ApplicationWindow; also for Screen
import QtQuick.Controls 1.4 // for ApplicationWindow
import QtQuick.Dialogs 1.2
import com.stremio.process 1.0
import com.stremio.screensaver 1.0
import com.stremio.libmpv 1.0
import com.stremio.razerchroma 1.0
import com.stremio.clipboard 1.0
import QtQml 2.2
import Qt.labs.platform 1.0

ApplicationWindow {
    id: root
    visible: true

    minimumWidth: 1000
    minimumHeight: 650

    readonly property int initialWidth: Math.max(root.minimumWidth, Math.min(1600, Screen.desktopAvailableWidth * 0.8))
    readonly property int initialHeight: Math.max(root.minimumHeight, Math.min(1000, Screen.desktopAvailableHeight * 0.8))

    width: root.initialWidth
    height: root.initialHeight

    property bool notificationsEnabled: true

    color: "#201f32";
    title: appTitle

    // This is built on the assumption it will be executed twice, at the start and end of the loading stage;
    // which means everything has to be checked
    property string injectedJs: "initShellComm()"

    // Transport
    QtObject {
        id: transport
        readonly property string shellVersion: Qt.application.version
        property string serverAddress: "http://127.0.0.1:11470" // will be set to something else if server inits on another port
        
	readonly property bool isFullscreen: root.visibility === Window.FullScreen // just to send the initial state

        signal event(var ev, var args)
        function onEvent(ev, args) {
            if (ev === "app-ready") transport.flushQueue()
            if (ev === "mpv-command" && args && args[0] !== "run") mpv.command(args)
            if (ev === "mpv-set-prop") mpv.setProperty(args[0], args[1])
            if (ev === "mpv-observe-prop") mpv.observeProperty(args)
            if (ev === "control-event") remoteControlEventFired()
            if (ev === "set-window-mode") onWindowMode(args)
            if (ev === "open-external") Qt.openUrlExternally(args)
            if (ev === "balloon-show" && root.notificationsEnabled) trayIcon.showMessage(args.title, args.content)
            if (ev === "win-focus") { if (!root.visible) root.show(); root.raise(); root.requestActivate(); }
            if (ev === "win-set-visibility") root.visibility = args.hasOwnProperty('fullscreen') ?
                                             (args.fullscreen ? Window.FullScreen : Window.Windowed) : args.visibility
            if (ev === "autoupdater-notif-clicked" && autoUpdater.onNotifClicked) autoUpdater.onNotifClicked()
            if (ev === "chroma-toggle") { args.enabled ? chroma.enable() : chroma.disable() }
            if (ev === "screensaver-toggle") shouldDisableScreensaver(args.disabled)
        }

        // events that we want to wait for the app to initialize
        property variant queued: []
        function queueEvent() { 
            if (transport.queued) transport.queued.push(arguments)
            else transport.event.apply(transport, arguments)
        }
        function flushQueue() {
            if (transport.queued) transport.queued.forEach(function(args) { transport.event.apply(transport, args) })
            transport.queued = null;
        }
    }


    // Utilities
    function onWindowMode(mode) {
        shouldDisableScreensaver(mode === "player")
        
        if (mode === "player") chroma.enable()
        else chroma.disable()
    }

    function remoteControlEventFired() {
        shouldDisableScreensaver(true)
        timerScreensaver.restart()
    }

    function shouldDisableScreensaver(condition) {
        if (condition === screenSaver.disabled) return;
        condition ? screenSaver.disable() : screenSaver.enable();
        screenSaver.disabled = condition;
    }

    function isPlayerPlaying() {
        return root.visible && typeof(mpv.getProperty("path"))==="string" && !mpv.getProperty("pause")
    }

    // Received external message
    function onAppMessageReceived(instance, message) {
        message = message.toString(); // cause it may be QUrl
        if (message == "SHOW") { root.show(); root.raise(); root.requestActivate() }
        else onAppOpenMedia(message)
    }

    // May be called from a message (from another app instance) or when app is initialized with an arg
    function onAppOpenMedia(message) {
        var url = (message.indexOf('://') > -1 || message.indexOf('magnet:') === 0) ? message : 'file://'+message;
        transport.queueEvent("open-media", url)
    }

    // Tray icon
    SystemTrayIcon {
        visible: true
        id: trayIcon
        iconSource: "qrc:/images/stremio.png"
        menu: Menu {
              MenuItem {
                  text: root.visible ? qsTr("Hide Stremio") : qsTr("Show Stremio")
                  onTriggered: root.visible ? root.hide() : root.show()
              }
              /*
              MenuItem {
                  id: trayIconNotifications
                  text: qsTr("Notifications")
                  onTriggered: root.notificationsEnabled = trayIconNotifications.checked
                  checked: root.notificationsEnabled
                  checkable: true
              }
              */
              MenuItem {
                  text: qsTr("Open in browser")
                  onTriggered: Qt.openUrlExternally(transport.serverAddress)
              }
              MenuItem {
                  text: qsTr("Quit")
                  onTriggered: Qt.quit()
              }
          }
    
        onActivated: function (reason) {
            // WARNING: on windows and mac, the reason is always undefined for some reason
            if (reason !== SystemTrayIcon.Context) {
                root.show()
                root.raise()
                root.requestActivate()
            }
        }

        onMessageClicked: function(data) { root.show() }
    }

    // Screen saver - enable & disable
    ScreenSaver {
        id: screenSaver
        property bool disabled: false // track last state so we don't call it multiple times
    }
    // This is needed so that 300s after the remote control has been used, we can re-enable the screensaver
    // (if the player is not playing)
    Timer {
        id: timerScreensaver
        interval: 300000
        running: false
        onTriggered: function () { shouldDisableScreensaver(isPlayerPlaying()) }
    }

    // Razer Chroma SDK - highlight player keys
    RazerChroma {
        id: chroma
    }

    // Clipboard proxy
    Clipboard {
        id: clipboard
    }

    //
    // Streaming server
    //
    Process {
        id: streamingServer
        property string errMessage:
            "Error while starting streaming server. Please consider re-installing Stremio from https://www.stremio.com"
        property int errors: 0
        property bool fastReload: false

        onStarted: function() { stayAliveStreamingServer.stop() }
        onFinished: function(code, status) { 
            // status -> QProcess::CrashExit is 1
            if (!streamingServer.fastReload && errors < 5 && (code !== 0 || status !== 0)) {
                errors++
                errorDialog.text = streamingServer.errMessage
                errorDialog.detailedText = 'Stremio streaming server has thrown an error \nexit code: ' + code
                errorDialog.visible = true
            }

            if (streamingServer.fastReload) {
                console.log("Streaming server: performing fast re-load")
                streamingServer.fastReload = false
                root.launchServer()
            } else {
                stayAliveStreamingServer.start()
            }
        }
        onAddressReady: function (address) {
            transport.serverAddress = address
            transport.event("server-address", address)
        }
        onErrorThrown: function (error) {
            if (streamingServer.fastReload && error == 1) return; // inhibit errors during fast reload mode;
                                                                  // we'll unset that after we've restarted the server
            errorDialog.text = streamingServer.errMessage
            errorDialog.detailedText =
                    'Stremio streaming server has thrown an error \nQProcess::ProcessError code: ' + error
            errorDialog.visible = true
       }
    }
    function launchServer() {
        var node_executable = applicationDirPath + "/node"
        if (Qt.platform.os === "windows") node_executable = applicationDirPath + "/node.exe"
        streamingServer.start(node_executable, 
            [applicationDirPath +"/server.js"].concat(Qt.application.arguments.slice(1)), 
            "EngineFS server started at "
        )
    }
    // TimerStreamingServer
    Timer {
        id: stayAliveStreamingServer
        interval: 10000
        running: false
        onTriggered: function () { root.launchServer() }
    }

    //
    // Player
    //
    MpvObject {
        id: mpv
        anchors.fill: parent
        onMpvEvent: function(ev, args) { transport.event(ev, args) }
    }

    //
    // Main UI (via WebEngineView)
    //
    Timer {
        id: retryTimer
        interval: 1000
        running: false
        onTriggered: function () {
            webView.tries++
            console.log("failed load, trying backupUrl ("+webView.backupUrl+"), tries: "+webView.tries) 
            webView.url = webView.backupUrl; // TODO: invalidate all caches
        }
    }
    WebEngineView {
        id: webView;

        focus: true

        readonly property string params: "?winControls=true&loginFlow=desktop";
        readonly property string mainUrl: 
            Qt.application.arguments.indexOf("--development") > -1 || debug 
            ? "http://127.0.0.1:11470/#"+webView.params 
            : "https://app.strem.io/#"+webView.params;
        
        readonly property string backupUrl: "http://127.0.0.1:11470/#"+webView.params;

        url: webView.mainUrl;
        anchors.fill: parent
        backgroundColor: "transparent";
        property int tries: 0

        readonly property int maxTries: 20

        onLoadingChanged: function(loadRequest) {
            if (webView.tries > 0) {
                // show the webview only if we're already on the backupUrl; the first one (network based)
                // can fail because of many reasons, including captive portals
                splashScreen.visible = false
            }

            if (loadRequest.status == WebEngineView.LoadSucceededStatus) { 
                webView.webChannel.registerObject( 'transport', transport );

                // Try-catch to be able to return the error as result, but still throw it in the client context
                // so it can be caught and reported
                var injectedJS = "try { "+root.injectedJs+" } " +
                        "catch(e) { setTimeout(function() { throw e }); e.message || JSON.stringify(e) }";
                webView.runJavaScript(injectedJS, function(err) {
                    if (! err) {
                        splashScreen.visible = false
                        webView.tries = 0
                        return
                    }

                    errorDialog.text = "Error while applying shell JS." +
                            " Please consider re-installing Stremio from https://www.stremio.com"
                    errorDialog.detailedText = err
                    errorDialog.visible = true

                    console.error(err)

                    // Fallback to local Stremio if we have an error with executing JS
                    if (webView.url !== webView.backupUrl && !webView.tries) {
                        console.log("fallbacking to local stremio")
                        webView.url = webView.backupUrl
                    }
                });
            }

            var shouldRetry = loadRequest.status == WebEngineView.LoadFailedStatus ||
                    loadRequest.status == WebEngineView.LoadStoppedStatus
            if ( shouldRetry && webView.tries < webView.maxTries) {
                retryTimer.restart()
            }
        }

        onRenderProcessTerminated: function(terminationStatus, exitCode) {
            console.log("render process terminated with code "+exitCode+" and status: "+terminationStatus)
            retryTimer.restart()
        }

        // WARNING: does not work..for some reason: "Scripts may close only the windows that were opened by it."
        onWindowCloseRequested: function() {
            root.visible = false;
            Qt.quit()
        }

        // In the app, we use open-external IPC signal, but make sure this works anyway
        property string hoveredUrl: ""
        onLinkHovered: webView.hoveredUrl = hoveredUrl
        onNewViewRequested: function(req) { if (req.userInitiated) Qt.openUrlExternally(webView.hoveredUrl) }

        onFullScreenRequested: function(req) {
            if (req.toggleOn) root.visibility = Window.FullScreen;
            else root.visibility = Window.Windowed;
            req.accept();
        }

        // Prevent navigation
        onNavigationRequested: function(req) {
            if (! req.url.toString().match(/^http(s?):\/\/(127.0.0.1:1147(\d)|app.strem.io|www.strem.io)\//)) {
                 console.log("onNavigationRequested: disallowed URL "+req.url.toString());
                 req.action = WebEngineView.IgnoreRequest;
            }
        }

        // Prevent ctx menu
        onContextMenuRequested: function(request) {
            request.accepted = true
        }

        Action {
            shortcut: StandardKey.Paste
            onTriggered: webView.triggerWebAction(WebEngineView.Paste)
        }

        DropArea {
            anchors.fill: parent
            onDropped: function(dropargs){
                var args = JSON.parse(JSON.stringify(dropargs))
                transport.event("dragdrop", args.urls)
            }
        }
    }

    //
    // Splash screen
    // Must be over the UI
    //
    Rectangle {
        id: splashScreen;
        color: "#1B1126";
        anchors.fill: parent;
        Image {
            id: splashLogo
            source: "qrc:///images/stremio.png"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            SequentialAnimation {
                id: pulseOpacity
                running: true
                NumberAnimation { target: splashLogo; property: "opacity"; to: 1.0; duration: 600;
                    easing.type: Easing.Linear; }
                NumberAnimation { target: splashLogo; property: "opacity"; to: 0.3; duration: 600;
                    easing.type: Easing.Linear; }
                loops: Animation.Infinite
            }
        }
    }

    //
    // Err dialog
    //
    MessageDialog {
        id: errorDialog
        title: "Stremio - Application Error"
        // onAccepted handler does not work
        //icon: StandardIcon.Critical
        //standardButtons: StandardButton.Ok
    }

    //
    // Binding window -> app events
    //
    onWindowStateChanged: function(state) {
        transport.event("win-state-changed", { state: state })
    }

    onVisibilityChanged: {
        transport.event("win-visibility-changed", { visible: root.visible, visibility: root.visibility,
                            isFullscreen: root.visibility === Window.FullScreen })
    }
    
    property int appState: Qt.application.state;
    onAppStateChanged: {
        // WARNING: we should load the app through https to avoid MITM attacks on the clipboard
        var clipboardUrl
        if (clipboard.text.match(/^(magnet|http|https|file|stremio|ipfs):/)) clipboardUrl = clipboard.text
        transport.event("app-state-changed", { state: appState, clipboard: clipboardUrl })
        
        // WARNING: CAVEAT: this works when you've focused ANOTHER app and then get back to this one
        if (Qt.platform.os === "osx" && appState === Qt.ApplicationActive && !root.visible) {
            root.show()
        }
    }

    onClosing: function(event){
        event.accepted = false
        root.hide()
    }

    //
    // AUTO UPDATER
    //
    signal autoUpdaterErr(var msg, var err);
    signal autoUpdaterRestartTimer();
    function initAutoUpdater() {
        var endpoints = ["https://www.strem.io/updater/check", "https://www.stremio.com/updater/check",
                         "https://www.stremio.net/updater/check"];
        var fallbackSite = "https://www.stremio.com/?fromFailedAutoupdate=true";
        var doAutoupdate = autoUpdater.isInstalled()

        // On Linux, because we use AppImage, we cannot do partial updates - because we can't replace files
        // in the read-only mountpoint
        if (Qt.platform.os === "linux" && doAutoupdate) autoUpdater.setForceFullUpdate(true);

        var args = Qt.application.arguments
        if (args.indexOf("--autoupdater-force-full") > -1) autoUpdater.setForceFullUpdate(true);
        if (args.indexOf("--autoupdater-force") > -1) doAutoupdate = true;

        var endpointArg = "--autoupdater-endpoint="
        args.forEach(function(arg) { if (arg.indexOf(endpointArg) === 0) endpoints = [arg.slice(endpointArg.length)] })
        autoUpdater.endpoint = function() {
            return endpoints[Math.floor(Math.random()*endpoints.length)]
        }

        if (! doAutoupdate) {
            console.log("Auto-updater: skipping, possibly not running an installed app?")
            return
        }
        
        // This is the timeout we use to check periodically; the signal is handled in the main (UI) thread
        var onTriggered
        autoUpdaterShortTimer.triggered.connect(onTriggered = function() {
            // WARNING: what if .isOnline() fails on some system?? it's based on QNetworkConfigurationManager
            // can we trust it??
            if (autoUpdater.isOnline()) {
                console.log("Auto-updater: checking for new version")
                autoUpdater.abort()
                autoUpdater.checkForUpdates(autoUpdater.endpoint())

            } else {
                console.log("Auto-update: skip check because we're not online")
                autoUpdaterShortTimer.restart()
            }
        })
        onTriggered() // initial check

        // Re-start this timer only from the main thread
        root.autoUpdaterRestartTimer.connect(function() { autoUpdaterLongTimer.restart() })

        // WARNING: all of the slot handlers are handled in another thread, that's why we need the autoUpdaterErr()
        // signal - to bring execution back to UI thread
        autoUpdater.checkFinished.connect(function(check) {
            // reset the notif, so there's no chance we'd trigger a re-start while downloading new ver
            if (check && !check.upToDate) autoUpdater.onNotifClicked = null;

            if (check && check.upToDate) console.log("Auto-updater: up to date");
            if (check && !check.upToDate) console.log("Auto-updater: updating to latest ver: "+check.versionDesc)
            else root.autoUpdaterRestartTimer() // no new ver, schedule a new check
        })

        // signal hack to bring it back to the main thread
        autoUpdater.error.connect(function(msg, err) { root.autoUpdaterErr(msg, err) })
        root.autoUpdaterErr.connect(function(msg, err) {
            // send to front-end, so we can handle accordingly
            transport.queueEvent("autoupdater-error", { err: err, msg: msg })

            autoUpdaterLongTimer.restart()

            // Display the error only if it's not QNetworkReply::HostNotFound (3) and not QNetworkReply::TimeoutError (4)
            // - this usually happens when we are not connected; sometimes autoupdater.isOnline() reports wrong
            if (err !== 3 && err !== 4) {
                errorDialog.text = "Auto updater error"
                errorDialog.detailedText = msg
                errorDialog.visible = true
            }
        })

        autoUpdater.prepared.connect(function(preparedFiles, version) {
            var firstFile = preparedFiles[0];

            console.log("Auto-updater: prepared update "+preparedFiles.join(", "))

            // When we finish preparing an update, we must call transport.queueEvent so that the app can receive
            // a notification event once it loads
            // Then, we must set .onNotifClicked to what we'll do when the notification is clicked

            if (preparedFiles.length == 2) {
                //
                // Prepare partial auto-update
                //
                console.log("Auto-updater: executing partial update")
                var failed = false
                preparedFiles.forEach(function(f) { if (!autoUpdater.moveFileToAppDir(f)) failed = true })
                if (failed) {
                    root.autoUpdaterErr("preparing partial update failed", null)
                    return
                }
                transport.queueEvent("autoupdater-show-notif", { mode: "reload" })
                autoUpdater.onNotifClicked = function() {
                    splashScreen.visible = true
                    webView.reloadAndBypassCache()
                    streamingServer.fastReload = true
                    streamingServer.terminate()
                }
            } else if (Qt.platform.os === "osx" && firstFile.match(".dmg$")) {
                // 
                // Prepare macOS auto-update (extract from .dmg)
                //
                console.log("Auto-updater: executing OSX update");

                var ver = version.version;
                var args = ["-c", 
                    "DMG=\""+firstFile+"\""
                    +"&& NEW=/Applications/$(date +%s).app"
                    +"&& MNT=\"/Volumes/Stremio "+ver+"\""

                    +"&& hdiutil attach \"$DMG\" -nobrowse -noautoopen" // NOTE: this returns 0,
                                                                        // even if it's already mounted
                    //+"&& MNT=$(hdiutil attach \"$DMG\" -nobrowse -noautoopen | awk -F'/Volumes/' '/Apple_HFS/ {print $2}') &&"
                            // WARNING: I'm not sure about this working on every OSX ver

                    +"&& cp -R \"$MNT\"/*.app \"$NEW\""
                    +"&& rm -rf /Applications/Stremio.app && mv \"$NEW\" \"/Applications/Stremio.app\""
                    +"&& xattr -d com.apple.quarantine /Applications/Stremio.app"
                    +"; hdiutil detach \"$MNT\"" 
                ];

                var code = autoUpdater.executeCmd("/bin/sh", args, false)
                if (code !== 0) {
                    root.autoUpdaterErr("preparing macOS .app failed", null);
                    return;
                }

                transport.queueEvent("autoupdater-show-notif", { mode: "restart" })
                autoUpdater.onNotifClicked = function() {
                    autoUpdater.executeCmd("/bin/sh", ["-c", "sleep 5; open -n /Applications/Stremio.app"], true)
                    Qt.quit()
                }
            } else if ( Qt.platform.os === "windows" && firstFile.match(".exe") ) {
                // 
                // Prepare launch-based auto-update (launch new installer/appimage on Windows)
                //
                transport.queueEvent("autoupdater-show-notif", { mode: "launchNew" })
                autoUpdater.onNotifClicked = function() {
                    Qt.openUrlExternally("file:///"+firstFile.replace(/\\/g,'/'))
                    Qt.quit()
                }
            } else if (Qt.platform.os === "linux" && firstFile.match(".appimage")) {
                // 
                // Prepare AppImage-based update (put in home dir and launch)
                //
                console.log("Auto-updater: executing Linux update");
                
                var baseName = firstFile.split("/").pop()
                var code = autoUpdater.executeCmd("/bin/sh",
                                                  ["-c", "mv '"+firstFile+"' $HOME; chmod +x $HOME/'"+baseName+"'"], false)
                if (code !== 0) {
                    root.autoUpdaterErr("preparing Linux .appimage failed", null);
                    return;
                }
                transport.queueEvent("autoupdater-show-notif", { mode: "launchNew" })
                autoUpdater.onNotifClicked = function() {
                    autoUpdater.executeCmd("/bin/sh", ["-c", "$HOME/'"+baseName+"'"], true)
                                    // crappy, but otherwise we have to write code to get env var
                    Qt.quit()
                }
            } else {
                root.autoUpdaterErr("Insane auto-update: "+preparedFiles.join(", "), null)
            }

            // WARNING: this seems to randomly crash the program in rare cases if called more than once
            // in this signal handler...
            root.autoUpdaterRestartTimer()
        })
    }
    // Explanation: when the long timer expires, we schedule the short timer; we do that, 
    // because in case the computer has been asleep for a long time, we want another short timer so we don't check
    // immediately (network not connected yet, etc)
    // we also schedule the short timer if the computer is offline
    Timer {
        id: autoUpdaterLongTimer
        interval: 2 * 60 * 60 * 1000
        running: false
        onTriggered: function() { autoUpdaterShortTimer.restart() }
    }
    Timer {
        id: autoUpdaterShortTimer
        interval: 5 * 60 * 1000
        running: false
        onTriggered: function() { } // empty, set if auto-updater is enabled in initAutoUpdater()
    }

    //
    // On complete handler
    //
    Component.onCompleted: function() {
        // Kind of hacky way to ensure there are no Qt bindings going on; otherwise when we go to fullscreen
        // Qt tries to restore original window size
        root.height = root.initialHeight
        root.width = root.initialWidth

        // Start streaming server
        var args = Qt.application.arguments
        if (args.indexOf("--development") > -1 && args.indexOf("--streaming-server") === -1) 
            console.log("Skipping launch of streaming server under --development");
        else 
            launchServer();

        // Handle file opens
        var lastArg = args[1]; // not actually last, but we want to be consistent with what happens when we open
                               // a second instance (main.cpp)
        if (args.length > 1 && !lastArg.match('^--')) onAppOpenMedia(lastArg)

        // Check for updates
        initAutoUpdater()
    }
}
