// Nim functions defined in webview_ios.nim that are made available to Objective-C code
void nim_sendMessageToNim(char* x);
void nim_signalJSMessagesReady();
char* jsbridgecode();
char* getInitURL();
void registerWiishController(void* controller);
void doLog(char* x);
void nim_didFinishLaunching();
void nim_applicationWillResignActive();
void nim_applicationDidEnterBackground();
void nim_applicationWillEnterForeground();
void nim_applicationDidBecomeActive();
void nim_applicationWillTerminate();
void nim_signalJSMessagesReady();