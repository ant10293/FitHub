
import SwiftUI

struct WeightSelectorView: View {
    @State private var config: WheelPicker.Config = .init(count: 40, steps: 10, spacing: 15, multiplier: 10)
    @Binding var value: CGFloat
    
    var body: some View {
        VStack {
            HStack(alignment: .lastTextBaseline, spacing: 5, content: {
                Text(verbatim: "\(value)")
                    .font(.largeTitle.bold())
                    .contentTransition(.numericText(value: value))
                    .animation(.snappy, value: value)
                Text("lbs" )
                    .font(.title2)
                    .fontWeight(.semibold)
                    .textScale(.secondary)
                    .foregroundStyle(.gray)
                
            })
            .padding(.bottom, 30)
            
            WheelPicker(value: $value, config: config)
                .frame(height: 60)
        }
    }
    
    struct WheelPicker: View {
        @Binding var value: CGFloat
        @State private var isLoaded: Bool = false
        var config: Config
        
        var body: some View {
            GeometryReader {
                let size = $0.size
                let horizontalPadding = size.width / 2
                
                ScrollView(.horizontal) {
                    HStack(spacing: config.spacing) {
                        let totalSteps = config.steps * config.count
                        
                        ForEach(0...totalSteps, id: \.self) { index in
                            let remainder = index % config.steps
                            
                            // Determine line height based on remainder
                             let lineHeight: CGFloat = {
                                 if remainder == 0 {
                                     // Major tick (e.g., multiples of 10)
                                     return 20
                                 } else if remainder == config.steps / 2 {
                                     // Halfway tick (e.g., multiples of 5)
                                     return 15
                                 } else {
                                     // Minor tick
                                     return 10
                                 }
                             }()
                            
                            Divider()
                                .background (remainder == 0 ? Color.primary : .gray)
                                .frame(width: 0, height: lineHeight, alignment: .center)
                                .frame(maxHeight: 20, alignment: .bottom)
                                .overlay (alignment: .bottom) {
                                    if remainder == 0 && config.showsText {
                                        Text("\((index / config.steps) * config.multiplier)")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .textScale(.secondary)
                                            .fixedSize()
                                            .offset(y: 20)
                                    }
                                }
                        }
                    }
                    .frame(height: size.height)
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: .init(get: {
                    let position: Int? = isLoaded ? (Int(value) * config.steps) /
                        config.multiplier : nil
                    return position
                }, set: { newValue in
                    if let newValue {
                        value = (CGFloat(newValue) / CGFloat(config.steps)) *
                            CGFloat(config.multiplier)
                    }
                }))
                .overlay(alignment: .center) {
                     ZStack(alignment: .top) {
                         // Red selection line
                         Rectangle()
                             .fill(Color.red)
                             .frame(width: 1, height: 40)
                             .padding(.bottom, 20)

                         // The inverted (downward) triangle at the top
                         DownwardTriangle()
                             .fill(Color.red)
                             .frame(width: 15, height: 10)
                             .rotationEffect(.degrees(180))
                     }
                 }
                .safeAreaPadding(.horizontal, horizontalPadding)
                .onAppear {
                    if !isLoaded { isLoaded = true }
                }
            }
        }
        
        struct Config: Equatable {
            var count: Int
            var steps: Int = 10
            var spacing: CGFloat = 5
            var multiplier: Int = 10
            var showsText: Bool = true
        }
        
        struct DownwardTriangle: Shape {
            func path(in rect: CGRect) -> Path {
                var path = Path()
                path.move(to: CGPoint(x: rect.midX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                path.closeSubpath()
                return path
            }
        }
    }
}


