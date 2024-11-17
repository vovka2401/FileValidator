import AppKit
import CryptoKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            Picker("Checksum algorithm type", selection: $viewModel.selectedAlgorithmType) {
                ForEach(ChecksumAlgorithmType.allCases, id: \.self) {
                    Text($0.rawValue)
                }
            }
            .pickerStyle(.segmented)
            button(label: "Open file") {
                viewModel.openFileDialog()
            }
            button(label: "Generate checksums") {
                viewModel.generateChecksum()
            }
            button(label: "Save checksums") {
                viewModel.createChecksumFile()
            }
            button(label: !viewModel.isInProgress ? "Check for validity" : "Cancel") {
                if !viewModel.isInProgress {
                    viewModel.cancelChecksumsGeneration()
                } else {
                    viewModel.checkForValidity()
                }
            }
            ProgressView(value: viewModel.progress, total: 100)
            Text("Selected file: \(viewModel.selectedFilePath ?? "No file selected")")
                .font(.system(size: 16))
            Text("Generated checksum: \(viewModel.checksumWithAlgorithmType?.checksum ?? "No checksum generated")")
                .font(.system(size: 16))
            if let isChecksumValid = viewModel.isChecksumValid {
                Text("Generated checksum IS \(isChecksumValid ? "" : "NOT ")valid")
                    .font(.system(size: 16))
            }
        }
        .frame(width: 700, height: 700)
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.escape) {
            viewModel.cancelChecksumsGeneration()
            return .handled
        }
        .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
            viewModel.handleOnDrop(providers: providers)
        }
    }
    
    func button(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 5)
                .fill(.gray)
                .frame(width: 200, height: 70)
                .overlay {
                    Text(label)
                        .font(.system(size: 20))
                }
        }
        .buttonStyle(.plain)
    }
}
