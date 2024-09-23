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
    let onChanged: ((T) -> Void)?
    
    public init(
        label: String,
        value: Binding<T>,
        values: [T],
        labels: [String],
        style: @escaping () -> TStyle,
        onChanged: ((T) -> Void)? = nil)
    {
        self.label = label
        self.values = values
        self.labels = labels
        self.style = style
        self.onChanged = onChanged
        self.value = value
    }
    
    public var body: some View {
        Picker(label, selection: value.projectedValue) {
            tnForEach(values) { idx, value in
                tnText(labels[idx])
                    .tag(value)
            }
        }
        .pickerStyle(style())
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


public func tnPickerFieldEnum<T: TnEnum, TStyle: PickerStyle>(label: String, value: Binding<T>, style: @escaping () -> TStyle, onChanged: ((T) -> Void)? = nil) -> TnPickerField<T, TStyle> {
    TnPickerField(
        label: label,
        value: value,
        values: T.allCases,
        labels: T.allNames,
        style: style,
        onChanged: onChanged)
}

public func tnPickerFieldEnum<T: TnEnum>(label: String, value: Binding<T>, onChanged: ((T) -> Void)? = nil) -> TnPickerField<T, SegmentedPickerStyle> {
    TnPickerField(
        label: label,
        value: value,
        values: T.allCases,
        labels: T.allNames,
        style: {SegmentedPickerStyle()},
        onChanged: onChanged
    )
}

public func tnPickerFieldString<TStyle: PickerStyle>(label: String, value: Binding<String>, labels: [String], style: @escaping () -> TStyle, onChanged: ((String) -> Void)? = nil) -> TnPickerField<String, TStyle> {
    TnPickerField(
        label: label,
        value: value,
        values: labels,
        labels: labels,
        style: style,
        onChanged: onChanged
    )
}

public func tnPickerFieldString(label: String, value: Binding<String>, labels: [String], onChanged: ((String) -> Void)? = nil) -> TnPickerField<String, SegmentedPickerStyle> {
    TnPickerField(
        label: label,
        value: value,
        values: labels,
        labels: labels,
        style: {SegmentedPickerStyle()}
    )
}

public func tnPickerFieldStringMenu(label: String, value: Binding<String>, labels: [String], onChanged: ((String) -> Void)? = nil) -> TnPickerField<String, MenuPickerStyle> {
    TnPickerField(
        label: label,
        value: value,
        values: labels,
        labels: labels,
        style: {MenuPickerStyle()},
        onChanged: onChanged
    )
}

public struct TnPickerFieldPopup<TValue: Hashable & Comparable>: View {
    let label: String
    let value: Binding<TValue>
    let values: [TValue]
    let labels: [String]
    var onChanged: ((TValue) -> Void)? = nil
    
    @State private var valueIndex = 0
    @State private var showPopup = false

    public init(label: String, value: Binding<TValue>, values: [TValue], labels: [String], onChanged: ((TValue) -> Void)? = nil) {
        self.label = label
        self.value = value
        self.values = values
        self.labels = labels
        self.onChanged = onChanged
    }
    
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
                    Picker(label, selection: $valueIndex) {
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
                    Picker(label, selection: $valueIndex) {
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


