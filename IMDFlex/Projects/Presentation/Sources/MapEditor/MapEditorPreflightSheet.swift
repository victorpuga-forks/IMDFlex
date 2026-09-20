import DesignSystem
import Domain
import SwiftUI

struct MapEditorPreflightSheet: View {
    let viewModel: MapEditorViewModel
    let onExport: () -> Void

    var body: some View {
        NavigationStack {
            List {
                if viewModel.preflightIssues.isEmpty {
                    ContentUnavailableView(MapEditorText.preflightAllClear, systemImage: MapEditorSymbol.readyFilled)
                } else {
                    ForEach(viewModel.preflightIssues) { issue in
                        row(for: issue)
                    }
                }

                Section {
                    Text(MapEditorText.preflightValidatorHint)
                        .font(IMDFFont.supporting)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(MapEditorText.preflightTitle)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .safeAreaInset(edge: .bottom) {
                if viewModel.hasBlockingPreflightIssues {
                    Text(MapEditorText.preflightBlockedMessage)
                        .font(IMDFFont.supporting)
                        .foregroundStyle(IMDFColor.danger)
                        .padding(IMDFSpacing.md)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(MapEditorText.preflightClose) {
                        viewModel.dismissPreflightSheet()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(MapEditorText.preflightExport, action: onExport)
                        .disabled(viewModel.hasBlockingPreflightIssues)
                }
            }
        }
    }

    private func row(for issue: IMDFPreflightIssue) -> some View {
        let jumpTargetID = issue.featureID.flatMap { id in
            viewModel.featureShapes.contains(where: { $0.id == id }) ? id : nil
        }

        return Group {
            if let jumpTargetID {
                Button {
                    viewModel.setMode(.view)
                    viewModel.select(id: jumpTargetID)
                    viewModel.dismissPreflightSheet()
                } label: {
                    rowContent(for: issue)
                }
                .buttonStyle(.plain)
            } else {
                rowContent(for: issue)
            }
        }
    }

    private func rowContent(for issue: IMDFPreflightIssue) -> some View {
        VStack(alignment: .leading, spacing: IMDFSpacing.xs) {
            HStack {
                Label(issue.feature.title, systemImage: issue.feature.systemImage)
                    .font(IMDFFont.inspectorLabel)

                Spacer()

                IMDFStatusBadge(issue.severity.title)
                    .status(issue.severity.badgeRole)
            }

            Text(issue.message)
                .font(IMDFFont.supporting)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, IMDFSpacing.xs)
    }
}
