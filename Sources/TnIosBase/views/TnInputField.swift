//
//  TnTextField.swift
//  TkgFaceRecognition
//
//  Created by Thinh Nguyen on 8/18/21.
//

import SwiftUI
import Combine


//func _TnInputField<TInput: View>(label: String, input: TInput, keyboardType: UIKeyboardType = .default) -> some View {
//    VStack(alignment: .leading, spacing: TnFieldExtensions.spacing){
//        TnText(label.lz())
//        input
//            .textFieldStyle(RoundedBorderTextFieldStyle())
//    }
//}
//
//func TnInputFieldText(label: String, value: Binding<String>, maxLength: Int = 0, keyboardType: UIKeyboardType = .default) -> some View {
//    let limitText: (String) -> String = { v in
//        var vRet = v
//        if maxLength > 0 && v.count > maxLength {
//            vRet = String(v.prefix(maxLength))
//        }
//        return vRet
//    }
//
//    return _TnInputField(
//        label: label,
//        input: TextField(label.lz(), text: value)
//            .onReceive(Just(value)) { _ in value.wrappedValue = limitText(value.wrappedValue) }
//        ,
//        keyboardType: keyboardType)
//}
//
func tnInputField<TInput: View>(label: String, input: TInput, showCaption: Bool = true) -> some View {
    Group {
        if showCaption && label.count > 0 {
            VStack(alignment: .leading, spacing: TnFieldExtensions.spacing){
                tnText(label.lz())
                input
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        } else {
            input
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct TnTextField: View {
    let label: String
    @Binding var value: String
    var maxLength = 0
    var keyboardType: UIKeyboardType = .default
    var defaultValue: String? = nil
    var showCaption: Bool = true
    
    var body: some View {
        tnInputField(
            label: label,
            input: TextField(label.lz(), text: $value)                
                .keyboardType(keyboardType)
                .onReceive(Just(value)) { _ in limitText() },
            showCaption: showCaption
        )
        .onAppear {
            if value.count == 0 {
                value = defaultValue ?? ""
            }
        }
    }

    func limitText() {
        if maxLength > 0 && value.count > maxLength {
            value = String(value.prefix(maxLength))
        }
    }
}

func tnNumberField<V: FixedWidthInteger>(
    label: String,
    value: Binding<V>,
    maxLength: Int = 0,
    keyboardType: UIKeyboardType = .numberPad,
    defaultValue: V? = nil,
    showCaption: Bool = true) -> some View {
    let valueString: Binding<String> = Binding {
        String(value.wrappedValue)
    } set: { s in
        value.wrappedValue = V(s) ?? 0
    }    
    let defaultString: String? = defaultValue == nil ? nil : String(defaultValue!)
    return TnTextField(label: label, value: valueString, maxLength: maxLength, keyboardType: .numberPad, defaultValue: defaultString, showCaption: showCaption)
}

struct TnPasswordField: View {
    let label: String
    @Binding var value: String
    var maxLength = 0
    var defaultValue: String? = nil

    var body: some View {
        tnInputField(
            label: label,
            input: SecureField(label.lz(), text: $value)
                .onReceive(Just(value)) { _ in limitText() }
        )
        .onAppear {
            if value.count == 0 {
                value = defaultValue ?? ""
            }
        }
    }

    func limitText() {
        if maxLength > 0 && value.count > maxLength {
            value = String(value.prefix(maxLength))
        }
    }
}
