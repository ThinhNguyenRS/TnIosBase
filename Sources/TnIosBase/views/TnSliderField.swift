//
//  TnSliderField.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 08/2024
//

import SwiftUI

public struct TnSliderField<TValue>: View where TValue : BinaryFloatingPoint & CVarArg, TValue.Stride : BinaryFloatingPoint {
    let value: Binding<TValue>
    let bounds: ClosedRange<TValue>
    let step: TValue.Stride
    let formatter: (TValue) -> String
    let onChanged: ((TValue) -> Void)?
    private let adjustBounds: Bool
    
    public init(
        value: Binding<TValue>,
        bounds: ClosedRange<TValue>,
        step: TValue.Stride,
        formatter: @escaping (TValue) -> String,
        onChanged: ((TValue) -> Void)? = nil,
        adjustBounds: Bool = false
    )
    {
        self.value = value
        self.bounds = bounds
        self.step = step
        self.formatter = formatter
        self.onChanged = onChanged
        self.adjustBounds = adjustBounds
    }
    
    var valueText: String {
        let v = adjustBounds ? value.wrappedValue : value.wrappedValue - bounds.lowerBound
        return self.formatter(v)
    }
    
    var minText: String {
        let v = adjustBounds ? 0 : bounds.lowerBound
        return self.formatter(v)
    }

    var maxText: String {
        let v = adjustBounds ? bounds.upperBound - bounds.lowerBound : bounds.upperBound
        return self.formatter(v)
    }

    public var body: some View {
        Slider(
            value: value,
            in: bounds,
            step: step,
            label: { Text(valueText) },
            minimumValueLabel: {Text(minText)},
            maximumValueLabel: {Text(maxText)}
        ) { editing in
            if !editing {
                onChanged?(value.wrappedValue)
            }
        }
        .onAppear {
            self.value.wrappedValue = value.wrappedValue.valueInRange(bounds)
        }
    }
}

extension View {
    public func tnSliderView<TValue>(
        value: Binding<TValue>,
        bounds: ClosedRange<TValue>,
        step: TValue.Stride,
        formatter: @escaping (TValue) -> String,
        onChanged: ((TValue) -> Void)? = nil,
        adjustBounds: Bool = false
    ) -> some View where TValue : BinaryFloatingPoint & CVarArg, TValue.Stride : BinaryFloatingPoint {
        TnSliderField(
            value: value,
            bounds: bounds,
            step: step,
            formatter: formatter,
            onChanged: onChanged,
            adjustBounds: adjustBounds
        )
    }
    
    public func tnSliderViewVert<TValue, TTopView: View, TBottomView: View>(
        value: Binding<TValue>,
        label: String,
        bounds: ClosedRange<TValue>,
        step: TValue.Stride,
        formatter: @escaping (TValue) -> String,
        onChanged: ((TValue) -> Void)? = nil,
        adjustBounds: Bool = false,
        topView: () -> TTopView?,
        bottomView: () -> TBottomView?
    ) -> some View where TValue : BinaryFloatingPoint & CVarArg, TValue.Stride : BinaryFloatingPoint {
        VStack(alignment: .leading) {
            tnText("\(label) \(formatter(value.wrappedValue))")
            
            topView()
            
            TnSliderField(
                value: value,
                bounds: bounds,
                step: step,
                formatter: formatter,
                onChanged: onChanged,
                adjustBounds: adjustBounds
            )
            
            bottomView()
        }
    }
    
    public func tnSliderViewVert<TValue, TTopView: View>(
        value: Binding<TValue>,
        label: String,
        bounds: ClosedRange<TValue>,
        step: TValue.Stride,
        formatter: @escaping (TValue) -> String,
        onChanged: ((TValue) -> Void)? = nil,
        adjustBounds: Bool = false,
        topView: () -> TTopView?
    ) -> some View where TValue : BinaryFloatingPoint & CVarArg, TValue.Stride : BinaryFloatingPoint {
        tnSliderViewVert(
            value: value,
            label: label,
            bounds: bounds,
            step: step,
            formatter: formatter,
            topView: topView,
            bottomView: { nil as EmptyView? }
        )
    }
    
    public func tnSliderViewVert<TValue, TBottomView: View>(
        value: Binding<TValue>,
        label: String,
        bounds: ClosedRange<TValue>,
        step: TValue.Stride,
        formatter: @escaping (TValue) -> String,
        onChanged: ((TValue) -> Void)? = nil,
        adjustBounds: Bool = false,
        bottomView: () -> TBottomView?
    ) -> some View where TValue : BinaryFloatingPoint & CVarArg, TValue.Stride : BinaryFloatingPoint {
        tnSliderViewVert(
            value: value,
            label: label,
            bounds: bounds,
            step: step,
            formatter: formatter,
            topView: { nil as EmptyView? },
            bottomView: bottomView
        )
    }
    
    public func tnSliderViewVert<TValue>(
        value: Binding<TValue>,
        label: String,
        bounds: ClosedRange<TValue>,
        step: TValue.Stride,
        formatter: @escaping (TValue) -> String,
        onChanged: ((TValue) -> Void)? = nil,
        adjustBounds: Bool = false
    ) -> some View where TValue : BinaryFloatingPoint & CVarArg, TValue.Stride : BinaryFloatingPoint {
        tnSliderViewVert(
            value: value,
            label: label,
            bounds: bounds,
            step: step,
            formatter: formatter,
            topView: { nil as EmptyView? },
            bottomView: { nil as EmptyView? }
        )
    }
}
