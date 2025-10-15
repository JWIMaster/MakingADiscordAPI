import UIKit
import UIKitCompatKit
import UIKitExtensions
import GPUImage1Swift

public class LiquidGlassView: UIKitCompatKit.UIVisualEffectView {

    // MARK: - Public properties
    public var cornerRadius: CGFloat = 50 {
        didSet {
            layer.cornerRadius = cornerRadius
            updateMaskPath()
            updateShadow()
        }
    }

    /// Shadow configuration
    public var shadowOpacity: Float = 1 {
        didSet { updateShadow() }
    }

    public var shadowRadius: CGFloat = 20 {
        didSet { updateShadow() }
    }

    public var shadowOffset: CGSize = CGSize(width: 0, height: 10) {
        didSet { updateShadow() }
    }

    /// Optional saturation multiplier (default 1.1)
    public var saturationBoost: CGFloat = 1.1 {
        didSet { applySaturationBoost() }
    }

    // MARK: - Private layers
    private let rimLayer = CALayer()
    private let edgeHighlightLayer = CAGradientLayer()
    private let darkenFalloffLayer = CAGradientLayer()
    private let diffractionLayer = CALayer()

    private var saturationFilter: GPUImageSaturationFilter?

    // MARK: - Init
    public init(blurRadius: CGFloat = 12, cornerRadius: CGFloat = 50) {
        super.init(effect: UIBlurEffect(blurRadius: blurRadius))
        self.cornerRadius = cornerRadius
        setupLayers()
        applySaturationBoost()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
        applySaturationBoost()
    }

    // MARK: - Setup
    private func setupLayers() {
        clipsToBounds = true
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = false
        updateShadow()

        // Subtle darken falloff (inner 10%)
        darkenFalloffLayer.colors = [
            UIColor.black.withAlphaComponent(0.15).cgColor,
            UIColor.clear.cgColor
        ]
        darkenFalloffLayer.startPoint = CGPoint(x: 0.5, y: 1)
        darkenFalloffLayer.endPoint = CGPoint(x: 0.5, y: 0)
        darkenFalloffLayer.locations = [0, 1]
        darkenFalloffLayer.compositingFilter = "multiplyBlendMode"
        layer.addSublayer(darkenFalloffLayer)

        // Rim / edge highlight (white corners, not all around)
        edgeHighlightLayer.colors = [
            UIColor.white.withAlphaComponent(0.5).cgColor, // strong corners
            UIColor.clear.cgColor,
            UIColor.white.withAlphaComponent(0.2).cgColor, // another subtle highlight
            UIColor.clear.cgColor
        ]
        edgeHighlightLayer.locations = [0.0, 0.15, 0.95, 1.0]
        edgeHighlightLayer.startPoint = CGPoint(x: 0, y: 0)
        edgeHighlightLayer.endPoint = CGPoint(x: 1, y: 1)
        edgeHighlightLayer.compositingFilter = "screenBlendMode"
        layer.addSublayer(edgeHighlightLayer)

        // Rim layer to slightly brighten edges
        rimLayer.borderColor = UIColor.white.withAlphaComponent(0.35).cgColor
        rimLayer.borderWidth = 1.0
        rimLayer.cornerRadius = cornerRadius
        layer.addSublayer(rimLayer)

        // Diffraction (subtle refractive inner layer)
        diffractionLayer.backgroundColor = UIColor.white.withAlphaComponent(0.06).cgColor
        diffractionLayer.cornerRadius = cornerRadius - 1
        diffractionLayer.compositingFilter = "differenceBlendMode"
        layer.addSublayer(diffractionLayer)
    }

    // MARK: - Layout
    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutLayers()
    }

    private func layoutLayers() {
        let inset: CGFloat = 2
        darkenFalloffLayer.frame = bounds
        edgeHighlightLayer.frame = bounds
        rimLayer.frame = bounds
        diffractionLayer.frame = bounds.insetBy(dx: inset, dy: inset)
        updateMaskPath()
    }

    private func updateMaskPath() {
        let mask = CAShapeLayer()
        mask.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
        layer.mask = mask
    }

    private func updateShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = shadowOpacity
        layer.shadowRadius = shadowRadius
        layer.shadowOffset = shadowOffset
        //]layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
    }

    // MARK: - Colour / Saturation
    private func applySaturationBoost() {
        // Optional: use GPUImage if available
        #if canImport(GPUImage1Swift)
        saturationFilter = GPUImageSaturationFilter()
        saturationFilter?.saturation = saturationBoost
        #endif
    }
}


class TestViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Background
        let background = UIImage(named: "example.jpg")
        let backgroundView = UIImageView(image: background)
        backgroundView.contentMode = .scaleAspectFill
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundView)
        backgroundView.pinToEdges(of: view)
        //view.backgroundColor = .init(red: 0.2, green: 0.2, blue: 0.22, alpha: 1)

        // Glass view
        let glassFrame = CGRect(x: 40, y: 100, width: view.bounds.width - 250, height: 500)
        let liquidGlass = LiquidGlassView(blurRadius: 8, cornerRadius: 30)
        liquidGlass.frame = glassFrame
        let blackView = UIView(frame: liquidGlass.frame)
        liquidGlass.addSubview(blackView)
        blackView.backgroundColor = .black
        blackView.pinToCenter(of: liquidGlass)
        view.addSubview(liquidGlass)

        // Make draggable
        addPanGesture(to: liquidGlass)
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
