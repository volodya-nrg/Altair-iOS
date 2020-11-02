import UIKit

// https://tproger.ru/articles/rxswift/
// ОБРАБАТЫВАТЬ ОШИБКИ С ПОМОЩЬЮ Materialize

class MyText {
    private static let h1: [NSAttributedString.Key: Any] = [
        .foregroundColor: Helper.myColorToUIColor(.black),
        .font: UIFont.boldSystemFont(ofSize: 23),
    ]
    private static let h2: [NSAttributedString.Key: Any] = [
        .foregroundColor: Helper.myColorToUIColor(.black),
        .font: UIFont.boldSystemFont(ofSize: 19),
    ]
    private static let h3: [NSAttributedString.Key: Any] = [
        .foregroundColor: Helper.myColorToUIColor(.black),
        .font: UIFont.boldSystemFont(ofSize: 17),
    ]
    private static let h4: [NSAttributedString.Key: Any] = [
        .foregroundColor: Helper.myColorToUIColor(.gray3),
        .font: UIFont.boldSystemFont(ofSize: 14),
    ]
    private static let h3Blue: [NSAttributedString.Key: Any] = [
        .foregroundColor: UIColor.systemBlue,
        .font: UIFont.boldSystemFont(ofSize: 17),
    ]
    private static let textDefaultSize: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 17)]
    private static let textSmall: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 13)]
    private static let textMuted: [NSAttributedString.Key: Any] = [.foregroundColor: Helper.myColorToUIColor(.gray3)]
    private static let textUnderline: [NSAttributedString.Key: Any] = [.underlineStyle: NSUnderlineStyle.single.rawValue]
    private static let textBold: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 17)]
    private static let textBoldSmall: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 13)]
    
    static func getH1Label(_ title: String) -> UILabel {
        let x = UILabel()
        x.attributedText = NSMutableAttributedString(string: title, attributes: h1)
        return x
    }
    static func getH2Label(_ title: String) -> UILabel {
        let x = UILabel()
        x.attributedText = NSMutableAttributedString(string: title, attributes: h2)
        return x
    }
    static func getH3Label(_ title: String) -> UILabel {
        let x = UILabel()
        x.attributedText = NSMutableAttributedString(string: title, attributes: h3)
        return x
    }
    static func getH4Label(_ title: String) -> UILabel {
        let x = UILabel()
        x.attributedText = NSMutableAttributedString(string: title, attributes: h4)
        return x
    }
    static func getH1Attr(_ title: String) -> NSMutableAttributedString {
        return NSMutableAttributedString(string: title, attributes: h1)
    }
    static func getH2Attr(_ title: String) -> NSMutableAttributedString {
        return NSMutableAttributedString(string: title, attributes: h2)
    }
    static func getH3Attr(_ title: String) -> NSMutableAttributedString {
        return NSMutableAttributedString(string: title, attributes: h3)
    }
    static func getH3BlueAttr(_ title: String) -> NSMutableAttributedString {
        return NSMutableAttributedString(string: title, attributes: h3Blue)
    }
    static func getH4Attr(_ title: String) -> NSMutableAttributedString {
        return NSMutableAttributedString(string: title, attributes: h4)
    }
    static func getSmallMuteLabel(_ title: String) -> UILabel {
        let x = UILabel()
        let tmpText = NSMutableAttributedString.init(string: title)
        tmpText.addAttributes(textSmall, range: NSRange(location: 0, length: title.count))
        tmpText.addAttributes(textMuted, range: NSRange(location: 0, length: title.count))
        x.attributedText = tmpText
        return x
    }
    static func getSmallLabel(_ title: String) -> UILabel {
        let x = UILabel()
        let tmpText = NSMutableAttributedString.init(string: title)
        tmpText.addAttributes(textSmall, range: NSRange(location: 0, length: title.count))
        x.attributedText = tmpText
        return x
    }
    static func getSmallMuteAttr(_ title: String) -> NSMutableAttributedString {
        let x = NSMutableAttributedString.init(string: title)
        x.addAttributes(textSmall, range: NSRange(location: 0, length: title.count))
        x.addAttributes(textMuted, range: NSRange(location: 0, length: title.count))
        return x
    }
    static func getDefaultSizeAttr(_ title: String) -> NSMutableAttributedString {
        let x = NSMutableAttributedString.init(string: title)
        x.addAttributes(textDefaultSize, range: NSRange(location: 0, length: title.count))
        return x
    }
    static func getSmallAttr(_ title: String) -> NSMutableAttributedString {
        let x = NSMutableAttributedString.init(string: title)
        x.addAttributes(textSmall, range: NSRange(location: 0, length: title.count))
        return x
    }
    static func getMutedAttr(_ title: String) -> NSMutableAttributedString {
        let x = NSMutableAttributedString.init(string: title)
        x.addAttributes(textMuted, range: NSRange(location: 0, length: title.count))
        return x
    }
    static func getUnderlineAttr(_ title: String) -> NSMutableAttributedString {
        let x = NSMutableAttributedString.init(string: title)
        x.addAttributes(textUnderline, range: NSRange(location: 0, length: title.count))
        return x
    }
    static func getBoldAttr(_ title: String) -> NSMutableAttributedString {
        let x = NSMutableAttributedString.init(string: title)
        x.addAttributes(textBold, range: NSRange(location: 0, length: title.count))
        return x
    }
    static func getBoldSmallAttr(_ title: String) -> NSMutableAttributedString {
        let x = NSMutableAttributedString.init(string: title)
        x.addAttributes(textBoldSmall, range: NSRange(location: 0, length: title.count))
        return x
    }
}

class MyError: NSObject, LocalizedError {
    private var desc = ""
    
    init(_ str: String) {
        self.desc = str
    }
    override var description: String {
        get {
            return "----->: \(desc)"
        }
    }
    //You need to implement `errorDescription`, not `localizedDescription`.
    var errorDescription: String? {
        get {
            return self.description
        }
    }
}

extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
extension Encodable {
    func myData(using encoder: JSONEncoder = JSONEncoder()) throws -> Data { try encoder.encode(self) }
}

// затык от бага
extension UIAlertController {
    func pruneNegativeWidthConstraints() {
        for subView in self.view.subviews {
            for constraint in subView.constraints where constraint.debugDescription.contains("width == - 16") {
                subView.removeConstraint(constraint)
            }
        }
    }
}
