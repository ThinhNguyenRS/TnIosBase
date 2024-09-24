//
//  TnSelectableModifier.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 9/12/21.
//

import Foundation
import SwiftUI

struct TnSelectableModifier<TTag: Hashable>: ViewModifier {
    let tag: TTag
    @Binding var tags: Set<TTag>
    var checkColor: Color = .red
    
    var isSelected: Bool {
        tags.contains(tag)
    }
    
    func body(content: Content) -> some View {
        ZStack(alignment: .bottom){
            content
            if isSelected {
                Image.iconCheckCircleFill
                    .foregroundColor(checkColor)
                    .padding(.all, 4)
//                VStack {
//                    Spacer()
//                    HStack {
//                        Spacer()
//                        Image.iconCheckCircleFill
//                            .foregroundColor(checkColor)
//                            .padding(.all, 4)
//                        Spacer()
//                    }
//                }
            }
        }
        .onTapGesture {
            withAnimation {
                if tags.contains(tag) {
                    tags.remove(tag)
                } else {
                    tags.insert(tag)
                }
            }
        }
    }
}
