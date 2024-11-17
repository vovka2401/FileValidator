import Foundation

public enum ChecksumAlgorithmType: String, CaseIterable, Codable {
    case sha256 = "SHA256"
    case md5 = "MD5"

    public var pathExtension: String { rawValue.lowercased() }
}
