# Разрашаем Сбербанку проходить 3ds

15 февраля 2023 года у Сбера кончится сертификат и надо переходить на самоподписный. Это ведет к изменениям в коде, пример решения в этом репозитории.

В примере проверяю доступность sberbank.ru, у него такое же состояние как и у экранов 3ds.

## Скорее всего у вас уже стоит этот флаг в Info.plist: он нужен чтобы вообще уметь хоть что-то грузить в WKWebView. На ревью Apple спросит зачем вам, расскажите про 3ds.

```
<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsArbitraryLoadsInWebContent</key>
		<true/>
	</dict>
```

## Все экраны будут проходить челендж, но Сбербанк не сможет пройти дефолтные проверки. Поэтому нам надо проверять сертификат вручную. 

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
        DispatchQueue.global(qos: .background).async {
            guard let serverTrust = challenge.protectionSpace.serverTrust else {
                return completionHandler(.performDefaultHandling, nil)
            }

            if self.checkValidity(of: serverTrust) {
                // Allow our sertificate
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
            } else {
                // Default check for another connections
                completionHandler(.performDefaultHandling, nil)
            }
        }
    }
    
    private func checkValidity(of serverTrust: SecTrust) -> Bool {
        SecTrustSetAnchorCertificates(serverTrust, self.certificates as CFArray);
        SecTrustSetAnchorCertificatesOnly(serverTrust, true);

        var error: CFError?
        let isTrusted = SecTrustEvaluateWithError(serverTrust, &error);
        
        return isTrusted
    }
}
```

## Подставляем правильный сертификат

Берем отсюда [https://www.gosuslugi.ru/crt](https://www.gosuslugi.ru/crt). Качайте андроидный сертификат, потому что для iOS он выдает профиль, а он нам не нужен. 

Конвертируем .cer в .der, потому что iOS только в .der умеет работать.

`openssl x509 -in russian_trusted_root_ca.cer -outform der -out certificate.der`

Если вы почему то доверяете мне, а не минцифре, то можете сразу взять готовый

[certificate.der](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/fb1de4df-226f-4f8f-9552-5e6dc1db3c7b/certificate.der)

Добавляете его в проект, линкуете так, чтобы он попал в бандл.

## Готово
Запускайте проект, сайт сбера должен открыться

## Вопросы
- [ ] Будут ли проблемы у других банков? Их все придется добавлять по одному?
- [ ] Как это решение влияет на PCI DSS?
