import Foundation

/// A flat, ID-indexed representation of an IMDF authoring document.
///
/// Dictionaries are the source of truth for feature values. Ordered ID arrays
/// preserve authored order for the sidebar and deterministic export.
public struct IMDFDocument: Codable, Sendable {
    public var venue: Venue
    public var addressID: UUID?
    public var addresses: [UUID: Address]
    public var buildings: [UUID: IMDFBuildingRecord]
    public var footprints: [UUID: Footprint]
    public var levels: [UUID: IMDFLevelRecord]
    public var units: [UUID: IMDFUnitRecord]
    public var openings: [UUID: Opening]
    public var amenities: [UUID: Amenity]
    public var anchors: [UUID: Anchor]
    public var occupants: [UUID: Occupant]
    public var details: [UUID: Detail]
    public var fixtures: [UUID: Fixture]
    public var geofences: [UUID: Geofence]
    public var kiosks: [UUID: Kiosk]
    public var sections: [UUID: Section]
    public var relationships: [UUID: Relationship]

    public var buildingIDs: [UUID]
    public var venueIDByBuildingID: [UUID: UUID]
    public var footprintIDByBuildingID: [UUID: UUID]
    public var buildingIDByLevelID: [UUID: UUID]
    public var levelIDByUnitID: [UUID: UUID]
    public var levelIDByOpeningID: [UUID: UUID]
    public var levelIDByDetailID: [UUID: UUID]
    public var levelIDByFixtureID: [UUID: UUID]
    public var levelIDByGeofenceID: [UUID: UUID]
    public var levelIDByKioskID: [UUID: UUID]
    public var levelIDBySectionID: [UUID: UUID]
    public var unitIDByAnchorID: [UUID: UUID]
    public var unitIDByAmenityID: [UUID: UUID]
    public var unitIDByOccupantID: [UUID: UUID]
    public var levelIDsByBuildingID: [UUID: [UUID]]
    public var unitIDsByLevelID: [UUID: [UUID]]
    public var openingIDsByLevelID: [UUID: [UUID]]
    public var detailIDsByLevelID: [UUID: [UUID]]
    public var fixtureIDsByLevelID: [UUID: [UUID]]
    public var geofenceIDsByLevelID: [UUID: [UUID]]
    public var kioskIDsByLevelID: [UUID: [UUID]]
    public var sectionIDsByLevelID: [UUID: [UUID]]
    public var anchorIDsByUnitID: [UUID: [UUID]]
    public var amenityIDsByUnitID: [UUID: [UUID]]
    public var occupantIDsByUnitID: [UUID: [UUID]]
    public var relationshipIDs: [UUID]

    private enum CodingKeys: String, CodingKey {
        case addressID, venue
        case addresses, buildings, footprints, levels, units, openings, amenities, anchors
        case occupants, details, fixtures, geofences, kiosks, sections, relationships
        case buildingIDs, venueIDByBuildingID, footprintIDByBuildingID, buildingIDByLevelID
        case levelIDByUnitID, levelIDByOpeningID, levelIDByDetailID, levelIDByFixtureID
        case levelIDByGeofenceID, levelIDByKioskID, levelIDBySectionID, unitIDByAnchorID
        case unitIDByAmenityID, unitIDByOccupantID, levelIDsByBuildingID, unitIDsByLevelID
        case openingIDsByLevelID, detailIDsByLevelID, fixtureIDsByLevelID, geofenceIDsByLevelID
        case kioskIDsByLevelID, sectionIDsByLevelID, anchorIDsByUnitID, amenityIDsByUnitID
        case occupantIDsByUnitID, relationshipIDs
    }

