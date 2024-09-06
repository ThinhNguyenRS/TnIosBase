//
//  TnToggleButton.swift
//  TkgFaceSpot
//
//  Created by Thinh Nguyen on 11/1/21.
//

import SwiftUI

public struct TnToggleButton: View {
    let isOn: () -> Bool
    let action: (Bool) -> Void
    
    public init(isOn: @escaping () -> Bool, action: @escaping (Bool) -> Void) {
        self.isOn = isOn
        self.action = action
    }

    public var body: some View {
        tnButton(
            ZStack {
                Circle()
                    .strokeBorder(Color.accentColor, lineWidth: 2)
                    .frame(width: 32, height: 32)
                if isOn() {
                    Image.iconCheck
                }
            }
        ) {
            action(!isOn())
        }
    }
}


