//
//  TnScroller.swift
//  TkgFaceSpot
//
//  Created by Thinh Nguyen on 11/1/21.
//

import SwiftUI

func getScrollerView(_ proxy: ScrollViewProxy, count: Int) -> some View {
    HStack {
        tnButton(Image.iconArrowTopView) {
            withAnimation {
                proxy.scrollTo(0, anchor: .top)
            }
        }
        Spacer()
        tnButton(Image.iconArrowBottomView) {
            withAnimation {
                proxy.scrollTo(count-1, anchor: .top)
            }
        }
    }.padding(.all, 4)
}