    public init(
        venue: Venue,
        addressID: UUID?,
        addresses: [UUID: Address],
        buildings: [UUID: IMDFBuildingRecord],
        footprints: [UUID: Footprint],
        levels: [UUID: IMDFLevelRecord],
        units: [UUID: IMDFUnitRecord],
        openings: [UUID: Opening],
        amenities: [UUID: Amenity],
        anchors: [UUID: Anchor],
        occupants: [UUID: Occupant],
        details: [UUID: Detail],
        fixtures: [UUID: Fixture],
        geofences: [UUID: Geofence],
        kiosks: [UUID: Kiosk],
        sections: [UUID: Section],
        relationships: [UUID: Relationship],
        buildingIDs: [UUID],
        venueIDByBuildingID: [UUID: UUID],
        footprintIDByBuildingID: [UUID: UUID],
        buildingIDByLevelID: [UUID: UUID],
        levelIDByUnitID: [UUID: UUID],
        levelIDByOpeningID: [UUID: UUID],
        levelIDByDetailID: [UUID: UUID],
        levelIDByFixtureID: [UUID: UUID],
        levelIDByGeofenceID: [UUID: UUID],
        levelIDByKioskID: [UUID: UUID],
        levelIDBySectionID: [UUID: UUID],
        unitIDByAnchorID: [UUID: UUID],
        unitIDByAmenityID: [UUID: UUID],
        unitIDByOccupantID: [UUID: UUID],
        levelIDsByBuildingID: [UUID: [UUID]],
        unitIDsByLevelID: [UUID: [UUID]],
        openingIDsByLevelID: [UUID: [UUID]],
        detailIDsByLevelID: [UUID: [UUID]],
        fixtureIDsByLevelID: [UUID: [UUID]],
        geofenceIDsByLevelID: [UUID: [UUID]],
        kioskIDsByLevelID: [UUID: [UUID]],
        sectionIDsByLevelID: [UUID: [UUID]],
        anchorIDsByUnitID: [UUID: [UUID]],
        amenityIDsByUnitID: [UUID: [UUID]],
        occupantIDsByUnitID: [UUID: [UUID]],
        relationshipIDs: [UUID]
    ) {
        self.venue = venue
        self.addressID = addressID
        self.addresses = addresses
        self.buildings = buildings
        self.footprints = footprints
        self.levels = levels
        self.units = units
        self.openings = openings
        self.amenities = amenities
        self.anchors = anchors
        self.occupants = occupants
        self.details = details
        self.fixtures = fixtures
        self.geofences = geofences
        self.kiosks = kiosks
        self.sections = sections
        self.relationships = relationships
        self.buildingIDs = buildingIDs
        self.venueIDByBuildingID = venueIDByBuildingID
        self.footprintIDByBuildingID = footprintIDByBuildingID
        self.buildingIDByLevelID = buildingIDByLevelID
        self.levelIDByUnitID = levelIDByUnitID
        self.levelIDByOpeningID = levelIDByOpeningID
        self.levelIDByDetailID = levelIDByDetailID
        self.levelIDByFixtureID = levelIDByFixtureID
        self.levelIDByGeofenceID = levelIDByGeofenceID
        self.levelIDByKioskID = levelIDByKioskID
        self.levelIDBySectionID = levelIDBySectionID
        self.unitIDByAnchorID = unitIDByAnchorID
        self.unitIDByAmenityID = unitIDByAmenityID
        self.unitIDByOccupantID = unitIDByOccupantID
        self.levelIDsByBuildingID = levelIDsByBuildingID
        self.unitIDsByLevelID = unitIDsByLevelID
        self.openingIDsByLevelID = openingIDsByLevelID
        self.detailIDsByLevelID = detailIDsByLevelID
        self.fixtureIDsByLevelID = fixtureIDsByLevelID
        self.geofenceIDsByLevelID = geofenceIDsByLevelID
        self.kioskIDsByLevelID = kioskIDsByLevelID
        self.sectionIDsByLevelID = sectionIDsByLevelID
        self.anchorIDsByUnitID = anchorIDsByUnitID
        self.amenityIDsByUnitID = amenityIDsByUnitID
        self.occupantIDsByUnitID = occupantIDsByUnitID
        self.relationshipIDs = relationshipIDs
    }

