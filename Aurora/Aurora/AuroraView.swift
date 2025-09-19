//
//  AuroraView.swift
//  Aurora
//
//  Created by Emilie on 19/09/2025.
//
import SwiftUI

struct AuroraView: View {
    @State private var time: Double = 0
    private let layers: [AuroraLayer] = [
        .init(color1: .purple.opacity(0.95), color2: .cyan.opacity(0.8), amplitude: 140, speed: 0.18, frequency: 0.0035, blur: 40, verticalOffset: -80),
        .init(color1: .green.opacity(0.9), color2: .blue.opacity(0.7), amplitude: 120, speed: 0.22, frequency: 0.0042, blur: 30, verticalOffset: -20),
        .init(color1: .yellow.opacity(0.85), color2: .green.opacity(0.55), amplitude: 90, speed: 0.28, frequency: 0.0050, blur: 22, verticalOffset: 60)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                
                LinearGradient(gradient: Gradient(colors: [Color.black, Color(red: 0.01, green: 0.02, blue: 0.04)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

              
                StarsView(seed: 42, count: 220, frame: geo.frame(in: .local))
                    .blendMode(.screen)
                    .opacity(0.9)

            
                ForEach(Array(layers.enumerated()), id: \.offset) { index, layer in
                    Canvas { context, size in
                        let layerPath = buildAuroraPath(size: size, time: time * layer.speed, amplitude: layer.amplitude, frequency: layer.frequency, verticalOffset: layer.verticalOffset)

                        
                        let g = Gradient(stops: [Gradient.Stop(color: layer.color1, location: 0.0), Gradient.Stop(color: layer.color2, location: 1.0)])
                        let rect = CGRect(origin: .zero, size: size)
                        context.fill(layerPath, with: .linearGradient(g, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: size.width, y: size.height)))

                       
                        var strokePath = layerPath
                        context.stroke(strokePath, with: .color(.white.opacity(0.03)), lineWidth: 1)

                    }
                    .compositingGroup()
                    .blur(radius: layer.blur)
                    .blendMode(.screen)
                    .opacity(0.9 - Double(index) * 0.12)
                    .offset(x: Double(index) * 6, y: Double(index) * -8)
                    .allowsHitTesting(false)
                }

                
                RoundedRectangle(cornerRadius: 0)
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0), Color.green.opacity(0.15)]), startPoint: .top, endPoint: .bottom))
                    .frame(height: geo.size.height * 0.35)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.85)
                    .blur(radius: 40)
                    .blendMode(.screen)

               
                VStack {
                    Spacer()
                    HStack(spacing: 0) {
                        Path { p in
                            let w = geo.size.width
                            p.move(to: CGPoint(x: 0, y: 120))
                            p.addCurve(to: CGPoint(x: w * 0.25, y: 40), control1: CGPoint(x: w * 0.06, y: 100), control2: CGPoint(x: w * 0.2, y: 20))
                            p.addCurve(to: CGPoint(x: w * 0.55, y: 90), control1: CGPoint(x: w * 0.33, y: 60), control2: CGPoint(x: w * 0.45, y: 110))
                            p.addCurve(to: CGPoint(x: w * 0.78, y: 40), control1: CGPoint(x: w * 0.66, y: 60), control2: CGPoint(x: w * 0.75, y: 10))
                            p.addLine(to: CGPoint(x: w, y: 120))
                            p.addLine(to: CGPoint(x: w, y: 200))
                            p.addLine(to: CGPoint(x: 0, y: 200))
                            p.closeSubpath()
                        }
                        .fill(Color.black.opacity(0.95))
                    }
                    .frame(height: 200)
                }
            }
            .task {
                while true {
                    try? await Task.sleep(nanoseconds: 33_000_000) // ~30 FPS
                    withAnimation(.linear(duration: 0.033)) {
                        time += 1
                    }
                }
            }
        }
    }

   
    private func buildAuroraPath(size: CGSize, time: Double, amplitude: CGFloat, frequency: Double, verticalOffset: CGFloat) -> Path {
        var path = Path()
        let w = Int(size.width)
        let samples = max(40, w / 4)
        let baseline = size.height * 0.35 + verticalOffset

       
        path.move(to: CGPoint(x: 0, y: baseline))
        for i in 0...samples {
            let x = CGFloat(i) / CGFloat(samples) * size.width
            let n = fBM(x: Double(x) * 0.6 * frequency, t: time * 0.6)
            let sine = sin((Double(x) * 0.01) + time * 0.4) * 0.6
            let y = baseline + CGFloat(sine * Double(amplitude)) + CGFloat(n * Double(amplitude) * 0.8)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.closeSubpath()
        return path
    }

    
    private func hash(_ x: Int) -> Int {
        var h = x &* 374761393
        h = (h ^ (h >> 13)) &* 1274126177
        return h
    }

    private func valueNoise(_ x: Double) -> Double {
        let xi = Int(floor(x))
        let xf = x - Double(xi)
        let v0 = Double(hash(xi) & 0xffff) / Double(0xffff)
        let v1 = Double(hash(xi + 1) & 0xffff) / Double(0xffff)
        let u = xf * xf * (3 - 2 * xf)
        return lerp(v0, v1, u)
    }

    private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        return a + (b - a) * t
    }

    private func fBM(x: Double, t: Double) -> Double {
        var total = 0.0
        var amplitude = 1.0
        var frequency = 1.0
        let octaves = 5
        for _ in 0..<octaves {
            total += amplitude * (valueNoise((x * frequency) + t))
            frequency *= 2.0
            amplitude *= 0.5
        }
        return (total - 0.5) * 2.0 * 0.9
    }
}

private struct AuroraLayer {
    var color1: Color
    var color2: Color
    var amplitude: CGFloat
    var speed: Double
    var frequency: Double
    var blur: CGFloat
    var verticalOffset: CGFloat
}


private struct StarsView: View {
    let seed: Int
    let count: Int
    let frame: CGRect
    @State private var twinkle = 0.0

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                var rng = SeededRNG(seed: seed)
                for i in 0..<count {
                    let x = rng.nextDouble() * Double(size.width)
                    let y = rng.nextDouble() * Double(size.height * 0.9)
                    let radius = rng.nextDouble(in: 0.3...1.8)
                    let shine = 0.6 + 0.4 * sin((timeline.date.timeIntervalSinceReferenceDate * 0.8) + Double(i))
                    let opacity = 0.5 + 0.5 * shine
                    let rect = CGRect(x: x, y: y, width: radius, height: radius)
                    context.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(opacity)))
                }
            }
        }
    }
}

private struct SeededRNG {
    private var state: UInt64
    init(seed: Int) { state = UInt64(seed) &* 6364136223846793005 &+ 1442695040888963407 }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
    mutating func nextDouble() -> Double { return Double(next() & 0xffffffff) / Double(0xffffffff) }
    mutating func nextDouble(in range: ClosedRange<Double>) -> Double {
        return range.lowerBound + (nextDouble() * (range.upperBound - range.lowerBound))
    }
}

struct AuroraView_Previews: PreviewProvider {
    static var previews: some View {
        AuroraView()
            .preferredColorScheme(.dark)
    }
}
