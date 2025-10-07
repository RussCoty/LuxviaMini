import SwiftUI

struct EulogyChatView: View {
    @StateObject private var engine = EulogyChatEngine()
    @State private var input = ""
    @State private var isSending = false

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(engine.messages) { msg in
                            MessageBubble(message: msg)
                                .id(msg.id)
                        }
                        if engine.isThinking {
                            TypingBubble()
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
                }
                .onChange(of: engine.messages) { _ in
                    if let last = engine.messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                }
            }
            inputBar
        }
        .background(Color(.systemGroupedBackground))
    }

    private var header: some View {
        HStack {
            Circle().fill(Color.green.opacity(0.85)).frame(width: 8, height: 8)
            Text("luxviaMini • Eulogy Assistant").font(.headline)
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                TextEditor(text: $input)
                    .padding(8)
                    .frame(minHeight: 40, maxHeight: 120)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .disableAutocorrection(false)
                    .textInputAutocapitalization(.sentences)
            }
            .frame(minHeight: 40, maxHeight: 120)

            Button {
                send()
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .padding(.all, 12)
        .background(.thinMaterial)
    }

    private func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        input = ""
        isSending = true
        engine.send(text)
        DispatchQueue.main.async { isSending = false }
    }
}

private struct MessageBubble: View {
    let message: ChatMessage
    var body: some View {
        HStack(alignment: .bottom) {
            if message.role == .user { Spacer() }
            VStack(alignment: .leading, spacing: 6) {
                if message.role == .draft {
                    Text("Draft eulogy").font(.caption).foregroundColor(.secondary)
                }
                Text(message.text)
                    .font(message.role == .draft ? .body : .callout)
                    .foregroundStyle(message.role == .user ? .white : .primary)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(message.role == .user ? Color.accentColor : Color(.secondarySystemBackground))
                    )
            }
            if message.role != .user { Spacer() }
        }
    }
}

private struct TypingBubble: View {
    var body: some View {
        HStack {
            ProgressView().scaleEffect(0.8)
            Text("Thinking…").foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 8)
    }
}
