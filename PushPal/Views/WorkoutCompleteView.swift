import SwiftUI

struct WorkoutCompleteView: View {
    let workout: Workout
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showConfetti = false
    
    var isNewRecord: Bool {
        workout.pushupCount >= dataManager.personalRecords.maxInOneSet
    }
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Trophy or celebration icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.accentOrange, .accentOrange.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: isNewRecord ? "trophy.fill" : "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.white)
                }
                .scaleEffect(showConfetti ? 1 : 0.5)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showConfetti)
                
                // Title
                VStack(spacing: 8) {
                    Text(isNewRecord ? "New Record! 🎉" : "Great Workout!")
                        .font(.title.weight(.bold))
                    
                    Text("You're getting stronger every day")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Stats
                VStack(spacing: 24) {
                    // Main stat - pushups
                    VStack(spacing: 4) {
                        Text("\(workout.pushupCount)")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("pushups")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Secondary stats
                    HStack(spacing: 40) {
                        statItem(icon: "clock.fill", value: workout.formattedDuration, label: "Duration")
                        statItem(icon: "flame.fill", value: String(format: "%.0f", workout.caloriesBurned), label: "Calories")
                        statItem(icon: "checkmark.seal.fill", value: "\(Int(workout.averageFormScore * 100))%", label: "Form")
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal)
                
                // Streak info
                if dataManager.currentStreak > 1 {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(dataManager.currentStreak) day streak!")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.orange.opacity(0.2))
                    .clipShape(Capsule())
                }
                
                // Daily progress
                if dataManager.userProfile.dailyGoal > 0 {
                    dailyProgressView
                }
                
                Spacer()
                
                // Done button
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            
            // Confetti overlay
            if showConfetti && isNewRecord {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.2)) {
                showConfetti = true
            }
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(isNewRecord ? .success : .warning)
        }
    }
    
    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.accentOrange)
            
            Text(value)
                .font(.title3.weight(.bold))
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var dailyProgressView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Today's Progress")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(dataManager.todayPushups)/\(dataManager.userProfile.dailyGoal)")
                    .font(.subheadline.weight(.semibold))
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [.accentOrange, .accentGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * dataManager.getDailyGoalProgress())
                        .animation(.spring(response: 0.6), value: dataManager.getDailyGoalProgress())
                }
            }
            .frame(height: 12)
        }
        .padding(.horizontal)
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                for particle in particles {
                    let age = timeline.date.timeIntervalSince(particle.creationDate)
                    let progress = age / particle.lifetime
                    
                    guard progress < 1 else { continue }
                    
                    let x = particle.x * size.width + sin(age * particle.spinSpeed) * 30
                    let y = particle.y * size.height + age * particle.fallSpeed
                    let opacity = 1 - progress
                    let rotation = Angle(degrees: age * particle.rotationSpeed)
                    
                    context.opacity = opacity
                    context.translateBy(x: x, y: y)
                    context.rotate(by: rotation)
                    
                    let rect = CGRect(x: -5, y: -5, width: 10, height: 10)
                    context.fill(
                        RoundedRectangle(cornerRadius: 2).path(in: rect),
                        with: .color(particle.color)
                    )
                    
                    context.rotate(by: -rotation)
                    context.translateBy(x: -x, y: -y)
                }
            }
        }
        .onAppear {
            generateParticles()
        }
    }
    
    private func generateParticles() {
        let colors: [Color] = [.accentOrange, .accentGreen, .accentBlue, .yellow, .pink, .purple]
        
        for _ in 0..<50 {
            particles.append(ConfettiParticle(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: -0.3...0),
                color: colors.randomElement()!,
                fallSpeed: CGFloat.random(in: 100...200),
                spinSpeed: CGFloat.random(in: 2...5),
                rotationSpeed: Double.random(in: 50...200),
                lifetime: Double.random(in: 2...4),
                creationDate: Date()
            ))
        }
    }
}

struct ConfettiParticle {
    let x: CGFloat
    let y: CGFloat
    let color: Color
    let fallSpeed: CGFloat
    let spinSpeed: CGFloat
    let rotationSpeed: Double
    let lifetime: TimeInterval
    let creationDate: Date
}

#Preview {
    WorkoutCompleteView(workout: Workout(pushupCount: 42, duration: 180, averageFormScore: 0.85, caloriesBurned: 13.44))
        .environmentObject(DataManager.shared)
        .preferredColorScheme(.dark)
}
