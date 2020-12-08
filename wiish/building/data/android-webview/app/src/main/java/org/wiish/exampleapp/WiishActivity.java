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

	public WiishJsBridge(WiishActivity initActivity) {
		activity = initActivity;
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

		// Log.i("org.wiish.webviewexample", "about to wiish_init()");
		wiish_init();
		// Log.i("org.wiish.webviewexample", "end      wiish_init()");

		LinearLayout view = new LinearLayout(this);
		view.setLayoutParams(new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT));
		view.setOrientation(LinearLayout.VERTICAL);
		setContentView(view);
    
		// Log.i("org.wiish.webviewexample", "A");

		webView = new WebView(this);

		// Log.i("org.wiish.webviewexample", "A2");
		webView.setLayoutParams(new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
		// Log.i("org.wiish.webviewexample", "A3");
		webView.setWebChromeClient(new WebChromeClient() {
			// @Override
			// public boolean onConsoleMessage(ConsoleMessage consoleMessage) {
				
			// }
		});

		// Log.i("org.wiish.webviewexample", "B");

		// This multi-line string syntax is ridiculous
		final String javascript = ""
			+ "const readyrunner = {"
			+ "	set: function(obj, prop, value) {"
			+ "   if (prop === 'onReady') { value(); wiishutil.signalJSIsReady(); }"
			+ "   obj[prop] = value;"
			+ "   return true;"
			+ " }"
			+ "};"
			// Check to see if onReady is already installed
			+ "let onReadyFunc;"
			+ "if (window.wiish && window.wiish.onReady) {"
			+ "	 onReadyFunc = window.wiish.onReady;"
			+ "}"
			+ "window.wiish = new Proxy({}, readyrunner);"
			+ "window.wiish.handlers = [];"
			// Called by Nim code to transmit a message to JS
			+ "window.wiish._handleMessage = function(message) {"
			+ "	 for (var i = 0; i < window.wiish.handlers.length; i++) {"
			+ "    window.wiish.handlers[i](message);"
			+ "  }"
			+ "};"
			// Called by JS application code to watch for messages from Nim
			+ "window.wiish.onMessage = function(handler) {"
			+ "  wiish.handlers.push(handler);"
			+ "};"
			// Called by JS application code to send messages to Nim
			+ "window.wiish.sendMessage = function(message) {"
			+ "  wiishutil.sendMessageToNim(message);"
			+ "};"
			// Run any existing onReady function
			+ "if (onReadyFunc) { window.wiish.onReady = onReadyFunc; }"
			+ "";

		webView.setWebViewClient(new WebViewClient() {
			@Override
			public boolean shouldOverrideUrlLoading(WebView webView, String url) {
				return false;
			}
			@Override
			public void onPageFinished(WebView view, String url) {
				super.onPageFinished(view, url);
				WiishActivity.this.evalJavaScript(javascript);
			}
		});
		// Log.i("org.wiish.webviewexample", "C");
		webView.getSettings().setJavaScriptEnabled(true);
		webView.addJavascriptInterface(new WiishJsBridge(this), "wiishutil");
		webView.loadUrl(wiish_getInitURL());
		view.addView(webView);

		// Log.i("org.wiish.webviewexample", "D");

		// Log.i("org.wiish.webviewexample", "about to wiish_nextWindowId()");
		windowId = wiish_nextWindowId();
		// Log.i("org.wiish.webviewexample", "E");
		// Log.i("org.wiish.webviewexample", "windowId = " + windowId);
		wiish_windowAdded(windowId);
		// Log.i("org.wiish.webviewexample", "F");
	}
}
