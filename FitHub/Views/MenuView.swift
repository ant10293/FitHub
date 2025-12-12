import SwiftUI


struct MenuView: View {
    @EnvironmentObject private var ctx: AppContext

    var body: some View {
        List {
            Section(header: Text("Logging")) {
                NavigationLink(destination: LazyDestination {
                    ExerciseView()
                }) {
                    Label("Exercise Library", systemImage: "list.bullet.rectangle")
                }

                NavigationLink(destination: LazyDestination {
                    MeasurementsView(userData: ctx.userData)
                }) {
                    Label("Measurements", systemImage: "ruler")
                }
                NavigationLink(destination: LazyDestination {
                    TemplateArchives(userData: ctx.userData)
                }) {
                    Label("Archived Templates", systemImage: "archivebox")
                }
            }

            Section(header: Text("Setup")) {
                NavigationLink(destination: LazyDestination {
                    EquipmentManagement()
                }) {
                    Label("Your Equipment", systemImage: "dumbbell")
                }

                NavigationLink(destination: LazyDestination {
                    StatsView(userData: ctx.userData)
                }) {
                    Label("Statistics", systemImage: "chart.bar")
                }

                NavigationLink(destination: LazyDestination {
                    GoalSelectionView(userData: ctx.userData)
                }) {
                    Label("Modify Goal", systemImage: "target")
                }
            }

            Section(header: Text("Premium")) {
                NavigationLink(destination: LazyDestination {
                    SubscriptionView()
                }) {
                    Label("FitHub Pro", systemImage: "crown")
                }
            }

            // MARK: Affiliate System guard
            if useAffiliateSystem {
                Section(header: Text("Partner")) {
                    NavigationLink(destination: LazyDestination {
                        AffiliateRegistrationView()
                    }) {
                        Label("Become an Affiliate", systemImage: "person.2")
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Menu")
    }
}
