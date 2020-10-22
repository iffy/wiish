// Nim functions defined in webview_ios.nim that are made available to Objective-C code
char* jsbridgecode();
char* getInitURL();
int nim_nextWindowId();
void nim_windowCreated(int windowId, void* controller);
void doLog(char* x);
void nim_didFinishLaunching();
void nim_windowWillBackground(int windowId);
void nim_windowWillForeground(int windowId);
void nim_windowDidForeground(int windowId);
void nim_applicationWillTerminate();
void nim_signalJSMessagesReady(int windowId);
void nim_sendMessageToNim(int windowId, char* x);
