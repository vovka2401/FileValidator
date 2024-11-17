import Foundation
import SwiftUI
import XPCFileValidator2

class MainViewModel: ObservableObject {
    @Published var selectedAlgorithmType = ChecksumAlgorithmType.sha256
    @Published var selectedFilePath: String?
    @Published var selectedChecksumFilePath: String?
    @Published var checksumWithAlgorithmType: ChecksumWithAlgorithmType?
    @Published var isChecksumValid: Bool?
    @Published var isInProgress = false
    @Published var progress: Double?
    @Published var connectionToService: NSXPCConnection?

    init() {
        connectionToService = NSXPCConnection(serviceName: "com.devchallenge.XPCFileValidator2")
        connectionToService?.remoteObjectInterface = NSXPCInterface(with: XPCFileValidator2Protocol.self)
        connectionToService?.resume()
    }
    
    deinit {
        connectionToService?.invalidate()
    }
    
    func openFileDialog() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select a file"
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = false
        guard openPanel.runModal() == .OK else { return }
        selectedFilePath = openPanel.url?.relativePath
        checksumWithAlgorithmType = nil
        isChecksumValid = nil
        progress = 0
    }
    
    func generateChecksum() {
        guard let selectedFilePath else { return }
        if let proxy = connectionToService?.remoteObjectProxy as? XPCFileValidator2Protocol {
            proxy.getAggregatedChecksum(for: selectedFilePath, algorithmType: selectedAlgorithmType.rawValue) { checksum in
                guard let checksum else { return }
                DispatchQueue.main.async { [self] in
                    checksumWithAlgorithmType = ChecksumWithAlgorithmType(checksum: checksum, algorithmType: selectedAlgorithmType)
                }
            }
            let remoteObject = connectionToService?.remoteObjectProxy as? XPCFileValidator2Protocol
            remoteObject?.requestFileProcessing { [weak self] progress in
                DispatchQueue.main.async {
                    self?.progress = progress
                }
            }
        }
    }
    
    func createChecksumFile() {
        guard let selectedFilePath, 
              let checksum = checksumWithAlgorithmType?.checksum,
              let algorithmType = checksumWithAlgorithmType?.algorithmType else { return }
        let fileURL = URL(fileURLWithPath: selectedFilePath)
        let lastPathComponent = fileURL.lastPathComponent
        let checksumFilePath = checksum + "  " + lastPathComponent
        let checksumFileURL = fileURL.deletingLastPathComponent().appending(component: checksumFilePath).appendingPathExtension(algorithmType.pathExtension)
        do {
            try checksum.write(to: checksumFileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to create SHA-256 file: \(error.localizedDescription)")
        }
    }
    
    func checkForValidity() {
        openFileDialogForChecksum()
        guard let selectedChecksumFilePath, let checksumWithAlgorithmType else { return }
        if let proxy = connectionToService?.remoteObjectProxy as? XPCFileValidator2Protocol {
            proxy.checkForValidity(
                filePath: selectedChecksumFilePath,
                checksum: checksumWithAlgorithmType.checksum,
                algorithmType: checksumWithAlgorithmType.algorithmType.rawValue
            ) { isValid in
                DispatchQueue.main.async { [self] in
                    isChecksumValid = isValid
                }
            }
        }
    }
    
    func openFileDialogForChecksum() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select a checksum file"
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = false
        guard openPanel.runModal() == .OK else { return }
        selectedChecksumFilePath = openPanel.url?.relativePath
    }
    
    func cancelChecksumsGeneration() {
        isInProgress = false
    }

    func handleOnDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                provider.loadObject(ofClass: URL.self) { (fileURL, error) in
                    guard let fileURL else {
                        print("Failed to load URL")
                        return
                    }
                    DispatchQueue.main.async { [self] in
                        selectedFilePath = fileURL.relativePath
                        checksumWithAlgorithmType = nil
                        isChecksumValid = nil
                        progress = 0
                    }
                }
            }
        }
        return true
    }
}
