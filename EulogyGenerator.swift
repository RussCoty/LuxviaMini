import Foundation

protocol EulogyGenerator {
    func generate(from form: EulogyForm) async throws -> String
}

final class TemplateGenerator: EulogyGenerator {
    func generate(from f: EulogyForm) async throws -> String {
        let name = f.subjectName ?? "your loved one"
        let rel = f.relationship ?? "loved one"

        let pronoun: (subj: String, obj: String, poss: String, reflex: String) = {
            switch f.pronouns {
            case .she: return ("she", "her", "her", "herself")
            case .he:  return ("he", "him", "his", "himself")
            case .they:return ("they", "them", "their", "themself")
            }
        }()

        func para(_ s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines) + "\n\n" }

        let opening: String = {
            switch f.tone {
            case .solemn: return "We gather today to honour the life of \(name), a cherished \(rel) whose presence shaped our days in quiet, meaningful ways."
            case .warm: return "Today we celebrate \(name) — a beloved \(rel) remembered for warmth, kindness, and the little moments that meant the most."
            case .celebratory: return "This is a celebration of \(name)’s life: the laughter, the generosity, and the countless ripples of good \(pronoun.subj) set in motion."
            case .humorous: return "If \(name) were here, \(pronoun.subj) would probably raise an eyebrow at all this fuss — and then crack a joke to make us smile."
            }
        }()

        let traits = f.traits.isEmpty ? "" : "\(name) will be remembered as " + f.traits.joined(separator: ", ") + "."
        let hobbies = f.hobbies.isEmpty ? "" : "Favourite pastimes included " + f.hobbies.joined(separator: ", ") + "."
        let achievements = f.achievements.isEmpty ? "" : "\(pronoun.poss.capitalized) proudest milestones: " + f.achievements.joined(separator: ", ") + "."

        let anecdotes = f.anecdotes.isEmpty ? "" :
        "Stories we’ll keep close:\n" + f.anecdotes.map { "• \($0)" }.joined(separator: "\n")

        let beliefs = (f.beliefsOrRituals?.isEmpty == false)
            ? "In keeping with \(name)’s wishes and beliefs (\(f.beliefsOrRituals!)), we give thanks for a life well lived."
            : ""

        let closing: String = {
            switch f.tone {
            case .solemn:
                return "Though grief is deep, love is deeper. We say goodbye with gratitude, carrying \(name)’s memory gently into tomorrow."
            case .warm:
                return "We’ll carry \(name)’s light forward — in kindness given freely, in time spent together, and in the stories we keep telling."
            case .celebratory:
                return "Let us honour \(name) by living generously — laughing loudly, loving boldly, and showing up for one another."
            case .humorous:
                return "And in true \(name) fashion, let’s leave with a smile — because that’s exactly what \(pronoun.subj) would have wanted."
            }
        }()

        let bodyPieces = [traits, hobbies, achievements, anecdotes, beliefs].filter { !$0.isEmpty }
        let shapedBody: String = {
            switch f.length {
            case .short:    return bodyPieces.prefix(2).joined(separator: " ")
            case .standard: return bodyPieces.prefix(4).joined(separator: " ")
            case .long:     return bodyPieces.joined(separator: " ")
            }
        }()

        return para(opening) + para(shapedBody) + closing
    }
}
