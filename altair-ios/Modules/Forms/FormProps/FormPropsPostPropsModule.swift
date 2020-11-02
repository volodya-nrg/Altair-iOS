import Foundation

final class FormPropsPostPropsModule: FormBaseModule {
    override init() {
        super.init()
        addArrangedSubview(FormPropsPostPutPropModule())
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
