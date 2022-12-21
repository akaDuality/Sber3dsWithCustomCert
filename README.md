# 3ds в Сбербанке после 15 февраля

# Разрешаем сберу чуть больше чем остальным

Ослабляем правила для Сбера в Info.plist
```
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSExceptionDomains</key>
  <dict>
    <key>sberbank.ru</key>
    <dict>
      <key>NSExceptionAllowsInsecureHTTPLoads</key>
      <true/>
      <key>NSIncludesSubdomains</key>
      <true/>
    </dict>
  </dict>
</dict>
```

# Но проверяем что мы можем ему доверять

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    
    webView.navigationDelegate = self

    let sber = URL(string: "https://sberbank.ru")!
    webView.load(URLRequest(url: sber))
}

extension ViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            return completionHandler(.performDefaultHandling, nil)
        }
        
        DispatchQueue.global(qos: .background).async {
            let path = Bundle.main.url(forResource: "certificate", withExtension: "der")
            let certData = try! Data(contentsOf: path!)
    
            guard let certificate = SecCertificateCreateWithData(nil, certData as CFData) else {
                return completionHandler(.performDefaultHandling, nil)
            }
            
            let anchors = [certificate]
            
            
            SecTrustSetAnchorCertificates(serverTrust, anchors as CFArray);
            SecTrustSetAnchorCertificatesOnly(serverTrust, true);

            var error: CFError?
            let isTrusted = SecTrustEvaluateWithError(serverTrust, &error);
            
            if isTrusted {
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        }
    }
}
```

# Подставляем правильный сертификат

Берем отсюда [https://www.gosuslugi.ru/crt](https://www.gosuslugi.ru/crt)

Конвертируем .cer в .der, потому что iOS только в .der умеет работать.

`openssl x509 -in russian_trusted_root_ca.cer -outform der -out certificate.der`

Если вы почему то доверяете мне, а не минцифре, то можете сразу взять готовый

[certificate.der](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/fb1de4df-226f-4f8f-9552-5e6dc1db3c7b/certificate.der)

Добавляете его в проект, линкуете так, чтобы он попал в бандл.

Запускайте проект, сайт сбера должен открыться
