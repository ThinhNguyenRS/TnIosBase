//
//  TnResizableModifier.swift
//  TkgFaceSpot
//
//  Created by Thinh Nguyen on 9/24/21.
//

import Foundation
import SwiftUI

struct TnResizableModifier: ViewModifier {
    let maxScale: CGFloat
    let initHeight: CGFloat

    @State private var scale: CGFloat = 1.0
    @State private var currentHeight: CGFloat

    init(initHeight: CGFloat, maxScale: CGFloat = 2) {
        self.initHeight = initHeight
        self.maxScale = maxScale
        self.currentHeight = initHeight
    }
    
    func body(content: Content) -> some View {
        let scaleGesture = MagnificationGesture()
            .onChanged { scale in
                if scale <= maxScale && scale >= 1 {
                    self.scale = scale
                    TnLogger.debug("TnResizableModifier", "scale ...", scale)
                }
            }
            .onEnded { scale in
                currentHeight = initHeight * self.scale
                TnLogger.debug("TnResizableModifier", "scale ended", self.scale)
            }
        content
            .height(currentHeight)
            .scaleEffect(scale)
            .gesture(scaleGesture)
    }
}
