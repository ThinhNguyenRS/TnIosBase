//
//  TnSheet.swift
//  TkgFaceSpot
//
//  Created by Thinh Nguyen on 10/19/21.
//

import SwiftUI

struct TnSheetButton<TButtonView: View>: View {
    let view: TButtonView
    let action: (() -> Void)?
    var isPresented: Binding<Bool>? = nil

    var body: some View {
        Group {
            if let action = action {
//                tnButton(HStack {
//                    Spacer()
//                    view.padding(.all, 8)
//                    Spacer()
//                }) {
//                    DispatchQueue.main.async {
//                        isPresented?.wrappedValue = false
//                    }
//                    action()
//                }
                tnButton(view.padding(.all, 8)) {
                    DispatchQueue.main.async {
                        isPresented?.wrappedValue = false
                    }
                    action()
                }
            } else {
                view
            }
        }
    }
}

func tnSheetButton<TButtonView: View>(_ label: TButtonView, isPresented: Binding<Bool>, action: @escaping () -> Void) -> some View {
    TnSheetButton(view: label, action: action, isPresented: isPresented)
}
func tnSheetButton(_ label: String, isPresented: Binding<Bool>, action: @escaping () -> Void) -> some View {
    tnSheetButton(tnText(label), isPresented: isPresented, action: action)
}
func tnSheetButton<TIcon: View>(_ label: String, icon: TIcon, isPresented: Binding<Bool>, action: @escaping () -> Void) -> some View {
    tnSheetButton(
        HStack {
            tnText(label)
            Spacer()
            icon
        },
        isPresented: isPresented,
        action: action)
}
func tnSheetButtonDivider() -> some View {
    TnSheetButton(view: Divider(), action: nil)
}

func tnSheetView<TContent: View>(isPresented: Binding<Bool>, title: String, content: @escaping () -> TContent) -> some View {
    VStack {
        ZStack(alignment: .trailing){
            HStack {
                Spacer()
                tnText(title)
                Spacer()
            }
            .height(44)
            .background(Color.background85)

            tnButton(Image.iconCloseCircle.buttonPage().foregroundColor(.primary),
                     action: {
                    withAnimation {
                        isPresented.wrappedValue.toggle()
                    }
                }
            ).offset(x: -8, y: 0)
        }
        
        content()
            .padding(.bottom, 8)
//            .font(.system(size: 20))
    }
    .padding(.all, 4)
    .background(Color.background)
    .cornerRadius(8)
}
extension View {
    func tnSheetOld<TButtonView: View>(isPresented: Binding<Bool>, title: String, buttons: @escaping () -> [TnSheetButton<TButtonView>]) -> some View {
        tnSheet(isPresented: isPresented, title: title) {
            tnForEach(buttons()) { idx, button in
                button
            }
        }
    }
    func tnSheetOld<TContent: View>(isPresented: Binding<Bool>, title: String, content: @escaping () -> TContent) -> some View {
        sheet(isPresented: isPresented) {
            tnSheetView(isPresented: isPresented, title: title, content: content)
        }
    }
}

extension View {
    // new method
    func tnSheet<TContent: View>(isPresented: Binding<Bool>, title: String, content: @escaping () -> TContent) -> some View {
        let sheetView = tnSheetView(isPresented: isPresented, title: title, content: content)
        return ZStack(alignment: .bottom) {
            self
                .onAppear(perform: {isPresented.wrappedValue = false})
            if isPresented.wrappedValue {
                sheetView
                    .animation(.easeInOut, value: UUID())
                    .transition(.move(edge: .bottom))
            }
        }
    }
}

