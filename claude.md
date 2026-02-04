# Gym App — Project Specification

## Project Overview

A native iOS weightlifting and gym tracking app built with **SwiftUI** and **Swift Data**. Inspired by apps like StrongLifts 5×5 and Gravl, the goal is to provide a streamlined workout experience with smart features: automatic progressive overload, a plate calculator that uses the lifter's actual plate inventory, and a local rule-based program generator that recommends routines based on a questionnaire — no external API calls required.

Target: iOS 17+, iPhone-first (iPad layout is a stretch goal).

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI |
| Persistence | Swift Data (`@Model`, `ModelContainer`, `ModelContext`) |
| Charts | Swift Charts |
| Health | HealthKit (optional — log workouts to Apple Health) |
| Notifications | Local notifications for rest timer alerts |
| Architecture | MVVM — Views observe Swift Data models directly; ViewModels used where non-trivial logic is needed |

No server, no external AI API. All logic runs on-device.

---

## Core Features

### 1. Equipment & Plate Inventory

Users configure the equipment they have access to. This inventory feeds the plate calculator and the program generator.

- **Barbells**: name, weight (e.g., Olympic 45 lb, EZ-curl 25 lb)
- **Dumbbells**: available weight set (e.g., 5–75 lb in 5 lb increments, or individual pairs)
- **Plates**: quantity per weight denomination (e.g., 4× 45 lb, 2× 25 lb, 2× 10 lb, 4× 5 lb, 2× 2.5 lb)
- **Machines**: name, weight stack range, increment size
- **Cable attachments**: list of available handles (rope, straight bar, V-bar, etc.)

### 2. Routine Management

- Create custom routines (name, ordered list of exercises with target sets/reps/RPE)
- Browse and select from built-in templates (Starting Strength, 5/3/1, PPL, Upper/Lower, etc.)
- Edit any routine — reorder exercises, swap exercises, adjust set/rep schemes
- Import/export routines as JSON for sharing

### 3. Program Generator (Rule Engine)

A local rule-based engine that maps questionnaire answers to program templates. No external API dependency.

**Questionnaire inputs:**
- Primary goal: strength, hypertrophy, general fitness, powerlifting, athletic performance
- Training experience: beginner (< 1 year), intermediate (1–3 years), advanced (3+ years)
- Available days per week: 2–6
- Available equipment (pulled from inventory)
- Session time limit (30, 45, 60, 75, 90 minutes)
- Injuries or movements to avoid (optional)

**Rule engine logic:**
1. Filter program templates by experience level and goal
2. Filter by days/week compatibility
3. Score remaining templates against available equipment (penalize programs requiring unavailable equipment)
4. Rank by fit and present the top 2–3 recommendations with rationale
5. User selects one; the engine generates the concrete routine with exercises, sets, reps, and starting weights

Templates are defined as structured data (JSON or Swift structs), not hard-coded logic. Adding a new template should not require changing engine code.

### 4. Workout Session UI

The active workout screen is the core experience. Design for one-handed use between sets.

- **Current exercise** displayed prominently with target sets × reps × weight
- **Set logging**: tap to mark a set complete, enter actual reps if different from target
- **Weight input**: quick +/− buttons with configurable increment, or type a value
- **Rest timer**: starts automatically after completing a set, configurable per exercise (default: 90s for compounds, 60s for isolation), with local notification when time is up
- **Plate calculator**: inline display showing exact plates to load per side for the current weight
- **Exercise notes**: view/edit notes for the current exercise
- **Reorder / skip / add exercises** mid-workout
- **Swipe between exercises** or use a list view to jump

### 5. Progressive Overload Engine

Automatic weight progression is central to the app.

- Each exercise has a **ProgressionRule** (configurable per exercise):
  - Increment amount (e.g., 5 lb for squat, 2.5 lb for OHP)
  - Trigger: all prescribed sets completed at target reps
  - Deload logic on repeated failure (see section below)
- After a successful session, the app automatically updates the target weight for the next session
- Users can override any automatic change

### 6. Plate Calculator

Given a target barbell weight and the user's plate inventory, compute the exact plates to load on each side.

