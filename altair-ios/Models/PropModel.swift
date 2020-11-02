struct PropModel: Codable {
    var propID: UInt = 0
    var title: String = ""
    var kindPropID: UInt = 0
    var name: String = ""
    var suffix: String = ""
    var comment: String = ""
    var privateComment: String = ""
}
class PropFullModel: Codable {
    var propID: UInt
    var title: String
    var kindPropID: UInt
    var name: String
    var suffix: String
    var comment: String
    var privateComment: String
    var kindPropName: String
    var propPos: UInt
    var propIsRequire: Bool
    var propIsCanAsFilter: Bool
    var propComment: String
    var values: [ValuePropModel] = []
}
class PropWithKindNameModel: Codable {
    var propID: UInt
    var title: String
    var kindPropID: UInt
    var name: String
    var suffix: String
    var comment: String
    var privateComment: String
    var kindPropName: String
}

struct PropAssignedForCatModel: Codable {
    var propID: UInt = 0
    var title: String = ""
    var comment: String = ""
    var pos: UInt = 0
    var isRequire: Bool = false
    var isCanAsFilter: Bool = false
    
    init(_ y: PropFullModel?) {
        if let x = y {
            self.propID = x.propID
            self.title = x.title
            self.comment = x.propComment
            self.pos = x.propPos
            self.isRequire = x.propIsRequire
            self.isCanAsFilter = x.propIsCanAsFilter

            if x.privateComment != "" {
                self.title += " (\(x.privateComment))"
            }
        }
    }
}
