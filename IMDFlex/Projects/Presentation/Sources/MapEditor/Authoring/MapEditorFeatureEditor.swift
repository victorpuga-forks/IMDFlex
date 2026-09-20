import Domain
import Foundation

public struct MapEditorFeatureFieldValues: Equatable, Sendable {
    public var name: String?
    public var categoryValue: String?

    public init(name: String? = nil, categoryValue: String? = nil) {
        self.name = name
        self.categoryValue = categoryValue
    }
}

public enum MapEditorFeatureEditorOutcome: Equatable {
    case success(Venue)
    case notFound

    /// `Venue` isn't `Equatable`, so a successful outcome only compares the venue's identity.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.notFound, .notFound):
            true
        case (.success(let lhsVenue), .success(let rhsVenue)):
            lhsVenue.id == rhsVenue.id
        default:
            false
        }
    }
}

/// Finds an existing Domain entity by id and mutates it in place, the read/write counterpart to
/// `MapEditorFeatureBuilder`'s append-only authoring.
///
/// Not every Domain type has both a name and a category, so `supportsNameField` and
/// `IMDFAuthoringContract.requiresCategory` gate which fields a caller should even offer.
/// `relationship` has no addressable geometry to select in the first place, so it always reports
/// `.notFound`/`nil`, the same honesty bar as the builder's `.unsupported`.
public enum MapEditorFeatureEditor {
    public static func supportsNameField(_ feature: IMDFAuthoringFeature) -> Bool {
        switch feature {
        case .footprint, .opening, .anchor, .relationship:
            false
        default:
            true
        }
    }

