import XPC
import CryptoKit
import SwiftUI
import Foundation
import Security
import CommonCrypto

class XPCFileValidator2: NSObject, XPCFileValidator2Protocol {
    var allFileURLs: [URL] = []
    var progress = Double.zero
    
    func requestFileProcessing(reply: @escaping (Double) -> Void) {
        reply(progress)
    }

    func getAggregatedChecksum(for path: String, algorithmType: String, with reply: @escaping (String?) -> Void) {
        guard let algorithmType = ChecksumAlgorithmType(rawValue: algorithmType) else { reply(nil)
            return
        }
        allFileURLs = getAllFiles(at: path)
        let fileManager = FileManager.default
        var combinedData = Data()
        for (index, fileURL) in allFileURLs.enumerated() {
            if fileManager.isReadableFile(atPath: fileURL.path),
               let checksum = getChecksumWithAlgorithmType(filePath: fileURL.relativePath, algorithmType: algorithmType)?.checksum {
                if let checksumData = checksum.data(using: .utf8) {
                    combinedData.append(checksumData)
                    progress = 100 * Double(index) / Double(allFileURLs.count)
                }
            }
        }
        if algorithmType == .md5 {
            var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            combinedData.withUnsafeBytes {
                CC_MD5($0.baseAddress, CC_LONG(combinedData.count), &digest)
            }
            let checksum = (0..<digest.count).map { String(format: "%02x", digest[$0]) }.joined()
            progress = 100
            reply(checksum)
        } else if algorithmType == .sha256 {
            var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            combinedData.withUnsafeBytes {
                CC_SHA256($0.baseAddress, CC_LONG(combinedData.count), &digest)
            }
            let checksum = (0..<digest.count).map { String(format: "%02x", digest[$0]) }.joined()
            progress = 100
            reply(checksum)
        } else {
            reply(nil)
        }
    }
    
    func getAllFiles(at path: String) -> [URL] {
        let fileManager = FileManager.default
        var allFiles: [URL] = []
        
        var isDirectory: ObjCBool = false
        
        if fileManager.fileExists(atPath: path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                
                do {
                    let contents = try fileManager.contentsOfDirectory(at: URL(fileURLWithPath: path), includingPropertiesForKeys: nil)
                    
                    for item in contents {
                        
                        if item.hasDirectoryPath {
                            
                            let subdirectoryFiles = getAllFiles(at: item.path)
                            allFiles.append(contentsOf: subdirectoryFiles)
                        } else {
                            
                            allFiles.append(item)
                        }
                    }
                } catch {
                    print("Error reading directory: \(error.localizedDescription)")
                }
            } else {
                
                allFiles.append(URL(fileURLWithPath: path))
            }
        } else {
            print("The path does not exist.")
        }
        
        return allFiles
    }

    func getChecksumWithAlgorithmType(filePath: String, algorithmType: ChecksumAlgorithmType) -> ChecksumWithAlgorithmType? {
        let fileURL = URL(fileURLWithPath: filePath)
        do {
            let fileData = try Data(contentsOf: fileURL)
            let checksum: String
            switch algorithmType {
            case .sha256:
                let digest = SHA256.hash(data: fileData)
                checksum = digest.map { String(format: "%02hhx", $0) }.joined()
            case .md5:
                let digest = Insecure.MD5.hash(data: fileData)
                checksum = digest.map { String(format: "%02hhx", $0) }.joined()
            }
            return ChecksumWithAlgorithmType(checksum: checksum, algorithmType: algorithmType)
        } catch {
            print("Error reading file: \(error)")
            return nil
        }
    }

    func checkForValidity(filePath: String, checksum: String, algorithmType: String, with reply: @escaping (Bool) -> Void) {
        let fileURL = URL(fileURLWithPath: filePath)
        guard let algorithmType = ChecksumAlgorithmType(rawValue: algorithmType),
              fileURL.pathExtension == algorithmType.pathExtension else {
            reply(false)
            return
        }
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            reply(content == checksum)
        } catch {
            print(error.localizedDescription)
        }
        reply(false)
    }
}

