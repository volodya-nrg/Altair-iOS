// т.к. CatTreeModel это рекурсия, то применяется тип class
class SettingsModel: Codable {
    var catsTree: CatTreeModel
    var kindProps: [KindPropModel] = []
    var props: [PropModel] = []
}
