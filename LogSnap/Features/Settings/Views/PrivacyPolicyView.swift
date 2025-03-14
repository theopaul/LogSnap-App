import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(LocalizedStringKey("Privacy Policy"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                
                Group {
                    Text(LocalizedStringKey("Last Updated: March 10, 2024"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(LocalizedStringKey("Introduction"))
                        .font(.headline)
                        .padding(.top, 8)
                    
                    Text(LocalizedStringKey("LogSnap (\"we\", \"our\", or \"us\") respects your privacy and is committed to protecting it through our compliance with this policy. This policy describes the types of information we may collect from you or that you may provide when you use our mobile application (\"App\") and our practices for collecting, using, maintaining, protecting, and disclosing that information."))
                    
                    Text(LocalizedStringKey("Information We Collect"))
                        .font(.headline)
                        .padding(.top, 8)
                    
                    Text(LocalizedStringKey("When you use our App, we may collect the following types of information:"))
                    
                    Text(LocalizedStringKey("• Personal Information: name, email address, or other identifiable information provided by you.\n• Usage Data: information about how you use our App, including preferences and settings.\n• Device Information: device type, operating system, and other technical data."))
                    
                    Text(LocalizedStringKey("How We Use Your Information"))
                        .font(.headline)
                        .padding(.top, 8)
                    
                    Text(LocalizedStringKey("We use the information we collect to:"))
                    
                    Text(LocalizedStringKey("• Provide, maintain, and improve our App and services.\n• Respond to your requests, inquiries, or customer service needs.\n• Send important notices, such as updates about our terms, conditions, and policies.\n• Analyze and understand how users interact with our App.\n• Protect the security and integrity of our App."))
                }
                
                Group {
                    Text(LocalizedStringKey("Data Storage and Security"))
                        .font(.headline)
                        .padding(.top, 8)
                    
                    Text(LocalizedStringKey("We implement appropriate technical and organizational measures to protect your personal data against unauthorized or unlawful processing, accidental loss, destruction, or damage. However, please note that no method of transmission over the internet or electronic storage is 100% secure."))
                    
                    Text(LocalizedStringKey("Your Rights"))
                        .font(.headline)
                        .padding(.top, 8)
                    
                    Text(LocalizedStringKey("Depending on your location, you may have certain rights regarding your personal information, including:"))
                    
                    Text(LocalizedStringKey("• Access to your personal information.\n• Correction of inaccurate or incomplete information.\n• Deletion of your personal information.\n• Restriction or objection to processing of your personal information.\n• Data portability."))
                    
                    Text(LocalizedStringKey("Contact Us"))
                        .font(.headline)
                        .padding(.top, 8)
                    
                    Text(LocalizedStringKey("If you have any questions about this Privacy Policy, please contact us at:\nsupport@logsnap.com"))
                }
            }
            .padding()
        }
        .navigationTitle(LocalizedStringKey("Privacy Policy"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PrivacyPolicyView()
        }
    }
} 