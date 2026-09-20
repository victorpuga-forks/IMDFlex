import Foundation
import Observation
import Domain

@MainActor
@Observable
public final class MapEditorViewModel {
    public private(set) var project: IMDFProject
    public private(set) var alert: MapEditorAlert?
    public private(set) var mode: MapEditorMode = .insert
    public private(set) var selectedShapeID: UUID?
    public private(set) var editingName: String = ""
    public private(set) var editingAlternateName: String = ""
    public private(set) var editingAccessibility: String = ""
    public private(set) var editingHours: String = ""
    public private(set) var editingPhone: String = ""
    public private(set) var editingWebsite: String = ""
    public private(set) var editingRestriction: String = ""
    public private(set) var editingCorrelationID: String = ""
    public private(set) var editingAddressID: UUID?
    public private(set) var editingShortName: String = ""
    public private(set) var editingCategoryValue: String?
    public private(set) var editingCoordinates: [Coordinate] = []
    public private(set) var editingAnchorIDs: [UUID] = []
    public private(set) var editingOriginID: UUID?
    public private(set) var editingDestinationID: UUID?
    public private(set) var isAddingGeometryPoint = false
    public private(set) var preflightIssues: [IMDFPreflightIssue] = []
    public private(set) var isPreflightSheetPresented = false

    public let authoringState: FeatureAuthoringToolState

    @ObservationIgnored
    private let service: any MapEditorServicing

    @ObservationIgnored
    private let exportService: any MapEditorExportServicing

    public init(
        project: IMDFProject,
        service: any MapEditorServicing,
        exportService: any MapEditorExportServicing,
        authoringState: FeatureAuthoringToolState = FeatureAuthoringToolState()
    ) {
        self.project = project
        self.service = service
        self.exportService = exportService
        self.authoringState = authoringState
    }

    public func finishDraft() async {
        guard let draft = authoringState.finishDrawingDraft() else { return }

        let outcome = MapEditorFeatureBuilder.apply(
            feature: authoringState.selectedFeature,
            draft: draft,
            categoryValue: authoringState.selectedCategoryValue,
            name: authoringState.name,
            shortName: authoringState.shortName,
            references: IMDFAuthoringReferenceSelection(
                buildingID: authoringState.selectedReferenceID(for: .building),
                levelID: authoringState.selectedReferenceID(for: .level)
                    ?? authoringState.selectedReferenceID(for: .levelOrBuilding),
                unitID: authoringState.selectedReferenceID(for: .unit),
                anchorID: authoringState.selectedReferenceID(for: .anchor),
                originID: authoringState.selectedReferenceID(for: .relationshipOrigin),
                destinationID: authoringState.selectedReferenceID(for: .relationshipDestination)
            ),
            to: project.venue
        )

        switch outcome {
        case .success(let venue):
            if await save(venue) {
                authoringState.resetAfterFinish()
            }
        case .missingReference:
            alert = .missingParent
        case .invalidRelationshipEndpoints:
            alert = .unsupported
        case .unsupported:
            alert = .unsupported
          case .missingParent:
            alert = .missingParent
        }
    }

    public func dismissAlert() {
        alert = nil
    }

    public var featureShapes: [MapEditorFeatureShape] {
        MapEditorFeatureShapeBuilder.shapes(for: project.venue)
    }

    public var drawableFeatureShapes: [MapEditorFeatureShape] {
        featureShapes.filter { shape in
            if case .none = shape.geometry {
                return false
            }
            return true
        }
    }

    public var selectedShape: MapEditorFeatureShape? {
        guard let selectedShapeID else { return nil }
        return featureShapes.first { $0.id == selectedShapeID }
    }

    public var canSaveSelectedFeatureEdits: Bool {
        guard let shape = selectedShape else { return false }

        let contract = shape.feature.contract
        let hasRequiredName = !contract.requiresName || !editingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasRequiredShortName = !contract.requiresShortName
            || !editingShortName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasRequiredCategory = !contract.requiresCategory || editingCategoryValue != nil
        let hasRequiredGeometry = contract.geometry == .form
            || editingCoordinates.count >= contract.geometry.minimumPointCount
        let hasValidReferences = editingReferencesAreValid(for: shape.feature)
        return hasRequiredName && hasRequiredShortName && hasRequiredCategory
            && hasRequiredGeometry && hasValidReferences
    }

    public var canEditSelectedFeatureGeometry: Bool {
        guard let shape = selectedShape else { return false }
        return shape.feature.contract.geometry != .form
    }

    public func setMode(_ mode: MapEditorMode) {
        self.mode = mode
        clearSelection()
    }

