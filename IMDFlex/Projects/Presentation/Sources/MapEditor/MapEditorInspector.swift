import DesignSystem
import SwiftUI

struct MapEditorInspector: View {
    let viewModel: MapEditorViewModel

    var body: some View {
        IMDFPanel {
            VStack(alignment: .leading, spacing: IMDFSpacing.lg) {
                IMDFInspectorSection(title: state.selectedFeature.title) {
                    IMDFInspectorRow(
                        MapEditorText.geometry,
                        value: state.contract.geometry.title
                    )
                    .systemImage(state.contract.geometry.systemImage)

                    IMDFInspectorRow(MapEditorText.draftPoints) {
                        Text(
                            MapEditorText.draftProgress(
                                current: state.draftedPointCount,
                                required: state.contract.geometry.minimumPointCount
                            )
                        )
                    }
                    .systemImage(MapEditorSymbol.draftPoints)

                    if state.contract.requiresName {
                        IMDFInspectorRow(MapEditorText.name) {
                            TextField(MapEditorText.namePlaceholder, text: nameBinding)
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    if state.contract.requiresShortName {
                        IMDFInspectorRow(MapEditorText.shortName) {
                            TextField(MapEditorText.shortNamePlaceholder, text: shortNameBinding)
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    IMDFInspectorRow(
                        MapEditorText.saved,
                        value: "\(viewModel.savedCount(for: state.selectedFeature))"
                    )

                    IMDFInspectorRow(MapEditorText.status) {
                        IMDFStatusBadge(state.canFinish ? MapEditorText.ready : MapEditorText.draft)
                            .status(state.canFinish ? .success : .warning)
                            .statusIcon(state.canFinish ? MapEditorSymbol.readyFilled : MapEditorSymbol.draftFilled)
                    }
                    .systemImage(state.canFinish ? MapEditorSymbol.ready : MapEditorSymbol.draft)
                }

                MapEditorRequirementSection(viewModel: viewModel)
                MapEditorDraftControls(state: state) {
                    await viewModel.finishDraft()
                }
            }
        }
        .imdfPanelStyle(.inspector)
    }

    private var state: FeatureAuthoringToolState {
        viewModel.authoringState
    }

    private var nameBinding: Binding<String> {
        Binding(get: { state.name }, set: { state.setName($0) })
    }

    private var shortNameBinding: Binding<String> {
        Binding(get: { state.shortName }, set: { state.setShortName($0) })
    }
}
