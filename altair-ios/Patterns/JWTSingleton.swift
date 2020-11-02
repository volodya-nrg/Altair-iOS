import Foundation

final class JWTSingleton {
    static let instance = JWTSingleton()
    
    private init(){
    }
    
    public var data: String {
        get {
            return UserDefaults.standard.string(forKey: UserDefKeys.JWT.rawValue) ?? ""
        }
        set (newValue) {
            if newValue == "" {
                UserDefaults.standard.removeObject(forKey: UserDefKeys.JWT.rawValue)
                return
            }
            
            UserDefaults.standard.set(newValue, forKey: UserDefKeys.JWT.rawValue)
        }
    }
    public var payload: JWTPayloadModel? {
        get {
            let str = data
            
            if str == "" {
                return nil
            }
            
            let indexDot = str.firstIndex(of: ".") ?? str.endIndex
            let part = str[..<indexDot]
            let base64 = String(part)
            let padded = base64.padding(toLength: ((base64.count + 3) / 4) * 4, withPad: "=", startingAt: 0)
            
            guard let decoded = Data(base64Encoded: padded) else {return nil}
            
            do {
                return try JSONDecoder().decode(JWTPayloadModel.self, from:decoded)
                
            } catch {
                NotificationCenter.default.post(name: .flyError,
                                                object: FlyErrorModule(kindVisual: .danger,
                                                msg: error.localizedDescription))
            }
            
            return nil
        }
    }
}
