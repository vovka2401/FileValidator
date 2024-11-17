import SwiftUI

@main
struct FileValidatorApp: App {
    @StateObject var viewModel = MainViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
        .commands {
            CommandMenu("File") {
                Button("Open") {
                    viewModel.openFileDialog()
                }
                .keyboardShortcut("o", modifiers: [.command])
                Button("Save") {
                    viewModel.createChecksumFile()
                }
                .keyboardShortcut("s", modifiers: [.command])
                Button("Generate") {
                    viewModel.generateChecksum()
                }
                .keyboardShortcut("g", modifiers: [.command])
            }
        }
    }
}
