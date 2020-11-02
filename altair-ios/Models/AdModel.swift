struct AdModel: Codable {
    var adID: UInt
    var title: String
    var slug: String
    var catID: UInt
    var userID: UInt
    var description: String
    var price: UInt
    var IP: String
    var isDisabled: Bool
    var isApproved: Bool
    var hasPhoto: Bool
    var youtube: String
    var latitude: Float
    var longitude: Float
    var cityName: String
    var countryName: String
    var phoneID: UInt
    var createdAt: String
    var updatedAt: String
}
class AdFullModel: Codable {
    var adID: UInt = 0
    var title: String = ""
    var slug: String = ""
    var catID: UInt = 0
    var userID: UInt = 0
    var description: String = ""
    var price: UInt = 0
    var IP: String = ""
    var isDisabled: Bool = false
    var isApproved: Bool = false
    var hasPhoto: Bool = false
    var youtube: String = ""
    var latitude: Float = 0.0
    var longitude: Float = 0.0
    var cityName: String = ""
    var countryName: String = ""
    var phoneID: UInt = 0
    var createdAt: String = ""
    var updatedAt: String = ""
    var images: [ImageModel] = []
    var detailsExt: [AdDetailExtModel] = []
}
struct AdDetailModel: Codable {
    var adID: UInt
    var propID: UInt
    var value: String
}
struct AdDetailExtModel: Codable {
    var adID: UInt
    var propID: UInt
    var value: String // и цифры могут быть и строки
    var propName: String
    var kindPropName: String
    var valueName: String
}
