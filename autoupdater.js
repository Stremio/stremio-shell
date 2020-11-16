    //
    // AUTO UPDATER
    //
    // signal autoUpdaterErr(var msg, var err);
    // signal autoUpdaterRestartTimer();
    function initAutoUpdater(autoUpdater, autoUpdaterErr, shortTimer, longTimer, restartTimer, userAgent) {
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
        autoUpdater.networkStatus.connect(function(isOnline) {
            if (isOnline) {
                console.log("Auto-updater: checking for new version")
                autoUpdater.abort()
                autoUpdater.checkForUpdates(autoUpdater.endpoint(), userAgent)

            } else {
                console.log("Auto-update: skip check because we're not online")
                shortTimer.restart()
            }
        });
        // This is the timeout we use to check periodically; the signal is handled in the main (UI) thread
        var onTriggered
        shortTimer.triggered.connect(onTriggered = function() {
            autoUpdater.checkNetworkStatus();
        })
        onTriggered(); // initial check

        // Re-start this timer only from the main thread
        restartTimer.connect(function() {
            longTimer.restart();
        });

        // WARNING: all of the slot handlers are handled in another thread, that's why we need the autoUpdaterErr()
        // signal - to bring execution back to UI thread
        autoUpdater.checkFinished.connect(function(check) {
            // reset the notif, so there's no chance we'd trigger a re-start while downloading new ver
            if (check && !check.upToDate) autoUpdater.onNotifClicked = null;

            if (check && check.upToDate) console.log("Auto-updater: up to date");
            if (check && !check.upToDate) console.log("Auto-updater: updating to latest ver: "+check.versionDesc)
            else restartTimer() // no new ver, schedule a new check
        })

        // signal hack to bring it back to the main thread
        autoUpdater.error.connect(function(msg, err) {
            autoUpdaterErr(msg, err);
        });
        autoUpdaterErr.connect(function(msg, err) {
            // send to front-end, so we can handle accordingly
            transport.queueEvent("autoupdater-error", {
                err: err,
                msg: msg
            });

            longTimer.restart()

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
                    autoUpdaterErr("preparing partial update failed", null)
                    return
                }
                transport.queueEvent("autoupdater-show-notif", { mode: "reload" })
                autoUpdater.onNotifClicked = function() {
                    splashScreen.visible = true
                    pulseOpacity.running = true
                    webView.reloadAndBypassCache()
                    streamingServer.fastReload = true
                    streamingServer.terminate()
                }
            } else if (Qt.platform.os === "osx" && firstFile && firstFile.match(".dmg$")) {
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
                    autoUpdaterErr("preparing macOS .app failed", null);
                    return;
                }

                transport.queueEvent("autoupdater-show-notif", { mode: "restart" })
                autoUpdater.onNotifClicked = function() {
                    autoUpdater.executeCmd("/bin/sh", ["-c", "sleep 5; open -n /Applications/Stremio.app"], true)
                    quitApp();
                }
            } else if ( Qt.platform.os === "windows" && firstFile && firstFile.match(".exe") ) {
                // 
                // Prepare launch-based auto-update (launch new installer/appimage on Windows)
                //
                transport.queueEvent("autoupdater-show-notif", { mode: "launchNew" })
                autoUpdater.onNotifClicked = function() {
                    Qt.openUrlExternally("file:///"+firstFile.replace(/\\/g,'/'))
                    quitApp();
                }
            } else if (Qt.platform.os === "linux" && firstFile && firstFile.match(".appimage")) {
                // 
                // Prepare AppImage-based update (put in home dir and launch)
                //
                console.log("Auto-updater: executing Linux update");
                
                var baseName = firstFile.split("/").pop()
                var code = autoUpdater.executeCmd("/bin/sh",
                                                  ["-c", "mv '"+firstFile+"' $HOME; chmod +x $HOME/'"+baseName+"'"], false)
                if (code !== 0) {
                    autoUpdaterErr("preparing Linux .appimage failed", null);
                    return;
                }
                transport.queueEvent("autoupdater-show-notif", { mode: "launchNew" })
                autoUpdater.onNotifClicked = function() {
                    autoUpdater.executeCmd("/bin/sh", ["-c", "$HOME/'"+baseName+"'"], true)
                                    // crappy, but otherwise we have to write code to get env var
                    quitApp();
                }
            } else {
                autoUpdaterErr("Insane auto-update: "+preparedFiles.join(", "), null)
            }

            // WARNING: this seems to randomly crash the program in rare cases if called more than once
            // in this signal handler...
            restartTimer()
        })
    }
