import DesignSystem
import SwiftUI

struct MapEditorRequirementSection: View {
    let viewModel: MapEditorViewModel

    var body: some View {
        IMDFInspectorSection(title: MapEditorText.requirements) {
            if state.contract.requiresCategory {
                IMDFInspectorRow(MapEditorText.category) {
                    Picker(MapEditorText.category, selection: categoryBinding) {
                        ForEach(MapEditorCategoryOptions.options(for: state.selectedFeature), id: \.self) { value in
                            Text(value).tag(value)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            }

            if state.contract.requiredReferences.isEmpty {
                IMDFInspectorRow(MapEditorText.references, value: MapEditorText.none)
                    .systemImage(MapEditorSymbol.readyFilled)
            } else {
                IMDFInspectorActionRow(MapEditorText.references) {
                    state.satisfyRequiredReferences()
                }
                .value(
                    state.missingReferences.isEmpty
                        ? MapEditorText.linked
                        : MapEditorText.referenceList(state.missingReferences.map(\.title))
                )
                .complete(state.missingReferences.isEmpty)
            }
        }
    }

    private var state: FeatureAuthoringToolState {
        viewModel.authoringState
    }

    private var categoryBinding: Binding<String> {
        Binding(
            get: {
                state.selectedCategoryValue
                    ?? MapEditorCategoryOptions.options(for: state.selectedFeature).first
                    ?? ""
            },
            set: { state.selectCategory($0) }
        )
    }
}
