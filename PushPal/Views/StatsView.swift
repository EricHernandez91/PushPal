import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTimeRange: TimeRange = .week
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Daily goal progress
                    dailyGoalCard
                    
                    // Quick stats
                    quickStatsGrid
                    
                    // Weekly chart
                    weeklyChartCard
                    
                    // Personal records
                    personalRecordsCard
                    
                    // Recent workouts
                    recentWorkoutsCard
                }
                .padding()
            }
            .background(Color.background)
            .navigationTitle("Stats")
        }
    }
    
    // MARK: - Daily Goal Card
    private var dailyGoalCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Goal")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(dataManager.todayPushups)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                        Text("/ \(dataManager.userProfile.dailyGoal)")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.cardBackground, lineWidth: 12)
                    
                    Circle()
                        .trim(from: 0, to: dataManager.getDailyGoalProgress())
                        .stroke(
                            LinearGradient(
                                colors: [.accentOrange, .accentGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6), value: dataManager.getDailyGoalProgress())
                    
                    Text("\(Int(dataManager.getDailyGoalProgress() * 100))%")
                        .font(.title3.weight(.bold))
                }
                .frame(width: 80, height: 80)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Quick Stats Grid
    private var quickStatsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            statCard(
                icon: "flame.fill",
                value: "\(dataManager.currentStreak)",
                label: "Day Streak",
                color: .orange
            )
            
            statCard(
                icon: "calendar",
                value: "\(dataManager.getWeeklyPushups())",
                label: "This Week",
                color: .accentBlue
            )
            
            statCard(
                icon: "chart.line.uptrend.xyaxis",
                value: "\(dataManager.getAveragePerDay())",
                label: "Daily Avg",
                color: .accentGreen
            )
        }
    }
    
    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2.weight(.bold))
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Weekly Chart
    private var weeklyChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.headline)
            
            Chart(dataManager.getWeeklyData(), id: \.day) { item in
                BarMark(
                    x: .value("Day", item.day),
                    y: .value("Pushups", item.count)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.accentOrange, .accentOrange.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(6)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.gray.opacity(0.3))
                    AxisValueLabel()
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Personal Records
    private var personalRecordsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Personal Records")
                    .font(.headline)
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
            }
            
            VStack(spacing: 12) {
                recordRow(label: "Best Set", value: "\(dataManager.personalRecords.maxInOneSet)", icon: "bolt.fill")
                Divider().background(Color.gray.opacity(0.3))
                recordRow(label: "Best Day", value: "\(dataManager.personalRecords.maxInOneDay)", icon: "sun.max.fill")
                Divider().background(Color.gray.opacity(0.3))
                recordRow(label: "Longest Streak", value: "\(dataManager.personalRecords.longestStreak) days", icon: "flame.fill")
                Divider().background(Color.gray.opacity(0.3))
                recordRow(label: "All-Time Total", value: "\(dataManager.personalRecords.totalAllTime)", icon: "star.fill")
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private func recordRow(label: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.accentOrange)
                .frame(width: 24)
            
            Text(label)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.headline)
        }
    }
    
    // MARK: - Recent Workouts
    private var recentWorkoutsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Workouts")
                .font(.headline)
            
            if dataManager.workouts.isEmpty {
                Text("No workouts yet. Start your first one!")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical)
            } else {
                ForEach(dataManager.workouts.suffix(5).reversed()) { workout in
                    workoutRow(workout)
                    if workout.id != dataManager.workouts.suffix(5).first?.id {
                        Divider().background(Color.gray.opacity(0.3))
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private func workoutRow(_ workout: Workout) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(workout.pushupCount) pushups")
                    .font(.headline)
                Text(workout.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(workout.formattedDuration)
                    .font(.subheadline)
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.accentGreen)
                        .font(.caption)
                    Text("\(Int(workout.averageFormScore * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    StatsView()
        .environmentObject(DataManager.shared)
        .preferredColorScheme(.dark)
}
