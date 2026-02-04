import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("weightUnit") private var weightUnit: String = WeightUnit.lb.rawValue
    @AppStorage("defaultRestCompound") private var defaultRestCompound: Int = 90
    @AppStorage("defaultRestIsolation") private var defaultRestIsolation: Int = 60
    @AppStorage("healthKitEnabled") private var healthKitEnabled: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section("Equipment") {
                    NavigationLink {
                        EquipmentListView()
                    } label: {
                        Label("Equipment Inventory", systemImage: "dumbbell.fill")
                    }

                    NavigationLink {
                        PlateCalculatorView()
                    } label: {
                        Label("Plate Calculator", systemImage: "scalemass.fill")
                    }
                }

                Section("Units") {
                    Picker("Weight Unit", selection: $weightUnit) {
                        Text("Pounds (lb)").tag(WeightUnit.lb.rawValue)
                        Text("Kilograms (kg)").tag(WeightUnit.kg.rawValue)
                    }
                }

                Section("Rest Timer Defaults") {
                    Stepper("Compound: \(defaultRestCompound)s", value: $defaultRestCompound, in: 30...300, step: 15)
                    Stepper("Isolation: \(defaultRestIsolation)s", value: $defaultRestIsolation, in: 15...180, step: 15)
                }

                Section("Integrations") {
                    Toggle("HealthKit Integration", isOn: $healthKitEnabled)
                        .onChange(of: healthKitEnabled) { _, newValue in
                            if newValue {
                                Task {
                                    try? await HealthKitService.shared.requestAuthorization()
                                }
                            }
                        }
                }

                Section("Data") {
                    NavigationLink {
                        Text("Import/Export coming soon")
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