    public init(venue: Venue) {
        var flatVenue = venue
        flatVenue.buildings = []
        flatVenue.address = nil
        flatVenue.relationships = []
        self.venue = flatVenue
        self.addressID = venue.address?.id
        self.addresses = venue.address.map { [$0.id: $0] } ?? [:]
        self.buildings = Dictionary(uniqueKeysWithValues: venue.buildings.map { building in
            (
                building.id,
                IMDFBuildingRecord(
                    id: building.id,
                    name: building.name,
                    category: building.category,
                    alternateName: building.alternateName,
                    displayPoint: building.displayPoint,
                    addressID: building.addressID,
                    restriction: building.restriction,
                    venueID: venue.id,
                    footprintID: building.footprint?.id,
                    levelIDs: building.levels.map(\.id)
                )
            )
        })
        self.footprints = Dictionary(
            uniqueKeysWithValues: venue.buildings.compactMap { building in
                building.footprint.map { ($0.id, $0) }
            }
        )
        self.levels = Dictionary(uniqueKeysWithValues: venue.buildings.flatMap { building in
            building.levels.map { level in
                (
                    level.id,
                    IMDFLevelRecord(
                        id: level.id,
                        name: level.name,
                        category: level.category,
                        ordinal: level.ordinal,
                        shortName: level.shortName,
                        coordinates: level.coordinates,
                        alternateName: level.alternateName,
                        displayPoint: level.displayPoint,
                        addressID: level.addressID,
                        outdoor: level.outdoor,
                        restriction: level.restriction,
                        buildingID: building.id,
                        unitIDs: level.units.map(\.id),
                        openingIDs: level.openings.map(\.id),
                        detailIDs: level.details.map(\.id),
                        fixtureIDs: level.fixtures.map(\.id),
                        geofenceIDs: level.geofences.map(\.id),
                        kioskIDs: level.kiosks.map(\.id),
                        sectionIDs: level.sections.map(\.id)
                    )
                )
            }
        })
        self.units = Dictionary(uniqueKeysWithValues: venue.buildings.flatMap(\.levels).flatMap { level in
            level.units.map { unit in
                (
                    unit.id,
                    IMDFUnitRecord(
                        id: unit.id,
                        name: unit.name,
                        category: unit.category,
                        coordinates: unit.coordinates,
                        alternateName: unit.alternateName,
                        displayPoint: unit.displayPoint,
                        accessibility: unit.accessibility,
                        restriction: unit.restriction,
                        levelID: level.id,
                        anchorIDs: unit.anchors.map(\.id),
                        amenityIDs: unit.amenities.map(\.id),
                        occupantIDs: unit.occupants.map(\.id)
                    )
                )
            }
        })
        self.openings = Dictionary(
            uniqueKeysWithValues: venue.buildings.flatMap(\.levels).flatMap(\.openings).map { ($0.id, $0) }
        )
        self.amenities = Dictionary(
            uniqueKeysWithValues: venue.buildings.flatMap(\.levels).flatMap(\.units).flatMap(\.amenities).map { ($0.id, $0) }
        )
        self.anchors = Dictionary(
            uniqueKeysWithValues: venue.buildings.flatMap(\.levels).flatMap(\.units).flatMap(\.anchors).map { ($0.id, $0) }
        )
        self.occupants = Dictionary(
            uniqueKeysWithValues: venue.buildings.flatMap(\.levels).flatMap(\.units).flatMap(\.occupants).map { ($0.id, $0) }
        )
        self.details = Dictionary(
            uniqueKeysWithValues: venue.buildings.flatMap(\.levels).flatMap(\.details).map { ($0.id, $0) }
        )
        self.fixtures = Dictionary(
            uniqueKeysWithValues: venue.buildings.flatMap(\.levels).flatMap(\.fixtures).map { ($0.id, $0) }
        )
        self.geofences = Dictionary(
            uniqueKeysWithValues: venue.buildings.flatMap(\.levels).flatMap(\.geofences).map { ($0.id, $0) }
        )
        self.kiosks = Dictionary(
            uniqueKeysWithValues: venue.buildings.flatMap(\.levels).flatMap(\.kiosks).map { ($0.id, $0) }
        )
        self.sections = Dictionary(
            uniqueKeysWithValues: venue.buildings.flatMap(\.levels).flatMap(\.sections).map { ($0.id, $0) }
        )
        self.relationships = Dictionary(uniqueKeysWithValues: venue.relationships.map { ($0.id, $0) })

        self.buildingIDs = venue.buildings.map(\.id)
        self.venueIDByBuildingID = Dictionary(
            uniqueKeysWithValues: venue.buildings.map { ($0.id, venue.id) }
        )
        self.footprintIDByBuildingID = Dictionary(
            uniqueKeysWithValues: venue.buildings.compactMap { building in
                building.footprint.map { (building.id, $0.id) }
            }
        )
        self.buildingIDByLevelID = Dictionary(
            uniqueKeysWithValues: venue.buildings.flatMap { building in
                building.levels.map { ($0.id, building.id) }
            }
        )
        self.levelIDByUnitID = Dictionary(
            uniqueKeysWithValues: venue.buildings.flatMap(\.levels).flatMap { level in
                level.units.map { ($0.id, level.id) }
            }
        )
        self.levelIDByOpeningID = Dictionary(
            uniqueKeysWithValues: venue.buildings.flatMap(\.levels).flatMap { level in
                level.openings.map { ($0.id, level.id) }
            }
        )
        self.levelIDByDetailID = Dictionary(
            uniqueKeysWithValues: venue.buildings.flatMap(\.levels).flatMap { level in
                level.details.map { ($0.id, level.id) }
            }
        )
        self.levelIDByFixtureID = Dictionary(
            uniqueKeysWithValues: venue.buildings.flatMap(\.levels).flatMap { level in
                level.fixtures.map { ($0.id, level.id) }
            }
        )
        self.levelIDByGeofenceID = Dictionary(
            uniqueKeysWithValues: venue.buildings.flatMap(\.levels).flatMap { level in
                level.geofences.map { ($0.id, level.id) }
            }
        )
        self.levelIDByKioskID = Dictionary(
            uniqueKeysWithValues: venue.buildings.flatMap(\.levels).flatMap { level in
                level.kiosks.map { ($0.id, level.id) }
            }
        )
        self.levelIDBySectionID = Dictionary(
            uniqueKeysWithValues: venue.buildings.flatMap(\.levels).flatMap { level in
                level.sections.map { ($0.id, level.id) }
            }
        )
        self.unitIDByAnchorID = Dictionary(
            uniqueKeysWithValues: venue.buildings.flatMap(\.levels).flatMap(\.units).flatMap { unit in
                unit.anchors.map { ($0.id, unit.id) }
            }
        )
        self.unitIDByAmenityID = Dictionary(
            uniqueKeysWithValues: venue.buildings.flatMap(\.levels).flatMap(\.units).flatMap { unit in
                unit.amenities.map { ($0.id, unit.id) }
            }
        )
        self.unitIDByOccupantID = Dictionary(
            uniqueKeysWithValues: venue.buildings.flatMap(\.levels).flatMap(\.units).flatMap { unit in
                unit.occupants.map { ($0.id, unit.id) }
            }
        )
        self.levelIDsByBuildingID = Dictionary(uniqueKeysWithValues: venue.buildings.map {
            ($0.id, $0.levels.map(\.id))
        })
        self.unitIDsByLevelID = Dictionary(uniqueKeysWithValues: venue.buildings.flatMap(\.levels).map {
            ($0.id, $0.units.map(\.id))
        })
        self.openingIDsByLevelID = Dictionary(uniqueKeysWithValues: venue.buildings.flatMap(\.levels).map {
            ($0.id, $0.openings.map(\.id))
        })
        self.detailIDsByLevelID = Dictionary(uniqueKeysWithValues: venue.buildings.flatMap(\.levels).map {
            ($0.id, $0.details.map(\.id))
        })
        self.fixtureIDsByLevelID = Dictionary(uniqueKeysWithValues: venue.buildings.flatMap(\.levels).map {
            ($0.id, $0.fixtures.map(\.id))
        })
        self.geofenceIDsByLevelID = Dictionary(uniqueKeysWithValues: venue.buildings.flatMap(\.levels).map {
            ($0.id, $0.geofences.map(\.id))
        })
        self.kioskIDsByLevelID = Dictionary(uniqueKeysWithValues: venue.buildings.flatMap(\.levels).map {
            ($0.id, $0.kiosks.map(\.id))
        })
        self.sectionIDsByLevelID = Dictionary(uniqueKeysWithValues: venue.buildings.flatMap(\.levels).map {
            ($0.id, $0.sections.map(\.id))
        })
        self.anchorIDsByUnitID = Dictionary(uniqueKeysWithValues: venue.buildings.flatMap(\.levels).flatMap(\.units).map {
            ($0.id, $0.anchors.map(\.id))
        })
        self.amenityIDsByUnitID = Dictionary(uniqueKeysWithValues: venue.buildings.flatMap(\.levels).flatMap(\.units).map {
            ($0.id, $0.amenities.map(\.id))
        })
        self.occupantIDsByUnitID = Dictionary(uniqueKeysWithValues: venue.buildings.flatMap(\.levels).flatMap(\.units).map {
            ($0.id, $0.occupants.map(\.id))
        })
        self.relationshipIDs = venue.relationships.map(\.id)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.venue = try container.decode(Venue.self, forKey: .venue)
        self.addressID = try container.decodeIfPresent(UUID.self, forKey: .addressID)
        self.addresses = try Self.decodeDictionary(Address.self, from: container, key: .addresses)
        self.buildings = try Self.decodeDictionary(IMDFBuildingRecord.self, from: container, key: .buildings)
        self.footprints = try Self.decodeDictionary(Footprint.self, from: container, key: .footprints)
        self.levels = try Self.decodeDictionary(IMDFLevelRecord.self, from: container, key: .levels)
        self.units = try Self.decodeDictionary(IMDFUnitRecord.self, from: container, key: .units)
        self.openings = try Self.decodeDictionary(Opening.self, from: container, key: .openings)
        self.amenities = try Self.decodeDictionary(Amenity.self, from: container, key: .amenities)
        self.anchors = try Self.decodeDictionary(Anchor.self, from: container, key: .anchors)
        self.occupants = try Self.decodeDictionary(Occupant.self, from: container, key: .occupants)
        self.details = try Self.decodeDictionary(Detail.self, from: container, key: .details)
        self.fixtures = try Self.decodeDictionary(Fixture.self, from: container, key: .fixtures)
        self.geofences = try Self.decodeDictionary(Geofence.self, from: container, key: .geofences)
        self.kiosks = try Self.decodeDictionary(Kiosk.self, from: container, key: .kiosks)
        self.sections = try Self.decodeDictionary(Section.self, from: container, key: .sections)
        self.relationships = try Self.decodeDictionary(Relationship.self, from: container, key: .relationships)
        self.buildingIDs = try container.decode([UUID].self, forKey: .buildingIDs)
        self.venueIDByBuildingID = try Self.decodeDictionary(UUID.self, from: container, key: .venueIDByBuildingID)
        self.footprintIDByBuildingID = try Self.decodeDictionary(UUID.self, from: container, key: .footprintIDByBuildingID)
        self.buildingIDByLevelID = try Self.decodeDictionary(UUID.self, from: container, key: .buildingIDByLevelID)
        self.levelIDByUnitID = try Self.decodeDictionary(UUID.self, from: container, key: .levelIDByUnitID)
        self.levelIDByOpeningID = try Self.decodeDictionary(UUID.self, from: container, key: .levelIDByOpeningID)
        self.levelIDByDetailID = try Self.decodeDictionary(UUID.self, from: container, key: .levelIDByDetailID)
        self.levelIDByFixtureID = try Self.decodeDictionary(UUID.self, from: container, key: .levelIDByFixtureID)
        self.levelIDByGeofenceID = try Self.decodeDictionary(UUID.self, from: container, key: .levelIDByGeofenceID)
        self.levelIDByKioskID = try Self.decodeDictionary(UUID.self, from: container, key: .levelIDByKioskID)
        self.levelIDBySectionID = try Self.decodeDictionary(UUID.self, from: container, key: .levelIDBySectionID)
        self.unitIDByAnchorID = try Self.decodeDictionary(UUID.self, from: container, key: .unitIDByAnchorID)
        self.unitIDByAmenityID = try Self.decodeDictionary(UUID.self, from: container, key: .unitIDByAmenityID)
        self.unitIDByOccupantID = try Self.decodeDictionary(UUID.self, from: container, key: .unitIDByOccupantID)
        self.levelIDsByBuildingID = try Self.decodeUUIDArrayDictionary(from: container, key: .levelIDsByBuildingID)
        self.unitIDsByLevelID = try Self.decodeUUIDArrayDictionary(from: container, key: .unitIDsByLevelID)
        self.openingIDsByLevelID = try Self.decodeUUIDArrayDictionary(from: container, key: .openingIDsByLevelID)
        self.detailIDsByLevelID = try Self.decodeUUIDArrayDictionary(from: container, key: .detailIDsByLevelID)
        self.fixtureIDsByLevelID = try Self.decodeUUIDArrayDictionary(from: container, key: .fixtureIDsByLevelID)
        self.geofenceIDsByLevelID = try Self.decodeUUIDArrayDictionary(from: container, key: .geofenceIDsByLevelID)
        self.kioskIDsByLevelID = try Self.decodeUUIDArrayDictionary(from: container, key: .kioskIDsByLevelID)
        self.sectionIDsByLevelID = try Self.decodeUUIDArrayDictionary(from: container, key: .sectionIDsByLevelID)
        self.anchorIDsByUnitID = try Self.decodeUUIDArrayDictionary(from: container, key: .anchorIDsByUnitID)
        self.amenityIDsByUnitID = try Self.decodeUUIDArrayDictionary(from: container, key: .amenityIDsByUnitID)
        self.occupantIDsByUnitID = try Self.decodeUUIDArrayDictionary(from: container, key: .occupantIDsByUnitID)
        self.relationshipIDs = try container.decode([UUID].self, forKey: .relationshipIDs)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(venue, forKey: .venue)
        try container.encodeIfPresent(addressID, forKey: .addressID)
        try Self.encodeDictionary(addresses, into: &container, key: .addresses)
        try Self.encodeDictionary(buildings, into: &container, key: .buildings)
        try Self.encodeDictionary(footprints, into: &container, key: .footprints)
        try Self.encodeDictionary(levels, into: &container, key: .levels)
        try Self.encodeDictionary(units, into: &container, key: .units)
        try Self.encodeDictionary(openings, into: &container, key: .openings)
        try Self.encodeDictionary(amenities, into: &container, key: .amenities)
        try Self.encodeDictionary(anchors, into: &container, key: .anchors)
        try Self.encodeDictionary(occupants, into: &container, key: .occupants)
        try Self.encodeDictionary(details, into: &container, key: .details)
        try Self.encodeDictionary(fixtures, into: &container, key: .fixtures)
        try Self.encodeDictionary(geofences, into: &container, key: .geofences)
        try Self.encodeDictionary(kiosks, into: &container, key: .kiosks)
        try Self.encodeDictionary(sections, into: &container, key: .sections)
        try Self.encodeDictionary(relationships, into: &container, key: .relationships)
        try container.encode(buildingIDs, forKey: .buildingIDs)
        try Self.encodeDictionary(venueIDByBuildingID, into: &container, key: .venueIDByBuildingID)
        try Self.encodeDictionary(footprintIDByBuildingID, into: &container, key: .footprintIDByBuildingID)
        try Self.encodeDictionary(buildingIDByLevelID, into: &container, key: .buildingIDByLevelID)
        try Self.encodeDictionary(levelIDByUnitID, into: &container, key: .levelIDByUnitID)
        try Self.encodeDictionary(levelIDByOpeningID, into: &container, key: .levelIDByOpeningID)
        try Self.encodeDictionary(levelIDByDetailID, into: &container, key: .levelIDByDetailID)
        try Self.encodeDictionary(levelIDByFixtureID, into: &container, key: .levelIDByFixtureID)
        try Self.encodeDictionary(levelIDByGeofenceID, into: &container, key: .levelIDByGeofenceID)
        try Self.encodeDictionary(levelIDByKioskID, into: &container, key: .levelIDByKioskID)
        try Self.encodeDictionary(levelIDBySectionID, into: &container, key: .levelIDBySectionID)
        try Self.encodeDictionary(unitIDByAnchorID, into: &container, key: .unitIDByAnchorID)
        try Self.encodeDictionary(unitIDByAmenityID, into: &container, key: .unitIDByAmenityID)
        try Self.encodeDictionary(unitIDByOccupantID, into: &container, key: .unitIDByOccupantID)
        try encodeUUIDArrayDictionary(levelIDsByBuildingID, into: &container, key: .levelIDsByBuildingID)
        try encodeUUIDArrayDictionary(unitIDsByLevelID, into: &container, key: .unitIDsByLevelID)
        try encodeUUIDArrayDictionary(openingIDsByLevelID, into: &container, key: .openingIDsByLevelID)
        try encodeUUIDArrayDictionary(detailIDsByLevelID, into: &container, key: .detailIDsByLevelID)
        try encodeUUIDArrayDictionary(fixtureIDsByLevelID, into: &container, key: .fixtureIDsByLevelID)
        try encodeUUIDArrayDictionary(geofenceIDsByLevelID, into: &container, key: .geofenceIDsByLevelID)
        try encodeUUIDArrayDictionary(kioskIDsByLevelID, into: &container, key: .kioskIDsByLevelID)
        try encodeUUIDArrayDictionary(sectionIDsByLevelID, into: &container, key: .sectionIDsByLevelID)
        try encodeUUIDArrayDictionary(anchorIDsByUnitID, into: &container, key: .anchorIDsByUnitID)
        try encodeUUIDArrayDictionary(amenityIDsByUnitID, into: &container, key: .amenityIDsByUnitID)
        try encodeUUIDArrayDictionary(occupantIDsByUnitID, into: &container, key: .occupantIDsByUnitID)
        try container.encode(relationshipIDs, forKey: .relationshipIDs)
    }

