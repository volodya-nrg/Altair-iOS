struct JWTPayloadModel: Codable {
    var Domain: String
    var Exp: UInt
    var UserID: UInt
    var UserRole: String
    var JWT: String
}
