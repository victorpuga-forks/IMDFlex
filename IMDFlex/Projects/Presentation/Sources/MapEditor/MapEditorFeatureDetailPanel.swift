import DesignSystem
import Domain
import SwiftUI

struct MapEditorFeatureDetailPanel: View {
    let viewModel: MapEditorViewModel

    @State private var isAdvancedExpanded = false
    @State private var isDeleteConfirmationPresented = false

    private enum MetadataField: Hashable {
        case alternateName
        case accessibility
        case hours
        case phone
        case website
        case restriction
        case correlationID
    }

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

                            metadataFields(for: shape.feature)

                            if supportsReferenceEditing(shape.feature) {
                                referenceSection(for: shape.feature)
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

                        if shape.feature != .venue {
                            IMDFToolButton(MapEditorText.delete, systemImage: "trash") {
                                isDeleteConfirmationPresented = true
                            }
                            .role(.destructive)
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
        .confirmationDialog(
            deleteConfirmationTitle,
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(MapEditorText.delete, role: .destructive) {
                Task { await viewModel.deleteSelectedFeature() }
            }
            Button(MapEditorText.deleteCancel, role: .cancel) {}
        } message: {
            Text(MapEditorText.deleteFeatureMessage)
        }
    }

    private var deleteConfirmationTitle: String {
        guard let feature = viewModel.selectedShape?.feature else {
            return MapEditorText.deleteFeatureTitle
        }
        return "\(feature.title): \(MapEditorText.deleteFeatureTitle)"
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
            || !metadataFieldKinds(for: feature).isEmpty
            || viewModel.canEditSelectedFeatureGeometry
            || supportsReferenceEditing(feature)
    }

    @ViewBuilder
    private func metadataFields(for feature: IMDFAuthoringFeature) -> some View {
        let fields = metadataFieldKinds(for: feature)
        if !fields.isEmpty {
            IMDFInspectorSection(title: MapEditorText.advanced) {
                ForEach(fields, id: \.self) { field in
                    metadataRow(for: field)
                }
            }
        }
    }

    @ViewBuilder
    private func metadataRow(for field: MetadataField) -> some View {
        switch field {
        case .alternateName:
            textRow(MapEditorText.alternateName, text: alternateNameBinding)
        case .accessibility:
            textRow(MapEditorText.accessibility, text: accessibilityBinding)
        case .hours:
            textRow(MapEditorText.hours, text: hoursBinding)
        case .phone:
            textRow(MapEditorText.phone, text: phoneBinding)
        case .website:
            textRow(MapEditorText.website, text: websiteBinding)
        case .restriction:
            textRow(MapEditorText.restriction, text: restrictionBinding)
        case .correlationID:
            textRow(MapEditorText.correlationID, text: correlationIDBinding)
        }
    }

    private func textRow(_ title: String, text: Binding<String>) -> some View {
        IMDFInspectorRow(title) {
            TextField(title, text: text)
                .multilineTextAlignment(.trailing)
        }
    }

    private func metadataFieldKinds(for feature: IMDFAuthoringFeature) -> [MetadataField] {
        switch feature {
        case .venue:
            [.alternateName, .hours, .phone, .website, .restriction]
        case .building:
            [.alternateName, .restriction]
        case .level:
            [.alternateName, .restriction]
        case .unit:
            [.alternateName, .accessibility, .restriction]
        case .opening:
            [.alternateName, .accessibility]
        case .amenity:
            [.alternateName, .accessibility, .hours, .phone, .website, .correlationID]
        case .occupant:
            [.alternateName, .hours, .phone, .website, .restriction, .correlationID]
        default:
            []
        }
    }

    private func supportsReferenceEditing(_ feature: IMDFAuthoringFeature) -> Bool {
        switch feature {
        case .building, .level, .amenity, .occupant, .fixture, .kiosk, .relationship:
            true
        default:
            false
        }
    }

    @ViewBuilder
    private func referenceSection(for feature: IMDFAuthoringFeature) -> some View {
        IMDFInspectorSection(title: MapEditorText.references) {
            if feature == .occupant || feature == .fixture || feature == .kiosk {
                referencePicker(
                    title: MapEditorText.anchor,
                    selection: anchorBinding,
                    options: IMDFAuthoringReferenceCatalog.options(for: .anchor, in: viewModel.project.venue)
                )
            }

            if supportsAddressReference(feature) {
                referencePicker(
                    title: MapEditorText.address,
                    selection: addressBinding,
                    options: addressOptions
                )
            }

            if feature == .relationship {
                referencePicker(
                    title: MapEditorText.origin,
                    selection: originBinding,
                    options: IMDFAuthoringReferenceCatalog.options(
                        for: .relationshipOrigin,
                        in: viewModel.project.venue,
                        excluding: viewModel.selectedShape?.id
                    )
                )
                referencePicker(
                    title: MapEditorText.destination,
                    selection: destinationBinding,
                    options: IMDFAuthoringReferenceCatalog.options(
                        for: .relationshipDestination,
                        in: viewModel.project.venue,
                        excluding: viewModel.selectedShape?.id
                    )
                )
            }

        }
    }

    private var addressOptions: [IMDFAuthoringReferenceOption] {
        guard let address = viewModel.project.venue?.address else { return [] }
        return [
            IMDFAuthoringReferenceOption(
                id: address.id,
                feature: .address,
                title: address.address ?? MapEditorText.address,
                context: MapEditorText.address
            )
        ]
    }

    private func supportsAddressReference(_ feature: IMDFAuthoringFeature) -> Bool {
        [.building, .level, .amenity, .occupant].contains(feature)
    }

    private func referencePicker(
        title: String,
        selection: Binding<UUID?>,
        options: [IMDFAuthoringReferenceOption]
    ) -> some View {
        IMDFInspectorRow(title) {
            Picker(title, selection: selection) {
                Text(MapEditorText.none).tag(UUID?.none)
                ForEach(options) { option in
                    Text("\(option.title) · \(option.context)").tag(UUID?.some(option.id))
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
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

    private var alternateNameBinding: Binding<String> {
        Binding(get: { viewModel.editingAlternateName }, set: viewModel.setEditingAlternateName)
    }
    private var accessibilityBinding: Binding<String> {
        Binding(get: { viewModel.editingAccessibility }, set: viewModel.setEditingAccessibility)
    }
    private var hoursBinding: Binding<String> {
        Binding(get: { viewModel.editingHours }, set: viewModel.setEditingHours)
    }
    private var phoneBinding: Binding<String> {
        Binding(get: { viewModel.editingPhone }, set: viewModel.setEditingPhone)
    }
    private var websiteBinding: Binding<String> {
        Binding(get: { viewModel.editingWebsite }, set: viewModel.setEditingWebsite)
    }
    private var restrictionBinding: Binding<String> {
        Binding(get: { viewModel.editingRestriction }, set: viewModel.setEditingRestriction)
    }
    private var correlationIDBinding: Binding<String> {
        Binding(get: { viewModel.editingCorrelationID }, set: viewModel.setEditingCorrelationID)
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

    private var anchorBinding: Binding<UUID?> {
        Binding(
            get: { viewModel.editingAnchorIDs.first },
            set: { viewModel.selectEditingAnchor($0) }
        )
    }

    private var originBinding: Binding<UUID?> {
        Binding(
            get: { viewModel.editingOriginID },
            set: { viewModel.selectEditingOrigin($0) }
        )
    }

    private var destinationBinding: Binding<UUID?> {
        Binding(
            get: { viewModel.editingDestinationID },
            set: { viewModel.selectEditingDestination($0) }
        )
    }

    private var addressBinding: Binding<UUID?> {
        Binding(
            get: { viewModel.editingAddressID },
            set: { viewModel.selectEditingAddress($0) }
        )
    }
}
