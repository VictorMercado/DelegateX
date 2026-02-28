import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

app.setActivationPolicy(.regular)

// Create a basic Main Menu so shortcuts like Cmd+C, Cmd+V work.
let mainMenu = NSMenu()
let appMenuItem = NSMenuItem()
mainMenu.addItem(appMenuItem)
let appMenu = NSMenu()
let quitMenuItem = NSMenuItem(title: "Quit CommandBuilder", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
appMenu.addItem(quitMenuItem)
appMenuItem.submenu = appMenu

let editMenuItem = NSMenuItem()
mainMenu.addItem(editMenuItem)
let editMenu = NSMenu(title: "Edit")
editMenuItem.submenu = editMenu
editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

app.mainMenu = mainMenu

app.activate(ignoringOtherApps: true)
app.run()
