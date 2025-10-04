//
//  GoalsView.swift
//  LeanLog
//
//  Created by Lokesh Kaki on 9/29/25.
//  Updated: Fixed female icon, independent unit toggles, modern UI, default screen logic
//

import SwiftUI
import SwiftData

// MARK: - User Profile Model
@Model
final class UserProfile {
    var id = UUID()
    
    // Personal Info
    var age = 25
    var sex = UserProfile.Sex.male
    var heightCm = 170.0
    var weightKg = 70.0
    var useMetricHeight = false // ft/in default
    var useMetricWeight = false // lbs default
    
    // Goals
    var goalType = UserProfile.GoalType.maintain
    var activityLevel = UserProfile.ActivityLevel.moderate
    var dietType = UserProfile.DietType.balanced
    
    // Calculated Targets
    var dailyCalories = 2000
    var proteinGrams = 150
    var carbsGrams = 200
    var fatGrams = 65
    
    var isOnboardingComplete = false
    var createdAt = Date()
    
    init() {}
    
    enum Sex: String, Codable, CaseIterable {
        case male = "Male"
        case female = "Female"
        
        var icon: String {
            switch self {
            case .male: return "figure.stand" // Clean, simple male figure
            case .female: return "figure.stand.dress" // Clear female figure with dress
            }
        }
        
        var explanation: String {
            "Sex affects metabolic calculations. Males typically have higher BMR due to greater muscle mass."
        }
    }
    
    enum GoalType: String, Codable, CaseIterable {
        case lose = "Lose Weight"
        case maintain = "Maintain Weight"
        case gain = "Gain Weight"
        case muscleGain = "Build Muscle"
        
        var icon: String {
            switch self {
            case .lose: return "arrow.down.circle.fill"
            case .maintain: return "equal.circle.fill"
            case .gain: return "arrow.up.circle.fill"
            case .muscleGain: return "figure.strengthtraining.traditional"
            }
        }
        
        var description: String {
            switch self {
            case .lose: return "Lose 0.5-1 kg per week"
            case .maintain: return "Stay at current weight"
            case .gain: return "Gain 0.25-0.5 kg per week"
            case .muscleGain: return "Build lean muscle mass"
            }
        }
        
        var calorieModifier: Double {
            switch self {
            case .lose: return -500
            case .maintain: return 0
            case .gain: return 300
            case .muscleGain: return 350
            }
        }
    }
    
    enum ActivityLevel: String, Codable, CaseIterable {
        case sedentary = "Sedentary"
        case light = "Lightly Active"
        case moderate = "Moderately Active"
        case veryActive = "Very Active"
        case extremelyActive = "Extremely Active"
        
        var icon: String {
            switch self {
            case .sedentary: return "figure.seated.side"
            case .light: return "figure.walk"
            case .moderate: return "figure.run"
            case .veryActive: return "figure.outdoor.cycle"
            case .extremelyActive: return "figure.strengthtraining.traditional"
            }
        }
        
        var description: String {
            switch self {
            case .sedentary: return "Little or no exercise"
            case .light: return "Exercise 1-3 days/week"
            case .moderate: return "Exercise 3-5 days/week"
            case .veryActive: return "Exercise 6-7 days/week"
            case .extremelyActive: return "Very intense exercise daily"
            }
        }
        
        var multiplier: Double {
            switch self {
            case .sedentary: return 1.2
            case .light: return 1.375
            case .moderate: return 1.55
            case .veryActive: return 1.725
            case .extremelyActive: return 1.9
            }
        }
    }
    
    enum DietType: String, Codable, CaseIterable {
        case balanced = "Balanced"
        case highProtein = "High Protein"
        case keto = "Keto"
        case lowCarb = "Low Carb"
        case lowFat = "Low Fat"
        
        var icon: String {
            switch self {
            case .balanced: return "circle.hexagongrid.fill"
            case .highProtein: return "flame.fill"
            case .keto: return "leaf.fill"
            case .lowCarb: return "minus.circle.fill"
            case .lowFat: return "drop.fill"
            }
        }
        
