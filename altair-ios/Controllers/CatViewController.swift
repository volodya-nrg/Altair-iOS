import UIKit
import RxSwift

final class CatViewController: BaseViewController {
    private let serviceAd = AdService()
    private let disposeBag = DisposeBag()
    private lazy var breadcrumbs: BreadcrumbsModule = {
        let x = BreadcrumbsModule()
        x.delegate = self
        return x
    }()
    private lazy var bricks: BricksModule = {
        let x = BricksModule()
        x.delegate = self
        return x
    }()
    private let cellID = "CatViewControllerCellID"
    private var adsFull: [AdFullModel] = []
    private var isLoadAll = false
    private let limit: UInt = 3
    private var offset: UInt = 0
    private var saveHeightConstraint = NSLayoutConstraint.init()
    public var catID: UInt = 0
    private var searchText = ""
    private var searchLimit = 0
    private var searchOffset = 0
    
    private lazy var adsColView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: Helper.adMiniCubeWidth, height: Helper.adMiniCubeHeight)
        
        let x = UICollectionView(frame: .zero, collectionViewLayout: layout)
        x.backgroundColor = .none
        
        x.dataSource = self
        x.register(AdModule.self, forCellWithReuseIdentifier: cellID)
        x.isScrollEnabled = false
        
        return x
    }()
    private let preloader: UIActivityIndicatorView = {
        let x = UIActivityIndicatorView()
        x.translatesAutoresizingMaskIntoConstraints = false
        x.hidesWhenStopped = true
        x.backgroundColor = Helper.myColorToUIColor(.white)
        return x
    }()
    private let h1 = MyText.getH1Label(DictionaryWord.categoriesWithColon.rawValue)
    private lazy var searchBar: UISearchBar = {
        let x = UISearchBar()
        x.placeholder = DictionaryWord.search.rawValue
        x.searchBarStyle = .minimal
        x.delegate = self
        return x
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = DictionaryWord.catalog.rawValue
    }
    override func viewWillAppear(_ animated: Bool) {
        boxStackView.subviews.forEach{$0.removeFromSuperview()}
        
        attachElements()
        setConstrains()
        addEvents()
        start()
    }
}

extension CatViewController: DisciplineProtocol {
    func attachElements() {
        if catID < 1 {
            boxStackView.addArrangedSubview(breadcrumbs)
            boxStackView.addArrangedSubview(h1)
            boxStackView.addArrangedSubview(bricks)

        } else {
            boxStackView.addArrangedSubview(searchBar)
            boxStackView.addArrangedSubview(breadcrumbs)
            boxStackView.addArrangedSubview(adsColView)
            view.addSubview(preloader)
        }
    }
    func setConstrains() {
        if catID > 0 {
            view.addConstraints([
                preloader.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -1 * Helper.em1),
                preloader.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ])
        }
    }
    func addEvents() {
        boxScrollView.delegate = self // присоединяемся чтоб отслеживать scroll
    }
}
extension CatViewController {
    private func start() {
        setToDefault()
        
        Helper.settings$.subscribe { settingsModel in
            self.breadcrumbs.catModels = Helper.getAncestors(settingsModel.catsTree.childes, self.catID)
        } onError: { error in
        } onCompleted: {
        }.disposed(by: disposeBag)

        if catID > 0 {
            send()
        }
    }
    private func setToDefault() {
        offset = 0
        adsFull.removeAll()
        adsColView.reloadData()
        isLoadAll = false
    }
    private func send(){
        preloader.startAnimating()
        
        let data: [String: Any] = [
            "catID": catID,
            "limit": limit,
            "offset": offset,
        ]
        serviceAd.getFromCat(data).subscribe { adFullModels in
            self.adsFull.append(contentsOf: adFullModels)
            self.offset += self.limit
            self.adsColView.reloadData()
            self.controlHeightAdsColView()

            if (adFullModels.count < self.limit) {
                self.isLoadAll = true
            } else if self.boxStackView.frame.height < self.view.frame.height {
                self.send()
            }
        } onError: { error in
            self.preloader.stopAnimating()
        } onCompleted: {
            self.preloader.stopAnimating()
        }.disposed(by: disposeBag)
    }
    private func controlHeightAdsColView() {
        let contraintHeight = adsColView.heightAnchor.constraint(greaterThanOrEqualToConstant: adsColView.contentSize.height)
        NSLayoutConstraint.deactivate([saveHeightConstraint])
        NSLayoutConstraint.activate([contraintHeight])
        view.layoutIfNeeded()
        saveHeightConstraint = contraintHeight
    }
}
extension CatViewController: BreadcrumbsModuleDelegate {
    func didTapBreadcrumbItem(_ sender: UIButton) {
        if preloader.isAnimating {
            NotificationCenter.default.post(name: .flyError,
                                            object: FlyErrorModule(kindVisual: .danger,
                                                                   msg: DictionaryWord.nowIsRequesting.rawValue))
            return
        }
        let tmpCatID = UInt(sender.tag)
        
        if tmpCatID == catID || preloader.isAnimating {
            return
        }
        
        catID = tmpCatID
        viewWillAppear(true)
    }
}
extension CatViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = 0
        
        if collectionView == adsColView {
            count = adsFull.count
        }
        
        return count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let index = indexPath.item
        
        if collectionView == adsColView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! AdModule
            cell.delegate = self
            cell.setup(adFull: adsFull[index])
            return cell
        }
        
        return collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath)
    }
}
extension CatViewController: AdDelegate {
    func showAdFull(_ adID: UInt) {
        navigationController?.pushViewController(AdViewController(adID), animated: true)
    }
}
extension CatViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let c = scrollView.contentOffset.y + scrollView.frame.height - (breadcrumbs.frame.height + 10) // 10 - spacing
        if c < adsColView.frame.height || preloader.isAnimating || isLoadAll || catID < 1 {
            return
        }
        send()
    }
}
extension CatViewController: BricksModuleDelegate {
    func bricksDidSendCatID(_ catIDSrc: UInt) {
        catID = catIDSrc
        viewWillAppear(true)
    }
}
extension CatViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print(searchText)
    }
}
