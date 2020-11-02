import UIKit
import RxSwift

final class ProfileAdsViewController: BaseViewController {
    private let serviceProfile = ProfileService()
    private let disposeBag = DisposeBag()
    private let cellID = "ProfileAdsViewControllerCellID"
    private var ads: [AdFullModel] = [] {
        didSet {
            adsColView.reloadData()
            controlHeightAdsColView()
        }
    }
    private let limit: UInt = 2
    private var offset: UInt = 0
    private var isLoadAll = false
    private var saveHeightConstraint = NSLayoutConstraint.init()
    
    private lazy var adsColView: UICollectionView = {
        boxStackView.layoutIfNeeded() // обязателен, а то ломается
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: boxStackView.frame.width - Helper.globalMarginSide * 2, height: Helper.adMiniLineHeight)
        // layout.minimumLineSpacing = 0 // default = 10
        
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
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = DictionaryWord.myAds.rawValue
        
        attachElements()
        setConstrains()
        addEvents()
        send()
    }
    private func send(){
        let data: [String: Any] = [
            "limit": limit,
            "offset": offset,
        ]
        
        preloader.startAnimating()
        serviceProfile.getAds(data).subscribe { adFullModels in
            self.ads.append(contentsOf: adFullModels)
            self.offset += self.limit
            
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
        adsColView.layoutIfNeeded()
        let contraintHeight = adsColView.heightAnchor.constraint(greaterThanOrEqualToConstant: adsColView.contentSize.height)
        NSLayoutConstraint.deactivate([saveHeightConstraint])
        NSLayoutConstraint.activate([contraintHeight])
        saveHeightConstraint = contraintHeight
    }
    private func reset() {
        offset = 0
        isLoadAll = false
        adsColView.contentSize = .zero
        ads.removeAll()
    }
}
extension ProfileAdsViewController: DisciplineProtocol {
    func attachElements() {
        boxStackView.addArrangedSubview(adsColView)
        view.addSubview(preloader)
    }
    func setConstrains() {
        view.addConstraints([
            preloader.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -1 * Helper.em1),
            preloader.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    func addEvents() {
        boxScrollView.delegate = self // присоединяемся чтоб отслеживать scroll
        
        // слушаем обновления (объявлений) профиля
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onListenerProfileAdsUpdate(_:)),
                                               name: .profileAdsUpdate,
                                               object: nil)
    }
}
extension ProfileAdsViewController {
    @objc private func onListenerProfileAdsUpdate(_ notif: Notification) {
        reset()
        send()
    }
}
extension ProfileAdsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ads.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! AdModule
        let index = indexPath.item
        
        cell.delegate = self
        cell.setup(adFull: ads[index], opt: .line, inProfile: true)
        
        return cell
    }
}
extension ProfileAdsViewController: AdDelegate {
    func showAdFull(_ adID: UInt) {
        let x = AdViewController(adID)
        navigationController?.pushViewController(x, animated: true)
    }
    func goToEdit(_ adID: UInt) {
        let x = AdCreateEditViewController()
        x.adID = adID
        navigationController?.pushViewController(x, animated: true)
    }
}
extension ProfileAdsViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let c = scrollView.contentOffset.y + scrollView.frame.height
        
        if c < adsColView.frame.height || preloader.isAnimating || isLoadAll {
            return
        }
        
        send()
    }
}
