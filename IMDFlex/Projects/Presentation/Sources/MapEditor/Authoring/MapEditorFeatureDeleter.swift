import Domain
import Foundation

public enum MapEditorFeatureDeletionOutcome: Sendable {
    case success(Venue)
    case notFound
    case blockedByReferences([UUID])
    case unsupported
}

/// Removes authored features while preserving nested ownership and references.
public enum MapEditorFeatureDeleter {
    public static func delete(
        id: UUID,
        feature: IMDFAuthoringFeature,
        from venue: Venue
    ) -> MapEditorFeatureDeletionOutcome {
        guard feature != .venue else { return .unsupported }

        let ids = ownedIDs(id: id, feature: feature, in: venue)
        guard !ids.isEmpty else { return .notFound }

        let affectedRelationships = venue.relationships.filter {
            ids.contains($0.originID) || ids.contains($0.destinationID)
        }.map(\.id)
        guard affectedRelationships.isEmpty || feature == .relationship else {
            return .blockedByReferences(affectedRelationships)
        }

        var updatedVenue = venue
        switch feature {
        case .address:
            guard updatedVenue.address?.id == id else { return .notFound }
            updatedVenue.address = nil
            updatedVenue.buildings = updatedVenue.buildings.map { building in
                var building = building
                if building.addressID == id { building.addressID = nil }
                building.levels = building.levels.map { level in
                    var level = level
                    if level.addressID == id { level.addressID = nil }
                    level.units = level.units.map { unit in
                        var unit = unit
                        unit.amenities = unit.amenities.map { amenity in
                            var amenity = amenity
                            if amenity.addressID == id { amenity.addressID = nil }
                            return amenity
                        }
                        unit.occupants = unit.occupants.map { occupant in
                            var occupant = occupant
                            if occupant.addressID == id { occupant.addressID = nil }
                            return occupant
                        }
                        unit.anchors = unit.anchors.map { anchor in
                            var anchor = anchor
                            if anchor.addressID == id { anchor.addressID = nil }
                            return anchor
                        }
                        return unit
                    }
                    return level
                }
                return building
            }
        case .building:
            updatedVenue.buildings.removeAll { $0.id == id }
        case .footprint:
            updatedVenue.buildings = updatedVenue.buildings.map { building in
                var building = building
                if building.footprint?.id == id { building.footprint = nil }
                return building
            }
        case .level:
            updatedVenue.buildings = updatedVenue.buildings.map { building in
                var building = building
                building.levels.removeAll { $0.id == id }
                return building
            }
        case .unit:
            updatedVenue.buildings = updateLevels(in: updatedVenue.buildings) { level in
                var level = level
                level.units.removeAll { $0.id == id }
                return level
            }
        case .opening:
            updatedVenue.buildings = updateLevels(in: updatedVenue.buildings) { level in
                var level = level
                level.openings.removeAll { $0.id == id }
                return level
            }
        case .amenity, .occupant:
            updatedVenue.buildings = updateUnits(in: updatedVenue.buildings) { unit in
                var unit = unit
                switch feature {
                case .amenity:
                    unit.amenities.removeAll { $0.id == id }
                case .occupant:
                    unit.occupants.removeAll { $0.id == id }
                default:
                    break
                }
                return unit
            }
        case .anchor:
            updatedVenue.buildings = updateLevels(in: updatedVenue.buildings) { level in
                var level = level
                level.units = level.units.map { unit in
                    var unit = unit
                    unit.anchors.removeAll { $0.id == id }
                    unit.occupants = unit.occupants.map { occupant in
                        var occupant = occupant
                        if occupant.anchorID == id { occupant.anchorID = nil }
                        return occupant
                    }
                    return unit
                }
                level.fixtures = level.fixtures.map { fixture in
                    var fixture = fixture
                    fixture.anchorIDs.removeAll { $0 == id }
                    return fixture
                }
                level.kiosks = level.kiosks.map { kiosk in
                    var kiosk = kiosk
                    kiosk.anchorIDs.removeAll { $0 == id }
                    return kiosk
                }
                return level
            }
        case .detail, .fixture, .geofence, .kiosk, .section:
            updatedVenue.buildings = updateLevels(in: updatedVenue.buildings) { level in
                var level = level
                switch feature {
                case .detail: level.details.removeAll { $0.id == id }
                case .fixture:
                    level.fixtures = level.fixtures.map { fixture in
                        var fixture = fixture
                        fixture.anchorIDs.removeAll { $0 == id }
                        return fixture
                    }
                    level.fixtures.removeAll { $0.id == id }
                case .geofence: level.geofences.removeAll { $0.id == id }
                case .kiosk:
                    level.kiosks = level.kiosks.map { kiosk in
                        var kiosk = kiosk
                        kiosk.anchorIDs.removeAll { $0 == id }
                        return kiosk
                    }
                    level.kiosks.removeAll { $0.id == id }
                case .section: level.sections.removeAll { $0.id == id }
                default: break
                }
                return level
            }
        case .relationship:
            updatedVenue.relationships.removeAll { $0.id == id }
        case .venue:
            return .unsupported
        }

        return .success(updatedVenue)
    }

