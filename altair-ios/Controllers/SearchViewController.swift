import UIKit

final class SearchViewController: BaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = DictionaryWord.search.rawValue
    }
}
