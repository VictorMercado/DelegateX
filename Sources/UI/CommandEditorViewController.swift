import AppKit
import SwiftData

class CommandEditorViewController: NSViewController, NSTextFieldDelegate {
    var command: CommandItem!
    var modelContainer: ModelContainer?
    var onCommandUpdated: (() -> Void)?

    let nameField = NSTextField()
    let templateField = NSTextField()
    let workDirField = NSTextField()

    let addParamButton = NSButton(title: "Add Parameter {}", target: nil, action: nil)
    let saveButton = NSButton(title: "Save", target: nil, action: nil)
    let runButton = NSButton(title: "Run Command", target: nil, action: nil)
    let stopButton = NSButton(title: "Stop", target: nil, action: nil)

    var outputTextView: NSTextView!
    var outputScrollView: NSScrollView!

    let paramsStackView = NSStackView()

    let executor = CommandExecutor()

    override func loadView() {
        self.view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        populateData()

        nameField.delegate = self
        templateField.delegate = self
        workDirField.delegate = self

        addParamButton.target = self
        addParamButton.action = #selector(addParameterPlaceholder)

        saveButton.target = self
        saveButton.action = #selector(saveCommand)

        runButton.target = self
        runButton.action = #selector(runCommand)

        stopButton.target = self
        stopButton.action = #selector(stopCommand)

        executor.onOutput = { [weak self] text in
            self?.appendOutput(text)
        }
        executor.onError = { [weak self] text in
            self?.appendOutput("ERROR: " + text)
        }
        executor.onTermination = { [weak self] status in
            self?.appendOutput("\n[Process exited with status \(status)]\n")
            self?.runButton.isEnabled = true
            self?.stopButton.isEnabled = false
        }
    }

    func setupUI() {
        let nameLabel = NSTextField(labelWithString: "Name:")
        let templateLabel = NSTextField(labelWithString: "Template:")
        let workDirLabel = NSTextField(labelWithString: "Working Directory:")

        paramsStackView.orientation = .vertical
        paramsStackView.alignment = .leading
        paramsStackView.spacing = 10

        let scrollView = NSScrollView()
        scrollView.documentView = paramsStackView
        scrollView.hasVerticalScroller = true

        // Correctly configure NSTextView inside NSScrollView
        outputScrollView = NSTextView.scrollableTextView()
        outputTextView = outputScrollView.documentView as? NSTextView
        outputTextView.isEditable = false
        outputTextView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)

        let controlsStack = NSStackView(views: [nameLabel, nameField, workDirLabel, workDirField, templateLabel, templateField, addParamButton, scrollView, saveButton, runButton, stopButton, outputScrollView])
        controlsStack.orientation = .vertical
        controlsStack.alignment = .leading
        controlsStack.spacing = 10
        controlsStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(controlsStack)

        NSLayoutConstraint.activate([
            controlsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            controlsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            controlsStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            controlsStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),

            nameField.widthAnchor.constraint(equalToConstant: 250),
            workDirField.widthAnchor.constraint(equalToConstant: 400),
            templateField.widthAnchor.constraint(equalToConstant: 400),
            scrollView.widthAnchor.constraint(equalTo: controlsStack.widthAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 150),
            outputScrollView.widthAnchor.constraint(equalTo: controlsStack.widthAnchor),
            outputScrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 150)
        ])

        stopButton.isEnabled = false
    }

    func populateData() {
        nameField.stringValue = command.name
        templateField.stringValue = command.template
        workDirField.stringValue = command.workingDirectory
        renderParameters()
    }

    func renderParameters() {
        paramsStackView.views.forEach { $0.removeFromSuperview() }

        let sortedParams = command.parameters.sorted { $0.order < $1.order }

        for (index, param) in sortedParams.enumerated() {
            let rowStack = NSStackView()
            rowStack.orientation = .horizontal
            rowStack.spacing = 10

            let labelField = NSTextField(string: param.label)
            labelField.placeholderString = "Label (e.g. Path)"
            labelField.tag = index * 2 // Evens are labels
            labelField.delegate = self

            let valueField = NSTextField(string: param.value)
            valueField.placeholderString = "Value"
            valueField.tag = index * 2 + 1 // Odds are values
            valueField.delegate = self

            let removeButton = NSButton(title: "X", target: self, action: #selector(removeParameter(_:)))
            removeButton.tag = index

            rowStack.addArrangedSubview(labelField)
            rowStack.addArrangedSubview(valueField)
            rowStack.addArrangedSubview(removeButton)

            paramsStackView.addArrangedSubview(rowStack)
        }
    }

    @objc func addParameterPlaceholder() {
        // Append {} to template string
        templateField.stringValue += " {}"

        let sortedParams = command.parameters.sorted { $0.order < $1.order }
        let nextOrder = (sortedParams.last?.order ?? -1) + 1

        // Add new parameter model
        let newParam = CommandParameter(label: "New Param", value: "", order: nextOrder)
        command.parameters.append(newParam)

        renderParameters()
    }

    @objc func removeParameter(_ sender: NSButton) {
        let index = sender.tag
        let sortedParams = command.parameters.sorted { $0.order < $1.order }
        if index < sortedParams.count {
            let paramToRemove = sortedParams[index]
            if let realIndex = command.parameters.firstIndex(where: { $0.id == paramToRemove.id }) {
                command.parameters.remove(at: realIndex)

                // Re-order remaining
                let newSorted = command.parameters.sorted { $0.order < $1.order }
                for (i, p) in newSorted.enumerated() {
                    p.order = i
                }
                renderParameters()
            }
        }
    }

    @objc func saveCommand() {
        command.name = nameField.stringValue
        command.template = templateField.stringValue
        command.workingDirectory = workDirField.stringValue
        try? modelContainer?.mainContext.save()
        onCommandUpdated?()
    }

    @objc func runCommand() {
        saveCommand()
        outputTextView.string = ""
        runButton.isEnabled = false
        stopButton.isEnabled = true
        executor.execute(command: command)
    }

    @objc func stopCommand() {
        executor.stop()
        runButton.isEnabled = true
        stopButton.isEnabled = false
    }

    func appendOutput(_ text: String) {
        outputTextView.string += text
        outputTextView.scrollToEndOfDocument(nil)
    }

    // Auto-update values
    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }

        if textField == nameField {
            command.name = textField.stringValue
            onCommandUpdated?()
        } else if textField == templateField {
            command.template = textField.stringValue
        } else if textField == workDirField {
            command.workingDirectory = textField.stringValue
        } else {
            // It's a parameter field
            let index = textField.tag / 2
            let sortedParams = command.parameters.sorted { $0.order < $1.order }
            if index < sortedParams.count {
                let targetParamId = sortedParams[index].id
                if let realIndex = command.parameters.firstIndex(where: { $0.id == targetParamId }) {
                    if textField.tag % 2 == 0 {
                        command.parameters[realIndex].label = textField.stringValue
                    } else {
                        command.parameters[realIndex].value = textField.stringValue
                    }
                }
            }
        }
    }
}
