import SwiftUI

// MARK: - XP Gain Animation View
struct XPGainView: View {
    let xpEvent: XPGainEvent
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 0.5
    
    var body: some View {
        HStack(spacing: 8) {
            Text(xpEvent.emoji)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("+\(xpEvent.amount) XP")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                
                Text(xpEvent.reason)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                )
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .offset(y: offset)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                scale = 1.0
                offset = -50
            }
            
            withAnimation(.easeOut(duration: 2.0).delay(1.0)) {
                opacity = 0
                offset = -100
            }
        }
    }
}

// MARK: - Level Up Animation
struct LevelUpView: View {
    @Binding var isShowing: Bool
    let level: Int
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = 0
    @State private var sparkleScale: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissAnimation()
                }
            
            VStack(spacing: 30) {
                // Sparkle effects
                ZStack {
                    ForEach(0..<8, id: \.self) { index in
                        Image(systemName: "sparkles")
                            .font(.title)
                            .foregroundColor(.yellow)
                            .scaleEffect(sparkleScale)
                            .rotationEffect(.degrees(Double(index) * 45))
                            .offset(x: 60)
                            .rotationEffect(.degrees(rotation))
                    }
                    
                    // Main level up content
                    VStack(spacing: 20) {
                        Text("LEVEL UP!")
                            .font(.largeTitle)
                            .fontWeight(.black)
                            .foregroundColor(.yellow)
                            .shadow(color: .orange, radius: 10)
                        
                        Text("🎉")
                            .font(.system(size: 80))
                            .scaleEffect(scale)
                        
                        Text("Level \(level)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Keep up the amazing work!")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                }
                
                Button("Continue") {
                    dismissAnimation()
                }
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(Color.yellow)
                .cornerRadius(25)
            }
            .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1.0
                sparkleScale = 1.0
            }
            
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
    
    private func dismissAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            scale = 0.5
            sparkleScale = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isShowing = false
        }
    }
}

// MARK: - Achievement Unlock Animation
struct AchievementView: View {
    @Binding var isShowing: Bool
    let achievement: Achievement
    @State private var scale: CGFloat = 0
    @State private var badgeRotation: Double = 0
    @State private var glowOpacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissAnimation()
                }
            
            VStack(spacing: 25) {
                Text("🏆 ACHIEVEMENT UNLOCKED 🏆")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(Color.yellow.opacity(glowOpacity))
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
                    
                    // Achievement badge
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Text(achievement.emoji)
                            .font(.system(size: 50))
                    }
                    .rotationEffect(.degrees(badgeRotation))
                    .scaleEffect(scale)
                }
                
                VStack(spacing: 10) {
                    Text(achievement.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(achievement.description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Text("+\(achievement.xpReward) XP")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                        .padding(.top, 5)
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.yellow.opacity(0.5), lineWidth: 2)
                    )
            )
            .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                glowOpacity = 0.3
            }
            
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                badgeRotation = 10
                glowOpacity = 0.6
            }
            
            // Auto dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                dismissAnimation()
            }
        }
    }
    
    private func dismissAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            scale = 0
            glowOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isShowing = false
        }
    }
}

// MARK: - Custom Achievement Unlock Animation
struct CustomAchievementView: View {
    @Binding var isShowing: Bool
    let achievement: CustomAchievement
    @State private var scale: CGFloat = 0
    @State private var badgeRotation: Double = 0
    @State private var glowOpacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissAnimation()
                }
            
            VStack(spacing: 25) {
                Text("🏆 ACHIEVEMENT UNLOCKED 🏆")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(Color.yellow.opacity(glowOpacity))
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
                    
                    // Achievement badge
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Text(achievement.emoji)
                            .font(.system(size: 50))
                    }
                    .rotationEffect(.degrees(badgeRotation))
                    .scaleEffect(scale)
                }
                
                VStack(spacing: 10) {
                    Text(achievement.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(achievement.description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Text("+\(achievement.xpReward) XP")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                        .padding(.top, 5)
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.yellow.opacity(0.5), lineWidth: 2)
                    )
            )
            .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                glowOpacity = 0.3
            }
            
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                badgeRotation = 10
                glowOpacity = 0.6
            }
            
            // Auto dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                dismissAnimation()
            }
        }
    }
    
    private func dismissAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            scale = 0
            glowOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isShowing = false
        }
    }
}

// MARK: - Particle System
struct ParticleSystemView: View {
    let effect: ParticleEffect
    @State private var particles: [Particle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.position.x, y: particle.position.y)
                    .opacity(particle.opacity)
                    .scaleEffect(particle.scale)
            }
        }
        .onAppear {
            generateParticles()
            animateParticles()
        }
    }
    
    private func generateParticles() {
        particles = (0..<effect.type.particleCount).map { _ in
            Particle(
                position: CGPoint(x: 0, y: 0),
                velocity: CGPoint(
                    x: Double.random(in: -100...100),
                    y: Double.random(in: -150...50)
                ),
                color: effect.type.colors.randomElement() ?? .white,
                size: Double.random(in: 3...8),
                opacity: 1.0,
                scale: 1.0
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
                newParticle.scale = 0.5
                return newParticle
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let velocity: CGPoint
    let color: Color
    let size: Double
    var opacity: Double
    var scale: Double
}

// MARK: - Progress Ring
struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Gold Color Extension
extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
}