        var macroRatio: (carbs: Double, protein: Double, fat: Double) {
            switch self {
            case .balanced: return (0.40, 0.30, 0.30)
            case .highProtein: return (0.30, 0.40, 0.30)
            case .keto: return (0.05, 0.25, 0.70)
            case .lowCarb: return (0.20, 0.35, 0.45)
            case .lowFat: return (0.50, 0.30, 0.20)
            }
        }
    }
    
    // MARK: - Calculation Methods
    
    func calculateBMR() -> Double {
        let weightFactor = 10 * weightKg
        let heightFactor = 6.25 * heightCm
        let ageFactor = 5 * Double(age)
        let baseBMR = weightFactor + heightFactor - ageFactor
        return sex == .male ? baseBMR + 5 : baseBMR - 161
    }
    
    func calculateTDEE() -> Double {
        let bmr = calculateBMR()
        return bmr * activityLevel.multiplier
    }
    
    func calculateTargetCalories() -> Int {
        let tdee = calculateTDEE()
        let adjustedCalories = tdee + goalType.calorieModifier
        return Int(adjustedCalories)
    }
    
    func calculateMacros() {
        dailyCalories = calculateTargetCalories()
        let ratios = dietType.macroRatio
        let carbCalories = Double(dailyCalories) * ratios.carbs
        let proteinCalories = Double(dailyCalories) * ratios.protein
        let fatCalories = Double(dailyCalories) * ratios.fat
        carbsGrams = Int(carbCalories / 4)
        proteinGrams = Int(proteinCalories / 4)
        fatGrams = Int(fatCalories / 9)
    }
    
    // Sync to AppStorage for system-wide use
    func syncToAppStorage() {
        UserDefaults.standard.set(dailyCalories, forKey: "dailyCalorieGoal")
        UserDefaults.standard.set(Double(proteinGrams), forKey: "proteinGoal")
        UserDefaults.standard.set(Double(carbsGrams), forKey: "carbGoal")
        UserDefaults.standard.set(Double(fatGrams), forKey: "fatGoal")
    }
}

// MARK: - Main Goals View
struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var showOnboarding = false
    
    private var userProfile: UserProfile? {
        profiles.first
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if let profile = userProfile, profile.isOnboardingComplete {
                    GoalsDetailView(profile: profile)
                } else {
                    GoalsEmptyStateView(showOnboarding: $showOnboarding)
                }
            }
            .screenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .modernNavigation()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Goals")
                        .font(AppTheme.Typography.title3)
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                }
            }
            .sheet(isPresented: $showOnboarding) {
                GoalsOnboardingFlow(modelContext: modelContext)
            }
            .onAppear {
                if userProfile == nil {
                    showOnboarding = true
                }
            }
        }
    }
}

// MARK: - Empty State View
struct GoalsEmptyStateView: View {
    @Binding var showOnboarding: Bool
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            
            Image(systemName: "target")
                .font(.system(size: 72))
                .foregroundStyle(AppTheme.Colors.accent)
            
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Set Your Goals")
                    .font(AppTheme.Typography.largeTitle)
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
                    .fontWeight(.bold)
                
                Text("Get personalized nutrition targets based on your goals")
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.labelSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.screenPadding)
            }
            
            Button {
                showOnboarding = true
            } label: {
                Text("Get Started")
                    .font(AppTheme.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.Colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
            }
            .padding(.horizontal, AppTheme.Spacing.screenPadding)
            .padding(.top, AppTheme.Spacing.lg)
            
            Spacer()
        }
    }
}

// MARK: - Onboarding Flow
struct GoalsOnboardingFlow: View {
    let modelContext: ModelContext
    @State private var currentStep = 0
    @State private var profile = UserProfile()
    @Environment(\.dismiss) private var dismiss
    
    private let totalSteps = 5
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                    .tint(AppTheme.Colors.accent)
                    .padding(.horizontal, AppTheme.Spacing.screenPadding)
                    .padding(.top, AppTheme.Spacing.md)
                
