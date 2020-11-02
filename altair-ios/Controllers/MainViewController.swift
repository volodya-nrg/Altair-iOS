import UIKit
import RxSwift

final class MainViewController: BaseViewController {
    private let servicePages = PagesService()
    private let disposeBag = DisposeBag()
    private var _settings: SettingsModel?
    private let cellID = "MainViewControllerCellID"
    
    private lazy var breadcrumbs: BreadcrumbsModule = {
        let x = BreadcrumbsModule()
        x.delegate = self
        return x
    }()
    private var lastAdsFull: [AdFullModel] = [AdFullModel(), AdFullModel()] {
        didSet {
            carouselColView.reloadData()
        }
    }
    
    private lazy var carouselColView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: Helper.adMiniCubeWidth, height: Helper.adMiniCubeHeight)
        layout.scrollDirection = .horizontal
        
        let x = UICollectionView(frame: .zero, collectionViewLayout: layout)
        x.backgroundColor = .none // необходим, иначе черный цвет
        x.heightAnchor.constraint(equalToConstant: Helper.adMiniCubeHeight).isActive = true
        x.register(AdModule.self, forCellWithReuseIdentifier: cellID)
        x.dataSource = self
        
        return x
    }()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = DictionaryWord.altairUz.rawValue
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "line.horizontal.3"),
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(didTapCat))
        navigationItem.leftBarButtonItem?.isEnabled = false
        navigationItem.leftBarButtonItem?.tag = 0
        
        attachElements()
        setConstrains()
        addEvents()
        
        Helper.settings$.subscribe { settingsModel in
            self._settings = settingsModel
            self.navigationItem.leftBarButtonItem?.isEnabled = true
            self.start()
        } onError: { error in
        } onCompleted: {
        }.disposed(by: disposeBag)
        
        Helper.profile$.subscribe { userExtModelOrNil in
            guard userExtModelOrNil != nil else {
                self.navigationItem.rightBarButtonItems = [
                    UIBarButtonItem(image: UIImage(systemName: "plus"),
                                    style: .plain,
                                    target: self,
                                    action: #selector(self.didTapPlus)),
                    UIBarButtonItem(image: UIImage(systemName: "person"),
                                    style: .plain,
                                    target: self,
                                    action: #selector(self.didTapLogin)),
                ]
                return
            }
            
            self.navigationItem.rightBarButtonItems = [
                UIBarButtonItem(image: UIImage(systemName: "plus"),
                                style: .plain,
                                target: self,
                                action: #selector(self.didTapPlus)),
                UIBarButtonItem(image: UIImage(systemName: "person.fill"),
                                style: .plain,
                                target: self,
                                action: #selector(self.didTapProfile)),
            ]
        } onError: { error in
        } onCompleted: {
        }.disposed(by: disposeBag)
    }
    
    private func start(){
        servicePages.pageMain(limit: 10).subscribe { x in
            self.lastAdsFull = x.lastAdsFull
        } onError: { error in
        } onCompleted: {
            guard let s = self._settings else {return}
            let catID = (self.lastAdsFull.count > 0 ? self.lastAdsFull[0].catID : 0)
            self.breadcrumbs.catModels = Helper.getAncestors(s.catsTree.childes, catID)
        }.disposed(by: disposeBag)
    }
}
extension MainViewController: DisciplineProtocol {
    func attachElements() {
        boxStackView.addArrangedSubview(breadcrumbs)
        boxStackView.addArrangedSubview(carouselColView)
    }
    func setConstrains() {
    }
    func addEvents() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onDidListenTopCatTree(_:)),
                                               name: .didTapOnTopCatTree,
                                               object: nil)
    }
}
extension MainViewController {
    @objc private func onDidListenTopCatTree(_ notif: Notification) {
        guard let s = _settings else {return}
        
        var catTree = s.catsTree
        var topA = view.safeAreaLayoutGuide.topAnchor // т.к. контент boxView не высокий, то клики по кнопкам не проходят
        var leftA = view.leadingAnchor
        var level = 0
        var catID: UInt = 0
        
        if let data = notif.object as? ForTopCatTreeModel {
            guard let x = Helper.getDescendantsNode(listCatTree: s.catsTree.childes, findCatID: data.catID) else {return}
            
            catID = data.catID
            catTree = x
            topA = data.topA as! NSLayoutYAxisAnchor
            leftA = data.leftA as! NSLayoutXAxisAnchor
            level = data.level
        }
        
        // если это лист
        if Helper.isLeaf(s.catsTree.childes, catID) > 0 {
            if let btn = navigationItem.leftBarButtonItem {
                didTapCat(sender: btn) // вернем гл. кнопку в обратное состояние
            }
            
            let x = CatViewController()
            x.catID = catID
            navigationController?.pushViewController(x, animated: true)
            return
        }
        
        for v in view.subviews {
            if v is TreeInTheTopModule && v.tag > level {
                v.removeFromSuperview()
            }
        }
        
        let chain = Helper.getAncestors(s.catsTree.childes, catID)
        let blockStackView = TreeInTheTopModule(cats: catTree, level: chain.count)
        blockStackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(blockStackView)
        
        view.addConstraints([
            blockStackView.topAnchor.constraint(equalTo: topA),
            blockStackView.leadingAnchor.constraint(equalTo: leftA),
        ])
    }
    @objc private func didTapCat(sender: UIBarButtonItem) {
        // если открыто, то все типы UIScrollView (в корне) и tag-ом больше нуля, почистить
        if sender.tag == 1 {
            sender.tag = 0
            
            // почистить все за собой
            for v in view.subviews {
                if v is TreeInTheTopModule {
                    v.removeFromSuperview()
                }
            }
            
        } else {
            sender.tag = 1
            NotificationCenter.default.post(name: .didTapOnTopCatTree, object: nil)
        }
    }
    @objc private func didTapLogin(sender: UIBarButtonItem) {
        navigationController?.pushViewController(LoginViewController(), animated: true)
    }
    @objc private func didTapProfile(sender: UIBarButtonItem) {
        navigationController?.pushViewController(ProfileInfoViewController(), animated: true)
    }
    @objc private func didTapPlus(sender: UIBarButtonItem) {
        navigationController?.pushViewController(AdCreateEditViewController(), animated: true)
    }
}
extension MainViewController: AdDelegate {
    internal func showAdFull(_ adID: UInt) {
        navigationController?.pushViewController(AdViewController(adID), animated: true)
    }
}
extension MainViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = 0
        
        if collectionView == carouselColView {
            count = lastAdsFull.count
        }
        
        return count
    }
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let index = indexPath.item
        
        if collectionView == carouselColView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! AdModule
            cell.setup(adFull: lastAdsFull[index], opt: .cube, inProfile: false)
            cell.delegate = self
            return cell
        }
        
        return collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath)
    }
}
extension MainViewController: BreadcrumbsModuleDelegate {
    internal func didTapBreadcrumbItem(_ sender: UIButton) {
        let x = CatViewController()
        x.catID = UInt(sender.tag)
        navigationController?.pushViewController(x, animated: true)
    }
}
