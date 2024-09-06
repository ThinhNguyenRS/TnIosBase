//
//  TnSelectableListView.swift
//  TkgFaceRecognition
//
//  Created by Thinh Nguyen on 9/10/21.
//

import SwiftUI

struct TnSelectableListView<TItem: Equatable, TItemView: View>: View {
    struct SelectableItem {
        let item: TItem
        var selected = false
    }
    
    @Binding var items: [TItem]
    @Binding var selectable: Bool
    let itemView: (Int, TItem) -> TItemView

    @State var selectableItems: [SelectableItem] = []
    @State private var selectedIndexs: Set<Int> = []
    
    var body: some View {
        ScrollView {
            VStack {
                tnForEach(selectableItems) { idx, item in
                    HStack {
                        if selectable {
                            Group {
                                if item.selected {
                                    Image.iconCheckCircle
                                        .tnMakeScalable()
                                } else {
                                    Image.iconCheckNone
                                        .tnMakeScalable()
                                }
                            }
                            .height(30)
                            .onTapGesture {
                                toggle(idx)
                            }
                        }
                        itemView(idx, item.item)
                    }
                }
            }
        }
        .onChange(of: items, perform: { _ in
            self.selectableItems = items.map {item in
                SelectableItem(item: item)
            }
            TnLogger.debug("TnSelectableListView", "items changed", self.selectableItems.count)
        })
        .onAppear {
            self.selectableItems = items.map {item in
                SelectableItem(item: item)
            }
            
            TnLogger.debug("TnSelectableListView", "list count", self.selectableItems.count)
        }
    }
}

extension TnSelectableListView {
    func toggle(_ idx: Int) {
        selectableItems[idx].selected.toggle()
    }
}
