import SwiftUI

// MARK: - Enhanced XP Gain Animation View
struct XPGainView: View {
    let xpEvent: XPGainEvent
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = 0
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text(xpEvent.emoji)
                    .font(.title2)
                    .scaleEffect(1.2)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("+\(xpEvent.amount) XP")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                        
                        if xpEvent.isCombo && xpEvent.comboMultiplier > 1.0 {
                            Text("×\(String(format: "%.1f", xpEvent.comboMultiplier))")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.orange.opacity(0.3))
                                )
                        }
                        
                        if xpEvent.isMultiplied && xpEvent.streakMultiplier > 1.0 {
                            Text("🔥×\(String(format: "%.1f", xpEvent.streakMultiplier))")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.red.opacity(0.3))
                                )
                        }
                    }
                    
                    Text(xpEvent.reason)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(
                    LinearGradient(
                        colors: xpEvent.isCombo ?
                            [Color.orange.opacity(0.9), Color.red.opacity(0.7)] :
                            [Color.black.opacity(0.8), Color.purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            LinearGradient(
                                colors: xpEvent.isCombo ?
                                    [Color.orange, Color.red] :
                                    [Color.yellow.opacity(0.7), Color.purple.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: xpEvent.isCombo ? .orange.opacity(0.6) : .purple.opacity(0.4), radius: 15, x: 0, y: 5)
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .offset(y: offset)
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                scale = 1.0
                offset = -60
            }
            
            if xpEvent.isCombo {
                withAnimation(.easeInOut(duration: 0.5).repeatCount(3, autoreverses: true)) {
                    rotation = 5
                }
            }
            
            withAnimation(.easeOut(duration: 2.5).delay(1.5)) {
                opacity = 0
                offset = -120
                scale = 0.8
            }
        }
    }
}

// MARK: - Explosive Level Up Animation
struct LevelUpView: View {
    @Binding var isShowing: Bool
    let level: Int
    @State private var scale: CGFloat = 0.1
    @State private var rotation: Double = 0
    @State private var sparkleScale: CGFloat = 0
    @State private var screenShake: CGFloat = 0
    @State private var glowIntensity: Double = 0
    @State private var explosionScale: CGFloat = 0
    @State private var fireworksTriggered = false
    
    var body: some View {
        ZStack {
            // Background overlay with pulsing effect
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissAnimation()
                }
                .offset(x: screenShake, y: screenShake)
            
            // Explosion ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.yellow, .orange, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 10
                )
                .frame(width: 300, height: 300)
                .scaleEffect(explosionScale)
                .opacity(explosionScale > 0 ? 1.0 - explosionScale : 0)
            
            VStack(spacing: 40) {
                // Sparkle effects with enhanced animation
                ZStack {
                    ForEach(0..<12, id: \.self) { index in
                        Image(systemName: "sparkles")
                            .font(.system(size: 30))
                            .foregroundColor(.yellow)
                            .scaleEffect(sparkleScale)
                            .rotationEffect(.degrees(Double(index) * 30))
                            .offset(x: 80)
                            .rotationEffect(.degrees(rotation))
                            .shadow(color: .yellow, radius: 10)
                        
                        // Additional inner sparkles
                        Image(systemName: "star.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .scaleEffect(sparkleScale * 0.8)
                            .rotationEffect(.degrees(Double(index) * 30 + 15))
                            .offset(x: 50)
                            .rotationEffect(.degrees(-rotation * 1.5))
                    }
                    
                    // Main level up content with glow
                    VStack(spacing: 25) {
                        Text("LEVEL UP!")
                            .font(.system(size: 36, weight: .black))
                            .foregroundColor(.yellow)
                            .shadow(color: .orange, radius: 20)
                            .shadow(color: .yellow, radius: glowIntensity * 30)
                            .scaleEffect(scale * 1.1)
                        
                        ZStack {
                            // Glow ring
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [.yellow.opacity(glowIntensity), .clear],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 80
                                    )
                                )
                                .frame(width: 160, height: 160)
                            
                            Text("🎉")
                                .font(.system(size: 100))
                                .scaleEffect(scale)
                                .shadow(color: .yellow, radius: 15)
                        }
                        
                        VStack(spacing: 15) {
                            Text("Level \(level)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .purple, radius: 10)
                            
                            Text("Amazing progress!")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                            
                            Text("You're becoming unstoppable! 🚀")
                                .font(.headline)
                                .foregroundColor(.yellow.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                
                Button("CONTINUE") {
                    dismissAnimation()
                }
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .padding(.horizontal, 40)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(30)
                .shadow(color: .yellow.opacity(0.5), radius: 20, x: 0, y: 10)
                .scaleEffect(scale * 0.9)
            }
            .scaleEffect(scale)
            .offset(x: screenShake, y: screenShake)
        }
        .onAppear {
            performExplosiveAnimation()
        }
    }
    
    private func performExplosiveAnimation() {
        // Explosion ring
        withAnimation(.easeOut(duration: 1.5)) {
            explosionScale = 2.0
        }
        
        // Screen shake
        withAnimation(.easeInOut(duration: 0.1).repeatCount(8, autoreverses: true)) {
            screenShake = 10
        }
        
        // Main content scale with bounce
        withAnimation(.spring(response: 1.0, dampingFraction: 0.5)) {
            scale = 1.0
        }
        
        // Sparkles with delayed start
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                sparkleScale = 1.0
            }
        }
        
        // Continuous rotation
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        
        // Pulsing glow effect
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowIntensity = 1.0
        }
        
