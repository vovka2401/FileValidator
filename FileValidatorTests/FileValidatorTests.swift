import XCTest
@testable import FileValidator

final class FileValidatorTests: XCTestCase {
    private var viewModel: MainViewModel!

    override func setUpWithError() throws {
        viewModel = MainViewModel()
        viewModel.selectedFilePath = getRelativePathToTestImage()
        viewModel.checksumWithAlgorithmType = nil
        viewModel.isChecksumValid = nil
    }

    override func tearDownWithError() throws {
        viewModel = nil
    }
    

    func testChecksumIsNotNilUsingSHA256() {
        viewModel.selectedAlgorithmType = .sha256
        viewModel.generateChecksum()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let checksum = self.viewModel.checksumWithAlgorithmType?.checksum
            XCTAssertNotNil(checksum)
        }
    }
    
    func testChecksumIsNotNilUsingMD5() {
        viewModel.selectedAlgorithmType = .md5
        viewModel.generateChecksum()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let checksum = self.viewModel.checksumWithAlgorithmType?.checksum
            XCTAssertNotNil(checksum)
        }
    }

    func getRelativePathToTestImage() -> String? {
        if let url = Bundle(for: type(of: self)).url(forResource: "testImage", withExtension: "png") {
            return url.relativePath
        } else {
            print("Image not found in the test bundle.")
            return nil
        }
    }
}
