import UIKit
import RxSwift

protocol BricksModuleDelegate: class {
    func bricksDidSendCatID(_ catID: UInt)
}

final class BricksModule: UIStackView {
    private let disposeBag = DisposeBag()
    public weak var delegate: BricksModuleDelegate?
    
    init() {
        super.init(frame: .zero)
        
        axis = .vertical
        spacing = 10
        
        Helper.settings$.subscribe { settingsModel in
            for v in settingsModel.catsTree.childes {
                let brickView = BrickModule(v)
                brickView.delegate = self
                self.addArrangedSubview(brickView)
            }
        } onError: { error in
        } onCompleted: {
        }.disposed(by: disposeBag)
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
extension BricksModule: BrickModuleDelegate {
    internal func didTapBrick(_ sender: UIButton) {
        let catID = UInt(sender.tag)
        delegate?.bricksDidSendCatID(catID)
    }
}
// ------------------------------
protocol BrickModuleDelegate: class {
    func didTapBrick(_ sender: UIButton)
}

final class BrickModule: UIView {
    private let disposeBag = DisposeBag()
    private var catTree: CatTreeModel
    private lazy var titleButton: UIButton = {
        let x = UIButton(type: .system)
        x.setAttributedTitle(MyText.getH3BlueAttr(catTree.name), for: .normal)
        x.tag = Int(catTree.catID)
        x.sizeToFit()
        x.translatesAutoresizingMaskIntoConstraints = false
        return x
    }()
    private let itemsStackView: UIStackView = {
        let x = UIStackView()
        x.axis = .vertical
        x.alignment = .leading
        x.spacing = 5
        x.translatesAutoresizingMaskIntoConstraints = false
        return x
    }()
    public weak var delegate: BrickModuleDelegate? // слабая ссылка
    
    init (_ catTree: CatTreeModel) {
        self.catTree = catTree
        
        super.init(frame: .zero)
        
        translatesAutoresizingMaskIntoConstraints = false
        
        attachElements()
        setConstrains()
        addEvents()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func addBorder() {
        let border = UIView()
        
        border.backgroundColor = Helper.myColorToUIColor(.gray7)
        border.frame = CGRect(x: 0, y: 0, width: 1, height: itemsStackView.frame.size.height)
        border.autoresizingMask = [.flexibleHeight, .flexibleRightMargin]
        
        itemsStackView.addSubview(border)
    }
}
extension BrickModule: DisciplineProtocol {
    internal func attachElements() {
        for v in catTree.childes {
            let x = UIButton(type: .system)
            x.setAttributedTitle(MyText.getH4Attr(v.name), for: .normal)
            x.contentEdgeInsets = UIEdgeInsets(top: 3, left: 20, bottom: 3, right: 0)
            x.tag = Int(v.catID)
            x.sizeToFit()
            
            x.rx.tap.asDriver().drive(onNext:{
                self.delegate?.didTapBrick(x)
            }).disposed(by: self.disposeBag)
            
            itemsStackView.addArrangedSubview(x)
        }
        
        addBorder()
        
        addSubview(titleButton)
        addSubview(itemsStackView)
    }
    internal func setConstrains() {
        addConstraints([
            titleButton.topAnchor.constraint(equalTo: topAnchor),
            titleButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            itemsStackView.topAnchor.constraint(equalTo: titleButton.bottomAnchor),
            bottomAnchor.constraint(greaterThanOrEqualTo: itemsStackView.bottomAnchor),
        ])
    }
    internal func addEvents() {
        titleButton.rx.tap.asDriver().drive(onNext:{
            self.delegate?.didTapBrick(self.titleButton)
        }).disposed(by: self.disposeBag)
    }
}