**Algorithm** (greedy, largest-first):
1. Subtract barbell weight from target weight
2. Divide remaining weight by 2 (per-side weight)
3. From largest plate to smallest, add as many of that plate as possible without exceeding per-side target (limited by inventory — each plate used here reduces available count by 2, one per side)
4. If exact match is not achievable, show the closest achievable weight and the difference

Display: visual representation of plates on bar (colored rectangles scaled by plate diameter).

---

## Data Models

All models use `@Model` (Swift Data).

### Equipment

```swift
@Model class Barbell {
    var name: String          // "Olympic Barbell"
    var weight: Double        // 45.0
    var unit: WeightUnit      // .lb or .kg
    var isDefault: Bool       // mark one as default
}

@Model class DumbbellSet {
    var availableWeights: [Double]  // [5, 10, 15, ..., 75]
    var unit: WeightUnit
}

@Model class Plate {
    var weight: Double        // 45.0
    var unit: WeightUnit
    var count: Int            // total count owned (must be even for barbell use)
    var color: String         // for plate calculator visualization
}

@Model class Machine {
    var name: String          // "Lat Pulldown"
    var minWeight: Double
    var maxWeight: Double
    var increment: Double     // weight stack increment
    var unit: WeightUnit
}

@Model class CableAttachment {
    var name: String          // "Rope", "Straight Bar"
}
```

### Exercise

```swift
@Model class Exercise {
    var name: String
    var category: ExerciseCategory    // .compound, .isolation, .cardio
    var muscleGroups: [MuscleGroup]   // [.chest, .triceps]
    var equipmentType: EquipmentType  // .barbell, .dumbbell, .machine, .bodyweight, .cable
    var notes: String
    var isCustom: Bool                // user-created vs built-in
}
```

### Routine

```swift
@Model class Routine {
    var name: String
    var routineExercises: [RoutineExercise]  // ordered
    var isTemplate: Bool       // built-in template vs user-created
    var source: String?        // "Starting Strength", "Custom", etc.
}

@Model class RoutineExercise {
    var exercise: Exercise
    var order: Int
    var targetSets: Int
    var targetReps: Int        // or rep range string "8-12"
    var targetRPE: Double?
    var restSeconds: Int       // rest between sets
    var progressionRule: ProgressionRule?
}
```

### Workout Session & Logging

```swift
@Model class WorkoutSession {
    var routine: Routine?
    var startTime: Date
    var endTime: Date?
    var setLogs: [SetLog]
    var notes: String
    var isCompleted: Bool
}

@Model class SetLog {
    var exercise: Exercise
    var setNumber: Int
    var targetWeight: Double
    var actualWeight: Double
    var targetReps: Int
    var actualReps: Int
    var unit: WeightUnit
    var isWarmup: Bool
    var timestamp: Date
    var rpe: Double?
}
```

### Progression Rule

```swift
@Model class ProgressionRule {
    var exercise: Exercise
    var incrementAmount: Double    // 5.0
    var unit: WeightUnit
    var triggerType: ProgressionTrigger  // .allSetsCompleted, .topSetHit
    var consecutiveFailures: Int   // current failure streak count
    var deloadPercentage: Double   // e.g., 0.10 for 10% deload
    var deloadAfterFailures: Int   // trigger deload after N consecutive failures (default: 3)
}
```

### Enums

```swift
enum WeightUnit: String, Codable { case lb, kg }
enum ExerciseCategory: String, Codable { case compound, isolation, cardio }
enum MuscleGroup: String, Codable { case chest, back, shoulders, biceps, triceps, quads, hamstrings, glutes, calves, abs, forearms }
enum EquipmentType: String, Codable { case barbell, dumbbell, machine, cable, bodyweight, other }
enum ProgressionTrigger: String, Codable { case allSetsCompleted, topSetHit }
```

---

## Screen Architecture

Tab-based navigation with five tabs:

### Tab 1 — Dashboard
- Next scheduled workout summary
- Recent workout history (last 3–5)
- Weekly volume/frequency stats (Swift Charts)
- Quick-start button for next routine

### Tab 2 — Routines
- List of user routines and templates
- Create / edit / delete routines
- Access program generator questionnaire
- Import/export options

### Tab 3 — Workout (Active)
- Only active during a workout session
- Current exercise with set/rep/weight targets
- Set completion logging
- Rest timer with notification
- Inline plate calculator
- Badge on tab when workout is in progress

