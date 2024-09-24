//
//  TnPickerField.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 8/18/21.
//

import SwiftUI

public enum TnPickerStyle {
    case segmented, wheel, menu
}

extension View {
    public func tnPickerStyle(_ v: TnPickerStyle) -> some View {
        Group {
            switch v {
            case .segmented:
                self.pickerStyle(SegmentedPickerStyle())
            case .wheel:
                self.pickerStyle(WheelPickerStyle())
            case .menu:
                self.pickerStyle(MenuPickerStyle())
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
            tnPickerView(
                value: value,
                values: values,
                labels: labels,
                onChanged: onChanged,
                style: style
            )
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
            tnPickerView(
                value: value,
                values: values,
                onChanged: onChanged,
                style: style
            )
        }
    }
    
    public func tnPickerViewVert<T: Hashable & Comparable, TTopView: View, TBottomView: View>(
        label: String,
        value: Binding<T>,
        values: [T],
        labels: [String],
        onChanged: ((T) -> Void)? = nil,
        topView: () -> TTopView?,
        bottomView: () -> TBottomView?,
        padding: CGFloat = 0,
        style: TnPickerStyle = .segmented
    ) -> some View {
        VStack(alignment: .leading) {
            Text(label)
            
            topView()
            
            tnPickerView(
                value: value,
                values: values,
                labels: labels,
                onChanged: onChanged,
                style: style
            )
            
            bottomView()
        }
        .padding(.all, padding)
    }
    
    public func tnPickerViewVert<T: TnEnum, TTopView: View, TBottomView: View>(
        label: String,
        value: Binding<T>,
        values: [T]? = nil,
        onChanged: ((T) -> Void)? = nil,
        topView: () -> TTopView?,
        bottomView: () -> TBottomView?,
        padding: CGFloat = 0,
        style: TnPickerStyle = .segmented
    ) -> some View {
        VStack(alignment: .leading) {
            Text(label)
            
            topView()
            
            tnPickerView(
                value: value,
                values: values,
                onChanged: onChanged,
                style: style
            )
            
            bottomView()
        }
        .padding(.all, padding)
    }
    
    public func tnPickerViewVert<T: TnEnum, TTopView: View>(
        label: String,
        value: Binding<T>,
        values: [T]? = nil,
        onChanged: ((T) -> Void)? = nil,
        topView: () -> TTopView?,
        padding: CGFloat = 0,
        style: TnPickerStyle = .segmented
    ) -> some View {
        tnPickerViewVert(
            label: label,
            value: value,
            values: values,
            onChanged: onChanged,
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
        padding: CGFloat = 0,
        style: TnPickerStyle = .segmented
    ) -> some View {
        tnPickerViewVert(
            label: label,
            value: value,
            values: values,
            onChanged: onChanged,
            topView: { nil as EmptyView? },
            bottomView: { nil as EmptyView? },
            padding: padding,
            style: style
        )
    }
}
