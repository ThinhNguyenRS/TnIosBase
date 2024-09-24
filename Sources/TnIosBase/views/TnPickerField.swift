//
//  TnPickerField.swift
//  TkgFaceRecognition
//
//  Created by Thinh Nguyen on 8/18/21.
//

import SwiftUI

//public struct TnPickerField<T: Hashable & Comparable, TStyle: PickerStyle>: View {
//    var label: String = ""
//    var value: Binding<T>
//    let values: [T]
//    let labels: [String]
//    let style: () -> TStyle
//    let onChanged: ((T) -> Void)?
//    
//    public init(
//        label: String,
//        value: Binding<T>,
//        values: [T],
//        labels: [String],
//        style: @escaping () -> TStyle,
//        onChanged: ((T) -> Void)? = nil
//    )
//    {
//        self.label = label
//        self.values = values
//        self.labels = labels
//        self.style = style
//        self.onChanged = onChanged
//        self.value = value
//    }
//    
//    public var body: some View {
//        VStack(alignment: .leading){
//            Text(label.lz())
//            Picker("", selection: value.projectedValue) {
//                tnForEach(values) { idx, value in
//                    tnText(labels[idx])
//                        .tag(value)
//                }
//            }
//            .pickerStyle(style())
//        }
//        .onChange(of: value.wrappedValue, perform: { _ in
//            self.onChanged?(value.wrappedValue)
//        })
//    }
//}

public enum TnPickerStyle {
    case segmented, wheel, menu
}

extension View {
    
    public func tnPickerStyle(_ v: TnPickerStyle) -> some View {
        Group {
            switch v {
//            case .segmented:
//                self.pickerStyle(SegmentedPickerStyle())
            case .wheel:
                self.pickerStyle(WheelPickerStyle())
            case .menu:
                self.pickerStyle(MenuPickerStyle())
            default:
                self.pickerStyle(SegmentedPickerStyle())
            }
        }
    }

    public func tnPickerView<T: Hashable & Comparable>(
        value: Binding<T>,
        values: [T],
        labels: [String],
        onChanged: ((T) -> Void)? = nil,
        style: TnPickerStyle = .segmented
    ) -> some View {
        Picker("", selection: value.projectedValue) {
            tnForEach(values) { idx, value in
                tnText(labels[idx])
                    .tag(value)
            }
        }
        .onChange(of: value.wrappedValue, perform: { _ in
            onChanged?(value.wrappedValue)
        })
        .tnPickerStyle(style)
    }
    
    public func tnPickerView<T: TnEnum>(
        value: Binding<T>,
        values: [T]? = nil,
        onChanged: ((T) -> Void)? = nil,
        style: TnPickerStyle = .segmented
    ) -> some View {
        let valuesToUse = values ?? T.allCases
        let labels = valuesToUse.descriptions
        
        return tnPickerView(
            value: value,
            values: valuesToUse,
            labels: labels,
            onChanged: onChanged,
            style: style
        )
    }
    
    public func tnPickerViewHorz<T: Hashable & Comparable>(
        label: String,
        value: Binding<T>,
        values: [T],
        labels: [String],
        onChanged: ((T) -> Void)? = nil,
        style: TnPickerStyle = .segmented
    ) -> some View {
        HStack {
            Text(label)
            tnPickerView(value: value, values: values, labels: labels, style: style)
        }
    }
    
    public func tnPickerViewHorz<T: TnEnum>(
        label: String,
        value: Binding<T>,
        values: [T]? = nil,
        onChanged: ((T) -> Void)? = nil,
        style: TnPickerStyle = .segmented
    ) -> some View {
        HStack {
            Text(label)
            tnPickerView(value: value, values: values, style: style)
        }
    }
    
    public func tnPickerViewVert<T: Hashable & Comparable, TTopView: View, TBottomView: View>(
        label: String,
        value: Binding<T>,
        values: [T],
        labels: [String],
        onChanged: ((T) -> Void)? = nil,
        topView: (() -> TTopView?),
        bottomView: (() -> TBottomView?),
        padding: CGFloat = 8,
        style: TnPickerStyle = .segmented
    ) -> some View {
        VStack(alignment: .leading) {
            Text(label)
            
            topView()
            
            tnPickerView(value: value, values: values, labels: labels, style: style)
            
            bottomView()
        }
        .padding(.all, padding)
    }
    
    public func tnPickerViewVert<T: TnEnum, TTopView: View, TBottomView: View>(
        label: String,
        value: Binding<T>,
        values: [T]? = nil,
        onChanged: ((T) -> Void)? = nil,
        topView: (() -> TTopView?),
        bottomView: (() -> TBottomView?),
        padding: CGFloat = 8,
        style: TnPickerStyle = .segmented
    ) -> some View {
        VStack(alignment: .leading) {
            Text(label)
            
            topView()
            
            tnPickerView(value: value, values: values, style: style)
            
            bottomView()
        }
        .padding(.all, padding)
    }
    
    public func tnPickerViewVert<T: TnEnum, TTopView: View>(
        label: String,
        value: Binding<T>,
        values: [T]? = nil,
        onChanged: ((T) -> Void)? = nil,
        topView: (() -> TTopView?) = { nil as EmptyView? },
        padding: CGFloat = 8,
        style: TnPickerStyle = .segmented
    ) -> some View {
        tnPickerViewVert(
            label: label,
            value: value,
            topView: topView,
            bottomView: { nil as EmptyView? },
            padding: padding,
            style: style
        )
    }
    