        // Trigger haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Reset screen shake after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            screenShake = 0
        }
    }
    
    private func dismissAnimation() {
        withAnimation(.easeInOut(duration: 0.4)) {
            scale = 0.1
            sparkleScale = 0
            glowIntensity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isShowing = false
        }
    }
}

// MARK: - Enhanced Achievement Animation with 3D Effects
struct AchievementView: View {
    @Binding var isShowing: Bool
    let achievement: Achievement
    @State private var scale: CGFloat = 0
    @State private var badgeRotation: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var particleScale: CGFloat = 0
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissAnimation()
                }
            
            VStack(spacing: 30) {
                Text("🏆 ACHIEVEMENT UNLOCKED 🏆")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                    .shadow(color: .orange, radius: 10)
                
                ZStack {
                    // Tier-based glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: tierGradientColors(achievement.tier),
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 180, height: 180)
                        .opacity(glowOpacity * achievement.tier.glowIntensity)
                        .blur(radius: 25)
                    
                    // Particle ring around achievement
                    ForEach(0..<8, id: \.self) { index in
                        Circle()
                            .fill(Color.white)
                            .frame(width: 6, height: 6)
                            .offset(x: 70)
                            .rotationEffect(.degrees(Double(index) * 45 + badgeRotation))
                            .scaleEffect(particleScale)
                            .opacity(0.8)
                    }
                    
                    // 3D Achievement badge with shimmer
                    ZStack {
                        // Shadow layer
                        Circle()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 115, height: 115)
                            .offset(x: 3, y: 3)
                        
                        // Main badge with tier gradient
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: tierGradientColors(achievement.tier),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 110, height: 110)
                            .overlay(
                                // Shimmer effect
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.clear, .white.opacity(0.6), .clear],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 30)
                                    .offset(x: shimmerOffset)
                                    .clipShape(Circle())
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 3)
                            )
                        
                        Text(achievement.emoji)
                            .font(.system(size: 60))
                            .shadow(color: .black.opacity(0.5), radius: 5, x: 2, y: 2)
                    }
                    .rotationEffect(.degrees(badgeRotation * 0.1))
                    .scaleEffect(scale)
                }
                
                VStack(spacing: 15) {
                    Text(achievement.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 5)
                    
                    Text(achievement.description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    
                    HStack(spacing: 15) {
                        Text("+\(achievement.xpReward) XP")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.yellow.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color.yellow, lineWidth: 1)
                                    )
                            )
                        
                        Text(achievement.tier.rawValue.capitalized)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: tierGradientColors(achievement.tier),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.black.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                LinearGradient(
                                    colors: tierGradientColors(achievement.tier),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
                    .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
            )
            .scaleEffect(scale)
        }
        .onAppear {
            performAchievementAnimation()
        }
    }
    
    private func performAchievementAnimation() {
        // Main scale animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            scale = 1.0
        }
        
        // Glow effect
        withAnimation(.easeInOut(duration: 1.0)) {
            glowOpacity = 1.0
        }
        
        // Particle ring animation
        withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.3)) {
            particleScale = 1.0
        }
        
        // Continuous badge rotation
        withAnimation(.linear(duration: 10.0).repeatForever(autoreverses: false)) {
            badgeRotation = 360
        }
        
        // Shimmer effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 1.5)) {
                shimmerOffset = 200
            }
        }
        
        // Auto dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            dismissAnimation()
        }
    }
    
    private func dismissAnimation() {
        withAnimation(.easeInOut(duration: 0.4)) {
            scale = 0
            glowOpacity = 0
            particleScale = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isShowing = false
        }
    }
    
    private func tierGradientColors(_ tier: AchievementTier) -> [Color] {
        switch tier {
        case .bronze:
            return [Color(hex: "#CD7F32"), Color(hex: "#D2B48C")]
        case .silver:
            return [Color(hex: "#C0C0C0"), Color(hex: "#E5E5E5")]
        case .gold:
            return [Color(hex: "#FFD700"), Color(hex: "#FFA500")]
        case .platinum:
            return [Color(hex: "#E5E4E2"), Color(hex: "#F8F8FF")]
        case .diamond:
            return [Color(hex: "#B9F2FF"), Color(hex: "#87CEEB")]
        }
    }
}

