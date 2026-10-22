# libhev-socks5-tunnel's JNI_OnLoad registers natives on this class by name, and fails
# if any of them is missing, so R8 must neither rename nor remove its members.
-keep class com.example.share_link.TProxyService { *; }
