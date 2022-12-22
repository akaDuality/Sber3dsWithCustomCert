//
//  ViewController.swift
//  SberWebViewTesting
//
//  Created by Mikhail Rubanov on 21.12.2022.
//

import UIKit
import WebKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        webView.navigationDelegate = self
        let sber = URL(string: "https://sberbank.ru")!
        webView.load(URLRequest(url: sber))
        
        prepareCertificates()
    }
    
    private func prepareCertificates() {
        DispatchQueue.global(qos: .userInitiated).async {
            let path = Bundle.main.url(forResource: "certificate", withExtension: "der")
            let certData = try! Data(contentsOf: path!)
            
            if let certificate = SecCertificateCreateWithData(nil, certData as CFData) {
                DispatchQueue.main.async {
                    self.certificates = [certificate]
                }
                
            }
        }
    }
    
    var certificates = [SecCertificate]()

    @IBOutlet weak var webView: WKWebView!
    
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


// https://developer.apple.com/library/archive/technotes/tn2232/_index.html#//apple_ref/doc/uid/DTS40012884

// Custom Certificate Authority
// If your server's certificate is issued by a certificate authority that is not trusted by the system by default, you can resolve the resulting server trust evaluation failure by including the certificate authority's root certificate in your program. The procedure is as follows:
//
// include a copy of the certificate authority's root certificate in your program
// once you have the trust object, create a certificate object from the certificate data (SecCertificateCreateWithData) and then set that certificate as a trusted anchor for the trust object (SecTrustSetAnchorCertificates)
// SecTrustSetAnchorCertificates sets a flag that prevents the trust object from trusting any other anchors; if you also want to trust the default system anchors, call SecTrustSetAnchorCertificatesOnly to clear that flag
// evaluate the trust object as per usual

//https://github.com/rnapier/practical-security/blob/master/SelfCert/SelfCert/Connection.m
//https://fivedottwelve.com/blog/installing-custom-rootca-certificates-programmatically-with-swift/

// openssl x509 -in russian_trusted_root_ca.cer -outform der -out certificate.der
