//
//  TnArcView.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 8/17/21.
//

import SwiftUI

struct TnArcView: View {
    let value: Double
    let max: Double
    var specifier = "%.0f"
    var label: String
    var invert = false

    static let delta: Double = 30
    static let from = 180 - delta
    static let to = 360 + delta
    static let total: Double = to - from

    var body: some View {
        var varP = value / max
        if varP > 1 {
            varP = 1
        }
        
        return ZStack(alignment: .bottom) {
            GeometryReader { g in
                // base arc
                Path { path in
                    let xc = g.size.width/2
                    let yc: CGFloat = g.size.height/2
                    let radius = g.size.height/2 - 2

                    path.addArc(
                        center: .init(x: xc, y: yc),
                        radius: radius,
                        startAngle: .degrees(TnArcView.to),
                        endAngle: .degrees(TnArcView.from),
                        clockwise: true
                    )
                }
                .stroke(Color.gray.opacity(0.50), style: StrokeStyle(lineWidth: 4, lineCap: .round))

                // value arc
                Path { path in
                    let xc = g.size.width/2
                    let yc: CGFloat = g.size.height/2
                    let radius = g.size.height/2 - 2

                    path.addArc(
                        center: .init(x: xc, y: yc),
                        radius: radius,
                        startAngle: .degrees(TnArcView.from + TnArcView.total*varP),
                        endAngle: .degrees(TnArcView.from),
                        clockwise: true
                    )
                }
                .stroke(invert ? Color.gradientInvertHorz : Color.gradientNormalHorz, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            }
            .padding(.all, 2)

            VStack {
                Text("\(value, specifier: specifier)")
                    .font(.system(size: 14).bold())
                // bar title
                Text(label.lz())
                    .font(.system(size: 14))
            }
//            .padding(.bottom, 20)
        }
        .background(Color("moss"))
        .cornerRadius(2)
    }
}

struct TnArcView_Previews: PreviewProvider {
    static var previews: some View {
        TnArcView(value: 7, max: 16, label: "FPS", invert: true)
            .frame(width: 50, height: 50)
    }
}
