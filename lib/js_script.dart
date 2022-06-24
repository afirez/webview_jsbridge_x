String defaultjs = """
(function () {
    if (window.WebViewJavascriptBridge) {
        return;
    }

    window.WebViewJavascriptBridge = {
        handlers: {},
        callbacks: {},
        index: 0,
        defaultHandler: null,

        registerHandler: _registerHandler,
        callHandler: _callHandler,
        init: _init,
        send: _send,
        nativeCall: _nativeCall,
    };


    function _registerHandler(handlerName, handler) {
        WebViewJavascriptBridge.handlers[handlerName] = handler;
    }

    function _callHandler(handlerName, data, callback) {
        if (arguments.length == 2 && typeof data == 'function') {
            callback = data;
            data = null;
        }
        _send(data, callback, handlerName);
    }

    function _init(callback) {
        WebViewJavascriptBridge.defaultHandler = callback;
    }

    function _send(data, callback, handlerName) {
        if (!data && !handlerName) {
            console.log('WebViewJavascriptBridge: data and handlerName can not both be null at the same in WebViewJavascriptBridge send method');
            return;
        }

        var index = WebViewJavascriptBridge.index;

        var message = {
            index: index,
            type: 'request',
        };
        if (data) {
            message.data = data;
        }
        if (handlerName) {
            message.handlerName = handlerName;
        }

        WebViewJavascriptBridge.callbacks[index] = callback;
        WebViewJavascriptBridge.index += 1;

        _postMessage(message, callback);
    }


    function _jsCallResponse(jsonData) {
        var index = jsonData.index;
        var callback = WebViewJavascriptBridge.callbacks[index];
        delete WebViewJavascriptBridge.callbacks[index];
        if (jsonData.type === 'response') {
            callback(jsonData.data);
        } else {
            console.log('YGWebViewJavascriptBridge: js call native error for request ', JSON.stringify(jsonData));
        }
    }

    function _postMessage(jsonData) {
        var jsonStr = JSON.stringify(jsonData);
        var encodeStr = encodeURIComponent(jsonStr);
        YGFlutterJSBridgeChannel.postMessage(encodeStr);
    }

    function _nativeCall(message) {
        //here can't run immediately, wtf?
        setTimeout(() => _nativeCall(message), 0);
    }

    function _nativeCall(message) {
        var decodeStr = decodeURIComponent(message);
        var jsonData = JSON.parse(decodeStr);

        if (jsonData.type === 'request') {
            if ('handlerName' in jsonData) {
                var handlerName = jsonData.handlerName;
                if (handlerName in WebViewJavascriptBridge.handlers) {
                    var handler = WebViewJavascriptBridge.handlers[jsonData.handlerName];
                    handler(jsonData.data, function (data) {
                        _nativeCallResponse(jsonData, data);
                    });
                } else {
                    _nativeCallError(jsonData);
                    console.log('WebViewJavascriptBridge: no handler for native call ', handlerName);
                }

            } else {
                if (WebViewJavascriptBridge.defaultHandler) {
                    WebViewJavascriptBridge.defaultHandler(jsonData.data, function (data) {
                        _nativeCallResponse(jsonData, data);
                    });
                } else {
                    _nativeCallError(jsonData);
                    console.log('WebViewJavascriptBridge: no handler for native send');
                }
            }
        } else if (jsonData.type === 'response' || jsonData.type === 'error') {
            _jsCallResponse(jsonData);
        }
    }

    function _nativeCallError(jsonData) {
        jsonData.type = 'error';
        _postMessage(jsonData);
    }

    function _nativeCallResponse(jsonData, response) {
        jsonData.type = 'response';
        jsonData.data = response;
        _postMessage(jsonData);
    }

    setTimeout(() => {
        var doc = document;
        var readyEvent = doc.createEvent('Events');
        var jobs = window.WVJBCallbacks || [];
        readyEvent.initEvent('WebViewJavascriptBridgeReady');
        readyEvent.bridge = WebViewJavascriptBridge;
        delete window.WVJBCallbacks;
        for (var i = 0; i < jobs.length; i++) {
            var job = jobs[i];
            job(WebViewJavascriptBridge);
        }
        doc.dispatchEvent(readyEvent);
    }, 0);
})();
""";
String asyncjs = """
(function () {
    if (window.WebViewJavascriptBridge) {
        return;
    }

    class YGWebViewJavascriptBridge {
        constructor() {
            this.handlers = {};
            this.callbacks = {};
            this.index = 0;
            this.defaultHandler = null;
        }

        registerHandler(handlerName, handler) {
            this.handlers[handlerName] = handler;
        }

        async callHandler(handlerName, data) {
            if (arguments.length == 1) {
                data = null;
            }
            let result = await this.send(data, handlerName);
            return result;
        }

        async send(data, handlerName) {
            if (!data && !handlerName) {
                console.log('YGWebViewJavascriptBridge: data and handlerName can not both be null at the same in YGWebViewJavascriptBridge send method');
                return;
            }

            let message = {
                index: this.index,
                type: 'request',
            };
            if (data) {
                message.data = data;
            }
            if (handlerName) {
                message.handlerName = handlerName;
            }

            this._postMessage(message);
            let index = this.index;
            this.index += 1;
            return new Promise(resolve => this.callbacks[index] = resolve);
        }

        init(callback) {
            this.defaultHandler = callback;
        }

        _jsCallResponse(jsonData) {
            let index = jsonData.index;
            let callback = this.callbacks[index];
            delete this.callbacks[index];
            if (jsonData.type === 'response') {
                callback(jsonData.data);
            } else {
                console.log('YGWebViewJavascriptBridge: js call native error for request ', JSON.stringify(jsonData));
            }
        }

        _postMessage(jsonData) {
            let jsonStr = JSON.stringify(jsonData);
            let encodeStr = encodeURIComponent(jsonStr);
            YGFlutterJSBridgeChannel.postMessage(encodeStr);
        }

        nativeCall(message) {
            //here can't run immediately, wtf?
            setTimeout(() => this._nativeCall(message), 0);
        }

        async _nativeCall(message) {
            let decodeStr = decodeURIComponent(message);
            let jsonData = JSON.parse(decodeStr);

            if (jsonData.type === 'request') {
                if ('handlerName' in jsonData) {
                    let handlerName = jsonData.handlerName;
                    if (handlerName in this.handlers) {
                        let handler = this.handlers[jsonData.handlerName];
                        let data = await handler(jsonData.data);
                        this._nativeCallResponse(jsonData, data);
                    } else {
                        this._nativeCallError(jsonData);
                        console.log('YGWebViewJavascriptBridge: no handler for native call ', handlerName);
                    }
                } else {
                    if (this.defaultHandler) {
                        let data = await this.defaultHandler(jsonData.data);
                        this._nativeCallResponse(jsonData, data);
                    } else {
                        this._nativeCallError(jsonData);
                        console.log('YGWebViewJavascriptBridge: : no handler for native send');
                    }

                }
            } else if (jsonData.type === 'response' || jsonData.type === 'error') {
                this._jsCallResponse(jsonData);
            }
        }

        _nativeCallResponse(jsonData, response) {
            jsonData.data = response;
            jsonData.type = 'response';
            this._postMessage(jsonData);
        }

        _nativeCallError(jsonData) {
            jsonData.type = 'error';
            this._postMessage(jsonData);
        }
    }

    window.WebViewJavascriptBridge = new YGWebViewJavascriptBridge();

    setTimeout(() => {
        let doc = document;
        let readyEvent = doc.createEvent('Events');
        let jobs = window.WVJBCallbacks || [];
        readyEvent.initEvent('WebViewJavascriptBridgeReady');
        readyEvent.bridge = WebViewJavascriptBridge;
        delete window.WVJBCallbacks;
        for (let job of jobs) {
            job(WebViewJavascriptBridge);
        }
        doc.dispatchEvent(readyEvent);
    }, 0);
})();
""";