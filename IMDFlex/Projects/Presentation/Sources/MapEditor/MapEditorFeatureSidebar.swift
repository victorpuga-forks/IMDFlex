import DesignSystem
import SwiftUI

struct MapEditorFeatureSidebar: View {
    let viewModel: MapEditorViewModel

    var body: some View {
        IMDFPanel {
            VStack(alignment: .leading, spacing: IMDFSpacing.lg) {
                Text(MapEditorText.sidebarTitle)
                    .font(IMDFFont.panelTitle)

                if groupedShapes.isEmpty {
                    Text(MapEditorText.sidebarEmpty)
                        .font(IMDFFont.inspectorLabel)
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: IMDFSpacing.lg) {
                            ForEach(groupedShapes, id: \.feature) { group in
                                IMDFInspectorSection(title: group.feature.title) {
                                    ForEach(group.shapes) { shape in
                                        row(for: shape)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .imdfPanelStyle(.inspector)
    }

    private var groupedShapes: [(feature: IMDFAuthoringFeature, shapes: [MapEditorFeatureShape])] {
        IMDFAuthoringFeature.allCases.compactMap { feature in
            let shapes = viewModel.featureShapes.filter { $0.feature == feature }
            return shapes.isEmpty ? nil : (feature, shapes)
        }
    }

    private func row(for shape: MapEditorFeatureShape) -> some View {
        let isSelected = shape.id == viewModel.selectedShapeID

        return Button {
            viewModel.select(id: shape.id)
        } label: {
            HStack {
                Text(shape.title ?? shape.feature.title)
                    .foregroundStyle(.primary)
                Spacer(minLength: IMDFSpacing.sm)
                if isSelected {
                    Image(systemName: MapEditorSymbol.readyFilled)
                        .foregroundStyle(IMDFColor.accent)
                }
            }
            .padding(.horizontal, IMDFSpacing.sm)
            .padding(.vertical, IMDFSpacing.xs)
            .frame(minHeight: IMDFControlMetrics.statusHeight)
            .background(isSelected ? IMDFColor.selectedFill : .clear)
            .clipShape(.rect(cornerRadius: IMDFRadius.control))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .font(IMDFFont.inspectorLabel)
    }
}
