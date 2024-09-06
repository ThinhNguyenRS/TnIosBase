//
//  BottomButtons.swift
//  TkgFaceRecognition
//
//  Created by Thinh Nguyen on 01/08/2021.
//

import SwiftUI

struct TnNavigableButtonSheetList<Destination: View>: View {
    let buttons: [TnNavigableButtonSheet<Destination>]
    
    var body: some View {
        HStack {
            ForEach(buttons, id: \.label) { button in
                button
                Spacer()
            }
        }
        .tnFormatBottomButtons()
    }
}
