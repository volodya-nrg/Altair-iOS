import UIKit

protocol ButtonProtocol {
    func get() -> UIButton
}

class ButtonFactory {
    public static func create(_ typeSrc: UIButton.ButtonType, _ title: String, _ imgSrc: String = "") -> UIButton {
        var btn: UIButton
        
        switch typeSrc {
        case .custom:
            btn = ButtonSystem(title, imgSrc).get()
        default:
            btn = ButtonDefault(title, imgSrc).get()
        }

        return btn
    }
}
class ButtonSystem: ButtonProtocol {
    private let btn = UIButton(type: .system)
    
    init(_ title: String, _ imgSrc: String){
        if imgSrc != "" {
            let img = UIImage(named: imgSrc)
            btn.setImage(img, for: .normal)
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        } else {
            btn.setTitle(title, for: .normal)
            btn.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        }
        
        btn.backgroundColor = Helper.myColorToUIColor(.gray8)
        btn.layer.cornerRadius = 6
        btn.layer.borderWidth = 1
        btn.layer.borderColor = Helper.myColorToUIColor(.gray7).cgColor
    }
    public func get() -> UIButton {
        return btn
    }
}
class ButtonDefault: ButtonProtocol {
    private let btn = UIButton(type: .system)

    init(_ title: String, _ imgSrc: String){
        if imgSrc != "" {
            let img = UIImage(named: imgSrc)
            btn.setImage(img, for: .normal)
        } else {
            btn.setTitle(title, for: .normal)
        }
    }
    public func get() -> UIButton {
        return btn
    }
}
