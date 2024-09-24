//
//  TnCharts.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 8/17/21.
//

import Foundation
import SwiftUI

struct BarValue<TLabel: View>: View {
    let value: Float
    let max: Float
    var specifier = "%.0f"
    var label: TLabel
    var invert = false
    var height: CGFloat = 70
    
    var body: some View {
        VStack {
            ZStack(alignment: .bottom) {
                // bar whole
                Rectangle()
                    .fill(
                        invert ? Color.gradientInvertVert : Color.gradientNormalVert
                    )
                
                // bar value color
                Rectangle()
                    .fill(Color.white.opacity(0.50))
                    .frame(height: getHeight(CGFloat(value/max)*height) )
                
                // bar title
                VStack {
                    label
                        .font(.system(size: 14))
                        .frame(height: 16)
                    Spacer()
                    Text("\(value, specifier: specifier)")
                        .font(.system(size: 14).bold())
                }
                .padding([.top, .bottom], 2)
            }
        }
        .height(height)
        .cornerRadius(2)
        //        .animation(.easeIn)
        .animation(.interpolatingSpring(mass: 1.0, stiffness: 100.0, damping: 10, initialVelocity: 0),
                   value: UUID()
        )

    }
}

struct BarText: View {
    var text: String
    var label: String
    var height: CGFloat = 70
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color("moss"))
            // bar title
            VStack {
                Text(label)
                    .font(.system(size: 14))
                    .frame(height: 16)
                Spacer()
                Text(text)
                    .font(.system(size: 14).bold())
            }
            .padding([.top, .bottom], 2)
            .frame(height: height)
        }
        .cornerRadius(2)
    }
}

struct ArcView: View {
    let value: Float
    let max: Float
    var specifier = "%.0f"
    var invert = false
    var height: CGFloat = 70
    
    var body: some View {
        var varP = value / max
        if varP > 1 {
            varP = 1
        }
        
        return ZStack(alignment: .bottom) {
            GeometryReader { g in
                Path { path in
                    let xc = g.size.width/2
                    let yc: CGFloat = 4 //g.size.height - 4
                    let radius = g.size.width/2 - 2
                    
                    path.addArc(
                        center: .init(x: xc, y: yc),
                        radius: radius,
                        startAngle: .degrees(0),
                        endAngle: .degrees(Double(180 * varP)),
                        clockwise: false
                    )
                }
                .stroke(invert ? Color.gradientInvertHorz : Color.gradientNormalHorz, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-180))
            }
            
            VStack {
                // bar title
                Text("FPS")
                    .font(.system(size: 14))
                
                Spacer()

                Text("\(value, specifier: specifier)")
                    .font(.system(size: 14).bold())
                //                        .padding(.top, 16)
            }
        }
        .padding(.all, 2)
        .background(Color("moss"))
        .cornerRadius(2)
    }
}