### Tab 4 — History
- Calendar or list view of past workouts
- Drill into session details (exercises, sets, weights)
- Per-exercise progress charts over time (Swift Charts)
- Personal records tracking and display

### Tab 5 — Settings / Equipment
- Equipment inventory management (barbells, plates, dumbbells, machines, attachments)
- Weight unit preference (lb / kg)
- Default rest timer durations
- HealthKit integration toggle
- Data export (JSON backup)
- App appearance settings

---

## Progression & Deload Logic

### Successful Session
When all prescribed sets for an exercise are completed at or above target reps:
1. Mark exercise as "passed" for this session
2. Increase target weight by the exercise's configured increment for next session
3. Reset consecutive failure count to 0

### Failed Session
When the lifter fails to complete all prescribed reps on any working set:
1. Keep target weight the same for next session
2. Increment consecutive failure count by 1
3. If consecutive failures reach the deload threshold (default: 3):
   - Reduce target weight by deload percentage (default: 10%)
   - Reset consecutive failure count to 0
   - Log the deload event

### Configurable per exercise
- Increment amount (default: 5 lb barbell compound, 2.5 lb barbell isolation, 5 lb dumbbell)
- Deload percentage (default: 10%)
- Failures before deload (default: 3)
- Progression trigger type (all sets completed vs top set only)

---

## Plate Calculator Algorithm

```
function calculatePlates(targetWeight, barWeight, availablePlates) -> PlateResult:
    remainingPerSide = (targetWeight - barWeight) / 2
    if remainingPerSide < 0: return error

    platesToLoad = []
    tempInventory = copy(availablePlates)  // don't mutate real inventory

    // Sort plate denominations descending
    for plate in tempInventory.sortedByWeightDescending():
        while remainingPerSide >= plate.weight AND plate.availableCount >= 2:
            platesToLoad.append(plate.weight)
            remainingPerSide -= plate.weight
            plate.availableCount -= 2  // one per side

    if remainingPerSide == 0:
        return .exact(platesToLoad)
    else:
        achievableWeight = targetWeight - (remainingPerSide * 2)
        return .approximate(platesToLoad, achievable: achievableWeight, difference: remainingPerSide * 2)
```

The plate calculator is used in two places:
1. **Workout session UI** — automatically shown for the current exercise weight
2. **Standalone tool** — accessible from Settings/Equipment for ad-hoc calculations

---

## File / Folder Structure (Target)

```
gym_app/
├── GymApp.swift                    # @main App entry, ModelContainer setup
├── Models/
│   ├── Equipment.swift             # Barbell, Plate, DumbbellSet, Machine, CableAttachment
│   ├── Exercise.swift              # Exercise model + enums
│   ├── Routine.swift               # Routine, RoutineExercise
│   ├── WorkoutSession.swift        # WorkoutSession, SetLog
│   ├── ProgressionRule.swift       # ProgressionRule
│   └── Enums.swift                 # WeightUnit, MuscleGroup, etc.
├── Views/
│   ├── Dashboard/
│   ├── Routines/
│   ├── Workout/
│   ├── History/
│   └── Settings/
├── ViewModels/
│   ├── WorkoutViewModel.swift
│   ├── ProgressionEngine.swift
│   ├── PlateCalculator.swift
│   └── ProgramGenerator.swift      # Rule engine + questionnaire logic
├── Services/
│   ├── HealthKitService.swift
│   └── ImportExportService.swift
├── Resources/
│   ├── Templates/                  # Built-in program templates (JSON)
│   └── ExerciseLibrary.json        # Seed data for exercises
└── claude.md
```

---

## Development Notes

- **Swift Data** handles all persistence. No Core Data migration layer needed since this is a new project.
- **Program templates** are stored as JSON in the app bundle under `Resources/Templates/`. The rule engine loads and filters these at runtime.
- **HealthKit** integration is optional and gated behind a user toggle. Request permissions lazily, only when the user enables it.
- **Unit conversion**: store all weights in the user's preferred unit. Provide a conversion utility but do not dual-store.
- **Seed data**: on first launch, populate the exercise library from `ExerciseLibrary.json` and set default plate inventory (standard Olympic set).
