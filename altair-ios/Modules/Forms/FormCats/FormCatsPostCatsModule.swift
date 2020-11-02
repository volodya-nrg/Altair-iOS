import Foundation

final class FormCatsPostCatsModule: FormBaseModule {
    override init() {
        super.init()
        addArrangedSubview(FormCatsPostPutCatModule())
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
