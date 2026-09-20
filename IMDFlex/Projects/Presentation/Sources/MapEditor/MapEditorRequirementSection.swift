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
                ForEach(state.contract.requiredReferences, id: \.self) { reference in
                    referencePicker(for: reference)
                }
            }
        }
    }

    private func referencePicker(for reference: IMDFAuthoringReference) -> some View {
        let options = IMDFAuthoringReferenceCatalog.options(
            for: reference,
            in: viewModel.project.venue,
            excluding: excludedEndpointID(for: reference)
        )

        return IMDFInspectorRow(reference.title) {
            Picker(reference.title, selection: selectionBinding(for: reference)) {
                Text(MapEditorText.selectReference).tag(UUID?.none)
                ForEach(options) { option in
                    Text("\(option.title) · \(option.context)")
                        .tag(UUID?.some(option.id))
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
        .systemImage(
            state.selectedReferenceID(for: reference) == nil
                ? MapEditorSymbol.draft
                : MapEditorSymbol.readyFilled
        )
    }

    private func selectionBinding(for reference: IMDFAuthoringReference) -> Binding<UUID?> {
        Binding(
            get: { state.selectedReferenceID(for: reference) },
            set: { id in
                if let id {
                    state.selectReference(id, for: reference)
                } else {
                    state.clearReference(reference)
                }
            }
        )
    }

    private func excludedEndpointID(for reference: IMDFAuthoringReference) -> UUID? {
        switch reference {
        case .relationshipDestination:
            state.selectedReferenceID(for: .relationshipOrigin)
        default:
            nil
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
