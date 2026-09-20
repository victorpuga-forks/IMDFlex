import Foundation

public struct IMDFBuildingRecord: Codable, Sendable {
    public let id: UUID
    public var name: String?
    public var category: BuildingCategory
    public var alternateName: String?
    public var displayPoint: Coordinate?
    public var addressID: UUID?
    public var restriction: String?
    public var venueID: UUID
    public var footprintID: UUID?
    public var levelIDs: [UUID]

    public init(
        id: UUID,
        name: String?,
        category: BuildingCategory,
        alternateName: String?,
        displayPoint: Coordinate?,
        addressID: UUID?,
        restriction: String?,
        venueID: UUID,
        footprintID: UUID?,
        levelIDs: [UUID]
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.alternateName = alternateName
        self.displayPoint = displayPoint
        self.addressID = addressID
        self.restriction = restriction
        self.venueID = venueID
        self.footprintID = footprintID
        self.levelIDs = levelIDs
    }
}

public struct IMDFLevelRecord: Codable, Sendable {
    public let id: UUID
    public var name: String
    public var category: LevelCategory
    public var ordinal: Int
    public var shortName: String?
    public var coordinates: [Coordinate]
    public var alternateName: String?
    public var displayPoint: Coordinate?
    public var addressID: UUID?
    public var outdoor: Bool?
    public var restriction: String?
    public var buildingID: UUID
    public var unitIDs: [UUID]
    public var openingIDs: [UUID]
    public var detailIDs: [UUID]
    public var fixtureIDs: [UUID]
    public var geofenceIDs: [UUID]
    public var kioskIDs: [UUID]
    public var sectionIDs: [UUID]

    public init(
        id: UUID,
        name: String,
        category: LevelCategory,
        ordinal: Int,
        shortName: String?,
        coordinates: [Coordinate],
        alternateName: String?,
        displayPoint: Coordinate?,
        addressID: UUID?,
        outdoor: Bool?,
        restriction: String?,
        buildingID: UUID,
        unitIDs: [UUID],
        openingIDs: [UUID],
        detailIDs: [UUID],
        fixtureIDs: [UUID],
        geofenceIDs: [UUID],
        kioskIDs: [UUID],
        sectionIDs: [UUID]
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.ordinal = ordinal
        self.shortName = shortName
        self.coordinates = coordinates
        self.alternateName = alternateName
        self.displayPoint = displayPoint
        self.addressID = addressID
        self.outdoor = outdoor
        self.restriction = restriction
        self.buildingID = buildingID
        self.unitIDs = unitIDs
        self.openingIDs = openingIDs
        self.detailIDs = detailIDs
        self.fixtureIDs = fixtureIDs
        self.geofenceIDs = geofenceIDs
        self.kioskIDs = kioskIDs
        self.sectionIDs = sectionIDs
    }
}

public struct IMDFUnitRecord: Codable, Sendable {
    public let id: UUID
    public var name: String?
    public var category: UnitCategory
    public var coordinates: [Coordinate]
    public var alternateName: String?
    public var displayPoint: Coordinate?
    public var accessibility: String?
    public var restriction: String?
    public var levelID: UUID
    public var anchorIDs: [UUID]
    public var amenityIDs: [UUID]
    public var occupantIDs: [UUID]

    public init(
        id: UUID,
        name: String?,
        category: UnitCategory,
        coordinates: [Coordinate],
        alternateName: String?,
        displayPoint: Coordinate?,
        accessibility: String?,
        restriction: String?,
        levelID: UUID,
        anchorIDs: [UUID],
        amenityIDs: [UUID],
        occupantIDs: [UUID]
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.coordinates = coordinates
        self.alternateName = alternateName
        self.displayPoint = displayPoint
        self.accessibility = accessibility
        self.restriction = restriction
        self.levelID = levelID
        self.anchorIDs = anchorIDs
        self.amenityIDs = amenityIDs
        self.occupantIDs = occupantIDs
    }
}
