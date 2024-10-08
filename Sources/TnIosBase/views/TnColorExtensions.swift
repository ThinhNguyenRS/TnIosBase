//
//  TnColorExtensions.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 12/08/2021.
//

import Foundation
import SwiftUI

extension Color {
    public func getComponents() -> (red: Double, green: Double, blue: Double, opacity: Double) {
#if canImport(UIKit)
        typealias NativeColor = UIColor
#elseif canImport(AppKit)
        typealias NativeColor = NSColor
#endif
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var o: CGFloat = 0
        
        guard NativeColor(self).getRed(&r, green: &g, blue: &b, alpha: &o) else {
            // You can handle the failure here as you want
            return (0, 0, 0, 0)
        }
        
        return (Double(r), Double(g), Double(b), Double(o))
    }
    
    public func invert() -> Color {
        let components = self.getComponents()
        return Color(RGBColorSpace.sRGB, red: 1-components.red, green: 1-components.green, blue: 1-components.blue, opacity: components.opacity)
    }
    
    public static let dark_1_snow = Color("snow")
    public static let dark_2_mercury = Color("mercury")
    public static let dark_3_silver = Color("silver")
    public static let dark_4_magnesium = Color("magnesium")
    public static let dark_5_aluminum = Color("aluminum")
    public static let dark_6_nickel = Color("nickel")
    public static let dark_7_tin = Color("tin")
    public static let dark_8_steel = Color("steel")
    public static let dark_9_iron = Color("iron")
    public static let dark_10_tungsten = Color("tungsten")
    public static let dark_11_lead = Color("lead")
    public static let dark_12 = Color(RGBColorSpace.sRGB, red: 0.18, green: 0.18, blue: 0.18, opacity: 0.75)
    
    /// App specific
    public static let TKG = Color("tkg")
    
    public static func adaptiveColor(_ name: String) -> Color {
        return TnSystem.instance.activeColorScheme == .light ? Color("\(name)-light") : Color("\(name)-dark")
    }
    public static var background: Color {
        return adaptiveColor("background")
    }
    public static var backgroundOfView: some View {
        background.edgesIgnoringSafeArea(.all)
    }
    public static var backgroundTKG: Color {
        return adaptiveColor("backgroundTKG")
    }
    public static var background85: Color {
        return adaptiveColor("background85")
    }
    public static var foreground: Color {
        return adaptiveColor("foreground")
    }
    public static var captionBackground: Color {
        return adaptiveColor("captionBackground")
    }
    public static var captionForeground: Color {
        return adaptiveColor("captionForeground")
    }
    public static var footerBackground: Color {
        return adaptiveColor("footerBackground")
    }
    public static var label: Color {
        return adaptiveColor("foreground")
    }
    public static var border: Color {
        return adaptiveColor("border")
    }
    
    public static let gradientColor = Gradient(colors: [Color.blue, Color.green, Color.orange, Color.red])
    public static func getGradientHorz(start: CGFloat = 0, end: CGFloat = 1, y: CGFloat = 0.5) -> LinearGradient {
        LinearGradient(
            gradient: gradientColor,
            startPoint: UnitPoint(x: start, y: y),
            endPoint  : UnitPoint(x: end, y: y))
    }
    public static func getGradientVert(start: CGFloat = 0, end: CGFloat = 1, x: CGFloat = 0.5) -> LinearGradient {
        LinearGradient(
            gradient: gradientColor,
            startPoint: UnitPoint(x: x, y: start),
            endPoint  : UnitPoint(x: x, y: end))
    }
    
    public static let gradientNormalHorz = getGradientHorz(start: 0, end: 1, y: 0.5)
    public static let gradientInvertHorz = getGradientHorz(start: 1, end: 0, y: 0.5)
    
    public static let gradientNormalVert = getGradientVert(start: 0, end: 1, x: 0.5)
    public static let gradientInvertVert = getGradientVert(start: 1, end: 0, x: 0.5)
    
    public static let background_1 = dark_2_mercury.opacity(0.75)
    public static let background_2 = dark_3_silver.opacity(0.75)
    public static let background_3 = dark_4_magnesium.opacity(0.75)
    public static let background_4 = dark_5_aluminum.opacity(0.75)
    
    public static let background85Dark = Color(RGBColorSpace.sRGB, red: 0.15, green: 0.15, blue: 0.15, opacity: 1)
    
    public static let appleTin = Color(RGBColorSpace.sRGB, red: 0.57, green: 0.57, blue: 0.57, opacity: 1)
    public static let appleAsparagus = Color(RGBColorSpace.sRGB, red: 0.576, green: 0.566, blue: 0.0, opacity: 1)
    public static let appleCayenne = Color(RGBColorSpace.sRGB, red: 0.581, green: 0.067, blue: 0.0, opacity: 1)
    public static let appleClover = Color(RGBColorSpace.sRGB, red: 0.0, green: 0.560, blue: 0.0, opacity: 1)
    public static let appleFern = Color(RGBColorSpace.sRGB, red: 0.308, green: 0.562, blue: 0.0, opacity: 1)
    public static let appleSalmon = Color(RGBColorSpace.sRGB, red: 1.0, green: 0.493, blue: 0.474, opacity: 1)
    public static let appleSteel = Color(RGBColorSpace.sRGB, red: 0.476, green: 0.476, blue: 0.476, opacity: 1)
    public static let appleTangerine = Color(RGBColorSpace.sRGB, red: 1.0, green: 0.587, blue: 0.0, opacity: 1)
    public static let appleTeal = Color(RGBColorSpace.sRGB, red: 0.0, green: 0.569, blue: 0.575, opacity: 1)
    public static let appleCantaloupe = Color(RGBColorSpace.sRGB, red: 1.0, green: 0.832, blue: 0.473, opacity: 1)
    public static let appleBanana = Color(RGBColorSpace.sRGB, red: 1.0, green: 0.988, blue: 0.473, opacity: 1)    
    public static let appleIron = Color(RGBColorSpace.sRGB, red: 0.371, green: 0.371, blue: 0.371, opacity: 1)
    public static let appleMagnesium = Color(RGBColorSpace.sRGB, red: 0.754, green: 0.754, blue: 0.754, opacity: 1)
    public static let appleMocha = Color(RGBColorSpace.sRGB, red: 0.579, green: 0.322, blue: 0.000, opacity: 1)
}
