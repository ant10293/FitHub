import SwiftUI

struct UnitSelection: View {
    @EnvironmentObject private var ctx: AppContext

    var body: some View {
        VStack {
            // Content lives under the pinned header
            descriptionCard
                .padding(.vertical)

            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .safeAreaInset(edge: .top) {
            header
                .background(.ultraThinMaterial)
                .overlay(Divider(), alignment: .bottom)
                .padding(.bottom)
        }
        .navigationBarTitle("Unit Selection", displayMode: .inline)
    }

    // MARK: - Views

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Unit of Measurement")
                .font(.headline)
                .foregroundStyle(.secondary)

            Picker("", selection: $ctx.unitSystem) {
                ForEach(UnitSystem.allCases, id: \.self) { u in
                    Text(u.displayName).tag(u)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private var descriptionCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "scalemass")
                .imageScale(.large)
                .fontWeight(.semibold)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(ctx.unitSystem.displayName)
                    .font(.headline)
                Text("\(ctx.unitSystem.weightUnit) / \(ctx.unitSystem.sizeUnit) • \(ctx.unitSystem.lengthUnit)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(ctx.unitSystem.desc)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .cardContainer(cornerRadius: 12, backgroundColor: Color(UIColor.secondarySystemBackground))
    }
}
