import AppKit
import SwiftData

class BinariesViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    var modelContainer: ModelContainer?
    var binaries: [BinaryLocation] = []

    let tableView = NSTableView()
    let scrollView = NSScrollView()
    let scanButton = NSButton(title: "Scan Common Paths", target: nil, action: nil)
    let searchField = NSSearchField()
    let statusLabel = NSTextField(labelWithString: "Found 0 binaries.")

    override func loadView() {
        self.view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchBinaries()

        scanButton.target = self
        scanButton.action = #selector(scanPaths)
    }

    func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        searchField.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        view.addSubview(scanButton)
        view.addSubview(searchField)
        view.addSubview(statusLabel)

        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("BinaryName"))
        nameColumn.title = "Name"
        nameColumn.width = 150
        tableView.addTableColumn(nameColumn)

        let pathColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("BinaryPath"))
        pathColumn.title = "Path"
        pathColumn.width = 400
        tableView.addTableColumn(pathColumn)

        tableView.delegate = self
        tableView.dataSource = self
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true

        NSLayoutConstraint.activate([
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            searchField.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            searchField.widthAnchor.constraint(equalToConstant: 300),

            scanButton.leadingAnchor.constraint(equalTo: searchField.trailingAnchor, constant: 10),
            scanButton.centerYAnchor.constraint(equalTo: searchField.centerYAnchor),

            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 10),
            scrollView.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -10),

            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            statusLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10)
        ])
    }

    func fetchBinaries() {
        guard let context = modelContainer?.mainContext else { return }
        let descriptor = FetchDescriptor<BinaryLocation>(sortBy: [SortDescriptor(\.name)])
        do {
            binaries = try context.fetch(descriptor)
            tableView.reloadData()
            updateStatus()
        } catch {
            print("Failed to fetch binaries: \(error)")
        }
    }

    func updateStatus() {
        statusLabel.stringValue = "Found \(binaries.count) binaries."
    }

    @objc func scanPaths() {
        scanButton.isEnabled = false
        statusLabel.stringValue = "Scanning..."

        let pathsToScan = [
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin",
            "/usr/local/bin",
            "/opt/homebrew/bin",
            "/opt/homebrew/sbin"
        ]

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let fm = FileManager.default
            var newBinaries: [BinaryLocation] = []

            for path in pathsToScan {
                guard let items = try? fm.contentsOfDirectory(atPath: path) else { continue }
                for item in items {
                    let fullPath = (path as NSString).appendingPathComponent(item)
                    var isDir: ObjCBool = false
                    if fm.fileExists(atPath: fullPath, isDirectory: &isDir), !isDir.boolValue {
                        if fm.isExecutableFile(atPath: fullPath) {
                            let loc = BinaryLocation(name: item, path: fullPath)
                            newBinaries.append(loc)
                        }
                    }
                }
            }

            DispatchQueue.main.async {
                guard let self = self, let context = self.modelContainer?.mainContext else { return }

                // Clear old entries
                do {
                    try context.delete(model: BinaryLocation.self)

                    // Insert new
                    for bin in newBinaries {
                        context.insert(bin)
                    }
                    try context.save()

                    self.fetchBinaries()
                    self.scanButton.isEnabled = true
                } catch {
                    print("Error saving scanned binaries: \(error)")
                    self.scanButton.isEnabled = true
                }
            }
        }
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return binaries.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = tableColumn?.identifier ?? NSUserInterfaceItemIdentifier("")
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

        let binary = binaries[row]
        if identifier.rawValue == "BinaryName" {
            cell?.textField?.stringValue = binary.name
        } else {
            cell?.textField?.stringValue = binary.path
        }

        return cell
    }
}
