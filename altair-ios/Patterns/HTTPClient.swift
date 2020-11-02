import Foundation
import RxSwift

final class HTTPClient {
    public func get<T:Codable>(_ url: String, _ data: [String: Any] = [:]) -> Observable<T> {
        return request("get", url, data, false)
    }
    public func post<T:Codable>(_ url: String, _ data: [String: Any] = [:], _ asMultipart: Bool = false) -> Observable<T> {
        return request("post", url, data, asMultipart)
    }
    public func put<T:Codable>(_ url: String, _ data: [String: Any] = [:], _ asMultipart: Bool = false) -> Observable<T> {
        return request("put", url, data, asMultipart)
    }
    public func delete<T:Codable>(_ url: String, _ data: [String: Any] = [:]) -> Observable<T> {
        return request("delete", url, data, false)
    }
    private func request<T:Codable>(_ methodSrc: String, _ urlSrc: String, _ params: [String: Any], _ asMultipart: Bool) -> Observable<T> {
        let resultSubject = AsyncSubject<T>()
        let minOffsetTimeLifeAccessToken: Double = 10
        let method = methodSrc.uppercased()
        var url = "\(Helper.APIServer)\(urlSrc)"
        
        // удобней вставлять параметры именно тут
        if params.count > 0 && method == "GET" {
            guard let tmp = Helper.queryString(params).addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) else {
                resultSubject.onError(MyError(DictionaryWord.errorInQueryParam.rawValue))
                resultSubject.onCompleted()
                return resultSubject.asObservable()
            }
            url += "?\(tmp)"
        }
        
        guard let requestUrl = URL(string: url) else {
            resultSubject.onError(MyError(DictionaryWord.notCorrectURL.rawValue))
            resultSubject.onCompleted()
            return resultSubject.asObservable()
        }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = method
        request.allHTTPHeaderFields = [
            "Content-Type": "application/json", // корректная передача данных (POST и др.) на сервер (как в Angular)
            "Accept": "application/json, text/plain, */*", // получение данных в виде json (как в Angular)
            "Accept-Language": "ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7", // (как в Angular)
            "Accept-Encoding": "gzip, deflate, br", // (как в Angular)
            "Pragma": "no-cache", // (как в Angular)
            "Cache-Control": "no-cache", // (как в Angular)
        ]

        // передача токена
        if JWTSingleton.instance.data != "" {
            request.addValue("Bearer \(JWTSingleton.instance.data)", forHTTPHeaderField: "Authorization")
            
            // обрабатываем везде, кроме урла заканчивающего на /auth/refresh-tokens
            if urlSrc.hasSuffix("/auth/refresh-tokens") == false {
                if let jwt = JWTSingleton.instance.payload {
                    let locTimestamp = NSDate().timeIntervalSince1970
                    let diffSec = Double(jwt.Exp) - locTimestamp
                    
                    // если осталось 10 секунд до окончания access-token-а
                    if diffSec < minOffsetTimeLifeAccessToken {
                        #if DEBUG
                            print("====> обновление access-token-а")
                        #endif
                        
                        let serviceAuth = AuthService()
                        serviceAuth.refreshTokens().subscribe { JWTModel in
                            JWTSingleton.instance.data = JWTModel.JWT
                            Helper.profile$.onNext(JWTModel.userExt)
                        } onError: { error in
                        } onCompleted: {
                        }.disposed(by: DisposeBag())
                    }
                }
            }
        }
        
        if params.count > 0 && (method == "POST" || method == "PUT") {
            // могут форму передавать и без файла, но на сервере ожидается мультипарт
            
            if asMultipart {
                let body = NSMutableData()
                let boundary = Helper.getUniqHash()
                
                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                
                for (key, value) in params {
                    body.append("--\(boundary)\r\n".data(using: .utf8)!)
                    
                    if (value is Data) {
                        let timestamp = "\(Date().timeIntervalSince1970 * 1000)"
                        body.append("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(timestamp)\"\r\n".data(using:.utf8)!)
                        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
                        body.append(value as! Data)
                        
                    } else {
                        body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                        body.append("\(value)".data(using: .utf8)!)
                    }
                    
                    body.append("\r\n".data(using: .utf8)!)
                }
                
                body.append("--\(boundary)--\r\n".data(using: .utf8)!)
                request.httpBody = body as Data
                
            } else {
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: params)
                    
                } catch (let error) {
                    resultSubject.onError(error)
                    resultSubject.onCompleted()
                    return resultSubject.asObservable()
                }
            }
        }
        
        URLSession.shared.dataTask(with: request) {(dataSrc, response, error) in
            DispatchQueue.main.async {
                if let error = error {
                    NotificationCenter.default.post(name: .flyError,
                                                    object: FlyErrorModule(kindVisual: .danger,
                                                                           msg: error.localizedDescription))
                    resultSubject.onError(error)
                
                } else if let data = dataSrc, let response = response as? HTTPURLResponse {
                    if response.statusCode == 204 { // нет содержимого
                        resultSubject.onNext(EmptyModel() as! AsyncSubject<T>.Element)
                        
                    } else if response.statusCode == 401 { // клиент не авторизован
                        JWTSingleton.instance.data = ""
                        Helper.profile$.onNext(nil)
                        
                        let sData = String(data: data, encoding: String.Encoding.utf8)!
                        resultSubject.onError(MyError(sData))
                        
                        // редирект или всплывающая ошибка проверяется в BaseViewController-е
                        NotificationCenter.default.post(name: .goToLogin,
                                                        object: FlyErrorModule(kindVisual: .warning,
                                                                               msg: sData))
                        
                    } else if response.statusCode == 428 { // отсутствуют данные (обычно куки)
                        // eсли нет куки, то и JWT затираем.
                        JWTSingleton.instance.data = ""
                        Helper.profile$.onNext(nil)
                        
                        let sData = "отсутствуют данные"
                        resultSubject.onError(MyError(sData))
                        NotificationCenter.default.post(name: .goToLogin,
                                                        object: FlyErrorModule(kindVisual: .warning,
                                                                               msg: sData))
                    
                    } else if response.statusCode >= 400 { // неправильный запрос пользователя
                        let sData = String(data: data, encoding: String.Encoding.utf8)!
                        NotificationCenter.default.post(name: .flyError,
                                                        object: FlyErrorModule(kindVisual: .warning,
                                                                               msg: sData))
                        resultSubject.onError(MyError(sData))
                    } else {
                        do {
                            if T.self == EmptyModel.self {
                                resultSubject.onNext(EmptyModel() as! AsyncSubject<T>.Element)
                                
                            } else {
                                let x = try JSONDecoder().decode(T.self, from: data)
                                resultSubject.onNext(x)
                            }
                            
                        } catch (let error) {
                            NotificationCenter.default.post(name: .flyError,
                                                            object: FlyErrorModule(kindVisual: .danger,
                                                                                   msg: error.localizedDescription))
                            resultSubject.onError(error)
                        }
                    }
                }
                
                resultSubject.onCompleted()
            }
        }.resume()
        
        return resultSubject.asObservable()
    }
}
