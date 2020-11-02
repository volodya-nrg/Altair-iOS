import UIKit

enum FlyErrorKindVisual {
    case success
    case warning
    case danger
}

final class FlyErrorModule: UIView {
    private let radius: CGFloat = 4
    private var msg = ""
    private var kind: FlyErrorKindVisual?
    private let messageLabel: UILabel = {
        let x = UILabel()
        x.numberOfLines = 0
        x.translatesAutoresizingMaskIntoConstraints = false
        return x
    }()
    
    init (kindVisual: FlyErrorKindVisual, msg: String, title: String = "") {
        super.init(frame: .zero)
        
        backgroundColor = Helper.myColorToUIColor(.gray8)
        isUserInteractionEnabled = true
        layer.cornerRadius = radius
        
        switch kindVisual {
        case .success:
            backgroundColor = .systemGreen
        case .warning:
            backgroundColor = Helper.myColorToUIColor(.warning)
        case .danger:
            backgroundColor = Helper.myColorToUIColor(.danger)
        }

        messageLabel.text = msg

        attachElements()
        setConstrains()
        addEvents()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override var alignmentRectInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
}
extension FlyErrorModule: DisciplineProtocol {
    internal func attachElements() {
        addSubview(messageLabel)
    }
    internal func setConstrains() {
        addConstraints([
            messageLabel.widthAnchor.constraint(equalTo: widthAnchor),
            messageLabel.heightAnchor.constraint(equalTo: heightAnchor),
        ])
    }
    internal func addEvents() {
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:))))
    }
}
extension FlyErrorModule {
    @objc private func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        guard let tappedView = tapGestureRecognizer.view else {return}
        let t = tappedView as UIView
        t.removeFromSuperview()
    }
}