    public func tnPickerViewVert<T: TnEnum>(
        label: String,
        value: Binding<T>,
        values: [T]? = nil,
        onChanged: ((T) -> Void)? = nil,
        padding: CGFloat = 8,
        style: TnPickerStyle = .segmented
    ) -> some View {
        tnPickerViewVert(
            label: label,
            value: value,
            topView: { nil as EmptyView? },
            bottomView: { nil as EmptyView? },
            padding: padding,
            style: style
        )
    }
}

//extension TnPickerField where T: TnEnum, TStyle ==  SegmentedPickerStyle {
//    public static func forEnum(label: String, value: Binding<T>, onChanged: ((T) -> Void)? = nil) -> TnPickerField {
//        TnPickerField(
//            label: label,
//            value: value,
//            values: T.allCases,
//            labels: T.allNames,
//            style: { SegmentedPickerStyle() },
//            onChanged: onChanged
//        )
//    }
//    
//    public static func forEnum(label: String, value: Binding<T>, values: [T], onChanged: ((T) -> Void)? = nil) -> TnPickerField {
//        TnPickerField(
//            label: label,
//            value: value,
//            values: values,
//            labels: values.descriptions,
//            style: { SegmentedPickerStyle() },
//            onChanged: onChanged
//        )
//    }
//}
//
//extension TnPickerField where T == String {
//    var pickerLabel: String {
//        value.wrappedValue
//    }
//}
//
//
//public func tnPickerFieldEnum<T: TnEnum, TStyle: PickerStyle>(label: String, value: Binding<T>, style: @escaping () -> TStyle, onChanged: ((T) -> Void)? = nil) -> TnPickerField<T, TStyle> {
//    TnPickerField(
//        label: label,
//        value: value,
//        values: T.allCases,
//        labels: T.allNames,
//        style: style,
//        onChanged: onChanged)
//}
//
//public func tnPickerFieldEnum<T: TnEnum>(label: String, value: Binding<T>, onChanged: ((T) -> Void)? = nil) -> TnPickerField<T, SegmentedPickerStyle> {
//    TnPickerField(
//        label: label,
//        value: value,
//        values: T.allCases,
//        labels: T.allNames,
//        style: {SegmentedPickerStyle()},
//        onChanged: onChanged
//    )
//}
//
//public func tnPickerFieldString<TStyle: PickerStyle>(label: String, value: Binding<String>, labels: [String], style: @escaping () -> TStyle, onChanged: ((String) -> Void)? = nil) -> TnPickerField<String, TStyle> {
//    TnPickerField(
//        label: label,
//        value: value,
//        values: labels,
//        labels: labels,
//        style: style,
//        onChanged: onChanged
//    )
//}
//
//public func tnPickerFieldString(label: String, value: Binding<String>, labels: [String], onChanged: ((String) -> Void)? = nil) -> TnPickerField<String, SegmentedPickerStyle> {
//    TnPickerField(
//        label: label,
//        value: value,
//        values: labels,
//        labels: labels,
//        style: {SegmentedPickerStyle()}
//    )
//}
//
//public func tnPickerFieldStringMenu(label: String, value: Binding<String>, labels: [String], onChanged: ((String) -> Void)? = nil) -> TnPickerField<String, MenuPickerStyle> {
//    TnPickerField(
//        label: label,
//        value: value,
//        values: labels,
//        labels: labels,
//        style: {MenuPickerStyle()},
//        onChanged: onChanged
//    )
//}
//
//public struct TnPickerFieldPopup<TValue: Hashable & Comparable>: View {
//    let label: String
//    let value: Binding<TValue>
//    let values: [TValue]
//    let labels: [String]
//    var onChanged: ((TValue) -> Void)? = nil
//    
//    @State private var valueIndex = 0
//    @State private var showPopup = false
//
//    public init(label: String, value: Binding<TValue>, values: [TValue], labels: [String], onChanged: ((TValue) -> Void)? = nil) {
//        self.label = label
//        self.value = value
//        self.values = values
//        self.labels = labels
//        self.onChanged = onChanged
//    }
//    
//    public var body: some View {
//        HStack {
//            tnText(label)
//            Spacer()
//            if labels.count > valueIndex {
//                Text(labels[valueIndex])
//                    .foregroundColor(.blue)
//            }
//        }
//        .onTapGesture {
//            showPopup = true
//        }
//        .sheet(isPresented: $showPopup, content: {
//            VStack {
//                tnText(label)
//                    .bold()
//                    .foregroundColor(.TKG)
//                    .padding()
//
//                Spacer()
//
//                if #available(iOS 17.0, *) {
//                    Picker(label, selection: $valueIndex) {
//                        tnForEach(values) { idx, value in
//                            tnText(labels[idx])
//                                .tag(idx)
//                        }
//                    }
//                    .pickerStyle(WheelPickerStyle())
//                    .onChange(of: valueIndex) {
//                        value.wrappedValue = values[valueIndex]
//                        onChanged?(value.wrappedValue)
//                    }
//                } else {
//                    // Fallback on earlier versions
//                    Picker(label, selection: $valueIndex) {
//                        tnForEach(values) { idx, value in
//                            tnText(labels[idx])
//                                .tag(idx)
//                        }
//                    }
//                    .pickerStyle(WheelPickerStyle())
//                    .onChange(of: valueIndex, perform: { newIndex in
//                        value.wrappedValue = values[newIndex]
//                        onChanged?(value.wrappedValue)
//                    })
//                }
//                
//                Spacer()
//                tnTextButton("Close", action: {
//                    showPopup = false
//                })
//                .padding()
//            }
//        })
//        .onAppear {
//            value.wrappedValue = value.wrappedValue.valueInRange(values)
//            if !values.isEmpty {
//                valueIndex = values.firstIndex(of: value.wrappedValue)!
//            }
//        }
//    }
//}
//
//
