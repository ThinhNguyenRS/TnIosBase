//
//  ActionButton.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 01/08/2021.
//

import SwiftUI

struct TnNavigableButtonSheet<Destination: View>: View {
    @Binding var showActions: Bool
    let icon: Image
    var label: String? = nil
    let destination: () -> Destination
    var width: CGFloat? = nil
    var action: (() -> Void)? = nil
    var isModal = true

    var buttonView: some View {
        Button(
            action: {
                action?()
                showActions = true
            },
            label: {
                tnIconText(icon: icon, label: label, width: width)
            }
        )
    }
    
    var body: some View {
        if isModal {
            buttonView
            .fullScreenCover(isPresented: $showActions) {
                destination()
            }
        } else {
            buttonView
            .sheet(isPresented: $showActions) {
                destination()
            }
        }
    }
}
