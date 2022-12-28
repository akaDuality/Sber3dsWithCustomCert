//
//  SberWebViewTestingTests.swift
//  SberWebViewTestingTests
//
//  Created by Mikhail Rubanov on 21.12.2022.
//

import XCTest
@testable import SberWebViewTesting

final class SberWebViewTestingTests: XCTestCase {

    var sut: CertificateValidator!
    
    override func setUpWithError() throws {
        sut = CertificateValidator()
        let names = ["Russian Trusted Root CA",
                     "Russian Trusted Sub CA"]
        
        Task {
            await sut.prepareCertificates(names)
        }
    }

    override func tearDown() {
        sut = nil
    }
    
    func test_shouldLoad2Certificates() async {
        let certsCount = await sut.certificates.count
        XCTAssertEqual(certsCount, 2)
    }

    func test_shouldBeValidAt2023() async throws {
        let date = DateComponents(calendar: .current, year: 2023, month: 1, day: 1).date!
        let areCertsValid = await sut.isCertificatesValid(at: date)
        XCTAssertTrue(areCertsValid)
    }
    
    func test_shouwdBeInvalidAt2028() async throws {
        let date = DateComponents(calendar: .current, year: 2028, month: 1, day: 1).date!
        let areCertsValid = await sut.isCertificatesValid(at: date)
        XCTAssertFalse(areCertsValid)
    }
    
    func test_shouldBeValidNextYear() async throws {
        var dateComponent = DateComponents()
        dateComponent.year = 1
        
        let nextYear = Calendar.current.date(byAdding: dateComponent, to: Date())!
        
        let areCertsValid = await sut.isCertificatesValid(at: nextYear)
        XCTAssertTrue(areCertsValid, "Update certificate now to allow users update your application before certificates expires")
        // https://www.gosuslugi.ru/crt
    }
}
