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
    public private(set) var editingCategoryValue: String?

    public let authoringState: FeatureAuthoringToolState

    @ObservationIgnored
    private let service: any MapEditorServicing

    public init(
        project: IMDFProject,
        service: any MapEditorServicing,
        authoringState: FeatureAuthoringToolState = FeatureAuthoringToolState()
    ) {
        self.project = project
        self.service = service
        self.authoringState = authoringState
    }

    public func finishDraft() async {
        guard let draft = authoringState.finishDrawingDraft() else { return }

        let outcome = MapEditorFeatureBuilder.apply(
            feature: authoringState.selectedFeature,
            draft: draft,
            categoryValue: authoringState.selectedCategoryValue,
            name: authoringState.name,
            to: project.venue
        )

        switch outcome {
        case .success(let venue):
            if await save(venue) {
                authoringState.resetAfterFinish()
            }
        case .missingParent:
            alert = .missingParent
        case .unsupported:
            alert = .unsupported
        }
    }

    public func dismissAlert() {
        alert = nil
    }

    public var featureShapes: [MapEditorFeatureShape] {
        MapEditorFeatureShapeBuilder.shapes(for: project.venue)
    }

    public var selectedShape: MapEditorFeatureShape? {
        guard let selectedShapeID else { return nil }
        return featureShapes.first { $0.id == selectedShapeID }
    }

    public var canSaveSelectedFeatureEdits: Bool {
        guard let shape = selectedShape else { return false }

        let contract = shape.feature.contract
        let hasRequiredName = !contract.requiresName || !editingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasRequiredCategory = !contract.requiresCategory || editingCategoryValue != nil
        return hasRequiredName && hasRequiredCategory
    }

    public func setMode(_ mode: MapEditorMode) {
        self.mode = mode
        clearSelection()
    }

    public func select(id: UUID) {
        selectedShapeID = id

        guard let shape = selectedShape,
              let values = MapEditorFeatureEditor.currentValues(id: id, feature: shape.feature, in: project.venue) else {
            editingName = ""
            editingCategoryValue = nil
            return
        }

        editingName = values.name ?? ""
        editingCategoryValue = values.categoryValue
    }

    public func clearSelection() {
        selectedShapeID = nil
        editingName = ""
        editingCategoryValue = nil
    }

    public func setEditingName(_ name: String) {
        editingName = name
    }

    public func selectEditingCategory(_ value: String) {
        editingCategoryValue = value
    }

    public func saveSelectedFeatureEdits() async {
        guard let shape = selectedShape else { return }

        let outcome = MapEditorFeatureEditor.apply(
            id: shape.id,
            feature: shape.feature,
            name: MapEditorFeatureEditor.supportsNameField(shape.feature) ? editingName : nil,
            categoryValue: shape.feature.contract.requiresCategory ? editingCategoryValue : nil,
            to: project.venue
        )

        switch outcome {
        case .success(let venue):
            await save(venue)
        case .notFound:
            clearSelection()
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
        project.venue = venue
        project.updatedAt = Date()

        do {
            try await service.updateProject(project)
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
}
