import Domain
import Foundation

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

public struct MapEditorFeatureFieldValues: Equatable, Sendable {
    public var name: String?
    public var alternateName: String?
    public var accessibility: String?
    public var hours: String?
    public var phone: String?
    public var website: String?
    public var restriction: String?
    public var correlationID: String?
    public var addressID: UUID?
    public var categoryValue: String?
    public var shortName: String?
    public var anchorIDs: [UUID]
    public var originID: UUID?
    public var destinationID: UUID?

    public init(
        name: String? = nil,
        alternateName: String? = nil,
        accessibility: String? = nil,
        hours: String? = nil,
        phone: String? = nil,
        website: String? = nil,
        restriction: String? = nil,
        correlationID: String? = nil,
        addressID: UUID? = nil,
        categoryValue: String? = nil,
        shortName: String? = nil,
        anchorIDs: [UUID] = [],
        originID: UUID? = nil,
        destinationID: UUID? = nil
    ) {
        self.name = name
        self.alternateName = alternateName
        self.accessibility = accessibility
        self.hours = hours
        self.phone = phone
        self.website = website
        self.restriction = restriction
        self.correlationID = correlationID
        self.addressID = addressID
        self.categoryValue = categoryValue
        self.shortName = shortName
        self.anchorIDs = anchorIDs
        self.originID = originID
        self.destinationID = destinationID
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
        guard let venue else { return nil }

        switch feature {
        case .address:
            guard let address = venue.address, address.id == id else { return nil }
            return .init(name: address.address, categoryValue: nil)
        case .venue:
            guard venue.id == id else { return nil }
            return .init(name: venue.name, alternateName: venue.alternateName, hours: venue.hours, phone: venue.phone, website: venue.website?.absoluteString, restriction: venue.restriction, categoryValue: venue.category.rawValue)
        case .building:
            guard let buildingIndex = buildingIndex(id: id, in: venue) else { return nil }
            let building = venue.buildings[buildingIndex]
            return .init(name: building.name, alternateName: building.alternateName, restriction: building.restriction, addressID: building.addressID, categoryValue: building.category.rawValue)
        case .footprint:
            guard let buildingIndex = buildingIndexWithFootprint(id: id, in: venue),
                  let footprint = venue.buildings[buildingIndex].footprint else { return nil }
            return .init(name: nil, categoryValue: footprint.category.rawValue)
        case .level:
            guard let location = levelLocation(id: id, in: venue) else { return nil }
            let level = venue.buildings[location.buildingIndex].levels[location.levelIndex]
            return .init(name: level.name, alternateName: level.alternateName, restriction: level.restriction, addressID: level.addressID, categoryValue: level.category.rawValue, shortName: level.shortName)
        case .unit:
            guard let location = unitLocation(id: id, in: venue) else { return nil }
            let unit = venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex]
            return .init(name: unit.name, alternateName: unit.alternateName, accessibility: unit.accessibility, restriction: unit.restriction, categoryValue: unit.category.rawValue)
        case .opening:
            guard levelChildLocation(id: id, in: venue, children: \.openings) != nil else { return nil }
            let item = opening(id: id, in: venue)
            return .init(name: item?.name, alternateName: item?.alternateName, accessibility: item?.accessibility, categoryValue: item?.category.rawValue)
        case .amenity:
            guard let amenity = amenity(id: id, in: venue) else { return nil }
            return .init(name: amenity.name, alternateName: amenity.alternateName, accessibility: amenity.accessibility, hours: amenity.hours, phone: amenity.phone, website: amenity.website?.absoluteString, correlationID: amenity.correlationID, addressID: amenity.addressID, categoryValue: amenity.category.rawValue)
        case .anchor:
            guard anchor(id: id, in: venue) != nil else { return nil }
            return .init(name: nil, categoryValue: nil)
        case .occupant:
            guard let occupant = occupant(id: id, in: venue) else { return nil }
            return .init(name: occupant.name, alternateName: occupant.alternateName, hours: occupant.hours, phone: occupant.phone, website: occupant.website?.absoluteString, restriction: occupant.restriction, correlationID: occupant.correlationID, addressID: occupant.addressID, categoryValue: occupant.category?.rawValue, anchorIDs: occupant.anchorID.map { [$0] } ?? [])
        case .detail:
            guard let detail = detail(id: id, in: venue) else { return nil }
            return .init(name: detail.name, categoryValue: nil)
        case .fixture:
            guard let fixture = fixture(id: id, in: venue) else { return nil }
            return .init(name: fixture.name, categoryValue: fixture.category.rawValue, anchorIDs: fixture.anchorIDs)
        case .geofence:
            guard let geofence = geofence(id: id, in: venue) else { return nil }
            return .init(name: geofence.name, categoryValue: geofence.category.rawValue)
        case .kiosk:
            guard let kiosk = kiosk(id: id, in: venue) else { return nil }
            return .init(name: kiosk.name, categoryValue: nil, anchorIDs: kiosk.anchorIDs)
        case .relationship:
            guard let relationship = venue.relationships.first(where: { $0.id == id }) else { return nil }
            return .init(
                categoryValue: relationship.category.rawValue,
                originID: relationship.originID,
                destinationID: relationship.destinationID
            )
        case .section:
            guard let section = section(id: id, in: venue) else { return nil }
            return .init(name: section.name, categoryValue: section.category.rawValue)
        }
    }

    public static func apply(
        id: UUID,
        feature: IMDFAuthoringFeature,
        name: String?,
        alternateName: String? = nil,
        accessibility: String? = nil,
        hours: String? = nil,
        phone: String? = nil,
        website: String? = nil,
        restriction: String? = nil,
        correlationID: String? = nil,
        addressID: UUID? = nil,
        categoryValue: String?,
        shortName: String? = nil,
        coordinates: [Coordinate]?,
        anchorIDs: [UUID] = [],
        originID: UUID? = nil,
        destinationID: UUID? = nil,
        to venue: Venue?
    ) -> MapEditorFeatureEditorOutcome {
        guard var venue else { return .notFound }

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
            venue.alternateName = alternateName?.nilIfEmpty
            venue.hours = hours?.nilIfEmpty
            venue.phone = phone?.nilIfEmpty
            venue.website = URL(string: website ?? "")
            venue.restriction = restriction?.nilIfEmpty
            if let coordinates { venue.coordinates = coordinates }
            return .success(venue)
        case .building:
            guard let buildingIndex = buildingIndex(id: id, in: venue) else { return .notFound }
            guard addressID == nil || venue.address?.id == addressID else { return .notFound }
            if let name { venue.buildings[buildingIndex].name = name.isEmpty ? nil : name }
            if let category = category(BuildingCategory.self, from: categoryValue) {
                venue.buildings[buildingIndex].category = category
            }
            venue.buildings[buildingIndex].alternateName = alternateName?.nilIfEmpty
            venue.buildings[buildingIndex].addressID = addressID
            venue.buildings[buildingIndex].restriction = restriction?.nilIfEmpty
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
            guard addressID == nil || venue.address?.id == addressID else { return .notFound }
            if let name, !name.isEmpty {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].name = name
            }
            if let category = category(LevelCategory.self, from: categoryValue) {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].category = category
            }
            if let shortName {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].shortName = shortName.isEmpty ? nil : shortName
            }
            venue.buildings[location.buildingIndex].levels[location.levelIndex].alternateName = alternateName?.nilIfEmpty
            venue.buildings[location.buildingIndex].levels[location.levelIndex].addressID = addressID
            venue.buildings[location.buildingIndex].levels[location.levelIndex].restriction = restriction?.nilIfEmpty
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
            venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex].alternateName = alternateName?.nilIfEmpty
            venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex].accessibility = accessibility?.nilIfEmpty
            venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex].restriction = restriction?.nilIfEmpty
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
            venue.buildings[location.buildingIndex].levels[location.levelIndex].openings[location.childIndex].name = name?.nilIfEmpty
            venue.buildings[location.buildingIndex].levels[location.levelIndex].openings[location.childIndex].alternateName = alternateName?.nilIfEmpty
            venue.buildings[location.buildingIndex].levels[location.levelIndex].openings[location.childIndex].accessibility = accessibility?.nilIfEmpty
            if let coordinates {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].openings[location.childIndex]
                    .coordinates = coordinates
            }
            return .success(venue)
        case .amenity:
            guard let location = unitChildLocation(id: id, in: venue, children: \.amenities) else { return .notFound }
            guard addressID == nil || venue.address?.id == addressID else { return .notFound }
            if let name {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex]
                    .amenities[location.childIndex].name = name.isEmpty ? nil : name
            }
            if let category = category(AmenityCategory.self, from: categoryValue) {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex]
                    .amenities[location.childIndex].category = category
            }
            venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex].amenities[location.childIndex].alternateName = alternateName?.nilIfEmpty
            venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex].amenities[location.childIndex].accessibility = accessibility?.nilIfEmpty
            venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex].amenities[location.childIndex].hours = hours?.nilIfEmpty
            venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex].amenities[location.childIndex].phone = phone?.nilIfEmpty
            venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex].amenities[location.childIndex].website = URL(string: website ?? "")
            venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex].amenities[location.childIndex].correlationID = correlationID?.nilIfEmpty
            venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex].amenities[location.childIndex].addressID = addressID
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
            guard addressID == nil || venue.address?.id == addressID else { return .notFound }
            if let name, !name.isEmpty {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex]
                    .occupants[location.childIndex].name = name
            }
            if let category = category(OccupantCategory.self, from: categoryValue) {
                venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex]
                    .occupants[location.childIndex].category = category
            }
            venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex].occupants[location.childIndex].alternateName = alternateName?.nilIfEmpty
            venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex].occupants[location.childIndex].hours = hours?.nilIfEmpty
            venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex].occupants[location.childIndex].phone = phone?.nilIfEmpty
            venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex].occupants[location.childIndex].website = URL(string: website ?? "")
            venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex].occupants[location.childIndex].restriction = restriction?.nilIfEmpty
            venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex].occupants[location.childIndex].correlationID = correlationID?.nilIfEmpty
            venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex].occupants[location.childIndex].addressID = addressID
            guard anchorIDs.count <= 1,
                  anchorIDs.allSatisfy({ anchorID in
                      venue.buildings[location.buildingIndex].levels[location.levelIndex]
                          .units[location.unitIndex].anchors.contains { $0.id == anchorID }
                  }) else { return .notFound }
            venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex]
                .occupants[location.childIndex].anchorID = anchorIDs.first
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
            guard anchorIDs.allSatisfy({ anchorExists($0, in: venue) }) else { return .notFound }
            venue.buildings[location.buildingIndex].levels[location.levelIndex].fixtures[location.childIndex]
                .anchorIDs = anchorIDs
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
            guard anchorIDs.allSatisfy({ anchorExists($0, in: venue) }) else { return .notFound }
            venue.buildings[location.buildingIndex].levels[location.levelIndex].kiosks[location.childIndex]
                .anchorIDs = anchorIDs
            return .success(venue)
        case .relationship:
            guard let relationshipIndex = venue.relationships.firstIndex(where: { $0.id == id }),
                  let originID,
                  let destinationID,
                  originID != destinationID,
                  allFeatureIDs(in: venue).contains(originID),
                  allFeatureIDs(in: venue).contains(destinationID) else {
                return .notFound
            }
            if let category = category(RelationshipCategory.self, from: categoryValue) {
                venue.relationships[relationshipIndex].category = category
            }
            venue.relationships[relationshipIndex].originID = originID
            venue.relationships[relationshipIndex].destinationID = destinationID
            return .success(venue)
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

    private static func anchorExists(_ id: UUID, in venue: Venue) -> Bool {
        venue.buildings.contains { building in
            building.levels.contains { level in
                level.units.contains { unit in
                    unit.anchors.contains { $0.id == id }
                }
            }
        }
    }

    private static func allFeatureIDs(in venue: Venue) -> Set<UUID> {
        var ids: Set<UUID> = [venue.id]
        if let address = venue.address { ids.insert(address.id) }
        for building in venue.buildings {
            ids.insert(building.id)
            if let footprint = building.footprint { ids.insert(footprint.id) }
            for level in building.levels {
                ids.insert(level.id)
                for unit in level.units {
                    ids.insert(unit.id)
                    ids.formUnion(unit.anchors.map(\.id))
                    ids.formUnion(unit.amenities.map(\.id))
                    ids.formUnion(unit.occupants.map(\.id))
                }
                ids.formUnion(level.openings.map(\.id))
                ids.formUnion(level.details.map(\.id))
                ids.formUnion(level.fixtures.map(\.id))
                ids.formUnion(level.geofences.map(\.id))
                ids.formUnion(level.kiosks.map(\.id))
                ids.formUnion(level.sections.map(\.id))
            }
        }
        ids.formUnion(venue.relationships.map(\.id))
        return ids
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
