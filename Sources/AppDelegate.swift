import AppKit
import SwiftData

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var sharedModelContainer: ModelContainer?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        do {
            sharedModelContainer = try ModelContainer(for: CommandItem.self, CommandParameter.self, BinaryLocation.self)
        } catch {
            print("Failed to initialize SwiftData model container: \(error)")
        }

        let splitVC = MainSplitViewController()
        if let container = sharedModelContainer {
            splitVC.modelContainer = container
        }

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false)

        window.center()
        window.title = "CommandBuilder"
        window.contentViewController = splitVC
        window.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
