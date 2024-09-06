//
//  TnFIeldView.swift
//  TkgFaceSpot
//
//  Created by Thinh Nguyen on 10/11/21.
//

import SwiftUI

func tnFieldView<TContent: View>(_ label: String, content: @escaping () -> TContent) -> some View {
    HStack {
        tnText(label)
        Spacer()        
        content()
    }
    .lineLimit(1)
}

func tnFieldView(_ label: String, content: String) -> some View {
    HStack {
        tnText(label)
        Spacer()
        Text(content)
    }
    .lineLimit(1)
}