    public static func currentValues(
        id: UUID,
        feature: IMDFAuthoringFeature,
        in venue: Venue?
    ) -> MapEditorFeatureFieldValues? {
        guard let venue, feature != .relationship else { return nil }

        switch feature {
        case .address:
            guard let address = venue.address, address.id == id else { return nil }
            return .init(name: address.address, categoryValue: nil)
        case .venue:
            guard venue.id == id else { return nil }
            return .init(name: venue.name, categoryValue: venue.category.rawValue)
        case .building:
            guard let buildingIndex = buildingIndex(id: id, in: venue) else { return nil }
            let building = venue.buildings[buildingIndex]
            return .init(name: building.name, categoryValue: building.category.rawValue)
        case .footprint:
            guard let buildingIndex = buildingIndexWithFootprint(id: id, in: venue),
                  let footprint = venue.buildings[buildingIndex].footprint else { return nil }
            return .init(name: nil, categoryValue: footprint.category.rawValue)
        case .level:
            guard let location = levelLocation(id: id, in: venue) else { return nil }
            let level = venue.buildings[location.buildingIndex].levels[location.levelIndex]
            return .init(name: level.name, categoryValue: level.category.rawValue)
        case .unit:
            guard let location = unitLocation(id: id, in: venue) else { return nil }
            let unit = venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex]
            return .init(name: unit.name, categoryValue: unit.category.rawValue)
        case .opening:
            guard levelChildLocation(id: id, in: venue, children: \.openings) != nil else { return nil }
            return .init(name: nil, categoryValue: opening(id: id, in: venue)?.category.rawValue)
        case .amenity:
            guard let amenity = amenity(id: id, in: venue) else { return nil }
            return .init(name: amenity.name, categoryValue: amenity.category.rawValue)
        case .anchor:
            guard anchor(id: id, in: venue) != nil else { return nil }
            return .init(name: nil, categoryValue: nil)
        case .occupant:
            guard let occupant = occupant(id: id, in: venue) else { return nil }
            return .init(name: occupant.name, categoryValue: occupant.category?.rawValue)
        case .detail:
            guard let detail = detail(id: id, in: venue) else { return nil }
            return .init(name: detail.name, categoryValue: nil)
        case .fixture:
            guard let fixture = fixture(id: id, in: venue) else { return nil }
            return .init(name: fixture.name, categoryValue: fixture.category.rawValue)
        case .geofence:
            guard let geofence = geofence(id: id, in: venue) else { return nil }
            return .init(name: geofence.name, categoryValue: geofence.category.rawValue)
        case .kiosk:
            guard let kiosk = kiosk(id: id, in: venue) else { return nil }
            return .init(name: kiosk.name, categoryValue: nil)
        case .relationship:
            return nil
        case .section:
            guard let section = section(id: id, in: venue) else { return nil }
            return .init(name: section.name, categoryValue: section.category.rawValue)
        }
    }

    public static func apply(
        id: UUID,
        feature: IMDFAuthoringFeature,
        name: String?,
        categoryValue: String?,
        coordinates: [Coordinate]?,
        to venue: Venue?
    ) -> MapEditorFeatureEditorOutcome {
        guard var venue, feature != .relationship else { return .notFound }

        switch feature {
        case .address:
            guard venue.address?.id == id else { return .notFound }
            if let name {
                venue.address?.address = name.isEmpty ? nil : name
            }
            return .success(venue)
        case .venue:
            guard venue.id == id else { return .notFound }
            if let name, !name.isEmpty { venue.name = name }
            if let category = category(VenueCategory.self, from: categoryValue) {
                venue.category = category
            }
            if let coordinates { venue.coordinates = coordinates }
            return .success(venue)
        case .building:
            guard let buildingIndex = buildingIndex(id: id, in: venue) else { return .notFound }
            if let name { venue.buildings[buildingIndex].name = name.isEmpty ? nil : name }
            if let category = category(BuildingCategory.self, from: categoryValue) {
                venue.buildings[buildingIndex].category = category
            }
            return .success(venue)
        case .footprint:
            guard let buildingIndex = buildingIndexWithFootprint(id: id, in: venue) else { return .notFound }
            if let category = category(FootprintCategory.self, from: categoryValue) {
                venue.buildings[buildingIndex].footprint?.category = category
            }
            if let coordinates { venue.buildings[buildingIndex].footprint?.coordinates = coordinates }
            return .success(venue)
        case .level:
            guard let location = levelLocation(id: id, in: venue) else { return .notFound }
            if let name, !name.isEmpty {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].name = name
            }
            if let category = category(LevelCategory.self, from: categoryValue) {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].category = category
            }
            if let coordinates {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].coordinates = coordinates
            }
            return .success(venue)
        case .unit:
            guard let location = unitLocation(id: id, in: venue) else { return .notFound }
            if let name {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex]
                    .name = name.isEmpty ? nil : name
            }
            if let category = category(UnitCategory.self, from: categoryValue) {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex]
                    .category = category
            }
            if let coordinates {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex]
                    .coordinates = coordinates
            }
            return .success(venue)
        case .opening:
            guard let location = levelChildLocation(id: id, in: venue, children: \.openings) else { return .notFound }
            if let category = category(OpeningCategory.self, from: categoryValue) {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].openings[location.childIndex]
                    .category = category
            }
            if let coordinates {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].openings[location.childIndex]
                    .coordinates = coordinates
            }
            return .success(venue)
        case .amenity:
            guard let location = unitChildLocation(id: id, in: venue, children: \.amenities) else { return .notFound }
            if let name {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex]
                    .amenities[location.childIndex].name = name.isEmpty ? nil : name
            }
            if let category = category(AmenityCategory.self, from: categoryValue) {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex]
                    .amenities[location.childIndex].category = category
            }
            if let coordinate = coordinates?.first {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex]
                    .amenities[location.childIndex].coordinate = coordinate
            }
            return .success(venue)
        case .anchor:
            guard let location = unitChildLocation(id: id, in: venue, children: \Domain.Unit.anchors) else { return .notFound }
            if let coordinate = coordinates?.first {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex]
                    .anchors[location.childIndex].coordinate = coordinate
            }
            return .success(venue)
        case .occupant:
            guard let location = unitChildLocation(id: id, in: venue, children: \.occupants) else { return .notFound }
            if let name, !name.isEmpty {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex]
                    .occupants[location.childIndex].name = name
            }
            if let category = category(OccupantCategory.self, from: categoryValue) {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex]
                    .occupants[location.childIndex].category = category
            }
            return .success(venue)
        case .detail:
            guard let location = levelChildLocation(id: id, in: venue, children: \.details) else { return .notFound }
            if let name {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].details[location.childIndex]
                    .name = name.isEmpty ? nil : name
            }
            if let coordinates {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].details[location.childIndex]
                    .coordinates = coordinates
            }
            return .success(venue)
        case .fixture:
            guard let location = levelChildLocation(id: id, in: venue, children: \.fixtures) else { return .notFound }
            if let name {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].fixtures[location.childIndex]
                    .name = name.isEmpty ? nil : name
            }
            if let category = category(FixtureCategory.self, from: categoryValue) {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].fixtures[location.childIndex]
                    .category = category
            }
            if let coordinates {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].fixtures[location.childIndex]
                    .coordinates = coordinates
            }
            return .success(venue)
        case .geofence:
            guard let location = levelChildLocation(id: id, in: venue, children: \.geofences) else { return .notFound }
            if let name {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].geofences[location.childIndex]
                    .name = name.isEmpty ? nil : name
            }
            if let category = category(GeofenceCategory.self, from: categoryValue) {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].geofences[location.childIndex]
                    .category = category
            }
            if let coordinates {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].geofences[location.childIndex]
                    .coordinates = coordinates
            }
            return .success(venue)
        case .kiosk:
            guard let location = levelChildLocation(id: id, in: venue, children: \.kiosks) else { return .notFound }
            if let name {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].kiosks[location.childIndex]
                    .name = name.isEmpty ? nil : name
            }
            if let coordinates {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].kiosks[location.childIndex]
                    .coordinates = coordinates
            }
            return .success(venue)
        case .relationship:
            return .notFound
        case .section:
            guard let location = levelChildLocation(id: id, in: venue, children: \.sections) else { return .notFound }
            if let name {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].sections[location.childIndex]
                    .name = name.isEmpty ? nil : name
            }
            if let category = category(SectionCategory.self, from: categoryValue) {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].sections[location.childIndex]
                    .category = category
            }
            if let coordinates {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].sections[location.childIndex]
                    .coordinates = coordinates
            }
            return .success(venue)
        }
    }

    private static func category<Category: RawRepresentable>(
        _ type: Category.Type,
        from rawValue: String?
    ) -> Category? where Category.RawValue == String {
        rawValue.flatMap(Category.init(rawValue:))
    }

    private static func opening(id: UUID, in venue: Venue) -> Opening? {
        guard let location = levelChildLocation(id: id, in: venue, children: \.openings) else { return nil }
        return venue.buildings[location.buildingIndex].levels[location.levelIndex].openings[location.childIndex]
    }

    private static func amenity(id: UUID, in venue: Venue) -> Amenity? {
        guard let location = unitChildLocation(id: id, in: venue, children: \.amenities) else { return nil }
        return venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex]
            .amenities[location.childIndex]
    }

    private static func anchor(id: UUID, in venue: Venue) -> Anchor? {
        guard let location = unitChildLocation(id: id, in: venue, children: \Domain.Unit.anchors) else { return nil }
        return venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex]
            .anchors[location.childIndex]
    }

    private static func occupant(id: UUID, in venue: Venue) -> Occupant? {
        guard let location = unitChildLocation(id: id, in: venue, children: \.occupants) else { return nil }
        return venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex]
            .occupants[location.childIndex]
    }

    private static func detail(id: UUID, in venue: Venue) -> Detail? {
        guard let location = levelChildLocation(id: id, in: venue, children: \.details) else { return nil }
        return venue.buildings[location.buildingIndex].levels[location.levelIndex].details[location.childIndex]
    }

    private static func fixture(id: UUID, in venue: Venue) -> Fixture? {
        guard let location = levelChildLocation(id: id, in: venue, children: \.fixtures) else { return nil }
        return venue.buildings[location.buildingIndex].levels[location.levelIndex].fixtures[location.childIndex]
    }

    private static func geofence(id: UUID, in venue: Venue) -> Geofence? {
        guard let location = levelChildLocation(id: id, in: venue, children: \.geofences) else { return nil }
        return venue.buildings[location.buildingIndex].levels[location.levelIndex].geofences[location.childIndex]
    }

    private static func kiosk(id: UUID, in venue: Venue) -> Kiosk? {
        guard let location = levelChildLocation(id: id, in: venue, children: \.kiosks) else { return nil }
        return venue.buildings[location.buildingIndex].levels[location.levelIndex].kiosks[location.childIndex]
    }

    private static func section(id: UUID, in venue: Venue) -> Section? {
        guard let location = levelChildLocation(id: id, in: venue, children: \.sections) else { return nil }
        return venue.buildings[location.buildingIndex].levels[location.levelIndex].sections[location.childIndex]
    }

    private static func buildingIndex(id: UUID, in venue: Venue) -> Int? {
        venue.buildings.firstIndex { $0.id == id }
    }

    private static func buildingIndexWithFootprint(id: UUID, in venue: Venue) -> Int? {
        venue.buildings.firstIndex { $0.footprint?.id == id }
    }

    private static func levelLocation(id: UUID, in venue: Venue) -> (buildingIndex: Int, levelIndex: Int)? {
        for buildingIndex in venue.buildings.indices {
            if let levelIndex = venue.buildings[buildingIndex].levels.firstIndex(where: { $0.id == id }) {
                return (buildingIndex, levelIndex)
            }
        }
        return nil
    }

    private static func unitLocation(
        id: UUID,
        in venue: Venue
    ) -> (buildingIndex: Int, levelIndex: Int, unitIndex: Int)? {
        for buildingIndex in venue.buildings.indices {
            for levelIndex in venue.buildings[buildingIndex].levels.indices {
                let units = venue.buildings[buildingIndex].levels[levelIndex].units
                if let unitIndex = units.firstIndex(where: { $0.id == id }) {
                    return (buildingIndex, levelIndex, unitIndex)
                }
            }
        }
        return nil
    }

    private static func levelChildLocation<Child: Identifiable>(
        id: UUID,
        in venue: Venue,
        children: KeyPath<Level, [Child]>
    ) -> (buildingIndex: Int, levelIndex: Int, childIndex: Int)? where Child.ID == UUID {
        for buildingIndex in venue.buildings.indices {
            for levelIndex in venue.buildings[buildingIndex].levels.indices {
                let level = venue.buildings[buildingIndex].levels[levelIndex]
                if let childIndex = level[keyPath: children].firstIndex(where: { $0.id == id }) {
                    return (buildingIndex, levelIndex, childIndex)
                }
            }
        }
        return nil
    }

    private static func unitChildLocation<Child: Identifiable>(
        id: UUID,
        in venue: Venue,
        children: KeyPath<Domain.Unit, [Child]>
    ) -> (buildingIndex: Int, levelIndex: Int, unitIndex: Int, childIndex: Int)? where Child.ID == UUID {
        for buildingIndex in venue.buildings.indices {
            for levelIndex in venue.buildings[buildingIndex].levels.indices {
                for unitIndex in venue.buildings[buildingIndex].levels[levelIndex].units.indices {
                    let unit = venue.buildings[buildingIndex].levels[levelIndex].units[unitIndex]
                    if let childIndex = unit[keyPath: children].firstIndex(where: { $0.id == id }) {
                        return (buildingIndex, levelIndex, unitIndex, childIndex)
                    }
                }
            }
        }
        return nil
    }
}
