
import SwiftUI


struct WeightSelectorView: View {
    @State private var config: WheelPicker.Config = .init(count: 40, steps: 10, spacing: 15, multiplier: 10)
    @Binding var value: CGFloat

    var body: some View {
        VStack {
            HStack(alignment: .lastTextBaseline, spacing: 5) {
                Text(verbatim: "\(Int(round(value)))")
                    .font(.largeTitle.bold())
                    .contentTransition(.numericText(value: value))
                    .animation(.snappy, value: value)

                Text(UnitSystem.current.weightUnit)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .textScale(.secondary)
                    .foregroundStyle(.gray)
            }

            WheelPicker(value: $value, config: config)
                .frame(height: 60)
                .padding(.bottom)
        }
    }

    struct WheelPicker: View {
        @Binding var value: CGFloat
        @State private var selectedIndex: Int? = nil
        var config: Config

        var body: some View {
            GeometryReader { geometry in
                let size = geometry.size
                let horizontalPadding = size.width / 2

                ScrollView(.horizontal) {
                    HStack(spacing: config.spacing) {
                        let totalSteps = config.steps * config.count

                        ForEach(0...totalSteps, id: \.self) { index in
                            let remainder = index % config.steps

                            let lineHeight: CGFloat = {
                                if remainder == 0 {
                                    return 20
                                } else if remainder == config.steps / 2 {
                                    return 15
                                } else {
                                    return 10
                                }
                            }()

                            Divider()
                                .background(remainder == 0 ? Color.primary : .gray)
                                .frame(width: 0, height: lineHeight, alignment: .center)
                                .frame(maxHeight: 20, alignment: .bottom)
                                .overlay(alignment: .bottom) {
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
                .scrollPosition(id: $selectedIndex)
                .onChange(of: selectedIndex) {
                    guard let index = selectedIndex else { return }
                    let step = CGFloat(config.steps)
                    let mult = CGFloat(config.multiplier)
                    value = CGFloat(index) * mult / step
                }
                .onAppear {
                    if selectedIndex == nil {
                        let scaled = value * CGFloat(config.steps)
                        let divided = scaled / CGFloat(config.multiplier)
                        selectedIndex = Int(round(divided))
                    }
                }
                .safeAreaPadding(.horizontal, horizontalPadding)
                .overlay(alignment: .center) {
                    ZStack(alignment: .top) {
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 1, height: 40)
                            .padding(.bottom, 20)

                        DownwardTriangle()
                            .fill(Color.red)
                            .frame(width: 15, height: 10)
                            .rotationEffect(.degrees(180))
                    }
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


