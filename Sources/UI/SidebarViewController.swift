import AppKit

enum SidebarItem: String, CaseIterable {
    case home = "Home / Commands"
    case binaries = "Binaries Scanner"
}

class SidebarViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    let tableView = NSTableView()
    let scrollView = NSScrollView()
    let items = SidebarItem.allCases
    var onSelectionChange: ((SidebarItem) -> Void)?

    override func loadView() {
        self.view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("SidebarColumn"))
        column.width = 200
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.delegate = self
        tableView.dataSource = self
        tableView.style = .sourceList

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return items.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("SidebarCell")
        var cell = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView

        if cell == nil {
            cell = NSTableCellView()
            cell?.identifier = identifier
            let textField = NSTextField(labelWithString: "")
            textField.translatesAutoresizingMaskIntoConstraints = false
            cell?.addSubview(textField)
            cell?.textField = textField

            NSLayoutConstraint.activate([
                textField.centerYAnchor.constraint(equalTo: cell!.centerYAnchor),
                textField.leadingAnchor.constraint(equalTo: cell!.leadingAnchor, constant: 10),
                textField.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -10)
            ])
        }

        cell?.textField?.stringValue = items[row].rawValue
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = tableView.selectedRow
        if selectedRow >= 0 {
            onSelectionChange?(items[selectedRow])
        }
    }
}
