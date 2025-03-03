//
//  Marquee.swift
//
//
//  Created by CatchZeng on 2020/11/23.
//

import SwiftUI

public enum MarqueeDirection {
    case right2left
    case left2right
}

private enum MarqueeState {
    case idle
    case ready
    case animating
}

public struct Marquee<Content> : View where Content : View {
    @Environment(\.marqueeDuration) var duration
    @Environment(\.marqueeAutoreverses) var autoreverses: Bool
    @Environment(\.marqueeDirection) var direction: MarqueeDirection
    @Environment(\.marqueeWhenNotFit) var stopWhenNotFit: Bool
    @Environment(\.marqueeIdleAlignment) var idleAlignment: HorizontalAlignment
    
    private var content: () -> Content
    @State private var state: MarqueeState = .idle
    @State private var contentWidth: CGFloat = 0
    @State private var isAppear = false
    
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    public var body: some View {
        GeometryReader { proxy in
            VStack {
                if isAppear {
                    content()
                        .background(GeometryBackground())
                        .fixedSize()
                        .myOffset(x: offsetX(proxy: proxy), y: 0)
                        .frame(maxHeight: .infinity)
                } else {
                    Text("")
                }
            }
            .onPreferenceChange(WidthKey.self, perform: { value in
                self.contentWidth = value
                resetAnimation(duration: duration, autoreverses: autoreverses, proxy: proxy)
            })
            .onAppear {
                self.isAppear = true
                resetAnimation(duration: duration, autoreverses: autoreverses, proxy: proxy)
            }
            .onDisappear {
                self.isAppear = false
            }
            .onValueChange(value: duration) { newDuration in
                resetAnimation(duration: newDuration, autoreverses: self.autoreverses, proxy: proxy)
            }
            .onValueChange(value: autoreverses){ newAutoreverses in
                resetAnimation(duration: self.duration, autoreverses: newAutoreverses, proxy: proxy)
            }
            onValueChange(value: direction ) { _ in
                resetAnimation(duration: duration, autoreverses: autoreverses, proxy: proxy)
            }
        }.clipped()
    }
    
    private func offsetX(proxy: GeometryProxy) -> CGFloat {
        switch self.state {
        case .idle:
            switch idleAlignment {
            case .center:
                return 0.5*(proxy.size.width-contentWidth)
            case .trailing:
                return proxy.size.width-contentWidth
            default:
                return 0
            }
        case .ready:
            return (direction == .right2left) ? proxy.size.width : -contentWidth
        case .animating:
            return (direction == .right2left) ? -contentWidth : proxy.size.width
        }
    }
    
    private func resetAnimation(duration: Double, autoreverses: Bool, proxy: GeometryProxy) {
        if duration == 0 || duration == Double.infinity {
            stopAnimation()
        } else {
            startAnimation(duration: duration, autoreverses: autoreverses, proxy: proxy)
        }
    }
    
    private func startAnimation(duration: Double, autoreverses: Bool, proxy: GeometryProxy) {
        let isNotFit = contentWidth < proxy.size.width
        if stopWhenNotFit && isNotFit {
            stopAnimation()
            return
        }
        
        withAnimation(.instant) {
            self.state = .ready
            withAnimation(Animation.linear(duration: duration).repeatForever(autoreverses: autoreverses)) {
                self.state = .animating
            }
        }
    }
    
    private func stopAnimation() {
        withAnimation(.instant) {
            self.state = .idle
        }
    }
}

struct Marquee_Previews: PreviewProvider {
    static var previews: some View {
        Marquee {
            Text("Hello World!")
                .fontWeight(.bold)
                .font(.system(size: 40))
        }
    }
}
