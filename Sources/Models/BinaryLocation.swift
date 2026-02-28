import Foundation
import SwiftData

@Model
final class BinaryLocation {
    var id: UUID
    var name: String
    var path: String

    init(name: String, path: String) {
        self.id = UUID()
        self.name = name
        self.path = path
    }
}