    private static func encodeDictionary<Value: Encodable, Key: CodingKey>(
        _ values: [UUID: Value],
        into container: inout KeyedEncodingContainer<Key>,
        key: Key
    ) throws {
        var object = container.nestedContainer(keyedBy: StringCodingKey.self, forKey: key)
        for (id, value) in values {
            try object.encode(value, forKey: StringCodingKey(id.uuidString))
        }
    }

    private static func decodeDictionary<Value: Decodable, Key: CodingKey>(
        _ type: Value.Type,
        from container: KeyedDecodingContainer<Key>,
        key: Key
    ) throws -> [UUID: Value] {
        do {
            let object = try container.nestedContainer(keyedBy: StringCodingKey.self, forKey: key)
            return try object.allKeys.reduce(into: [:]) { result, key in
                guard let id = UUID(uuidString: key.stringValue) else {
                    throw DecodingError.dataCorruptedError(
                        forKey: key,
                        in: object,
                        debugDescription: "Expected a UUID dictionary key."
                    )
                }
                result[id] = try object.decode(Value.self, forKey: key)
            }
        } catch DecodingError.typeMismatch {
            var values = try container.nestedUnkeyedContainer(forKey: key)
            var result: [UUID: Value] = [:]
            while !values.isAtEnd {
                let id = try values.decode(UUID.self)
                result[id] = try values.decode(Value.self)
            }
            return result
        }
    }

