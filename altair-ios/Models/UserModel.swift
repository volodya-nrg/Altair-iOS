class UserModel: Codable {
    var userID: UInt
    var email: String
    var isEmailConfirmed: Bool
    var name: String
    var avatar: String
    var createdAt: String
    var updatedAt: String
}
class UserExtModel: Codable {
    var userID: UInt
    var email: String
    var isEmailConfirmed: Bool
    var name: String
    var avatar: String
    var createdAt: String
    var updatedAt: String
    var phones: [PhoneModel] = []
}
