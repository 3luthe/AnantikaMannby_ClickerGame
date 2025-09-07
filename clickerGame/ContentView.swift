//
//  ContentView.swift
//  clickerGame
//
//  Created by Anantika Mannby on 9/2/25.
//

import SwiftUI

struct Award: Identifiable {
    let id = UUID()
    let threshold: Int
    let emoji: String
}

struct Level: Identifiable {
    let id = UUID()
    let name: String
    let goal: Int
    let badge: String
}

struct ContentView: View {
    @State var taps = 0
    @State var isJumping = false
    @State var collected: [String] = []

    @State var levelIndex = 0
    @State var didComplete = false
    @State var rainBurstID = UUID()
    @State var showRain = false
    @State var rainEmoji = "☁️"
    @State var bannerText: String? = nil

    let rainDropCount = 50
    let rainDelayStep = 0.1
    let rainFallDur   = 6.0
    let rainFadeDur   = 1.5
    
    let levels: [Level] = [
        Level(name: "Cloudy",         goal: 15, badge: "☁️"),
        Level(name: "Rainbow Rider",  goal: 20, badge: "🌈"),
        Level(name: "Queen",          goal: 30, badge: "👑")
    ]

    // 10 collectible awards
    let awards: [Award] = [
        Award(threshold: 3,  emoji: "✨"),
        Award(threshold: 6,  emoji: "🌟"),
        Award(threshold: 10, emoji: "🌈"),
        Award(threshold: 15, emoji: "🦋"),
        Award(threshold: 20, emoji: "🧁"),
        Award(threshold: 25, emoji: "🍓"),
        Award(threshold: 30, emoji: "💎"),
        Award(threshold: 40, emoji: "🪄"),
        Award(threshold: 50, emoji: "🎀"),
        Award(threshold: 60, emoji: "👑")
    ]

    // Grid that fills the screen
    let columns = [GridItem(.adaptive(minimum: 60), spacing: 10)]

    var currentLevel: Level { levels[min(levelIndex, levels.count - 1)] }
    var nextLevelGoal: Int? {
        let i = levelIndex + 1
        return i < levels.count ? levels[i].goal : nil
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.red, .orange, .yellow, .green, .blue, .indigo, .purple],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text("Unicorn Clicker \(currentLevel.badge)")
                        .font(.system(.largeTitle, design: .rounded))
                        .bold()
                        .foregroundColor(.white)
                        .shadow(radius: 6)

