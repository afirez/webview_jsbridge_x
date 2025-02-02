/* eslint-disable */
let isAndroid = navigator.userAgent.indexOf('Android') > -1 || navigator.userAgent.indexOf('Adr') > -1
let isiOS = !!navigator.userAgent.match(/\(i[^;]+;( U;)? CPU.+Mac OS X/)

function setupWebViewJavascriptBridge(callback) {
  if (window.WebViewJavascriptBridge) { return callback(WebViewJavascriptBridge); }
  if (window.WVJBCallbacks) { return window.WVJBCallbacks.push(callback); }
  window.WVJBCallbacks = [callback];

  //only take effect on iOS
  var WVJBIframe = document.createElement('iframe');
  WVJBIframe.style.display = 'none';
  WVJBIframe.src = 'https://__bridge_loaded__';
  document.documentElement.appendChild(WVJBIframe);
  setTimeout(function () { document.documentElement.removeChild(WVJBIframe) }, 0)
}

setupWebViewJavascriptBridge(function (bridge) {
  console.log('setupWebViewJavascriptBridge done');
  bridge.init(function (data, responseCallback) {
      console.log('defaultHandler get data ', data);
      var res = 'defaultHandler res from js';
      responseCallback(res);
  });

  bridge.registerHandler('JSEcho', function (data, responseCallback) {
      console.log("JSEcho get data ", data);
      var res = 'JSEcho res from js';
      responseCallback(res);
  });
});

if (window.WebViewJavascriptBridge) {
  console.log('WebViewJavascriptBridge done when body load');
} else {
  document.addEventListener(
      'WebViewJavascriptBridgeReady'
      , function () {
          console.log('WebViewJavascriptBridge done after WebViewJavascriptBridgeReady');
          //here will take effect on both Android and iOS
          //init or registerHandler bellow
          // WebViewJavascriptBridge.init(function (message, responseCallback) {
          //     console.log('defaultHandler JS got a message', message);
          //     let data = {
          //         'Javascript Responds': 'defaultHandler Wee!'
          //     };
          //     console.log('defaultHandler JS responding with', data);
          //     responseCallback(data);
          // });

          // WebViewJavascriptBridge.registerHandler('JSEcho', function (data, responseCallback) {
          //     console.log("JS Echo called with:", data);
          //     responseCallback(data);
          // });
      },
      false
  );
}

function sendHello() {
  window.WebViewJavascriptBridge.send(
      'hello', function (responseData) {
          console.log("sendHello res ", responseData);
      }
  );
}
function callNativeEcho() {
  window.WebViewJavascriptBridge.callHandler('NativeEcho', 'callNative from js', function (responseData) {
      console.log("callNativeEcho res ", responseData);
  });
}

function callNotExistHandler() {
  window.WebViewJavascriptBridge.callHandler('NotExist', 'callNative from js', function (responseData) {
      console.log("callNotExistHandler res ", responseData);
  });
}

export default {
  // js调APP方法 （参数分别为:app提供的方法名  传给app的数据  回调）
  callHandler (name, data, callback) {
    setupWebViewJavascriptBridge(function (bridge) {
      bridge.callHandler(name, data, callback)
    })
  },
  // APP调js方法 （参数分别为:js提供的方法名  回调）
  registerHandler (name, callback) {
    setupWebViewJavascriptBridge(function (bridge) {
      bridge.registerHandler(name, function (data, responseCallback) {
        callback(data, responseCallback)
      })
    })
  }
}

