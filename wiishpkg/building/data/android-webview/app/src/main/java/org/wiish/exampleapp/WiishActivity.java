package org.wiish.exampleapp;

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
	public String echo(String message) {
		return message;
	}
	@JavascriptInterface
	public void sendMessage(String message) {
		activity.wiish_sendMessage(message);
	}
}

public class WiishActivity extends Activity {
	static {
		System.loadLibrary("main");
	}

	// JNI stuff
	public native void wiish_init();
	public native String wiish_getInitURL();
	public native void wiish_sendMessage(String message);

	public void evalJavaScript(String js) {
		if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
			webView.evaluateJavascript(js, null);
		} else {
			// XXX This is untested
			webView.loadUrl("javascript:".concat(js));
		}
	}

	private WebView webView;

	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		wiish_init();
		wiish_sendMessage("Test message");

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
			+ "window.wiish = {};"
			+ "window.wiish.handlers = [];"
			+ "window.wiish._handleMessage = function(message) {"
			+ "	 for (var i = 0; i < window.wiish.handlers.length; i++) {"
			+ "    window.wiish.handlers[i](message);"
			+ "  }"
			+ "};"
			+ "window.wiish.onMessage = function(handler) {"
			+ "  wiish.handlers.push(handler);"
			+ "};"
			+ "window.wiish.sendMessage = function(message) {"
			+ "  wiishutil.sendMessage(message);"
			+ "};"
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
		//webView.getSettings().setSupportMultipleWindows(false);
		webView.getSettings().setJavaScriptEnabled(true);
		webView.addJavascriptInterface(new WiishJsBridge(this), "wiishutil");
		// webView.loadData("", "text/html", null);
		webView.loadUrl(wiish_getInitURL());
		//webView.loadUrl("javascript:alert(wiishthing.hello())");
		view.addView(webView);
	}
}
