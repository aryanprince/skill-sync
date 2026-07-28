import Foundation

enum CommandLineParser {
    static func parse(_ command: String) -> [String] {
        var result: [String] = []
        var current = ""
        var quote: Character?
        var isEscaping = false

        for character in command {
            if isEscaping {
                current.append(character)
                isEscaping = false
                continue
            }
            if character == "\\" && quote != "'" {
                isEscaping = true
                continue
            }
            if let activeQuote = quote {
                if character == activeQuote {
                    quote = nil
                } else {
                    current.append(character)
                }
                continue
            }
            if character == "\"" || character == "'" {
                quote = character
            } else if character.isWhitespace {
                if !current.isEmpty {
                    result.append(current)
                    current = ""
                }
            } else {
                current.append(character)
            }
        }
        if isEscaping {
            current.append("\\")
        }
        if !current.isEmpty {
            result.append(current)
        }
        return result
    }
}