                TabView(selection: $currentStep) {
                    PersonalInfoStep(profile: $profile).tag(0)
                    ActivityLevelStep(profile: $profile).tag(1)
                    GoalSelectionStep(profile: $profile).tag(2)
                    DietTypeStep(profile: $profile).tag(3)
                    SummaryStep(profile: profile).tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                HStack(spacing: AppTheme.Spacing.md) {
                    if currentStep > 0 {
                        Button {
                            withAnimation { currentStep -= 1 }
                        } label: {
                            Text("Back")
                                .font(AppTheme.Typography.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.Colors.accent)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppTheme.Colors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                        }
                    }
                    
                    Button {
                        if currentStep < totalSteps - 1 {
                            withAnimation { currentStep += 1 }
                        } else {
                            completeOnboarding()
                        }
                    } label: {
                        Text(currentStep == totalSteps - 1 ? "Complete" : "Continue")
                            .font(AppTheme.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.Colors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                    }
                }
                .padding(AppTheme.Spacing.screenPadding)
            }
            .screenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .modernNavigation()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func completeOnboarding() {
        profile.calculateMacros()
        profile.isOnboardingComplete = true
        profile.syncToAppStorage() // Sync to AppStorage!
        modelContext.insert(profile)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Step 1: Personal Info (FIXED: Independent unit toggles, better female icon)
struct PersonalInfoStep: View {
    @Binding var profile: UserProfile
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Let's Get Started")
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                        .fontWeight(.bold)
                    
                    Text("Tell us about yourself")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.labelSecondary)
                }
                
                // Sex Selection with Explanation
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    HStack {
                        Text("Biological Sex")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.labelSecondary)
                            .textCase(.uppercase)
                        
                        Spacer()
                        
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                            .foregroundStyle(AppTheme.Colors.labelTertiary)
                    }
                    
                    Text(profile.sex.explanation)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.labelTertiary)
                        .padding(.bottom, 4)
                    
                    HStack(spacing: AppTheme.Spacing.md) {
                        ForEach(UserProfile.Sex.allCases, id: \.self) { sex in
                            SelectionCard(
                                title: sex.rawValue,
                                icon: sex.icon,
                                isSelected: profile.sex == sex
                            ) {
                                profile.sex = sex
                            }
                        }
                    }
                }
                
                // Age
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Age")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.labelSecondary)
                        .textCase(.uppercase)
                    
                    HStack {
                        Text("\(profile.age)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(AppTheme.Colors.labelPrimary)
                        
                        Text("years")
                            .font(AppTheme.Typography.title3)
                            .foregroundStyle(AppTheme.Colors.labelSecondary)
                            .padding(.top, 16)
                        
                        Spacer()
                        
                        VStack(spacing: 8) {
                            Button {
                                if profile.age < 100 { profile.age += 1 }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.title3)
                                    .foregroundStyle(AppTheme.Colors.accent)
                                    .frame(width: 44, height: 44)
                                    .background(AppTheme.Colors.surface)
                                    .clipShape(Circle())
                            }
                            
                            Button {
                                if profile.age > 15 { profile.age -= 1 }
                            } label: {
                                Image(systemName: "minus")
                                    .font(.title3)
                                    .foregroundStyle(AppTheme.Colors.accent)
                                    .frame(width: 44, height: 44)
                                    .background(AppTheme.Colors.surface)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding()
                    .background(AppTheme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                }
                
                // Height with INDEPENDENT Unit Toggle
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    HStack {
                        Text("Height")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.labelSecondary)
                            .textCase(.uppercase)
                        
                        Spacer()
                        
                        Picker("Unit", selection: $profile.useMetricHeight) {
                            Text("ft/in").tag(false)
                            Text("cm").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }
                    
                    VStack(spacing: 12) {
                        if profile.useMetricHeight {
                            Text("\(Int(profile.heightCm)) cm")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(AppTheme.Colors.labelPrimary)
                        } else {
                            let feet = Int(profile.heightCm / 30.48)
                            let inches = Int((profile.heightCm / 2.54).truncatingRemainder(dividingBy: 12))
                            Text("\(feet)' \(inches)\"")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(AppTheme.Colors.labelPrimary)
                        }
                        
                        Slider(value: $profile.heightCm, in: 120...220, step: 1)
                            .tint(AppTheme.Colors.accent)
                    }
                    .padding()
                    .background(AppTheme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                }
                
                // Weight with INDEPENDENT Unit Toggle
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    HStack {
                        Text("Weight")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.labelSecondary)
                            .textCase(.uppercase)
                        
                        Spacer()
                        
                        Picker("Unit", selection: $profile.useMetricWeight) {
                            Text("lbs").tag(false)
                            Text("kg").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }
                    
                    VStack(spacing: 12) {
                        if profile.useMetricWeight {
                            Text(String(format: "%.1f kg", profile.weightKg))
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(AppTheme.Colors.labelPrimary)
                        } else {
                            let lbs = profile.weightKg * 2.20462
                            Text(String(format: "%.1f lbs", lbs))
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(AppTheme.Colors.labelPrimary)
                        }
                        
                        Slider(value: $profile.weightKg, in: 30...200, step: 0.5)
                            .tint(AppTheme.Colors.accent)
                    }
                    .padding()
                    .background(AppTheme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                }
                
                Spacer(minLength: 100)
            }
            .padding(AppTheme.Spacing.screenPadding)
        }
    }
}

