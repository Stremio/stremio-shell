new QWebChannel(window.qt.webChannelTransport, function(channel) {
    var events = {};
    window.shell = Object.freeze({
        on: function(eventName, listener) {
            events[eventName] = events[eventName] || [];
            if (events[eventName].indexOf(listener) === -1) {
                events[eventName].push(listener);
            }
        },
        off: function(eventName, listener) {
            if (Array.isArray(events[eventName])) {
                var listenerIndex = events[eventName].indexOf(listener);
                if (listenerIndex !== -1) {
                    events[eventName].splice(listenerIndex, 1);
                }
            }
        },
        dispatch: function() {
            var args = Array.from(arguments);
            return new Promise(function(resolve, reject) {
                channel.objects.transport.dispatch(args, function(result) {
                    if (result && result.error) {
                        reject(result.error);
                    } else {
                        resolve(result);
                    }
                });
            });
        }
    });

    channel.objects.transport.event.connect(function(eventName, data) {
        if (Array.isArray(events[eventName])) {
            events[eventName].forEach(function(listener) {
                listener(data);
            });
        }
    });

    if (typeof window.shellOnLoad === 'function') {
        window.shellOnLoad();
    }
});
