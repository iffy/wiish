// DEV NOTE: After making any change to this file
//  - Run updateJNIheaders.sh
package org.wiish.exampleapp;

import java.lang.Thread;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebChromeClient;
import android.webkit.ConsoleMessage;
import android.webkit.WebResourceRequest;
import android.webkit.JavascriptInterface;
import android.widget.LinearLayout;
import android.widget.LinearLayout.LayoutParams;
import android.graphics.Bitmap;
import android.os.Message;
import android.util.Log;

// Log.d(TAG, "message");

/**
 * Functions to expose to the JavaScript within a Webview
 */
class WiishJsBridge {
	private WiishActivity activity;
	private String LOGID;

	public WiishJsBridge(WiishActivity initActivity, String LOGID) {
		activity = initActivity;
		LOGID = LOGID;
	}

	@JavascriptInterface
	public void log(final String message) {
		activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				Log.i(LOGID, message);
			}
		});
	}

	@JavascriptInterface
	public void sendMessageToNim(final String message) {
		activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				activity.wiish_sendMessageToNim(activity.windowId, message);
			}
		});
	}

	@JavascriptInterface
	public void signalJSIsReady() {		
		activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				activity.wiish_signalJSIsReady(activity.windowId);
			}
		});
	}
}

public class WiishActivity extends Activity {
	public static String LOGID = "org.wiish.webviewexample";

	static {
		System.loadLibrary("main");
	}

	public int windowId;

	// JNI stuff
	public native void wiish_init();
	public native int wiish_nextWindowId();
	public native void wiish_windowAdded(int windowId);
	public native String wiish_getInitURL();
	public native void wiish_sendMessageToNim(int windowId, String message);
	public native void wiish_signalJSIsReady(int windowId);

	public void evalJavaScript(final String js) {
		if (webView == null) {
			return;
		}
		if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
			webView.post(new Runnable() {
				@Override
				public void run() {
					WiishActivity.this.webView.evaluateJavascript(js, null);
				}
			});
		} else {
			// XXX This is untested
			webView.loadUrl("javascript:".concat(js));
		}
	}

	public final String getInternalStoragePath() {
		return this.getFilesDir().getAbsolutePath();
	}

	private WebView webView;

	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		Log.i(LOGID, "about to wiish_init()");
		wiish_init();
		// Log.i(LOGID, "end      wiish_init()");

		LinearLayout view = new LinearLayout(this);
		view.setLayoutParams(new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT));
		view.setOrientation(LinearLayout.VERTICAL);
		setContentView(view);
    
		// Log.i(LOGID, "A");

		webView = new WebView(this);

		// Log.i(LOGID, "A2");
		webView.setLayoutParams(new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
		// Log.i(LOGID, "A3");
		webView.setWebChromeClient(new WebChromeClient() {
			// @Override
			// public boolean onConsoleMessage(ConsoleMessage consoleMessage) {
				
			// }
		});

		// Log.i(LOGID, "B");

		// This multi-line string syntax is ridiculous
		final String javascript = ""
			+ "function initWiish() {"
			+ "  if (window.wiish && window.wiish._initialized) { return; }"
			+ "  console.log('wiish init');"
			//   Check to see if onReady is already installed
			+ "  let onReadyFunc;"
			+ "  if (window.wiish && window.wiish.onReady) {"
			+ "  	 onReadyFunc = window.wiish.onReady;"
			+ "  }"
			+ "  const readyrunner = {"
			+ "  	set: function(obj, prop, value) {"
			+ "     if (prop === 'onReady') { value(); wiishutil.signalJSIsReady(); }"
			+ "     obj[prop] = value;"
			+ "     return true;"
			+ "   }"
			+ "  };"
			+ "  window.wiish = new Proxy({}, readyrunner);"
			+ "  window.wiish.handlers = [];"
			//   Called by Nim code to transmit a message to JS
			+ "  window.wiish._handleMessage = function(message) {"
			+ "  	 for (var i = 0; i < window.wiish.handlers.length; i++) {"
			+ "      window.wiish.handlers[i](message);"
			+ "    }"
			+ "  };"
			//   Called by JS application code to watch for messages from Nim
			+ "  window.wiish.onMessage = function(handler) {"
			+ "    wiish.handlers.push(handler);"
			+ "  };"
			//   Called by JS application code to send messages to Nim
			+ "  window.wiish.sendMessage = function(message) {"
			+ "    wiishutil.sendMessageToNim(message);"
			+ "  };"
			//   Run any existing onReady function
			+ "  if (onReadyFunc) { window.wiish.onReady = onReadyFunc; }"
			+ "  window.wiish._initialized = true;"
			+ "}  "
			+ "initWiish();"
			+ "delete window.initWiish;"
			+ "";
		Log.i(LOGID, javascript);

		webView.setWebViewClient(new WebViewClient() {
			@Override
			public boolean shouldOverrideUrlLoading(WebView webView, String url) {
				return false;
			}
			// @Override
			// public void doUpdateVisitedHistory(WebView view, String url, boolean isReload) {
			// 		super.doUpdateVisitedHistory(view, url, isReload);
			// 		Log.i(LOGID, "doUpdateVisitedHistory: " + url);
			// }
			@Override
			public void onPageFinished(WebView view, String url) {
				super.onPageFinished(view, url);
				// Log.i(LOGID, "Adding standard header JS to: " + url);
				// Log.i(LOGID, "Original URL: " + view.getOriginalUrl());
				// Log.i(LOGID, "getURL:       " + view.getUrl());
				try {
					WiishActivity.this.evalJavaScript(javascript);
				} catch(Exception e) {
					Log.i(LOGID, "Error adding header JS: " + e.toString());
					throw e;
				}
				// Log.i(LOGID, "Added standard header JS");
			}
		});
		webView.getSettings().setJavaScriptEnabled(true);
		webView.addJavascriptInterface(new WiishJsBridge(this, LOGID), "wiishutil");
		webView.loadUrl(wiish_getInitURL());
		view.addView(webView);

		// Log.i(LOGID, "D");

		// Log.i(LOGID, "about to wiish_nextWindowId()");
		windowId = wiish_nextWindowId();
		// Log.i(LOGID, "E");
		// Log.i(LOGID, "windowId = " + windowId);
		wiish_windowAdded(windowId);
		// Log.i(LOGID, "F");
	}
}