    private static func decodeUUIDArrayDictionary<Key: CodingKey>(
        from container: KeyedDecodingContainer<Key>,
        key: Key
    ) throws -> [UUID: [UUID]] {
        do {
            let object = try container.nestedContainer(keyedBy: StringCodingKey.self, forKey: key)
            return try object.allKeys.reduce(into: [:]) { result, key in
                guard let id = UUID(uuidString: key.stringValue) else {
                    throw DecodingError.dataCorruptedError(
                        forKey: key,
                        in: object,
                        debugDescription: "Expected a UUID dictionary key."
                    )
                }
                result[id] = try object.decode([UUID].self, forKey: key)
            }
        } catch DecodingError.typeMismatch {
            var values = try container.nestedUnkeyedContainer(forKey: key)
            var result: [UUID: [UUID]] = [:]
            while !values.isAtEnd {
                let id = try values.decode(UUID.self)
                result[id] = try values.decode([UUID].self)
            }
            return result
        }
    }

    private func encodeUUIDArrayDictionary<Key: CodingKey>(
        _ values: [UUID: [UUID]],
        into container: inout KeyedEncodingContainer<Key>,
        key: Key
    ) throws {
        var object = container.nestedContainer(keyedBy: StringCodingKey.self, forKey: key)
        for (id, children) in values {
            try object.encode(children, forKey: StringCodingKey(id.uuidString))
        }
    }
}

