import Foundation
import Combine
import CoreML

@MainActor
final class EulogyChatEngine: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var form = EulogyForm()
    @Published var isThinking = false

    private let generator: EulogyGenerator
    private let classifier: LuxSlotClassifier

    init(generator: EulogyGenerator = TemplateGenerator()) {
        print("EulogyChatEngine initialized")
        self.generator = generator
        self.classifier = try! LuxSlotClassifier(configuration: MLModelConfiguration())
        start()
    }

    func start() {
        print("EulogyChatEngine.start called")
        messages = [
            .init(role: .assistant, text:
"""
I’m here to help you compose a respectful, personal eulogy.

To begin, could you share the person’s **full name** and **your relationship** to them?
You can also tell me anything that feels important — personality, hobbies, a story you love — and I’ll guide you gently.
""")
        ]
    }

    func send(_ text: String) {
        print("send called with text: \(text)")
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        messages.append(.init(role: .user, text: text))
        Task { await handle(text) }
    }

    private func handle(_ text: String) async {
        print("handle called with text: \(text)")
        isThinking = true
        defer { isThinking = false }

        var label = "unknown"
        var probs: [String: Double] = [:]
        do {
            let res = try classifier.prediction(text: text)
            label = res.label
            print("Classifier label: \(label)")
            let probKeys = ["labelProbability", "labelProbabilities", "classLabelProbs"]
            outer: for key in probKeys {
                if let fv = res.featureValue(for: key) {
                    for (k, v) in fv.dictionaryValue {
                        if let s = k as? String { probs[s] = v.doubleValue }
                    }
                    if !probs.isEmpty { break outer }
                }
            }
        } catch {
            // fall back
        }

        applyHeuristics(from: text)
        applyLabel(label, with: text)

        if form.isReadyForDraft {
            do {
                let draft = try await generator.generate(from: form)
                messages.append(.init(role: .draft, text: draft))
                messages.append(.init(role: .assistant, text:
"""
Would you like any edits? I can adjust **tone** (\(EulogyTone.allCases.map{$0.rawValue}.joined(separator:", "))), **length** (\(EulogyLength.allCases.map{$0.rawValue}.joined(separator:", "))), add/remove **stories**, or include **religious/humanist** elements.
"""))
            } catch {
                messages.append(.init(role: .assistant, text: "I hit a snag generating the draft — please try again."))
            }
            return
        }

        messages.append(.init(role: .assistant, text: nextQuestion()))
    }

    private func applyLabel(_ label: String, with text: String) {
        let lower = label.lowercased()
        switch true {
        case lower.contains("name"):
            if form.subjectName == nil { form.subjectName = extractLikelyName(from: text) ?? text }
        case lower.contains("relationship") || lower.contains("relation"):
            if form.relationship == nil { form.relationship = text }
            if form.pronouns == .they { inferPronouns(from: text) }
        case lower.contains("trait"):
            form.traits.append(text)
        case lower.contains("hobby") || lower.contains("interest"):
            form.hobbies.append(text)
        case lower.contains("anecdote") || lower.contains("story"):
            form.anecdotes.append(text)
        case lower.contains("achievement") || lower.contains("milestone"):
            form.achievements.append(text)
        case lower.contains("belief") || lower.contains("faith") || lower.contains("ritual"):
            form.beliefsOrRituals = text
        case lower.contains("tone"):
            if text.range(of: "solemn", options: .caseInsensitive) != nil { form.tone = .solemn }
            else if text.range(of: "celebrat", options: .caseInsensitive) != nil { form.tone = .celebratory }
            else if text.range(of: "humor|humour|light", options: [.caseInsensitive, .regularExpression]) != nil { form.tone = .humorous }
            else { form.tone = .warm }
        case lower.contains("length") || lower.contains("duration"):
            if text.range(of: "short|3 ?min", options: [.caseInsensitive, .regularExpression]) != nil { form.length = .short }
            else if text.range(of: "long|7 ?min|10 ?min", options: [.caseInsensitive, .regularExpression]) != nil { form.length = .long }
            else { form.length = .standard }
        default:
            break
        }
    }

    private func applyHeuristics(from text: String) {
        inferPronouns(from: text)
        if form.subjectName == nil, let n = extractLikelyName(from: text) { form.subjectName = n }
        if form.relationship == nil,
           text.range(of: "(mother|mum|mom|father|dad|grand|friend|partner|wife|husband|colleague)", options: [.regularExpression, .caseInsensitive]) != nil {
            form.relationship = text
        }
    }

    private func inferPronouns(from text: String) {
        let lower = " " + text.lowercased() + " "
        if lower.contains(" she ") { form.pronouns = .she }
        else if lower.contains(" he ") { form.pronouns = .he }
    }

    private func extractLikelyName(from text: String) -> String? {
        let pattern = #"\b([A-Z][a-z]+(?:\s[A-Z][a-z]+)+)\b"#
        if let r = try? NSRegularExpression(pattern: pattern),
           let m = r.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(m.range(at: 1), in: text) {
            return String(text[range])
        }
        return nil
    }

    private func nextQuestion() -> String {
        if form.subjectName == nil { return "What was their **full name**?" }
        if form.relationship == nil { return "And how were you **related**?" }
        if form.traits.isEmpty { return "Tell me a few **qualities** that capture them (e.g., generous, determined, patient)." }
        if form.hobbies.isEmpty { return "What did they **love doing** — hobbies, passions, rituals?" }
        if form.anecdotes.isEmpty { return "Could you share **one short story** that friends/family always mention?" }
        if form.beliefsOrRituals == nil { return "Should we include any **religious or humanist** elements?" }
        return "Would you like a **warm**, **solemn**, **celebratory**, or **light/humorous** tone, and roughly **short/standard/long** length?"
    }
}