// MARK: - Step 2: Activity Level
struct ActivityLevelStep: View {
    @Binding var profile: UserProfile
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Activity Level")
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                        .fontWeight(.bold)
                    
                    Text("How active are you?")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.labelSecondary)
                }
                
                VStack(spacing: AppTheme.Spacing.md) {
                    ForEach(UserProfile.ActivityLevel.allCases, id: \.self) { level in
                        ActivityLevelCard(
                            level: level,
                            isSelected: profile.activityLevel == level
                        ) {
                            profile.activityLevel = level
                        }
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding(AppTheme.Spacing.screenPadding)
        }
    }
}

// MARK: - Step 3: Goal Selection
struct GoalSelectionStep: View {
    @Binding var profile: UserProfile
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Your Goal")
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                        .fontWeight(.bold)
                    
                    Text("What would you like to achieve?")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.labelSecondary)
                }
                
                VStack(spacing: AppTheme.Spacing.md) {
                    ForEach(UserProfile.GoalType.allCases, id: \.self) { goal in
                        GoalCard(
                            goal: goal,
                            isSelected: profile.goalType == goal
                        ) {
                            profile.goalType = goal
                        }
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding(AppTheme.Spacing.screenPadding)
        }
    }
}

// MARK: - Step 4: Diet Type
struct DietTypeStep: View {
    @Binding var profile: UserProfile
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Diet Preference")
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                        .fontWeight(.bold)
                    
                    Text("Choose your macronutrient distribution")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.labelSecondary)
                }
                
                VStack(spacing: AppTheme.Spacing.md) {
                    ForEach(UserProfile.DietType.allCases, id: \.self) { diet in
                        DietTypeCard(
                            diet: diet,
                            isSelected: profile.dietType == diet
                        ) {
                            profile.dietType = diet
                        }
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding(AppTheme.Spacing.screenPadding)
        }
    }
}

// MARK: - Step 5: Summary
struct SummaryStep: View {
    let profile: UserProfile
    
    private var calculatedCalories: Int {
        let tempProfile = profile
        tempProfile.calculateMacros()
        return tempProfile.dailyCalories
    }
    