    private static func ownedIDs(
        id: UUID,
        feature: IMDFAuthoringFeature,
        in venue: Venue
    ) -> Set<UUID> {
        switch feature {
        case .address:
            return venue.address?.id == id ? [id] : []
        case .venue:
            return []
        case .building:
            guard let building = venue.buildings.first(where: { $0.id == id }) else { return [] }
            return Set([building.id] + building.levels.flatMap(allIDs(in:)))
        case .footprint:
            return venue.buildings.contains { $0.footprint?.id == id } ? [id] : []
        case .level:
            guard let level = venue.buildings.flatMap(\.levels).first(where: { $0.id == id }) else { return [] }
            return Set(allIDs(in: level))
        case .unit:
            guard let unit = venue.buildings.flatMap(\.levels).flatMap(\.units).first(where: { $0.id == id }) else { return [] }
            return Set(allIDs(in: unit))
        case .opening:
            return venue.buildings.flatMap(\.levels).flatMap(\.openings).contains { $0.id == id } ? [id] : []
        case .amenity:
            return venue.buildings.flatMap(\.levels).flatMap(\.units).flatMap(\.amenities).contains { $0.id == id } ? [id] : []
        case .anchor:
            return venue.buildings.flatMap(\.levels).flatMap(\.units).flatMap(\.anchors).contains { $0.id == id } ? [id] : []
        case .occupant:
            return venue.buildings.flatMap(\.levels).flatMap(\.units).flatMap(\.occupants).contains { $0.id == id } ? [id] : []
        case .detail:
            return venue.buildings.flatMap(\.levels).flatMap(\.details).contains { $0.id == id } ? [id] : []
        case .fixture:
            return venue.buildings.flatMap(\.levels).flatMap(\.fixtures).contains { $0.id == id } ? [id] : []
        case .geofence:
            return venue.buildings.flatMap(\.levels).flatMap(\.geofences).contains { $0.id == id } ? [id] : []
        case .kiosk:
            return venue.buildings.flatMap(\.levels).flatMap(\.kiosks).contains { $0.id == id } ? [id] : []
        case .relationship:
            return venue.relationships.contains { $0.id == id } ? [id] : []
        case .section:
            return venue.buildings.flatMap(\.levels).flatMap(\.sections).contains { $0.id == id } ? [id] : []
        }
    }

    private static func allIDs(in building: Building) -> [UUID] {
        [building.id]
            + (building.footprint.map { [$0.id] } ?? [])
            + building.levels.flatMap(allIDs(in:))
    }

    private static func allIDs(in level: Level) -> [UUID] {
        [level.id]
            + level.units.flatMap(allIDs(in:))
            + level.openings.map(\.id)
            + level.details.map(\.id)
            + level.fixtures.map(\.id)
            + level.geofences.map(\.id)
            + level.kiosks.map(\.id)
            + level.sections.map(\.id)
    }

    private static func allIDs(in unit: Domain.Unit) -> [UUID] {
        [unit.id]
            + unit.anchors.map(\.id)
            + unit.amenities.map(\.id)
            + unit.occupants.map(\.id)
    }

    private static func updateLevels(
        in buildings: [Building],
        transform: (Level) -> Level
    ) -> [Building] {
        buildings.map { building in
            var building = building
            building.levels = building.levels.map(transform)
            return building
        }
    }

    private static func updateUnits(
        in buildings: [Building],
        transform: (Domain.Unit) -> Domain.Unit
    ) -> [Building] {
        updateLevels(in: buildings) { level in
            var level = level
            level.units = level.units.map(transform)
            return level
        }
    }
}
