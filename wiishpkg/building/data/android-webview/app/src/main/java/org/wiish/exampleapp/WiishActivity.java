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


class WiishJsBridge {

	private WiishActivity activity;

	public WiishJsBridge(WiishActivity initActivity) {
		activity = initActivity;
	}

	@JavascriptInterface
	public void sendMessageToNim(String message) {
		Log.d("org.wiish.webviewexample", "JAVA sendMessageToNim: " + message + " thread: " +  Thread.currentThread().getName() + " " + Thread.currentThread().getId());
		activity.wiish_sendMessageToNim(message);
	}

	@JavascriptInterface
	public void signalJSIsReady() {
		Log.d("org.wiish.webviewexample", "JAVA signalJSIsReady thread: " + Thread.currentThread().getName() + " " + Thread.currentThread().getId());
		activity.wiish_signalJSIsReady();
	}
}

public class WiishActivity extends Activity {
	static {
		System.loadLibrary("main");
	}

	// JNI stuff
	public native void wiish_init();
	public native String wiish_getInitURL();
	public native void wiish_sendMessageToNim(String message);
	public native void wiish_signalJSIsReady();

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

	private WebView webView;

	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

		LinearLayout view = new LinearLayout(this);
		view.setLayoutParams(new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT));
		view.setOrientation(LinearLayout.VERTICAL);
		setContentView(view);
        
		webView = new WebView(this);
		webView.setLayoutParams(new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
		webView.setWebChromeClient(new WebChromeClient() {
			// @Override
			// public boolean onConsoleMessage(ConsoleMessage consoleMessage) {
				
			// }
		});

		// This multi-line string syntax is ridiculous
		final String javascript = ""
			+ "const readyrunner = {"
			+ "	set: function(obj, prop, value) {"
			+ "   if (prop === 'onReady') { value(); }"
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
			+ "if (onReadyFunc) { onReadyFunc(); }"
			+ "wiishutil.signalJSIsReady();"
			+ "";

		wiish_init();
		// wiish_sendMessageToNim("Test message");

		webView.setWebViewClient(new WebViewClient() {
			@Override
			public boolean shouldOverrideUrlLoading(WebView webView, String url) {
				return false;
			}
			@Override
			public void onPageFinished(WebView view, String url) {
				super.onPageFinished(view, url);
				Log.d("org.wiish.webviewexample", "JAVA onPageFinished " + Thread.currentThread().getName() + " " + Thread.currentThread().getId());
				WiishActivity.this.evalJavaScript(javascript);
			}
		});
		webView.getSettings().setJavaScriptEnabled(true);
		webView.addJavascriptInterface(new WiishJsBridge(this), "wiishutil");
		webView.loadUrl(wiish_getInitURL());
		view.addView(webView);
		Log.d("org.wiish.webviewexample", "JAVA addView done: " + Thread.currentThread().getName() + " " + Thread.currentThread().getId());
	}
}
