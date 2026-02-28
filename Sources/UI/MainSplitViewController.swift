import AppKit
import SwiftData

class MainSplitViewController: NSSplitViewController {
    var modelContainer: ModelContainer?

    let sidebarVC = SidebarViewController()
    let detailContainerVC = NSViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        detailContainerVC.view = NSView()

        sidebarVC.onSelectionChange = { [weak self] selectedItem in
            self?.showDetail(for: selectedItem)
        }

        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarVC)
        let detailItem = NSSplitViewItem(viewController: detailContainerVC)

        addSplitViewItem(sidebarItem)
        addSplitViewItem(detailItem)

        showDetail(for: .home)
    }

    func showDetail(for item: SidebarItem) {
        let newVC: NSViewController

        switch item {
        case .home:
            let homeVC = HomeViewController()
            homeVC.modelContainer = modelContainer
            newVC = homeVC
        case .binaries:
            let binariesVC = BinariesViewController()
            binariesVC.modelContainer = modelContainer
            newVC = binariesVC
        }

        // Remove old view
        detailContainerVC.view.subviews.forEach { $0.removeFromSuperview() }
        detailContainerVC.children.forEach { $0.removeFromParent() }

        // Add new view
        detailContainerVC.addChild(newVC)
        detailContainerVC.view.addSubview(newVC.view)

        newVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newVC.view.leadingAnchor.constraint(equalTo: detailContainerVC.view.leadingAnchor),
            newVC.view.trailingAnchor.constraint(equalTo: detailContainerVC.view.trailingAnchor),
            newVC.view.topAnchor.constraint(equalTo: detailContainerVC.view.topAnchor),
            newVC.view.bottomAnchor.constraint(equalTo: detailContainerVC.view.bottomAnchor)
        ])
    }
}