private struct StringCodingKey: CodingKey {
    let stringValue: String
    var intValue: Int? { nil }

    init(_ stringValue: String) { self.stringValue = stringValue }
    init?(stringValue: String) { self.init(stringValue) }
    init?(intValue: Int) { nil }
}

public extension IMDFDocument {
    func materializedVenue() -> Venue {
        var result = venue
        result.address = addressID.flatMap { addresses[$0] }
        result.relationships = relationshipIDs.compactMap { relationships[$0] }
        result.buildings = buildingIDs.compactMap { buildingID in
            guard let record = buildings[buildingID] else { return nil }
            let levels = record.levelIDs.compactMap { levelID -> Level? in
                guard let level = levels[levelID] else { return nil }
                let units = level.unitIDs.compactMap { unitID -> Unit? in
                    guard let unit = units[unitID] else { return nil }
                    return Unit(
                        id: unit.id,
                        name: unit.name,
                        category: unit.category,
                        coordinates: unit.coordinates,
                        anchors: unit.anchorIDs.compactMap { anchors[$0] },
                        amenities: unit.amenityIDs.compactMap { amenities[$0] },
                        occupants: unit.occupantIDs.compactMap { occupants[$0] },
                        alternateName: unit.alternateName,
                        displayPoint: unit.displayPoint,
                        accessibility: unit.accessibility,
                        restriction: unit.restriction
                    )
                }
                return Level(
                    id: level.id,
                    name: level.name,
                    category: level.category,
                    ordinal: level.ordinal,
                    shortName: level.shortName,
                    coordinates: level.coordinates,
                    units: units,
                    openings: level.openingIDs.compactMap { openings[$0] },
                    details: level.detailIDs.compactMap { details[$0] },
                    fixtures: level.fixtureIDs.compactMap { fixtures[$0] },
                    geofences: level.geofenceIDs.compactMap { geofences[$0] },
                    kiosks: level.kioskIDs.compactMap { kiosks[$0] },
                    sections: level.sectionIDs.compactMap { sections[$0] },
                    alternateName: level.alternateName,
                    displayPoint: level.displayPoint,
                    addressID: level.addressID,
                    outdoor: level.outdoor,
                    restriction: level.restriction
                )
            }
            return Building(
                id: record.id,
                name: record.name,
                category: record.category,
                levels: levels,
                footprint: record.footprintID.flatMap { footprints[$0] },
                alternateName: record.alternateName,
                displayPoint: record.displayPoint,
                addressID: record.addressID,
                restriction: record.restriction
            )
        }
        return result
    }

