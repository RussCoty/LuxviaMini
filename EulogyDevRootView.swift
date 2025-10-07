import SwiftUI

struct EulogyDevRootView: View {
    var body: some View {
        TabView {
            EulogyChatView()
                .tabItem { Label("Eulogy", systemImage: "text.book.closed") }
            ModelTestView()
                .tabItem { Label("Model Test", systemImage: "waveform") }
        }
    }
}

#Preview { EulogyDevRootView() }