    public func select(id: UUID) {
        selectedShapeID = id
        isAddingGeometryPoint = false

        guard let shape = selectedShape else {
            editingName = ""
            resetMetadata()
            editingShortName = ""
            editingCategoryValue = nil
            editingCoordinates = []
            editingAnchorIDs = []
            editingOriginID = nil
            editingDestinationID = nil
            return
        }

        editingCoordinates = coordinates(from: shape.geometry)

        guard let values = MapEditorFeatureEditor.currentValues(id: id, feature: shape.feature, in: project.venue) else {
            editingName = ""
            resetMetadata()
            editingShortName = ""
            editingCategoryValue = nil
            editingAnchorIDs = []
            editingOriginID = nil
            editingDestinationID = nil
            return
        }

        editingName = values.name ?? ""
        editingAlternateName = values.alternateName ?? ""
        editingAccessibility = values.accessibility ?? ""
        editingHours = values.hours ?? ""
        editingPhone = values.phone ?? ""
        editingWebsite = values.website ?? ""
        editingRestriction = values.restriction ?? ""
        editingCorrelationID = values.correlationID ?? ""
        editingAddressID = values.addressID
        editingShortName = values.shortName ?? ""
        editingCategoryValue = values.categoryValue
        editingAnchorIDs = values.anchorIDs
        editingOriginID = values.originID
        editingDestinationID = values.destinationID
    }

    public func clearSelection() {
        selectedShapeID = nil
        editingName = ""
        resetMetadata()
        editingShortName = ""
        editingCategoryValue = nil
        editingCoordinates = []
        editingAnchorIDs = []
        editingOriginID = nil
        editingDestinationID = nil
        isAddingGeometryPoint = false
    }

    public func setEditingName(_ name: String) {
        editingName = name
    }

    public func setEditingAlternateName(_ value: String) { editingAlternateName = value }
    public func setEditingAccessibility(_ value: String) { editingAccessibility = value }
    public func setEditingHours(_ value: String) { editingHours = value }
    public func setEditingPhone(_ value: String) { editingPhone = value }
    public func setEditingWebsite(_ value: String) { editingWebsite = value }
    public func setEditingRestriction(_ value: String) { editingRestriction = value }
    public func setEditingCorrelationID(_ value: String) { editingCorrelationID = value }
    public func selectEditingAddress(_ id: UUID?) { editingAddressID = id }

    public func setEditingShortName(_ shortName: String) {
        editingShortName = shortName
    }

    public func selectEditingCategory(_ value: String) {
        editingCategoryValue = value
    }

    public func selectEditingAnchor(_ id: UUID?) {
        editingAnchorIDs = id.map { [$0] } ?? []
    }

    public func selectEditingOrigin(_ id: UUID?) {
        editingOriginID = id
    }

    public func selectEditingDestination(_ id: UUID?) {
        editingDestinationID = id
    }

    public func setAddingGeometryPoint(_ isAdding: Bool) {
        isAddingGeometryPoint = isAdding
    }

    public func appendGeometryPoint(_ coordinate: Coordinate) {
        guard let shape = selectedShape else { return }

        if shape.feature.contract.geometry == .point {
            editingCoordinates = [coordinate]
        } else {
            editingCoordinates.append(coordinate)
        }

        isAddingGeometryPoint = false
    }

    public func moveGeometryPoint(at index: Int, to coordinate: Coordinate) {
        guard editingCoordinates.indices.contains(index) else { return }
        editingCoordinates[index] = coordinate
    }

    public func moveGeometryPointUp(at index: Int) {
        guard editingCoordinates.indices.contains(index), index > 0 else { return }
        editingCoordinates.swapAt(index, index - 1)
    }

    public func moveGeometryPointDown(at index: Int) {
        guard editingCoordinates.indices.contains(index), index < editingCoordinates.count - 1 else { return }
        editingCoordinates.swapAt(index, index + 1)
    }
  
    public func removeGeometryPoint(at index: Int) {
        guard editingCoordinates.indices.contains(index) else { return }
        editingCoordinates.remove(at: index)
    }

