import Foundation
import RxSwift

final class AuthService {
    private let http = HTTPClient()
    
    func login(_ data: [String: Any]) -> Observable<JWTModel> {
        return http.post("/api/v1/auth/login", data)
    }
    func logout() -> Observable<EmptyModel> {
        return http.get("/api/v1/auth/logout")
    }
    func refreshTokens() -> Observable<JWTModel> {
        return http.post("/api/v1/auth/refresh-tokens")
    }
    func isAdmin() -> Bool {
        guard JWTSingleton.instance.data != "" else {return false}
        guard let jwt = parseJWT(JWTSingleton.instance.data) else {return false}
        return jwt.UserRole == "admin"
    }
    private func parseJWT(_ value: String) -> JWTPayloadModel? {
        var result: JWTPayloadModel?
        let segments = value.components(separatedBy: ".")
        var base64 = segments[0]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let length = Double(base64.lengthOfBytes(using: .utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = requiredLength - length
        
        if paddingLength > 0 {
            let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
            base64 = base64 + padding
        }
        
        guard let bodyData = Data(base64Encoded: base64, options: .ignoreUnknownCharacters) else {return result}
        
        do {
            result = try JSONDecoder().decode(JWTPayloadModel.self, from: bodyData)
            
        } catch (let error) {
            print(error)
        }
        
        return result
    }
}
