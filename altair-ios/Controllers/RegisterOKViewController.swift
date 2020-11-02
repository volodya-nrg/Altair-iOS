import UIKit

final class RegisterOKViewController: BaseViewController {
    private let h1Label: UILabel = {
        let x = UILabel()
        x.attributedText = MyText.getH1Attr(DictionaryWord.registrationCompletedSuccessfully.rawValue)
        x.numberOfLines = 0
        return x
    }()
    private let msgLabel: UILabel = {
        let x = UILabel()
        x.text = DictionaryWord.aLetterHasBeenSentToYourEmail.rawValue
        x.numberOfLines = 0
        return x
    }()
    override func viewDidLoad() {
        super.viewDidLoad()

        boxStackView.addArrangedSubview(h1Label)
        boxStackView.addArrangedSubview(msgLabel)
    }
}
