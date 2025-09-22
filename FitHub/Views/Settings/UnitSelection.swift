import SwiftUI

struct UnitSelection: View {
    @ObservedObject var userData: UserData
    @AppStorage(UnitSystem.storageKey) private var unit: UnitSystem = .metric
    @State private var showRestartNotice = false
    @State private var initialUnit: UnitSystem = .metric

    var body: some View {
        VStack {
            // Content lives under the pinned header
            descriptionCard
                .padding(.vertical)

            if showRestartNotice {
                restartBanner
                    .padding(.vertical)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

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
        .navigationBarBackButtonHidden(showRestartNotice)
        .animation(.spring(response: 0.28, dampingFraction: 0.9), value: showRestartNotice)
        .onAppear { initialUnit = unit }
    }

    // MARK: - Views

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Unit of Measurement")
                .font(.headline)
                .foregroundStyle(.secondary)

            Picker("", selection: $unit) {
                ForEach(UnitSystem.allCases, id: \.self) { u in
                    Text(u.displayName).tag(u)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: unit) { _, new in
                let changed = new != initialUnit
                showRestartNotice = changed
                userData.disableTabView = changed
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private var descriptionCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "scalemass")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(unit.displayName)
                    .font(.headline)
                Text("\(unit.weightUnit) / \(unit.sizeUnit) • \(unit.lengthUnit)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(unit.desc)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }

    private var restartBanner: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.white)
                    .font(.title3.bold())
                Text("Restart Required")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
            }

            Text("Please restart the app to apply unit changes. Navigation has been temporarily disabled.")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.leading)

            HStack {
                Spacer()
                Button(role: .destructive) {
                    exit(0)
                } label: {
                    Label("Close App", systemImage: "power")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.15))
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.red.gradient)
        )
    }
}
