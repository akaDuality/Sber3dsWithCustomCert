import Foundation

actor CertificateValidator {
    var certificates = [SecCertificate]()
   
    func prepareCertificates(_ names: [String]) {
        certificates = names.compactMap(certificate(name:))
    }

    private func certificate(name: String) -> SecCertificate? {
        let path = Bundle.main.url(forResource: name, withExtension: "der")
        let certData = try! Data(contentsOf: path!)
        
        let certificate = SecCertificateCreateWithData(nil, certData as CFData)!
        return certificate
    }
    
    func isCertificatesValid(at date: Date) -> Bool {
        for certificate in certificates {
            var trust: SecTrust!
            _ = SecTrustCreateWithCertificates(certificate, nil, &trust)
            
            let _ = SecTrustSetVerifyDate(trust, date as CFDate)

            if !checkValidity(of: trust!) {
                return false
            }
        }
        
        return true
    }
    
    func checkValidity(of serverTrust: SecTrust, anchorCertificatesOnly: Bool = false) -> Bool {
        SecTrustSetAnchorCertificates(serverTrust, certificates as CFArray)
        SecTrustSetAnchorCertificatesOnly(serverTrust, anchorCertificatesOnly)
        var error: CFError?
        let isTrusted = SecTrustEvaluateWithError(serverTrust, &error)
        
        return isTrusted
    }
}
