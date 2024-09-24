//
//  ViewExtensions.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 01/08/2021.
//

import Foundation
import SwiftUI

let defaultPagePadding: CGFloat = 8

extension View {
    public func tnFormatBottomButtons() -> some View {
        return self
            .padding(.all, 8)
            .background(Color.footerBackground)
    }

    public func tnWrapToBottomRight() -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                self
            }
        }
    }

    public func tnWrapToBottomLeft() -> some View {
        VStack {
            Spacer()
            HStack {
                self
                Spacer()
            }
        }
    }

    public func tnWrapToBottomCenter() -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                self
                Spacer()
            }
        }
    }

    public func tnWrapToTopLeft() -> some View {
        VStack {
            HStack {
                self
                Spacer()
            }
            Spacer()
        }
    }

    public func tnWrapToTopRight() -> some View {
        VStack {
            HStack {
                Spacer()
                self
            }
            Spacer()
        }
    }
    
    public func tnButtonCorner(width: CGFloat = 40, height: CGFloat = 40, backgroundColor: Color = Color.white, colorOpacity: Double = 0.5, cornerRadius: CGFloat = 12, padding: CGFloat = 4) -> some View {
        self
            .frame(width: width, height: height, alignment: .center)
            .padding(.all, padding)
            .background(backgroundColor.opacity(colorOpacity))
            .cornerRadius(cornerRadius)
    }

    public func tnCaption(height: CGFloat = 32, background: Color = Color.background85, padding: CGFloat = 4) -> some View {
        self
            .frame(height: height)
            .padding(.all, padding)
            .background(background)
    }
    
    public func tnPageTitle(_ title: String, showBack: Bool = true) -> some View {
        self
            .navigationTitle(title.lz())
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(!showBack)
    }
    public func tnPageTitle<TToolbar: View>(_ title: String, trailingButton: TToolbar? = nil, leadingButton: TToolbar? = nil, showBack: Bool = true) -> some View {
        self
            .navigationTitle(title.lz())
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(leadingButton != nil || trailingButton != nil || !showBack)
            .navigationBarItems(leading: leadingButton, trailing: trailingButton)
    }
    public func tnPageTitle(_ title: String? = nil, presentation: Binding<PresentationMode>? = nil) -> some View {
        self
            .navigationTitle(title?.lz() ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: tnButton(Image.iconClosePage, action: {presentation?.wrappedValue.dismiss()})
            )
    }
    public func tnPageTitle<TToolbar: View>(_ title: String? = nil, presentation: Binding<PresentationMode>? = nil, trailingButton: TToolbar) -> some View {
        self
            .navigationTitle(title?.lz() ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: tnButton(Image.iconClosePage, action: {presentation?.wrappedValue.dismiss()}),
                trailing: trailingButton)
    }

    public func tnPageTitleHide() -> some View {
        self
            .navigationBarHidden(true)
    }
    public func tnPageTitleShow() -> some View {
        self
            .navigationBarHidden(false)
    }

    public func getWidth(_ width: CGFloat, padding: CGFloat = 0) -> CGFloat? {
        let ret = width - padding*2
        if !ret.isFinite || ret <= 0 {
            return  nil
        }
        return ret
    }
    public func getHeight(_ height: CGFloat, padding: CGFloat = 0) -> CGFloat? {
        let ret = height - padding*2
        if !ret.isFinite || ret <= 0 {
            return  nil
        }
        return ret
    }
    
    public func tnPageFill<TBackground: View>(background: TBackground) -> some View {
        self
            .padding(.all, defaultPagePadding)
            .background(background.edgesIgnoringSafeArea(.all))
//        GeometryReader { g in
//            self
//                .frame(width: getWidth(g.size.width, padding: defaultPagePadding), height: getHeight(g.size.height, padding: defaultPagePadding))
//                .padding(.all, defaultPagePadding)
//                .background(background.edgesIgnoringSafeArea(.all))
//        }
    }

    public func tnPageFill(color: Color = Color.background) -> some View {
        tnPageFill(background: color)
    }

    public func tnPageFill(colorName: String) -> some View {
        tnPageFill(background: Color.adaptiveColor(colorName))
    }

    public func tnPageFill(image: Image) -> some View {
        tnPageFill(background: image)
    }

    public func tnPageFill(imageName: String) -> some View {
        tnPageFill(background: Image(imageName))
    }

    public func tnPageTitleOverlay<TTitle: View>(_ title: @escaping () -> TTitle, background: Color = Color.background) -> some View {
        GeometryReader { g in
            ZStack(alignment: .top) {
                title()
                    .frame(width: g.size.width)
                self
                    .frame(width: g.size.width)
            }
        }
        .tnPageFill(background: background)
        .tnPageTitleHide()
    }
    
    public func height(_ value: CGFloat?) -> some View {
        self.frame(height: value)
    }
    public func width(_ value: CGFloat?) -> some View {
        self.frame(width: value)
    }
    
    public func tnConfirmation(isPresented: Binding<Bool>, title: String = "Confirmation", message: String, onOK: @escaping () -> Void, onCancel: (() -> Void)? = nil) -> some View {
        self
            .alert(isPresented: isPresented, content: {
                tnAlert(isPresented: isPresented, title: title, message: message, onOK: onOK, onCancel: onCancel)
            })
    }
    
    public func tnConfirmationMulti(
        isPresented: Binding<Bool>,
        activeIndex: Binding<Int>,
        getter: (Binding<Bool>, Int) -> Alert
    ) -> some View {
        self
            .alert(isPresented: isPresented, content: {
                getter(isPresented, activeIndex.wrappedValue)
            })
    }
    
    public func beautifyBackground(backColor: Color = Color.background85.opacity(0.75), cornerRadius: CGFloat = 8) -> some View {
        self
        .padding([.top, .bottom], 6)
        .padding([.leading, .trailing], 16)
        .background(backColor)
        .cornerRadius(cornerRadius)
    }
    
    public func makeLikeButton(backColor: Color = Color.background85) -> some View {
        self
        .padding([.top, .bottom], 6)
        .padding([.leading, .trailing], 16)
        .background(backColor)
        .cornerRadius(8)
    }
    
    public func destructive() -> some View {
        self.foregroundColor(.red)
    }
}

