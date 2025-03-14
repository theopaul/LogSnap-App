import SwiftUI
import MessageUI

class MailViewModel: ObservableObject {
    @Published var isShowingMailView = false
    @Published var result: Result<MFMailComposeResult, Error>? = nil
    @Published var subject: String = ""
    
    var canSendMail: Bool {
        MFMailComposeViewController.canSendMail()
    }
    
    func sendEmail(subject: String = "", body: String = "") {
        self.subject = subject
        
        if canSendMail {
            self.isShowingMailView = true
        } else {
            // Handle case where mail cannot be sent
            print("Cannot send mail from this device")
        }
    }
} 