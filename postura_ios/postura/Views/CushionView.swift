//
//  CushionView.swift
//  postura
//
//  Created by YunHao Dong on 2/18/26.
//
import SwiftUI

import SwiftUI

struct PressureCushionView: View {
    
     var pressurePoints: [[Bool]]
     
     var body: some View {
         GeometryReader { geo in
             
             let width = geo.size.width
             let height = geo.size.height
             
             ZStack {
                 
                 // Chair shape scales automatically
                 ChairShape()
                     .fill(
                         LinearGradient(
                             colors: [
                                 Color.gray.opacity(0.35),
                                 Color.gray.opacity(0.15)
                             ],
                             startPoint: .top,
                             endPoint: .bottom
                         )
                     )
                     .shadow(radius: 10)
                 
                 // Pressure points scale proportionally
                 VStack(spacing: height * 0.12) {
                     
                     ForEach(0..<pressurePoints.count, id: \.self) { row in
                         HStack(spacing: width * 0.18) {
                             ForEach(0..<pressurePoints[row].count, id: \.self) { col in
                                 Circle()
                                     .fill(pressurePoints[row][col] ? .green : .red)
                                     .frame(
                                         width: width * 0.08,
                                         height: width * 0.08
                                     )
                                     .shadow(
                                        color: (pressurePoints[row][col] ? Color.green : Color.red)
                                            .opacity(0.7),
                                        radius: width * 0.04
                                    )
                             }
                         }
                     }
                 }
                 .padding(.top, height * 0.15)
             }
         }
         .aspectRatio(0.75, contentMode: .fit)
         .padding()
     }
    // MARK: Pressure Dot
    func pressureDot(isCorrect: Bool) -> some View {
        Circle()
            .fill(isCorrect ? Color.green : Color.red)
            .frame(width: 36, height: 36)
            .shadow(color: (isCorrect ? Color.green : Color.red).opacity(0.7),
                    radius: 12)
            .animation(.easeInOut(duration: 0.2), value: isCorrect)
    }
}

struct ChairShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        let backHeight = height * 0.65
        let seatHeight = height * 0.25
        
        // Start top center
        path.move(to: CGPoint(x: width * 0.25, y: 0))
        
        // Left side curve (backrest)
        path.addQuadCurve(
            to: CGPoint(x: 0, y: backHeight),
            control: CGPoint(x: 0, y: backHeight * 0.3)
        )
        
        // Left seat bottom curve
        path.addQuadCurve(
            to: CGPoint(x: width * 0.2, y: backHeight + seatHeight),
            control: CGPoint(x: 0, y: height)
        )
        
        // Bottom seat
        path.addLine(to: CGPoint(x: width * 0.8, y: backHeight + seatHeight))
        
        // Right seat curve
        path.addQuadCurve(
            to: CGPoint(x: width, y: backHeight),
            control: CGPoint(x: width, y: height)
        )
        
        // Right back curve
        path.addQuadCurve(
            to: CGPoint(x: width * 0.75, y: 0),
            control: CGPoint(x: width, y: backHeight * 0.3)
        )
        
        path.closeSubpath()
        
        return path
    }
}
