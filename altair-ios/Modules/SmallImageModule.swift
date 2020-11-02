import UIKit

final class SmallImageModule: UICollectionViewCell {
    private let imageView: UIImageView = {
        let x = UIImageView()
        x.backgroundColor = Helper.myColorToUIColor(.gray7)
        x.translatesAutoresizingMaskIntoConstraints = false
        x.contentMode = .scaleAspectFit
        return x
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
    public func setup(_ filepath: String){
        backgroundColor = Helper.myColorToUIColor(.gray8)
        
        if let url = URL(string: "\(Helper.domain)/api/v1/resample/56/0/\(filepath)") {
            Helper.downloadImage(url) { image in
                self.imageView.image = image
            }
        }
        
        addSubview(imageView)
        addConstraints([
            imageView.widthAnchor.constraint(equalTo: widthAnchor),
            imageView.heightAnchor.constraint(equalTo: heightAnchor),
        ])
    }
}
