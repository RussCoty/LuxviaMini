import Foundation

enum EulogyTone: String, Codable, CaseIterable { case solemn, warm, celebratory, humorous }
enum EulogyLength: String, Codable, CaseIterable { case short, standard, long }
enum Pronouns: String, Codable { case she, he, they }

struct EulogyForm: Codable {
    var subjectName: String?
    var relationship: String?
    var pronouns: Pronouns = .they
    var tone: EulogyTone = .warm
    var length: EulogyLength = .standard

    var traits: [String] = []
    var hobbies: [String] = []
    var anecdotes: [String] = []
    var achievements: [String] = []
    var beliefsOrRituals: String?

    var audienceNotes: String?

    var isReadyForDraft: Bool {
        subjectName != nil &&
        relationship != nil &&
        !traits.isEmpty &&
        (!hobbies.isEmpty || !anecdotes.isEmpty)
    }
}

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: Role
    let text: String
    enum Role { case user, assistant, draft }
}