    public func featureExists(_ id: UUID) -> Bool {
        id == venue.id
            || addresses[id] != nil
            || buildings[id] != nil
            || footprints[id] != nil
            || levels[id] != nil
            || units[id] != nil
            || openings[id] != nil
            || amenities[id] != nil
            || anchors[id] != nil
            || occupants[id] != nil
            || details[id] != nil
            || fixtures[id] != nil
            || geofences[id] != nil
            || kiosks[id] != nil
            || sections[id] != nil
            || relationships[id] != nil
    }

    public func allFeatureIDs() -> Set<UUID> {
        Set(
            [venue.id]
                + Array(addresses.keys)
                + Array(buildings.keys)
                + Array(footprints.keys)
                + Array(levels.keys)
                + Array(units.keys)
                + Array(openings.keys)
                + Array(amenities.keys)
                + Array(anchors.keys)
                + Array(occupants.keys)
                + Array(details.keys)
                + Array(fixtures.keys)
                + Array(geofences.keys)
                + Array(kiosks.keys)
                + Array(sections.keys)
                + Array(relationships.keys)
        )
    }

    public func missingRelationshipEndpointIDs() -> Set<UUID> {
        Set(
            relationships.values.flatMap { relationship in
                [relationship.originID, relationship.destinationID]
                    .filter { !featureExists($0) }
            }
        )
    }
}

