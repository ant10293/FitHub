import SwiftUI


struct MenuView: View {
    @EnvironmentObject private var ctx: AppContext

    var body: some View {
        List {
            Section(header: Text("Editing")) {
                NavigationLink(destination: LazyDestination {
                    ExerciseView(savedSortOption: ctx.userData.sessionTracking.exerciseSortOption)
                }) {
                    Label("Exercise Library", systemImage: "list.bullet.rectangle")
                }
                
                NavigationLink(destination: LazyDestination {
                    EquipmentManagement()
                }) {
                    Label("Your Equipment", systemImage: "dumbbell")
                }

                NavigationLink(destination: LazyDestination {
                    TemplateArchives(userData: ctx.userData)
                }) {
                    Label("Archived Templates", systemImage: "archivebox")
                }
            }

            Section(header: Text("Tracking")) {
                NavigationLink(destination: LazyDestination {
                    MeasurementsView(userData: ctx.userData)
                }) {
                    Label("Measurements", systemImage: "ruler")
                }

                NavigationLink(destination: LazyDestination {
                    StatsView(userData: ctx.userData)
                }) {
                    Label("Statistics", systemImage: "chart.bar")
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
