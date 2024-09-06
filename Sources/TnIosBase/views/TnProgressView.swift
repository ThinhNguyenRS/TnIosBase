//
//  TnProgressView.swift
//  TkgFaceSpot
//
//  Created by Thinh Nguyen on 9/26/21.
//

import SwiftUI

extension View {
    func progressView(inProgress: Binding<Bool>) -> some View {
        ZStack {
            self
            if inProgress.wrappedValue {
                ProgressView("Processing ...".lz())
                    .frame(width: 200, height: 200)
                    .background(Color.dark_8_steel.opacity(0.75))
                    .cornerRadius(40)
                    .animation(.easeInOut, value: UUID())
            }
        }
    }
}
