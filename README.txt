Conflict-Free Setup

- This pack avoids a 'ContentView' type to prevent 'Invalid redeclaration of ContentView' errors.
- Use EulogyRootView() as your app's root, or EulogyDevRootView() if you want a tab with both the chat and the model test.
- If your project still contains a file that defines 'struct ContentView: View', either delete it or rename it to 'ModelTestView'. Then update LuxviaMiniApp.swift accordingly.

How to wire the entry point (App):
----------------------------------
Replace the WindowGroup content with one of these:

    EulogyRootView()
    // or, for a dev tab:
    EulogyDevRootView()

Then clean build (Shift+Cmd+K) and build again.


Hello
