//
//  ToggleField.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 8/19/21.
//

import SwiftUI

public struct TnToggleField: View {
    let label: String
    var value: Binding<Bool>
    var onChanged: ((Bool) -> Void)? = nil
    
    public init(label: String, value: Binding<Bool>, onChanged: ((Bool) -> Void)? = nil) {
        self.label = label
        self.value = value
        self.onChanged = onChanged
    }

    public var body: some View {
        Toggle(isOn: value) {
            tnText(label)
        }
        .onChange(of: value.wrappedValue, perform: { v in
            onChanged?(v)
        })
    }
}
