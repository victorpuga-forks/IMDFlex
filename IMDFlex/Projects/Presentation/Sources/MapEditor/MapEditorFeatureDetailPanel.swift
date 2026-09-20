import DesignSystem
import Domain
import SwiftUI

struct MapEditorFeatureDetailPanel: View {
    let viewModel: MapEditorViewModel

    @State private var isAdvancedExpanded = false

    var body: some View {
        IMDFPanel {
            ScrollView {
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

                            if shape.feature.contract.requiresShortName {
                                IMDFInspectorRow(MapEditorText.shortName) {
                                    TextField(MapEditorText.shortNamePlaceholder, text: shortNameBinding)
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

                        if viewModel.canEditSelectedFeatureGeometry {
                            geometrySection
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
        }
        .imdfPanelStyle(.inspector)
    }

    private var geometrySection: some View {
        VStack(alignment: .leading, spacing: IMDFSpacing.md) {
            DisclosureGroup(MapEditorText.advanced, isExpanded: $isAdvancedExpanded) {
                IMDFInspectorSection(title: MapEditorText.points) {
                    ForEach(Array(viewModel.editingCoordinates.enumerated()), id: \.offset) { index, item in
                        reorderRow(number: index + 1, index: index, coordinate: item)
                    }

                    IMDFToolButton(
                        viewModel.isAddingGeometryPoint ? MapEditorText.addingPoint : MapEditorText.addPoint,
                        systemImage: MapEditorSymbol.addPoint
                    ) {
                        viewModel.setAddingGeometryPoint(!viewModel.isAddingGeometryPoint)
                    }
                    .selected(viewModel.isAddingGeometryPoint)
                }
                .padding(.top, IMDFSpacing.sm)
            }
        }
    }

    private func reorderRow(number: Int, index: Int, coordinate: Coordinate) -> some View {
        HStack {
            Text(MapEditorText.point(number: number))
                .font(IMDFFont.inspectorLabel)
                .foregroundStyle(.secondary)
          
            Text(coordinateText(coordinate))
              .font(IMDFFont.inspectorValue)
              .foregroundStyle(.primary)

            Spacer()

            IMDFToolButton(MapEditorText.moveUp, systemImage: MapEditorSymbol.moveUp) {
                viewModel.moveGeometryPointUp(at: index)
            }
            .disabled(index == 0)

            IMDFToolButton(MapEditorText.moveDown, systemImage: MapEditorSymbol.moveDown) {
                viewModel.moveGeometryPointDown(at: index)
            }
            .disabled(index == viewModel.editingCoordinates.count - 1)

          if let shape = viewModel.selectedShape {
            IMDFToolButton(MapEditorText.removePoint, systemImage: MapEditorSymbol.remove) {
              viewModel.removeGeometryPoint(at: index)
            }
            .role(.destructive)
            .disabled(viewModel.editingCoordinates.count <= shape.feature.contract.geometry.minimumPointCount)
          }
        }
    }

    private func hasEditableFields(for feature: IMDFAuthoringFeature) -> Bool {
        MapEditorFeatureEditor.supportsNameField(feature)
            || feature.contract.requiresCategory
            || viewModel.canEditSelectedFeatureGeometry
    }

    private func coordinateText(_ coordinate: Coordinate) -> String {
        let latitude = coordinate.latitude.formatted(.number.precision(.fractionLength(5)))
        let longitude = coordinate.longitude.formatted(.number.precision(.fractionLength(5)))
        return "\(latitude), \(longitude)"
    }

    private var nameBinding: Binding<String> {
        Binding(get: { viewModel.editingName }, set: { viewModel.setEditingName($0) })
    }

    private var shortNameBinding: Binding<String> {
        Binding(get: { viewModel.editingShortName }, set: { viewModel.setEditingShortName($0) })
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
