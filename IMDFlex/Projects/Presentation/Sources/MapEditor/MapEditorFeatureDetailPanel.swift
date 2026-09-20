import DesignSystem
import SwiftUI

struct MapEditorFeatureDetailPanel: View {
    let viewModel: MapEditorViewModel

    var body: some View {
        IMDFPanel {
            VStack(alignment: .leading, spacing: IMDFSpacing.lg) {
                if let shape = viewModel.selectedShape {
                    IMDFInspectorSection(title: shape.feature.title) {
                        IMDFInspectorRow(MapEditorText.geometry, value: shape.feature.contract.geometry.title)
                            .systemImage(shape.feature.systemImage)

                        if MapEditorFeatureEditor.supportsNameField(shape.feature) {
                            IMDFInspectorRow(MapEditorText.name) {
                                TextField(MapEditorText.namePlaceholder, text: nameBinding)
                                    .multilineTextAlignment(.trailing)
                            }
                        }

                        if shape.feature.contract.requiresCategory {
                            IMDFInspectorRow(MapEditorText.category) {
                                Picker(MapEditorText.category, selection: categoryBinding(for: shape.feature)) {
                                    ForEach(MapEditorCategoryOptions.options(for: shape.feature), id: \.self) { value in
                                        Text(value).tag(value)
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                            }
                        }
                    }

                    if hasEditableFields(for: shape.feature) {
                        IMDFToolButton(MapEditorText.save, systemImage: MapEditorSymbol.finish) {
                            Task { await viewModel.saveSelectedFeatureEdits() }
                        }
                        .role(.primary)
                        .disabled(!viewModel.canSaveSelectedFeatureEdits)
                    } else {
                        Text(MapEditorText.nothingToEdit)
                            .font(IMDFFont.inspectorLabel)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text(MapEditorText.nothingToEdit)
                        .font(IMDFFont.inspectorLabel)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .imdfPanelStyle(.inspector)
    }

    private func hasEditableFields(for feature: IMDFAuthoringFeature) -> Bool {
        MapEditorFeatureEditor.supportsNameField(feature) || feature.contract.requiresCategory
    }

    private var nameBinding: Binding<String> {
        Binding(get: { viewModel.editingName }, set: { viewModel.setEditingName($0) })
    }

    private func categoryBinding(for feature: IMDFAuthoringFeature) -> Binding<String> {
        Binding(
            get: {
                viewModel.editingCategoryValue
                    ?? MapEditorCategoryOptions.options(for: feature).first
                    ?? ""
            },
            set: { viewModel.selectEditingCategory($0) }
        )
    }
}
