/* eslint-disable */
let isAndroid = navigator.userAgent.indexOf('Android') > -1 || navigator.userAgent.indexOf('Adr') > -1
let isiOS = !!navigator.userAgent.match(/\(i[^;]+;( U;)? CPU.+Mac OS X/)

function setupWebViewJavascriptBridge(callback) {
  if (window.WebViewJavascriptBridge) { return callback(WebViewJavascriptBridge); }
  if (window.WVJBCallbacks) { return window.WVJBCallbacks.push(callback); }
  window.WVJBCallbacks = [callback];

  //only take effect on iOS
  let WVJBIframe = document.createElement('iframe');
  WVJBIframe.style.display = 'none';
  WVJBIframe.src = 'https://__bridge_loaded__';
  document.documentElement.appendChild(WVJBIframe);
  setTimeout(function () { document.documentElement.removeChild(WVJBIframe) }, 0)
}
setupWebViewJavascriptBridge(function (bridge) {
  console.log('setupWebViewJavascriptBridge done');
  async function defaultHandler(data) {
      console.log('defaultHandler get data ', data);
      return new Promise(resolve => {
          let res = 'defaultHandler res from js';
          setTimeout(() => resolve(res), 0);
      });
  }

  bridge.init(defaultHandler);

  async function JSEcho(data) {
      console.log("JSEcho get data ", data);
      let res = 'JSEcho res from js';
      return new Promise(resolve => setTimeout(() => resolve(res), 0));
  }

  bridge.registerHandler('JSEcho', JSEcho);
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
          // async function defaultHandler(message) {
          //     console.log('defaultHandler JS got a message', message);
          //     return new Promise(resolve => {
          //         let data = {
          //             'Javascript Responds': 'defaultHandler Wee!'
          //         };
          //         console.log('defaultHandler JS responding with', data);
          //         setTimeout(() => resolve(data), 0);
          //     });
          // }

          // WebViewJavascriptBridge.init(defaultHandler);

          // async function JSEcho(data) {
          //     console.log("JS Echo called with:", data);
          //     return new Promise(resolve => setTimeout(() => resolve(data), 0));
          // }

          // WebViewJavascriptBridge.registerHandler('JSEcho', JSEcho);
      },
      false
  );
}

async function sendHello() {
  let responseData = await window.WebViewJavascriptBridge.send('hello');
  console.log("sendHello res ", responseData);
}

async function callNativeEcho() {
  let responseData = await window.WebViewJavascriptBridge.callHandler('NativeEcho', 'callNative from js');
  console.log("callNativeEcho res ", responseData);
}

async function callNotExistHandler() {
  let responseData = await window.WebViewJavascriptBridge.callHandler('NotExist', 'callNative from js');
  console.log("callNotExistHandler res ", responseData);
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

