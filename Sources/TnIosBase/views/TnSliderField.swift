//
//  TnSliderField.swift
//  TkgFaceRecognition
//
//  Created by Thinh Nguyen on 8/18/21.
//

import SwiftUI

public struct TnSliderFieldDouble: View {
    let label: String
    let value: Binding<Double>
    let bounds: ClosedRange<Double>
    let step: Double.Stride
    let specifier: String?
    let formatter: ((Double) -> String)?
    let onEdited: ((Double) -> Void)?

    public init(label: String, value: Binding<Double>, bounds: ClosedRange<Double>, step: Double, specifier: String = "%.0f", formatter: ((Double) -> String)? = nil, onEdited: ((Double) -> Void)? = nil) {
        self.label = label
        self.value = value
        self.bounds = bounds
        self.step = step
        self.specifier = specifier
        self.formatter = formatter
        self.onEdited = onEdited
        
        self.value.wrappedValue = value.wrappedValue.valueInRange(bounds)
    }
    
    func getText() -> String {
        if formatter != nil {
            return formatter!(value.wrappedValue)
        }
        return String(format: specifier!, value.wrappedValue)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: TnFieldExtensions.spacing) {
            tnText(label)
            HStack {
                Slider(value: value, in: bounds, step: step, onEditingChanged: { editing in
                    if !editing {
                        onEdited?(value.wrappedValue)
                    }
                })
                tnText(getText(), lz: false)
            }
        }
    }
}

public func TnSliderFieldInt<V: FixedWidthInteger>(label: String, value: Binding<V>, bounds: ClosedRange<V>, step: V, specifier: String = "%.0f", formatter: ((V) -> String)? = nil, onEdited: ((V) -> Void)? = nil)
-> some View {
    let valueDouble = Binding<Double> {
        Double(value.wrappedValue)
    } set: { d in
        DispatchQueue.main.async {
            value.wrappedValue = V(d)
        }
    }
    let formatterDouble: ((Double) -> String)? = formatter == nil ? nil : { d in
        formatter!(V(d))
    }
    let onEditedDouble: ((Double) -> Void)? = onEdited == nil ? nil : { d in
        onEdited!(V(d))
    }
    return TnSliderFieldDouble(
        label: label,
        value: valueDouble,
        bounds: Double(bounds.lowerBound)...Double(bounds.upperBound),
        step: Double(step),
        formatter: formatterDouble,
        onEdited: onEditedDouble
    )
}

public struct TnSliderFieldIntOld<V: FixedWidthInteger>: View {
    let label: String
    var value: Binding<V>
    var formatter: ((V) -> String)? = nil

    private let boundsDouble: ClosedRange<Double>
    private let stepDouble: Double.Stride
    @State private var valueDouble: Double
    
    init(label: String, value: Binding<V>, bounds: ClosedRange<V>, step: V) {
        self.label = label
        self.value = value
        self.boundsDouble = Double(bounds.lowerBound)...Double(bounds.upperBound)
        self.stepDouble = Double(step)
        
        self.value.wrappedValue = value.wrappedValue.valueInRange(bounds)
        _valueDouble = State(initialValue: Double(value.wrappedValue))
        
        TnLogger.debug("TnSliderFieldIntOld", label, self.value, self.valueDouble, self.boundsDouble.lowerBound, valueDouble < self.boundsDouble.lowerBound)
    }
    
    func getText() -> String {
        if formatter != nil {
            return formatter!(value.wrappedValue)
        }
        return "\(value.wrappedValue)"
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: TnFieldExtensions.spacing) {
            tnText(label)
            HStack {
                Slider(value: $valueDouble, in: boundsDouble, step: stepDouble, onEditingChanged: { editing in
                    if !editing {
                        value.wrappedValue = V(valueDouble)
                        TnLogger.debug("TnSliderFieldIntOld", "Slider editing", value.wrappedValue)
                    }
                })
                tnText(getText(), lz: false)
            }
        }
        .onAppear {
            TnLogger.debug("TnSliderFieldIntOld", label, valueDouble, self.boundsDouble.lowerBound, valueDouble < self.boundsDouble.lowerBound)
        }
    }
}

// MARK: new implement 08/2024
public struct TnSliderField<TValue>: View where TValue : BinaryFloatingPoint & CVarArg, TValue.Stride : BinaryFloatingPoint {
    let value: Binding<TValue>
    let bounds: ClosedRange<TValue>
    let step: TValue.Stride
    let specifier: String
    let formatter: (TValue) -> String
    let onEdited: ((TValue) -> Void)?
    private let adjustBounds: Bool
    
    public init(value: Binding<TValue>, bounds: ClosedRange<TValue>, step: TValue.Stride, specifier: String = "%.1f", formatter: ((TValue) -> String)? = nil, onEdited: ((TValue) -> Void)? = nil, adjustBounds: Bool = false) {
        self.value = value
        self.bounds = bounds
        self.step = step
        self.specifier = specifier
        self.formatter = formatter ?? { (v: TValue) in v.toString(specifier)}
        self.onEdited = onEdited
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
        let v = adjustBounds ? 0 : bounds.upperBound - bounds.lowerBound
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
                onEdited?(value.wrappedValue)
            }
        }
        .onAppear {
            self.value.wrappedValue = value.wrappedValue.valueInRange(bounds)
        }
    }
}
