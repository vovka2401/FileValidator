import XPC
import CryptoKit
import SwiftUI
import Foundation
import Security
import CommonCrypto

class ServiceDelegate: NSObject, NSXPCListenerDelegate {
    
    /// This method is where the NSXPCListener configures, accepts, and resumes a new incoming NSXPCConnection.
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        
        // Configure the connection.
        // First, set the interface that the exported object implements.
        newConnection.exportedInterface = NSXPCInterface(with: XPCFileValidator2Protocol.self)
        
        // Next, set the object that the connection exports. All messages sent on the connection to this service will be sent to the exported object to handle. The connection retains the exported object.
        let exportedObject = XPCFileValidator2()
        newConnection.exportedObject = exportedObject
        
        // Resuming the connection allows the system to deliver more incoming messages.
        newConnection.resume()
        
        // Returning true from this method tells the system that you have accepted this connection. If you want to reject the connection for some reason, call invalidate() on the connection and return false.
        return true
    }
    
    func validateCodeSignature() -> Bool {
        guard let appCode = getApplicationCode(),
              let xpcCode = getXPCCode() else {
            return false
        }
        
        var requirement: SecRequirement?
        let status = SecRequirementCreateWithString("anchor apple generic and identifier \"com.devchallenge.FileValidator2\"" as CFString, SecCSFlags(rawValue: 0), &requirement)
        
        if status != errSecSuccess {
            print("Error creating security requirement: \(status)")
            return false
        }
        let validationStatus = SecCodeCheckValidity(xpcCode, SecCSFlags(rawValue: 0), requirement)
        if validationStatus == errSecSuccess {
            print("Validation successful: XPC signature matches application signature.")
            return true
        } else {
            print("Validation failed: \(validationStatus)")
            return false
        }
    }
    
    func getApplicationCode() -> SecCode? {
        var appCode: SecCode?
        let pid = getpid() 
        
        let status = SecCodeCopySelf(SecCSFlags(rawValue: 0), &appCode)
        if status == errSecSuccess {
            return appCode
        } else {
            print("Error obtaining main app code: \(status)")
            return nil
        }
    }
    
    func getXPCCode() -> SecCode? {
        var xpcCode: SecCode?
        let status = SecCodeCopySelf(SecCSFlags(rawValue: 0), &xpcCode)
        if status == errSecSuccess {
            return xpcCode
        } else {
            print("Error obtaining XPC code: \(status)")
            return nil
        }
    }
}

// Create the delegate for the service.
let delegate = ServiceDelegate()

// Set up the one NSXPCListener for this service. It will handle all incoming connections.
let listener = NSXPCListener.service()
listener.delegate = delegate

// Resuming the serviceListener starts this service. This method does not return.
listener.resume()
