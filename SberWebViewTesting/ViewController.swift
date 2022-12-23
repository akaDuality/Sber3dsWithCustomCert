//
//  ViewController.swift
//  SberWebViewTesting
//
//  Created by Mikhail Rubanov on 21.12.2022.
//

import UIKit
import WebKit

class ViewController: UIViewController {

    let validator = CertificateValidator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
    
        Task {
            let names = ["Russian Trusted Root CA",
                         "Russian Trusted Sub CA"]
            await validator.prepareCertificates(names)
        }
        
        let url = URL(string: "https://sberbank.ru")!
        webView.load(URLRequest(url: url))
    }

    @IBOutlet weak var webView: WKWebView!
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
        
        Task {
            if await validator.checkValidity(of: serverTrust) {
                // Allow our sertificate
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
            } else {
                // Default check for another connections
                completionHandler(.performDefaultHandling, nil)
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        
    }
}