    public func saveSelectedFeatureEdits() async {
        guard let shape = selectedShape else { return }

        let outcome = MapEditorFeatureEditor.apply(
            id: shape.id,
            feature: shape.feature,
            name: MapEditorFeatureEditor.supportsNameField(shape.feature) ? editingName : nil,
            alternateName: editingAlternateName,
            accessibility: editingAccessibility,
            hours: editingHours,
            phone: editingPhone,
            website: editingWebsite,
            restriction: editingRestriction,
            correlationID: editingCorrelationID,
            addressID: editingAddressID,
            categoryValue: shape.feature.contract.requiresCategory ? editingCategoryValue : nil,
            shortName: shape.feature.contract.requiresShortName ? editingShortName : nil,
            coordinates: canEditSelectedFeatureGeometry ? editingCoordinates : nil,
            anchorIDs: editingAnchorIDs,
            originID: editingOriginID,
            destinationID: editingDestinationID,
            to: project.venue
        )

        switch outcome {
        case .success(let venue):
            await save(venue)
        case .notFound:
            clearSelection()
        }
    }

    public func deleteSelectedFeature() async {
        guard let shape = selectedShape, let venue = project.venue else { return }

        switch MapEditorFeatureDeleter.delete(id: shape.id, feature: shape.feature, from: venue) {
        case .success(let updatedVenue):
            if await save(updatedVenue) {
                clearSelection()
            }
        case .notFound:
            clearSelection()
        case .blockedByReferences(let relationshipIDs):
            alert = .deletionBlocked(relationshipIDs)
        case .unsupported:
            alert = .unsupported
        }
    }

    private func resetMetadata() {
        editingAlternateName = ""
        editingAccessibility = ""
        editingHours = ""
        editingPhone = ""
        editingWebsite = ""
        editingRestriction = ""
        editingCorrelationID = ""
        editingAddressID = nil
    }

    public var hasBlockingPreflightIssues: Bool {
        preflightIssues.contains { $0.severity == .error }
    }

    public func startExport() {
        guard let venue = project.venue else { return }
        preflightIssues = exportService.preflight(venue)
        isPreflightSheetPresented = true
    }

    public func dismissPreflightSheet() {
        isPreflightSheetPresented = false
    }

    public func exportArchive() async -> Data? {
        guard let venue = project.venue else { return nil }

        do {
            return try await exportService.exportArchive(venue)
        } catch {
            alert = .exportFailed
            return nil
        }
    }

    public func savedCount(for feature: IMDFAuthoringFeature) -> Int {
        guard let venue = project.venue else { return 0 }

        switch feature {
        case .address:
            return venue.address == nil ? 0 : 1
        case .venue:
            return 1
        case .building:
            return venue.buildings.count
        case .footprint:
            return venue.buildings.compactMap(\.footprint).count
        case .level:
            return venue.buildings.reduce(0) { $0 + $1.levels.count }
        case .unit:
            return levels(in: venue).reduce(0) { $0 + $1.units.count }
        case .opening:
            return levels(in: venue).reduce(0) { $0 + $1.openings.count }
        case .amenity:
            return units(in: venue).reduce(0) { $0 + $1.amenities.count }
        case .anchor:
            return units(in: venue).reduce(0) { $0 + $1.anchors.count }
        case .occupant:
            return units(in: venue).reduce(0) { $0 + $1.occupants.count }
        case .detail:
            return levels(in: venue).reduce(0) { $0 + $1.details.count }
        case .fixture:
            return levels(in: venue).reduce(0) { $0 + $1.fixtures.count }
        case .geofence:
            return levels(in: venue).reduce(0) { $0 + $1.geofences.count }
        case .kiosk:
            return levels(in: venue).reduce(0) { $0 + $1.kiosks.count }
        case .relationship:
            return venue.relationships.count
        case .section:
            return levels(in: venue).reduce(0) { $0 + $1.sections.count }
        }
    }

    @discardableResult
    private func save(_ venue: Venue) async -> Bool {
        var updatedProject = project
        updatedProject.venue = venue
        updatedProject.updatedAt = Date()

        do {
            try await service.updateProject(updatedProject)
            project = updatedProject
            return true
        } catch {
            alert = .saveFailed
            return false
        }
    }

    private func levels(in venue: Venue) -> [Level] {
        venue.buildings.flatMap(\.levels)
    }

    private func units(in venue: Venue) -> [Domain.Unit] {
        levels(in: venue).flatMap(\.units)
    }

  private func coordinates(from geometry: MapEditorFeatureShape.Geometry) -> [Coordinate] {
    switch geometry {
      case .none: []
      case .polygon(let coordinates): coordinates
      case .line(let coordinates): coordinates
      case .point(let coordinate): [coordinate]
    }
  }

        private func editingReferencesAreValid(for feature: IMDFAuthoringFeature) -> Bool {
            switch feature {
            case .occupant:
                return editingAnchorIDs.count == 1
            case .fixture, .kiosk:
                return true
            case .relationship:
                return editingOriginID != nil
                    && editingDestinationID != nil
                    && editingOriginID != editingDestinationID
            default:
                return true
            }
    }
}
