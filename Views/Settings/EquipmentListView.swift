import SwiftUI
import SwiftData

struct EquipmentListView: View {
    @Query private var barbells: [Barbell]
    @Query private var plates: [Plate]
    @Query private var dumbbellSets: [DumbbellSet]
    @Query private var machines: [Machine]
    @Query private var cableAttachments: [CableAttachment]

    var body: some View {
        List {
            Section {
                NavigationLink {
                    BarbellListView()
                } label: {
                    HStack {
                        Label("Barbells", systemImage: "line.horizontal.3")
                        Spacer()
                        Text("\(barbells.count)")
                            .foregroundStyle(.secondary)
                    }
                }

                NavigationLink {
                    PlateInventoryView()
                } label: {
                    HStack {
                        Label("Plates", systemImage: "circle.fill")
                        Spacer()
                        Text("\(plates.count) types")
                            .foregroundStyle(.secondary)
                    }
                }

                NavigationLink {
                    DumbbellSetView()
                } label: {
                    HStack {
                        Label("Dumbbells", systemImage: "dumbbell")
                        Spacer()
                        Text("\(dumbbellSets.count) sets")
                            .foregroundStyle(.secondary)
                    }
                }

                NavigationLink {
                    MachineListView()
                } label: {
                    HStack {
                        Label("Machines", systemImage: "gearshape.2")
                        Spacer()
                        Text("\(machines.count)")
                            .foregroundStyle(.secondary)
                    }
                }

                NavigationLink {
                    CableAttachmentListView()
                } label: {
                    HStack {
                        Label("Cable Attachments", systemImage: "link")
                        Spacer()
                        Text("\(cableAttachments.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Equipment")
    }
}