public extension Venue {
    init(document: IMDFDocument) {
    self = document.materializedVenue()
    }
}

public extension IMDFDocument {
    func building(forLevelID id: UUID) -> IMDFBuildingRecord? {
        guard let buildingID = buildingIDs.first(where: {
            levelIDsByBuildingID[$0]?.contains(id) == true
        }) else { return nil }
        return buildings[buildingID]
    }

    func level(forUnitID id: UUID) -> IMDFLevelRecord? {
        guard let levelID = unitIDsByLevelID.first(where: { $0.value.contains(id) })?.key else {
            return nil
        }
        return levels[levelID]
    }

    func relationshipsReferencing(_ id: UUID) -> [Relationship] {
        relationshipIDs.compactMap { relationships[$0] }.filter {
            $0.originID == id || $0.destinationID == id
        }
    }

    func addressReferences(_ id: UUID) -> [UUID] {
        var references: [UUID] = []
        references += buildings.values.filter { $0.addressID == id }.map(\.id)
        references += levels.values.filter { $0.addressID == id }.map(\.id)
        references += amenities.values.filter { $0.addressID == id }.map(\.id)
        references += anchors.values.filter { $0.addressID == id }.map(\.id)
        references += occupants.values.filter { $0.addressID == id }.map(\.id)
        return references
    }
}
