// Nim functions defined in webview_ios.nim that are made available to Objective-C code
char* jsbridgecode(void);
char* getInitURL(void);
int nim_nextWindowId(void);
void nim_iterateLoop(void);
void nim_windowCreated(int windowId, void* controller);
void doLog(char* x);
void nim_didFinishLaunching(void);
void nim_windowWillBackground(int windowId);
void nim_windowWillForeground(int windowId);
void nim_windowDidForeground(int windowId);
void nim_applicationWillTerminate(void);
void nim_signalJSMessagesReady(int windowId);
void nim_sendMessageToNim(int windowId, char* x);
