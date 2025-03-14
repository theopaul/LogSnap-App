import SwiftUI

public struct FormField: View {
    // MARK: - Properties
    @Binding var text: String
    let placeholder: LocalizedStringKey
    let icon: String
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    let capitalization: TextInputAutocapitalization
    let isMultiline: Bool
    let validation: ((String) -> (Bool, LocalizedStringKey?))?
    
    @State private var isValid: Bool = true
    @State private var errorMessage: LocalizedStringKey? = nil
    @State private var isEditing: Bool = false
    
    private var showIcon: Bool {
        return !icon.isEmpty
    }
    
    private var iconImage: Image? {
        guard !icon.isEmpty else { return nil }
        return Image(systemName: icon)
    }
    
    // MARK: - Initializers
    public init(
        text: Binding<String>,
        placeholder: LocalizedStringKey,
        icon: String,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        capitalization: TextInputAutocapitalization = .sentences,
        isMultiline: Bool = false,
        validation: ((String) -> (Bool, LocalizedStringKey?))? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.icon = icon
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.capitalization = capitalization
        self.isMultiline = isMultiline
        self.validation = validation
    }
    
    // MARK: - Body
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                if showIcon {
                    iconImage?
                        .foregroundColor(.accentColor)
                        .frame(width: 24, height: 24)
                        .padding(.top, 10)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    if isMultiline {
                        ZStack(alignment: .topLeading) {
                            if text.isEmpty {
                                Text(placeholder)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.top, 12)
                            }
                            
                            TextEditor(text: $text)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color.primary.opacity(0.05))
                                .cornerRadius(8)
                                .onChange(of: text) { newValue in
                                    validateInput(newValue)
                                }
                                .onTapGesture {
                                    isEditing = true
                                }
                        }
                    } else if isSecure {
                        SecureField(placeholder, text: $text)
                            .textInputAutocapitalization(capitalization)
                            .keyboardType(keyboardType)
                            .padding(.vertical, 12) // Ensure 44pt minimum height
                            .onChange(of: text) { newValue in
                                validateInput(newValue)
                            }
                            .onTapGesture {
                                isEditing = true
                            }
                    } else {
                        TextField(placeholder, text: $text)
                            .textInputAutocapitalization(capitalization)
                            .keyboardType(keyboardType)
                            .padding(.vertical, 12) // Ensure 44pt minimum height
                            .onChange(of: text) { newValue in
                                validateInput(newValue)
                            }
                            .onTapGesture {
                                isEditing = true
                            }
                    }
                    
                    if let errorMessage = errorMessage, !isValid {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isValid ? Color.primary.opacity(0.1) : Color.red, lineWidth: 1)
                    .background(Color.primary.opacity(0.05).cornerRadius(8))
            )
        }
        .onAppear {
            // Validar o campo no aparecimento para mostrar erros iniciais
            if let validation = validation {
                let (valid, message) = validation(text)
                isValid = valid
                errorMessage = message
            }
        }
        // Ocultar teclado quando o usuário toca fora do campo
        .onTapGesture {
            if isEditing {
                hideKeyboard()
                isEditing = false
            }
        }
    }
    
    // MARK: - Helper Methods
    private func validateInput(_ input: String) {
        if let validation = validation {
            let (valid, message) = validation(input)
            isValid = valid
            errorMessage = message
        } else {
            isValid = true
            errorMessage = nil
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Previews
struct FormField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            FormField(
                text: .constant(""),
                placeholder: "Enter name",
                icon: "person",
                validation: { text in
                    return (text.count >= 3, text.count < 3 ? "Name must be at least 3 characters" : nil)
                }
            )
            .padding()
            
            FormField(
                text: .constant("Test"),
                placeholder: "Enter description",
                icon: "doc.text",
                isMultiline: true
            )
            .padding()
            
            FormField(
                text: .constant("No Icon"),
                placeholder: "Field without icon",
                icon: ""
            )
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
} 