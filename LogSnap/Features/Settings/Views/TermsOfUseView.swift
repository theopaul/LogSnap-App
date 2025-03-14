import SwiftUI

struct TermsOfUseView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(LocalizedStringKey("Terms of Use"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                
                Group {
                    Text(LocalizedStringKey("Last Updated: March 10, 2024"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(LocalizedStringKey("Agreement to Terms"))
                        .font(.headline)
                        .padding(.top, 8)
                    
                    Text(LocalizedStringKey("By accessing or using LogSnap (the \"App\"), you agree to be bound by these Terms of Use (\"Terms\"). If you disagree with any part of the terms, then you may not access or use the App."))
                    
                    Text(LocalizedStringKey("Use License"))
                        .font(.headline)
                        .padding(.top, 8)
                    
                    Text(LocalizedStringKey("Permission is granted to download and use the App on your device subject to the following conditions:"))
                    
                    Text(LocalizedStringKey("• The App shall be used for personal, non-commercial purposes only.\n• You shall not modify, decompile, or reverse engineer the App or any part thereof.\n• You shall not make the App available over a network where it could be downloaded by multiple devices.\n• You shall not remove any proprietary notices from the App.\n• You shall not transfer, sublicense, or distribute the App without our express permission."))
                    
                    Text(LocalizedStringKey("Intellectual Property"))
                        .font(.headline)
                        .padding(.top, 8)
                    
                    Text(LocalizedStringKey("The App and its content, features, and functionality are owned by LogSnap and are protected by international copyright, trademark, patent, and other intellectual property or proprietary rights laws."))
                }
                
                Group {
                    Text(LocalizedStringKey("User Content"))
                        .font(.headline)
                        .padding(.top, 8)
                    
                    Text(LocalizedStringKey("You retain any intellectual property rights in content you submit through the App. By posting, uploading, or otherwise making available any content through the App, you grant us a worldwide, non-exclusive, royalty-free license to use, reproduce, modify, adapt, publish, translate, distribute, and display your content."))
                    
                    Text(LocalizedStringKey("Termination"))
                        .font(.headline)
                        .padding(.top, 8)
                    
                    Text(LocalizedStringKey("We may terminate or suspend your access to the App immediately, without prior notice or liability, for any reason, including, without limitation, if you breach these Terms. Upon termination, your right to use the App will cease immediately."))
                    
                    Text(LocalizedStringKey("Limitation of Liability"))
                        .font(.headline)
                        .padding(.top, 8)
                    
                    Text(LocalizedStringKey("In no event shall LogSnap, its directors, employees, partners, agents, suppliers, or affiliates be liable for any indirect, incidental, special, consequential, or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from your access to or use of or inability to access or use the App."))
                    
                    Text(LocalizedStringKey("Governing Law"))
                        .font(.headline)
                        .padding(.top, 8)
                    
                    Text(LocalizedStringKey("These Terms shall be governed by and construed in accordance with the laws of the jurisdiction in which the App owner operates, without regard to its conflict of law provisions."))
                }
                
                Group {
                    Text(LocalizedStringKey("Changes to Terms"))
                        .font(.headline)
                        .padding(.top, 8)
                    
                    Text(LocalizedStringKey("We reserve the right to modify or replace these Terms at any time. It is your responsibility to review these Terms periodically for changes. Your continued use of the App following the posting of revised Terms means that you accept and agree to the changes."))
                    
                    Text(LocalizedStringKey("Contact Us"))
                        .font(.headline)
                        .padding(.top, 8)
                    
                    Text(LocalizedStringKey("If you have any questions about these Terms, please contact us at:\nsupport@logsnap.com"))
                }
            }
            .padding()
        }
        .navigationTitle(LocalizedStringKey("Terms of Use"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TermsOfUseView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TermsOfUseView()
        }
    }
} 