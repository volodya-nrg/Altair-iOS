class CatModel: Codable {
    var catID: UInt = 0
    var name: String = ""
    var slug: String = ""
    var parentID: UInt = 0
    var pos: UInt = 0
    var isDisabled: Bool = false
    var priceAlias: String = ""
    var priceSuffix: String = ""
    var titleHelp: String = ""
    var titleComment: String = ""
    var isAutogenerateTitle: Bool = false
}
class CatTreeModel: Codable {
    var catID: UInt
    var name: String
    var slug: String
    var parentID: UInt
    var pos: UInt
    var isDisabled: Bool
    var priceAlias: String
    var priceSuffix: String
    var titleHelp: String
    var titleComment: String
    var isAutogenerateTitle: Bool
    var childes: [CatTreeModel] = []
}
class CatFullModel: Codable {
    var catID: UInt
    var name: String
    var slug: String
    var parentID: UInt
    var pos: UInt
    var isDisabled: Bool
    var priceAlias: String
    var priceSuffix: String
    var titleHelp: String
    var titleComment: String
    var isAutogenerateTitle: Bool
    var props: [PropFullModel] = []
}
struct CatTreeFullModel: Codable {
    var catID: UInt
    var name: String
    var slug: String
    var parentID: UInt
    var pos: UInt
    var isDisabled: Bool
    var priceAlias: String
    var priceSuffix: String
    var titleHelp: String
    var titleComment: String
    var isAutogenerateTitle: Bool
    var childes: [CatTreeFullModel] = []
    var props: [PropFullModel] = []
}
struct CatWithDeepModel: Codable {
    var catID: UInt = 0
    var name: String = ""
    var slug: String = ""
    var parentID: UInt = 0
    var pos: UInt = 0
    var isDisabled: Bool = false
    var priceAlias: String = ""
    var priceSuffix: String = ""
    var titleHelp: String = ""
    var titleComment: String = ""
    var isAutogenerateTitle: Bool = false
    var deep: UInt = 0
}