    private var calculatedMacros: (protein: Int, carbs: Int, fat: Int) {
        let tempProfile = profile
        tempProfile.calculateMacros()
        return (tempProfile.proteinGrams, tempProfile.carbsGrams, tempProfile.fatGrams)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Your Plan")
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                        .fontWeight(.bold)
                    
                    Text("Here are your personalized targets")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.labelSecondary)
                }
                
                // Daily Calories with Icon
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Daily Calories")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.labelSecondary)
                        .textCase(.uppercase)
                    
                    HStack(spacing: 16) {
                        Image(systemName: AppTheme.Icons.calories)
                            .font(.system(size: 40))
                            .foregroundStyle(AppTheme.Colors.calories)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(calculatedCalories)")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(AppTheme.Colors.labelPrimary)
                            
                            Text("kcal per day")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.labelSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(AppTheme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                }
                
                // Macros with Icons
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Macronutrients")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.labelSecondary)
                        .textCase(.uppercase)
                    
                    HStack(spacing: AppTheme.Spacing.md) {
                        MacroSummaryCard(
                            icon: AppTheme.Icons.protein,
                            title: "Protein",
                            value: calculatedMacros.protein,
                            color: AppTheme.Colors.protein
                        )
                        
                        MacroSummaryCard(
                            icon: AppTheme.Icons.carbs,
                            title: "Carbs",
                            value: calculatedMacros.carbs,
                            color: AppTheme.Colors.carbs
                        )
                        
                        MacroSummaryCard(
                            icon: AppTheme.Icons.fat,
                            title: "Fat",
                            value: calculatedMacros.fat,
                            color: AppTheme.Colors.fat
                        )
                    }
                }
                
                // Summary Details
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Summary")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.labelSecondary)
                        .textCase(.uppercase)
                    
                    VStack(spacing: 0) {
                        SummaryRow(label: "Goal", value: profile.goalType.rawValue)
                        Divider().padding(.leading, 16)
                        SummaryRow(label: "Activity", value: profile.activityLevel.rawValue)
                        Divider().padding(.leading, 16)
                        SummaryRow(label: "Diet Type", value: profile.dietType.rawValue)
                    }
                    .padding()
                    .background(AppTheme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                }
                
                Spacer(minLength: 100)
            }
            .padding(AppTheme.Spacing.screenPadding)
        }
    }
}

// MARK: - Goals Detail View
struct GoalsDetailView: View {
    @Bindable var profile: UserProfile
    @State private var showEditSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Current Stats
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    HStack {
                        Text("Daily Targets")
                            .font(AppTheme.Typography.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button {
                            showEditSheet = true
                        } label: {
                            Text("Edit")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(AppTheme.Colors.accent)
                        }
                    }
                    
                    // Calories Card with Icon
                    HStack(spacing: 16) {
                        Image(systemName: AppTheme.Icons.calories)
                            .font(.title)
                            .foregroundStyle(AppTheme.Colors.calories)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Daily Calories")
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.labelSecondary)
                            
                            Text("\(profile.dailyCalories) kcal")
                                .font(AppTheme.Typography.title2)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(AppTheme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                    
                    // Macros Grid with Icons
                    HStack(spacing: AppTheme.Spacing.md) {
                        MacroDetailCard(
                            icon: AppTheme.Icons.protein,
                            title: "Protein",
                            value: profile.proteinGrams,
                            color: AppTheme.Colors.protein
                        )
                        
                        MacroDetailCard(
                            icon: AppTheme.Icons.carbs,
                            title: "Carbs",
                            value: profile.carbsGrams,
                            color: AppTheme.Colors.carbs
                        )
                        
                        MacroDetailCard(
                            icon: AppTheme.Icons.fat,
                            title: "Fat",
                            value: profile.fatGrams,
                            color: AppTheme.Colors.fat
                        )
                    }
                }
                
                // Current Profile
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    Text("Your Profile")
                        .font(AppTheme.Typography.title2)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 0) {
                        ProfileRow(icon: "target", label: "Goal", value: profile.goalType.rawValue)
                        Divider().padding(.leading, 56)
                        ProfileRow(icon: "figure.run", label: "Activity", value: profile.activityLevel.rawValue)
                        Divider().padding(.leading, 56)
                        ProfileRow(icon: "leaf.fill", label: "Diet", value: profile.dietType.rawValue)
                        Divider().padding(.leading, 56)
                        ProfileRow(icon: "person.fill", label: "Age", value: "\(profile.age) years")
                        Divider().padding(.leading, 56)
                        ProfileRow(icon: "ruler", label: "Height", value: "\(Int(profile.heightCm)) cm")
                        Divider().padding(.leading, 56)
                        ProfileRow(icon: "scalemass", label: "Weight", value: String(format: "%.1f kg", profile.weightKg))
                    }
                    .padding()
                    .background(AppTheme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                }
            }
            .padding(AppTheme.Spacing.screenPadding)
        }
        .sheet(isPresented: $showEditSheet) {
            GoalsEditView(profile: profile)
        }
    }
}

