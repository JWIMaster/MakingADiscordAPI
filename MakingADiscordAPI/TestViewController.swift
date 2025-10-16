import UIKit
import UIKitCompatKit
import UIKitExtensions
import GPUImage1Swift
import LiveFrost

class TestViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.22, alpha: 1)

        // MARK: - Scroll view with large content
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 15
        contentStack.alignment = .fill
        contentStack.distribution = .equalSpacing
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])

        // MARK: - Add lots of sections
        for i in 1...50 {
            let container = UIView()
            container.backgroundColor = UIColor.white.withAlphaComponent(0.08)
            container.layer.cornerRadius = 12
            container.layer.borderWidth = 1
            container.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
            container.translatesAutoresizingMaskIntoConstraints = false
            container.heightAnchor.constraint(equalToConstant: 80).isActive = true

            let label = UILabel()
            label.text = "Section \(i)"
            label.textColor = .white
            label.backgroundColor = .clear
            label.font = UIFont.systemFont(ofSize: 16)
            label.translatesAutoresizingMaskIntoConstraints = false

            let button = UIButton(type: .custom)
            button.setTitle("Action", for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = .blue
            button.layer.cornerRadius = 10
            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
            button.translatesAutoresizingMaskIntoConstraints = false

            container.addSubview(label)
            container.addSubview(button)

            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                button.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
                button.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            ])

            contentStack.addArrangedSubview(container)
        }

        // MARK: - Glass panels (on top)
        let glass1 = LiquidGlassView(blurRadius: 2, cornerRadius: 50)
        glass1.frame = CGRect(x: 40, y: 100, width: view.bounds.width - 80, height: 100)
        glass1.scaleFactor = 0.2
        glass1.isUserInteractionEnabled = true
        view.addSubview(glass1)

        let glass2 = LiquidGlassView(blurRadius: 2, cornerRadius: 50)
        glass2.frame = CGRect(x: 60, y: 300, width: view.bounds.width - 120, height: 150)
        glass2.scaleFactor = 0.2
        glass2.isUserInteractionEnabled = true
        //view.addSubview(glass2)

        // Make glass draggable
        //[glass1, glass2].forEach { addPanGesture(to: $0) }
    }

    private func addPanGesture(to view: UIView) {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let draggedView = gesture.view else { return }
        let translation = gesture.translation(in: view)
        draggedView.center.x += translation.x
        draggedView.center.y += translation.y
        gesture.setTranslation(.zero, in: view)
    }
}