// MARK: - Combo Multiplier Display
struct ComboDisplay: View {
    let combo: Int
    let multiplier: Double
    @State private var scale: CGFloat = 1.0
    @State private var pulseAnimation = false
    
    var body: some View {
        if combo > 2 {
            HStack(spacing: 8) {
                Text("🔥")
                    .font(.title2)
                    .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(combo)x COMBO!")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("×\(String(format: "%.1f", multiplier)) XP")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [.orange.opacity(0.3), .red.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: .orange.opacity(0.5), radius: 10, x: 0, y: 5)
            )
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    scale = 1.2
                }
                
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        scale = 1.0
                    }
                }
            }
        }
    }
}

// MARK: - Enhanced Particle System
struct EnhancedParticleSystemView: View {
    let effect: ParticleEffect
    @State private var particles: [EnhancedParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(Color(hex: particle.color))
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.position.x, y: particle.position.y)
                    .opacity(particle.opacity)
                    .scaleEffect(particle.scale)
                    .rotationEffect(.degrees(particle.rotation))
            }
        }
        .onAppear {
            generateParticles()
            animateParticles()
        }
    }
    
    private func generateParticles() {
        let colors = effect.type.colors
        particles = (0..<effect.type.particleCount).map { _ in
            EnhancedParticle(
                position: CGPoint(x: 0, y: 0),
                velocity: CGPoint(
                    x: Double.random(in: -150...150),
                    y: Double.random(in: -200...100)
                ),
                color: colors.randomElement() ?? "#FFFFFF",
                size: Double.random(in: 4...12),
                opacity: 1.0,
                scale: 1.0,
                rotation: Double.random(in: 0...360)
            )
        }
    }
    
    private func animateParticles() {
        withAnimation(.easeOut(duration: effect.duration)) {
            particles = particles.map { particle in
                var newParticle = particle
                newParticle.position.x += particle.velocity.x
                newParticle.position.y += particle.velocity.y
                newParticle.opacity = 0
                newParticle.scale = 0.3
                newParticle.rotation += 180
                return newParticle
            }
        }
    }
}

struct EnhancedParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let velocity: CGPoint
    let color: String
    let size: Double
    var opacity: Double
    var scale: Double
    var rotation: Double
}

// MARK: - Enhanced Progress Ring with Animation
struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: [.purple, .pink, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: .purple.opacity(0.5), radius: 5, x: 0, y: 0)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newProgress in
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedProgress = newProgress
            }
        }
    }
}

// MARK: - Helper Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
