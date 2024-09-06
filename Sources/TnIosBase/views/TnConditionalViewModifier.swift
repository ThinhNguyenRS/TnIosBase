//
//  TnConditionalViewModifier.swift
//  tCamera
//
//  Created by Thinh Nguyen on 7/29/24.
//

import Foundation
import SwiftUI

struct TnConditionalViewModifier: ViewModifier {
    let condition: Bool

    func body(content: Content) -> some View {
        Group {
            if condition {
                content
            } else {
                EmptyView()
            }
        }
    }
}

extension View {
    /// Whether the view should be empty.
    /// - Parameter bool: Set to `true` to hide the view (return EmptyView instead). Set to `false` to show the view.
    func tnCondition(_ v: Bool) -> some View {
        modifier(TnConditionalViewModifier(condition: v))
    }
}
