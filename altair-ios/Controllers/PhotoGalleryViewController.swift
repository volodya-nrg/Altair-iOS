import UIKit

final class PhotoGalleryViewController: UIViewController { // не наследуемся от BaseViewController
    public var items: [ImageModel] = []
    public var startIndex: Int = 0
    
    private let coof = 10
    private let coofTempo: CGFloat = 400
    private lazy var scrollView: UIScrollView = {
        let x = UIScrollView()
        x.isPagingEnabled = true
        x.translatesAutoresizingMaskIntoConstraints = false
        // x.bounces = false
        return x
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = DictionaryWord.photo.rawValue
        view.backgroundColor = Helper.myColorToUIColor(.black)
        
        attachElements()
        setConstrains()
        addEvents()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    private func createImage(_ img: ImageModel) -> UIImageView {
        let x = UIImageView()
        
        x.contentMode = .scaleAspectFit // .scaleAspectFill
        x.translatesAutoresizingMaskIntoConstraints = false
        x.clipsToBounds = true
        
        if let url = URL(string: "\(Helper.domain)/api/v1/resample/900/0/\(img.filepath)") {
            Helper.downloadImage(url) { image in
                x.image = image
            }
        }
        
        return x
    }
}
extension PhotoGalleryViewController: DisciplineProtocol {
    func attachElements() {
        view.addSubview(scrollView)
    }
    func setConstrains() {
        var aConstraints: [NSLayoutConstraint] = []
        
        aConstraints.append(contentsOf: [
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
        
        scrollView.contentSize.width = view.frame.width * CGFloat(items.count)
        
        var x: CGFloat = 0
        for (i, item) in items.enumerated() {
            let imgView = createImage(item)
            imgView.tag = i + coof
            
            scrollView.addSubview(imgView)
            aConstraints.append(contentsOf: [
                imgView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                imgView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: x),
                imgView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
                imgView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            ])
            
            x += view.frame.width
        }
        
        view.addConstraints(aConstraints)
        scrollView.contentOffset = CGPoint(x: Int(view.frame.width) * startIndex, y: 0)
    }
    func addEvents() {
    }
}