extension View {
    public func hideKeyboard() {
        DispatchQueue.main.async {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}


public func tnAlert(isPresented: Binding<Bool>, title: String = "Confirmation", message: String, onOK: @escaping () -> Void, onCancel: (() -> Void)? = nil) -> Alert {
    Alert(title: tnText(title), message: tnText(message),
          primaryButton: .default(tnText("OK")) {
            isPresented.wrappedValue = false
            onOK()
          },
          secondaryButton: .cancel() {
            isPresented.wrappedValue = false
            onCancel?()
          }
    )
}

extension Text {
    public func tnMakeScalable(font: Font = Font.system(size: 1000)) -> some View {
        self
            .font(font)
            .minimumScaleFactor(0.01)
            .lineLimit(1)
    }
}

/// make Text helpers
public func tnText(_ text: String, lz: Bool = true) -> Text {
    Text(lz ? text.lz() : text)
}


public func tnIconText(icon: Image, label: String? = nil, color: Color = Color.foreground, width: CGFloat? = nil, lz: Bool = true) -> some View {
    return VStack() {
        icon
            .tnMakeScalable()
            .frame(width: 18, height: 18)
            .foregroundColor(color)
        if let labelText = label?.lz(lz) {
            Text(labelText)
//                .font(.caption)
                .foregroundColor(color)
        }
    }
    .frame(width: width)
}

public func tnIconTextHorz(icon: Image, label: String? = nil, color: Color = Color.foreground, width: CGFloat? = nil, lz: Bool = true) -> some View {
    return HStack() {
        icon
            .tnMakeScalable()
            .frame(width: 18, height: 18)
            .foregroundColor(color)
        if let labelText = label?.lz(lz) {
            Text(labelText)
//                .font(.caption)
                .foregroundColor(color)
        }
    }
    .frame(width: width)
}

public func tnTextButton(_ label: String, action: @escaping () -> Void, lz: Bool = true, bold: Bool = true, backColor: Color = Color.background85) -> some View {
    Button(
        action: action,
        label: {
            if bold {
                tnText(label, lz: lz)
                    .bold()
            } else {
                tnText(label, lz: lz)
            }
        }
    ).makeLikeButton()
}



public func tnImageButton(_ label: Image, action: @escaping () -> Void, foreColor: Color? = nil, backColor: Color? = nil, padding: CGFloat = 0, size: CGFloat = 24, cornerRadius: CGFloat = 0) -> some View {
    Button(action: action, label: {
        label
            .tnMakeScalable()
            .foregroundColor(foreColor)
            .frame(width: size, height: size)
            .padding(.all, padding)
    })
    .background(backColor)
    .cornerRadius(cornerRadius)
}

public func tnImageButton(name: String, action: @escaping () -> Void, foreColor: Color? = nil, backColor: Color? = nil, padding: CGFloat = 0, size: CGFloat = 24, cornerRadius: CGFloat = 0) -> some View {
    Button(action: action, label: {
        Image(systemName: name)
            .tnMakeScalable()
            .foregroundColor(foreColor)
            .frame(width: size, height: size)
            .padding(.all, padding)
    })
    .background(backColor)
    .cornerRadius(cornerRadius)
}

public func tnButton<TLabel: View>(_ label: TLabel, action: @escaping () -> Void) -> some View {
    Button(
        action: action,
        label: {label}
    )
}
public func tnButton(_ label: String, action: @escaping () -> Void) -> some View {
    tnButton(tnText(label), action: action)
}

public func tnButtonInList<TLabel: View>(_ label: TLabel, action: @escaping () -> Void) -> some View {
    Button(
        action: action,
        label: {label}
    ).buttonStyle(.borderless) //BorderlessButtonStyle()
}


public func tnMenuItem<TIcon: View>(_ label: String, _ icon: TIcon) -> some View {
    HStack {
        Text(label.lz())
        Spacer()
        icon
    }
}

public func tnMenuButton<TIcon: View>(_ label: String, _ icon: TIcon, action: @escaping () -> Void) -> some View {
    Button(
        action: action,
        label: {
            tnMenuItem(label, icon)
        }
    )
}

public func tnMenu<TLabel: View, TButtons: View>(_ label: TLabel, buttons: TButtons) -> some View {
    Menu {
        buttons
    } label: {
        label
    }
}

public func tnMenu<TLabel: View, TButton: View>(_ label: TLabel, buttons: [TButton]) -> some View {
    Menu {
        tnForEach(buttons) { idx, button in
            button
        }
    } label: {
        label
    }
}


public func tnCaptionView(caption: String,
                   leftIcon: Image = Image.iconClose, leftAction: (()->Void)? = nil,
                   rightIcon: Image = Image.iconOK, rightAction: (()->Void)?) -> some View {
    HStack {
        if leftAction != nil {
            Button(
                action: {
                    withAnimation {
                        leftAction!()
                    }
                },
                label: {
                    leftIcon
                        .resizable()
                        .foregroundColor(Color.gray)
                        .frame(width: 24, height: 24)
                }
            )
        }

        Spacer()
        tnText(caption)
            .font(.headline.weight(.heavy))
        Spacer()

        if rightAction != nil {
            Button(
                action: {
                    withAnimation {
                        rightAction!()
                    }
                },
                label: {
                    rightIcon
                        .resizable()
                        .foregroundColor(Color.white)
                        .frame(width: 24, height: 24)
                }
            )
        }
    }
    .padding([.all], 8)
    .background(Color.captionBackground)
}

public func tnDivider(height: CGFloat = 6, color: Color = Color.dark_5_aluminum) -> some View {
    Divider()
        .frame(height: height)
        .background(color)
}

public func tnForEach<T, V: View>(_ items: [T], itemView: @escaping (Int, T) -> V) -> some View {
    ForEach(0..<items.count, id: \.self) {idx in
        itemView(idx, items[idx])
    }
}

//func tnLinkButton<TView: View>(_ label: String, view: TView) -> some View {
//    NavigationLink(destination: view, label: {Text(label)})
//}
//func tnLinkButton<TView: View>(_ labelImage: Image, view: TView) -> some View {
//    NavigationLink(destination: view, label: {labelImage})
//}
//func tnLinkButton<TLabel: View, TView: View>(_ labelView: TLabel, view: TView) -> some View {
//    
//    NavigationLink(destination: view, label: {labelView})
//}

public func tnLinkButton<TLabel: View, TView: View>(_ label: TLabel, view: @escaping () -> TView) -> some View {
    NavigationLink(destination: view, label: {label})
}
public func tnLinkButton<TView: View>(_ label: String, view: @escaping () -> TView) -> some View {
    NavigationLink(destination: view, label: {tnText(label)})
}
public func tnLinkButton<TView: View>(_ image: Image, view: @escaping () -> TView) -> some View {
    NavigationLink(destination: view, label: {image})
}


public func tnProgressView(_ text: String = "Processing ...") -> some View {
    ProgressView {
        tnText(text)
            .bold()
            .font(.caption)
    }
    .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
    .foregroundColor(.white)
    .frame(width: 200, height: 200)
    .scaleEffect(2, anchor: .center)
    .background(Color.dark_8_steel.opacity(0.75))
    .cornerRadius(40)
}

public func tnLabel<TIcon: View>(_ label: String, _ icon: TIcon) -> some View {
    Label(title: {Text(label)}, icon: {icon})
}

public func tnLabel(_ label: String, iconSystemName: String) -> some View {
    Label(title: {Text(label)}, icon: {Image(systemName: iconSystemName)})
}

// MARK: Circles
public func tnCircle(radius: CGFloat, backColor: Color = .appleTin.opacity(0.8)) -> some View {
    Circle()
        .foregroundColor(backColor)
        .frame(width: radius, height: radius, alignment: .center)
}

public func tnCircle(radius: CGFloat, strokeColor: Color, strokeWidth: CGFloat = 2) -> some View {
    Circle()
        .stroke(strokeColor, lineWidth: strokeWidth)
        .frame(width: radius, height: radius, alignment: .center)
}

public func tnCircle(imageName: String, radius: CGFloat = 80, backColor: Color = .appleTin.opacity(0.8), imageColor: Color? = .white) -> some View {
    Circle()
        .foregroundColor(backColor)
        .frame(width: radius, height: radius, alignment: .center)
        .overlay(Image(systemName: imageName).foregroundColor(imageColor))
}

public func tnCircle(text: String, radius: CGFloat = 80, backColor: Color = .appleTin.opacity(0.8), textColor: Color? = nil) -> some View {
    Circle()
        .foregroundColor(backColor)
        .frame(width: radius, height: radius, alignment: .center)
        .overlay(Text(text).foregroundColor(textColor))
}

public func tnCircleButton(imageName: String, radius: CGFloat = 70,  backColor: Color = .background85Dark.opacity(0.8), imageColor: Color? = .white, animate: Bool = true, action: @escaping () -> Void) -> some View {
    tnButton(tnCircle(imageName: imageName, radius: radius, backColor: backColor, imageColor: imageColor)) {
        if animate {
            withAnimation {
                action()
            }
        } else {
            action()
        }
    }
}

public func tnCircleButton(text: String, radius: CGFloat = 70, backColor: Color = .background85Dark.opacity(0.8), textColor: Color? = .white, animate: Bool = true, action: @escaping () -> Void) -> some View {
    tnButton(tnCircle(text: text, radius: radius, backColor: backColor, textColor: textColor)) {
        if animate {
            withAnimation {
                action()
            }
        } else {
            action()
        }
    }
}

extension AnyTransition {
    public static var moveAndFade: AnyTransition {
        let insertion = AnyTransition.move(edge: .trailing)
            .combined(with: .opacity)
        let removal = AnyTransition.scale
            .combined(with: .opacity)
        return .asymmetric(insertion: insertion, removal: removal)
    }
}
