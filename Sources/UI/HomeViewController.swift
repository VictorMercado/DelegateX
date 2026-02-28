import AppKit
import SwiftData

class HomeViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    var modelContainer: ModelContainer?
    var commands: [CommandItem] = []

    let tableView = NSTableView()
    let scrollView = NSScrollView()
    let addButton = NSButton(title: "Add Command", target: nil, action: nil)
    let deleteButton = NSButton(title: "Delete", target: nil, action: nil)

    let detailContainerView = NSView()
    var currentDetailVC: CommandEditorViewController?

    override func loadView() {
        self.view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchCommands()

        addButton.target = self
        addButton.action = #selector(addCommand)
        deleteButton.target = self
        deleteButton.action = #selector(deleteCommand)
    }

    func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        detailContainerView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        view.addSubview(addButton)
        view.addSubview(deleteButton)
        view.addSubview(detailContainerView)

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("CommandColumn"))
        column.title = "Commands"
        tableView.addTableColumn(column)
        tableView.delegate = self
        tableView.dataSource = self
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            scrollView.widthAnchor.constraint(equalToConstant: 200),
            scrollView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -10),

            addButton.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            addButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),

            deleteButton.leadingAnchor.constraint(equalTo: addButton.trailingAnchor, constant: 10),
            deleteButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),

            detailContainerView.leadingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: 10),
            detailContainerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            detailContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            detailContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10)
        ])
    }

    func fetchCommands() {
        guard let context = modelContainer?.mainContext else { return }
        let descriptor = FetchDescriptor<CommandItem>(sortBy: [SortDescriptor(\.name)])
        do {
            commands = try context.fetch(descriptor)
            tableView.reloadData()
        } catch {
            print("Failed to fetch commands: \(error)")
        }
    }

    @objc func addCommand() {
        guard let context = modelContainer?.mainContext else { return }
        let newCommand = CommandItem(name: "New Command", template: "echo {}")
        context.insert(newCommand)
        try? context.save()
        fetchCommands()
        let newIndex = commands.count - 1
        tableView.selectRowIndexes(IndexSet(integer: newIndex), byExtendingSelection: false)
    }

    @objc func deleteCommand() {
        let row = tableView.selectedRow
        guard row >= 0, let context = modelContainer?.mainContext else { return }
        let command = commands[row]
        context.delete(command)
        try? context.save()
        fetchCommands()

        if commands.isEmpty {
            currentDetailVC?.view.removeFromSuperview()
            currentDetailVC = nil
        } else {
            let nextIndex = min(row, commands.count - 1)
            tableView.selectRowIndexes(IndexSet(integer: nextIndex), byExtendingSelection: false)
        }
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return commands.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("CommandCell")
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
                textField.leadingAnchor.constraint(equalTo: cell!.leadingAnchor, constant: 5),
                textField.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -5)
            ])
        }

        cell?.textField?.stringValue = commands[row].name
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = tableView.selectedRow
        if row >= 0 {
            showDetail(for: commands[row])
        }
    }

    func showDetail(for command: CommandItem) {
        currentDetailVC?.view.removeFromSuperview()

        let editorVC = CommandEditorViewController()
        editorVC.command = command
        editorVC.modelContainer = modelContainer

        editorVC.onCommandUpdated = { [weak self] in
            self?.tableView.reloadData()
        }

        detailContainerView.addSubview(editorVC.view)
        editorVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            editorVC.view.leadingAnchor.constraint(equalTo: detailContainerView.leadingAnchor),
            editorVC.view.trailingAnchor.constraint(equalTo: detailContainerView.trailingAnchor),
            editorVC.view.topAnchor.constraint(equalTo: detailContainerView.topAnchor),
            editorVC.view.bottomAnchor.constraint(equalTo: detailContainerView.bottomAnchor)
        ])

        self.addChild(editorVC)
        currentDetailVC = editorVC
    }
}