// MARK: - Edit Goals View (FIXED: No text wrapping)
struct GoalsEditView: View {
    @Bindable var profile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    Picker("Sex", selection: $profile.sex) {
                        ForEach(UserProfile.Sex.allCases, id: \.self) { sex in
                            Label(sex.rawValue, systemImage: sex.icon).tag(sex)
                        }
                    }
                    
                    Stepper("Age: \(profile.age)", value: $profile.age, in: 15...100)
                    
                    HStack {
                        Text("Height")
                        Spacer()
                        Text("\(Int(profile.heightCm)) cm")
                            .foregroundStyle(AppTheme.Colors.labelSecondary)
                    }
                    Slider(value: $profile.heightCm, in: 120...220, step: 1)
                        .tint(AppTheme.Colors.accent)
                    
                    HStack {
                        Text("Weight")
                        Spacer()
                        Text(String(format: "%.1f kg", profile.weightKg))
                            .foregroundStyle(AppTheme.Colors.labelSecondary)
                    }
                    Slider(value: $profile.weightKg, in: 30...200, step: 0.5)
                        .tint(AppTheme.Colors.accent)
                }
                
                // FIXED: Shorter section header to prevent wrapping
                Section("Goals") {
                    Picker("Goal", selection: $profile.goalType) {
                        ForEach(UserProfile.GoalType.allCases, id: \.self) { goal in
                            Label(goal.rawValue, systemImage: goal.icon).tag(goal)
                        }
                    }
                    
                    Picker("Activity", selection: $profile.activityLevel) {
                        ForEach(UserProfile.ActivityLevel.allCases, id: \.self) { level in
                            Label(level.rawValue, systemImage: level.icon).tag(level)
                        }
                    }
                    
                    Picker("Diet", selection: $profile.dietType) {
                        ForEach(UserProfile.DietType.allCases, id: \.self) { diet in
                            Label(diet.rawValue, systemImage: diet.icon).tag(diet)
                        }
                    }
                }
                
                Section("Targets") {
                    HStack {
                        Image(systemName: AppTheme.Icons.calories)
                            .foregroundStyle(AppTheme.Colors.calories)
                        Text("Calories")
                        Spacer()
                        Text("\(profile.dailyCalories)")
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.Colors.calories)
                        Text("kcal")
                            .foregroundStyle(AppTheme.Colors.labelSecondary)
                    }
                    
                    HStack {
                        Image(systemName: AppTheme.Icons.protein)
                            .foregroundStyle(AppTheme.Colors.protein)
                        Text("Protein")
                        Spacer()
                        Text("\(profile.proteinGrams)")
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.Colors.protein)
                        Text("g")
                            .foregroundStyle(AppTheme.Colors.labelSecondary)
                    }
                    
                    HStack {
                        Image(systemName: AppTheme.Icons.carbs)
                            .foregroundStyle(AppTheme.Colors.carbs)
                        Text("Carbs")
                        Spacer()
                        Text("\(profile.carbsGrams)")
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.Colors.carbs)
                        Text("g")
                            .foregroundStyle(AppTheme.Colors.labelSecondary)
                    }
                    
                    HStack {
                        Image(systemName: AppTheme.Icons.fat)
                            .foregroundStyle(AppTheme.Colors.fat)
                        Text("Fat")
                        Spacer()
                        Text("\(profile.fatGrams)")
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.Colors.fat)
                        Text("g")
                            .foregroundStyle(AppTheme.Colors.labelSecondary)
                    }
                }
            }
            .navigationTitle("Edit Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        profile.calculateMacros()
                        profile.syncToAppStorage()
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct SelectionCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.labelSecondary)
                
                Text(title)
                    .font(AppTheme.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(AppTheme.Colors.labelPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(isSelected ? AppTheme.Colors.accent.opacity(0.15) : AppTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.subtleStroke, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ActivityLevelCard: View {
    let level: UserProfile.ActivityLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: level.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.labelSecondary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.rawValue)
                        .font(AppTheme.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                    
                    Text(level.description)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.labelSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.Colors.accent)
                }
            }
            .padding()
            .background(isSelected ? AppTheme.Colors.accent.opacity(0.15) : AppTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.subtleStroke, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct GoalCard: View {
    let goal: UserProfile.GoalType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: goal.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.labelSecondary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.rawValue)
                        .font(AppTheme.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                    
                    Text(goal.description)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.labelSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.Colors.accent)
                }
            }
            .padding()
            .background(isSelected ? AppTheme.Colors.accent.opacity(0.15) : AppTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.subtleStroke, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct DietTypeCard: View {
    let diet: UserProfile.DietType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: diet.icon)
                        .font(.title2)
                        .foregroundStyle(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.labelSecondary)
                        .frame(width: 32)
                    
                    Text(diet.rawValue)
                        .font(AppTheme.Typography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.Colors.labelPrimary)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.Colors.accent)
                    }
                }
                
                // Macro breakdown with icons
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: AppTheme.Icons.protein)
                            .font(.caption2)
                            .foregroundStyle(AppTheme.Colors.protein)
                        Text(String(format: "%.0f%%", diet.macroRatio.protein * 100))
                            .font(AppTheme.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.Colors.protein)
                    }
                    
                    Text("•")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.labelTertiary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: AppTheme.Icons.carbs)
                            .font(.caption2)
                            .foregroundStyle(AppTheme.Colors.carbs)
                        Text(String(format: "%.0f%%", diet.macroRatio.carbs * 100))
                            .font(AppTheme.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.Colors.carbs)
                    }
                    
                    Text("•")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.labelTertiary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: AppTheme.Icons.fat)
                            .font(.caption2)
                            .foregroundStyle(AppTheme.Colors.fat)
                        Text(String(format: "%.0f%%", diet.macroRatio.fat * 100))
                            .font(AppTheme.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.Colors.fat)
                    }
                }
                .padding(.leading, 44)
            }
            .padding()
            .background(isSelected ? AppTheme.Colors.accent.opacity(0.15) : AppTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.subtleStroke, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct MacroSummaryCard: View {
    let icon: String
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text("\(value)g")
                .font(AppTheme.Typography.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.labelSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
    }
}

struct MacroDetailCard: View {
    let icon: String
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text("\(value)g")
                .font(AppTheme.Typography.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.labelSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
    }
}

struct SummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.labelSecondary)
            
            Spacer()
            
            Text(value)
                .font(AppTheme.Typography.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.Colors.labelPrimary)
        }
        .padding(.vertical, 8)
    }
}

struct ProfileRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(AppTheme.Colors.accent)
                .frame(width: 24)
            
            Text(label)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.labelSecondary)
            
            Spacer()
            
            Text(value)
                .font(AppTheme.Typography.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.Colors.labelPrimary)
        }
        .padding(.vertical, 8)
    }
}

#Preview("Empty State") {
    GoalsView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}

#Preview("With Profile") {
    let container = try! ModelContainer(for: UserProfile.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let profile = UserProfile()
    profile.isOnboardingComplete = true
    profile.age = 28
    profile.sex = .male
    profile.heightCm = 178
    profile.weightKg = 75
    profile.goalType = .muscleGain
    profile.activityLevel = .veryActive
    profile.dietType = .highProtein
    profile.calculateMacros()
    container.mainContext.insert(profile)
    
    return GoalsView()
        .modelContainer(container)
}
