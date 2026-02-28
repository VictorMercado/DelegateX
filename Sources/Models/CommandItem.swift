import Foundation
import SwiftData

@Model
final class CommandItem {
    var id: UUID
    var name: String
    var template: String
    var workingDirectory: String

    @Relationship(deleteRule: .cascade)
    var parameters: [CommandParameter]

    init(name: String, template: String, workingDirectory: String = FileManager.default.currentDirectoryPath) {
        self.id = UUID()
        self.name = name
        self.template = template
        self.workingDirectory = workingDirectory
        self.parameters = []
    }
}

@Model
final class CommandParameter {
    var id: UUID
    var label: String
    var value: String
    var order: Int
    var item: CommandItem?

    init(label: String, value: String, order: Int) {
        self.id = UUID()
        self.label = label
        self.value = value
        self.order = order
    }
}
