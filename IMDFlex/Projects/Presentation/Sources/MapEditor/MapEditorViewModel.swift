import Foundation
import Observation
import Domain

@MainActor
@Observable
public final class MapEditorViewModel {
    public private(set) var project: IMDFProject
    public private(set) var alert: MapEditorAlert?

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
            await save(venue)
        case .missingParent:
            alert = .missingParent
        case .unsupported:
            alert = .unsupported
        }
    }

    public func dismissAlert() {
        alert = nil
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

    private func save(_ venue: Venue) async {
        project.venue = venue
        project.updatedAt = Date()

        do {
            try await service.updateProject(project)
            authoringState.resetAfterFinish()
        } catch {
            alert = .saveFailed
        }
    }

    private func levels(in venue: Venue) -> [Level] {
        venue.buildings.flatMap(\.levels)
    }

    private func units(in venue: Venue) -> [Domain.Unit] {
        levels(in: venue).flatMap(\.units)
    }
}