                    HStack(spacing: 10) {
                        Text("Level: \(currentLevel.name)")
                        Text("Clicks: \(taps)")
                    }
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .foregroundStyle(.white)
                }

                // Main Unicorn Button
                Button(action: handleTap) {
                    Text("🦄")
                        .font(.system(size: 140))
                        .scaleEffect(isJumping ? 1.1 : 1.0)
                        .offset(y: isJumping ? -20 : 0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isJumping)
                        .shadow(radius: 8)
                        .accessibilityLabel("Tap the unicorn to gain points")
                }
                .buttonStyle(.plain)

                if let next = nextAward(after: taps) {
                    Text("Next: \(next.emoji) at \(next.threshold) clicks")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .foregroundStyle(.white)
                } else {
                    Text("All 10 emojis collected! 🎉")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .foregroundStyle(.white)
                }

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(collected, id: \.self) { emoji in
                            Text(emoji)
                                .font(.system(size: 36))
                                .frame(width: 60, height: 60)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .shadow(radius: 3)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                Button {
                    taps = 0
                    collected = []
                    didComplete = false
                    levelIndex = 0
                    showBanner("Starting Level: \(levels[0].name) \(levels[0].badge)")
                    triggerEmojiRain(with: levels[0].badge)
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .foregroundStyle(.white)

                Spacer(minLength: 0)
            }
            .padding(.top, 40)
            .padding(.bottom, 24)
            .foregroundStyle(.white)
            .onAppear {
                // Intro banner + clouds rain at start
                showBanner("Starting Level: \(levels[0].name) \(levels[0].badge)")
                triggerEmojiRain(with: levels[0].badge)
            }

            if showRain {
                EmojiRain(
                    emoji: rainEmoji,
                    dropCount: rainDropCount,
                    delayStep: rainDelayStep,
                    fallDuration: rainFallDur,
                    fadeDuration: rainFadeDur
                )
                .id(rainBurstID)
                .transition(.opacity)
                .allowsHitTesting(false)
            }

            if let text = bannerText {
                Text(text)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .foregroundStyle(.white)
                    .shadow(radius: 6)
                    .transition(.opacity.combined(with: .scale))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .allowsHitTesting(false)
            }
        }
    }

    func handleTap() {
        taps += 1
        jump()
        unlockIfNeeded()
        checkProgress()
    }

    func jump() {
        isJumping = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isJumping = false
        }
    }

    func unlockIfNeeded() {
        for a in awards where taps == a.threshold {
            if !collected.contains(a.emoji) {
                collected.append(a.emoji)
                collected.sort { orderIndex(for: $0) < orderIndex(for: $1) }
            }
        }
    }

    func nextAward(after count: Int) -> Award? {
        awards.sorted { $0.threshold < $1.threshold }
              .first { $0.threshold > count }
    }

    func checkProgress() {
        // 1) Completion: after all 10 emojis collected
        if !didComplete && collected.count >= awards.count {
            didComplete = true
            showBanner("Completed all levels! 🦄")
            triggerEmojiRain(with: "🦄")
            return
        }

        if let nextGoal = nextLevelGoal, taps >= nextGoal {
            levelIndex += 1
            showBanner("Level Up: \(currentLevel.name) \(currentLevel.badge)")
            triggerEmojiRain(with: currentLevel.badge)
        }
    }

    func showBanner(_ text: String, duration: Double = 2.0) {
        withAnimation(.easeOut(duration: 0.25)) { bannerText = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(.easeIn(duration: 0.25)) { bannerText = nil }
        }
    }

    func triggerEmojiRain(with emoji: String) {
        rainEmoji = emoji
        showRain = true
        rainBurstID = UUID()

        let maxDelay = rainDelayStep * Double(rainDropCount - 1)
        let totalVisible = maxDelay + rainFallDur + rainFadeDur + 0.5

        DispatchQueue.main.asyncAfter(deadline: .now() + totalVisible) {
            withAnimation(.easeOut(duration: 0.3)) { showRain = false }
        }
    }

    func orderIndex(for emoji: String) -> Int {
        awards.firstIndex(where: { $0.emoji == emoji }) ?? Int.max
    }
}

struct EmojiRain: View {
    let emoji: String
    let dropCount: Int
    let delayStep: Double
    let fallDuration: Double
    let fadeDuration: Double

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<dropCount, id: \.self) { i in
                    let x = CGFloat.random(in: 0...geo.size.width)
                    let delay = Double(i) * delayStep
                    RainDrop(
                        emoji: emoji,
                        startX: x,
                        height: geo.size.height,
                        delay: delay,
                        fallDuration: fallDuration,
                        fadeDuration: fadeDuration
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
        }
    }
}

struct RainDrop: View {
    let emoji: String
    let startX: CGFloat
    let height: CGFloat
    let delay: Double
    let fallDuration: Double
    let fadeDuration: Double

    @State var fall = false
    @State var spin = false
    @State var fade = false

    var body: some View {
        Text(emoji)
            .font(.system(size: 34))
            .rotationEffect(.degrees(spin ? 720 : 0)) // gentle double spin
            .opacity(fade ? 0 : 1)
            .position(x: startX, y: fall ? height + 80 : -80)
            .onAppear {
                withAnimation(.easeInOut(duration: fallDuration).delay(delay)) {
                    fall = true
                }
                withAnimation(.linear(duration: fallDuration).delay(delay)) {
                    spin = true
                }
                withAnimation(.easeOut(duration: fadeDuration).delay(delay + max(0, fallDuration - 1.0))) {
                    fade = true
                }
            }
    }
}

#Preview { ContentView() }

