
import Foundation

@objc protocol XPCFileValidator2Protocol {
    
    func getAggregatedChecksum(for path: String, algorithmType: String, with reply: @escaping (String?) -> Void)
    
    func checkForValidity(filePath: String, checksum: String, algorithmType: String, with reply: @escaping (Bool) -> Void)
    
    func requestFileProcessing(reply: @escaping (Double) -> Void)

}
