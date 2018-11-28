package org.wiish.exampleapp;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.widget.LinearLayout;
import android.widget.LinearLayout.LayoutParams;
import android.os.Message;

public class WiishActivity extends Activity {
	static {
		System.loadLibrary("main");
	}

	// JNI stuff
	public native void wiish_init();
	public native String wiish_getInitURL();


	private WebView webView;

	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		wiish_init();

		LinearLayout view = new LinearLayout(this);
		view.setLayoutParams(new LayoutParams(LayoutParams.FILL_PARENT, LayoutParams.FILL_PARENT));
		view.setOrientation(LinearLayout.VERTICAL);
		setContentView(view);
		// setContentView(R.layout.webview);
        
		webView = new WebView(this);
		webView.setLayoutParams(new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
		// webView.setWebChromeClient(new WebChromeClient() {
		// 	@Override
		// 	public boolean onCreateWindow(WebView view, boolean dialog, boolean userGesture, Message resultMsg)
		// 	{
		// 		return true;
		// 	}
		// 	// @Override
		// 	// public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
		// 	// 	view.loadUrl("https://www.google.com");
		// 	// 	return false;
		// 	// }
		// });
		// (WebView) findViewById(R.id.webView1);
		// webView.setLayoutParams()
		webView.setWebViewClient(new WebViewClient() {
			@Override
			public boolean shouldOverrideUrlLoading(WebView webView, String url) {
				return false;
			}
		});
		webView.getSettings().setSupportMultipleWindows(false);
		webView.getSettings().setJavaScriptEnabled(true);
		//webView.loadUrl("http://www.google.com");
		webView.loadUrl(wiish_getInitURL());
		view.addView(webView);
	}
}
