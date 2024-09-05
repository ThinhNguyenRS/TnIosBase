//
//  TnPickerField.swift
//  TkgFaceRecognition
//
//  Created by Thinh Nguyen on 8/18/21.
//

import SwiftUI

public struct TnPickerField<T: Hashable & Comparable, TStyle: PickerStyle>: View {
    var label: String = ""
    var value: Binding<T>
    let values: [T]
    let labels: [String]
    let style: () -> TStyle
    var height: CGFloat? = nil
    var pickerLabel: String? = nil
    var horizontal: Bool = false
    
    var onChanged: ((T) -> Void)? = nil
    
    public init(
        label: String,
        value: Binding<T>,
        values: [T],
        labels: [String],
        style: @escaping () -> TStyle,
        height: CGFloat? = nil,
        pickerLabel: String? = nil,
        horizontal: Bool = false,
        onChanged: ((T) -> Void)? = nil)
    {
        self.label = label
        self.values = values
        self.labels = labels
        self.style = style
        self.height = height
        self.pickerLabel = pickerLabel
        self.horizontal = horizontal
        self.onChanged = onChanged
        self.value = value
    }
    
    var pickerView: some View {
        Picker((pickerLabel ?? label).lz(), selection: value.projectedValue) {
            tnForEach(values) { idx, value in
                tnText(labels[idx])
                    .tag(value)
            }
        }
        .pickerStyle(style())
        .height(height)
    }
    
    public var body: some View {
        Group {
            if label.isEmpty {
                pickerView
            } else {
                if horizontal {
                    HStack {
                        tnText(label)
                        Spacer()
                        pickerView
                    }
                } else {
                    VStack(alignment: .leading, spacing: TnFieldExtensions.spacing) {
                        tnText(label)
                        pickerView
                    }
                }
            }
        }
        .onAppear {
            value.wrappedValue = value.wrappedValue.valueInRange(values)
        }
        .onChange(of: value.wrappedValue, perform: { _ in
            self.onChanged?(value.wrappedValue)
        })
    }
}

extension TnPickerField where T: TnEnum, TStyle ==  SegmentedPickerStyle {
    public static func forEnum(label: String, value: Binding<T>, onChanged: ((T) -> Void)? = nil) -> TnPickerField {
        TnPickerField(
            label: label,
            value: value,
            values: T.allCases,
            labels: T.allNames,
            style: { SegmentedPickerStyle() },
            onChanged: onChanged
        )
    }
    
    public static func forEnum(label: String, value: Binding<T>, values: [T], onChanged: ((T) -> Void)? = nil) -> TnPickerField {
        TnPickerField(
            label: label,
            value: value,
            values: values,
            labels: values.descriptions,
            style: { SegmentedPickerStyle() },
            onChanged: onChanged
        )
    }
}

extension TnPickerField where T == String {
    var pickerLabel: String {
        value.wrappedValue
    }
}


public func tnPickerFieldEnum<T: TnEnum, TStyle: PickerStyle>(label: String, value: Binding<T>, style: @escaping () -> TStyle, height: CGFloat? = nil, pickerLabel: String? = nil, onChanged: ((T) -> Void)? = nil) -> TnPickerField<T, TStyle> {
    TnPickerField(
        label: label,
        value: value,
        values: T.allCases,
        labels: T.allNames,
        style: style,
        height: height,
        pickerLabel: pickerLabel,
        onChanged: onChanged)
}

public func tnPickerFieldEnum<T: TnEnum>(label: String, value: Binding<T>, height: CGFloat? = nil, pickerLabel: String? = nil, onChanged: ((T) -> Void)? = nil) -> TnPickerField<T, SegmentedPickerStyle> {
    TnPickerField(
        label: label,
        value: value,
        values: T.allCases,
        labels: T.allNames,
        style: {SegmentedPickerStyle()},
        height: height,
        pickerLabel: pickerLabel,
        onChanged: onChanged)
}

public func tnPickerFieldString<TStyle: PickerStyle>(label: String, value: Binding<String>, labels: [String], style: @escaping () -> TStyle, height: CGFloat? = nil, pickerLabel: String? = nil, onChanged: ((String) -> Void)? = nil) -> TnPickerField<String, TStyle> {
    TnPickerField(
        label: label,
        value: value,
        values: labels,
        labels: labels,
        style: style,
        height: height,
        pickerLabel: pickerLabel,
        onChanged: onChanged)
}

public func tnPickerFieldString(label: String, value: Binding<String>, labels: [String], height: CGFloat? = nil, pickerLabel: String? = nil, onChanged: ((String) -> Void)? = nil) -> TnPickerField<String, SegmentedPickerStyle> {
    TnPickerField(
        label: label,
        value: value,
        values: labels,
        labels: labels,
        style: {SegmentedPickerStyle()},
        height: height,
        pickerLabel: pickerLabel)
}

public func tnPickerFieldStringMenu(label: String, value: Binding<String>, labels: [String], height: CGFloat? = nil, pickerLabel: String? = nil, onChanged: ((String) -> Void)? = nil) -> TnPickerField<String, MenuPickerStyle> {
    TnPickerField(
        label: label,
        value: value,
        values: labels,
        labels: labels,
        style: {MenuPickerStyle()},
        height: height,
        pickerLabel: pickerLabel,
        onChanged: onChanged)
}

public struct TnPickerFieldPopup<T: Hashable & Comparable>: View {
    let label: String
    let value: Binding<T>
    let values: [T]
    let labels: [String]
    var onChanged: ((T) -> Void)? = nil
    
    @State private var valueIndex = 0
    @State private var showPopup = false

    public var body: some View {
        HStack {
            tnText(label)
            Spacer()
            if labels.count > valueIndex {
                Text(labels[valueIndex])
                    .foregroundColor(.blue)
            }
        }
        .onTapGesture {
            showPopup = true
        }
        .sheet(isPresented: $showPopup, content: {
            VStack {
                tnText(label)
                    .bold()
                    .foregroundColor(.TKG)
                    .padding()

                Spacer()

                if #available(iOS 17.0, *) {
                    Picker("Select value".lz(), selection: $valueIndex) {
                        tnForEach(values) { idx, value in
                            tnText(labels[idx])
                                .tag(idx)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .onChange(of: valueIndex) {
                        value.wrappedValue = values[valueIndex]
                        onChanged?(value.wrappedValue)
                    }
                } else {
                    // Fallback on earlier versions
                    Picker("Select value".lz(), selection: $valueIndex) {
                        tnForEach(values) { idx, value in
                            tnText(labels[idx])
                                .tag(idx)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .onChange(of: valueIndex, perform: { newIndex in
                        value.wrappedValue = values[newIndex]
                        onChanged?(value.wrappedValue)
                    })
                }
                
                Spacer()
                tnTextButton("Close", action: {
                    showPopup = false
                })
                .padding()
            }
        })
        .onAppear {
            value.wrappedValue = value.wrappedValue.valueInRange(values)
            if !values.isEmpty {
                valueIndex = values.firstIndex(of: value.wrappedValue)!
            }
        }
    }
}


