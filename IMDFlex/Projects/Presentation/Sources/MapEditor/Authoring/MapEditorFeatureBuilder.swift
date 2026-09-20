import Foundation
import Domain

public enum MapEditorFeatureBuilderOutcome: Equatable {
    case success(Venue)
    @available(*, deprecated, message: "Use missingReference(_:).")
    case missingParent
    case missingReference(IMDFAuthoringReference)
    case invalidRelationshipEndpoints
    case unsupported

    /// `Venue` isn't `Equatable`, so a successful outcome only compares the venue's identity.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.missingParent, .missingParent),
             (.invalidRelationshipEndpoints, .invalidRelationshipEndpoints),
             (.unsupported, .unsupported):
            true
        case (.missingReference(let lhs), .missingReference(let rhs)):
            lhs == rhs
        case (.success(let lhsVenue), .success(let rhsVenue)):
            lhsVenue.id == rhsVenue.id
        default:
            false
        }
    }
}

/// Turns a finished drawing draft into the right Domain entity and attaches it to the venue.
///
public struct IMDFAuthoringReferenceSelection: Equatable, Sendable {
    public var buildingID: UUID?
    public var levelID: UUID?
    public var unitID: UUID?
    public var anchorID: UUID?
    public var originID: UUID?
    public var destinationID: UUID?

    public init(
        buildingID: UUID? = nil,
        levelID: UUID? = nil,
        unitID: UUID? = nil,
        anchorID: UUID? = nil,
        originID: UUID? = nil,
        destinationID: UUID? = nil
    ) {
        self.buildingID = buildingID
        self.levelID = levelID
        self.unitID = unitID
        self.anchorID = anchorID
        self.originID = originID
        self.destinationID = destinationID
    }
}

public enum MapEditorFeatureBuilder {
    public static func apply(
        feature: IMDFAuthoringFeature,
        draft: IMDFDrawingDraftResult,
        categoryValue: String?,
        name: String,
        shortName: String = "",
        references: IMDFAuthoringReferenceSelection = .init(),
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        switch feature {
        case .address:
            applyAddress(name: name, to: venue)
        case .venue:
            applyVenue(draft: draft, categoryValue: categoryValue, name: name, to: venue)
        case .building:
            applyBuilding(categoryValue: categoryValue, name: name, to: venue)
        case .footprint:
            applyFootprint(draft: draft, categoryValue: categoryValue, references: references, to: venue)
        case .level:
            applyLevel(draft: draft, categoryValue: categoryValue, name: name, shortName: shortName, references: references, to: venue)
        case .unit:
            applyUnit(draft: draft, categoryValue: categoryValue, name: name, references: references, to: venue)
        case .opening:
            applyOpening(draft: draft, categoryValue: categoryValue, references: references, to: venue)
        case .amenity:
            applyAmenity(draft: draft, categoryValue: categoryValue, name: name, references: references, to: venue)
        case .anchor:
            applyAnchor(draft: draft, references: references, to: venue)
        case .occupant:
            applyOccupant(categoryValue: categoryValue, name: name, references: references, to: venue)
        case .detail:
            applyDetail(draft: draft, name: name, references: references, to: venue)
        case .fixture:
            applyFixture(draft: draft, categoryValue: categoryValue, name: name, references: references, to: venue)
        case .geofence:
            applyGeofence(draft: draft, categoryValue: categoryValue, name: name, references: references, to: venue)
        case .kiosk:
            applyKiosk(draft: draft, name: name, references: references, to: venue)
        case .relationship:
            applyRelationship(categoryValue: categoryValue, references: references, to: venue)
        case .section:
            applySection(draft: draft, categoryValue: categoryValue, name: name, references: references, to: venue)
        }
    }

    private static func applyVenue(
        draft: IMDFDrawingDraftResult,
        categoryValue: String?,
        name: String,
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        let category = resolvedCategory(VenueCategory.self, rawValue: categoryValue)
        let coordinates = coordinates(from: draft)

        guard var venue else {
            return .success(Venue(name: name, category: category, coordinates: coordinates))
        }

        venue.name = name
        venue.category = category
        venue.coordinates = coordinates
        return .success(venue)
    }

    private static func applyAddress(name: String, to venue: Venue?) -> MapEditorFeatureBuilderOutcome {
        guard var venue else { return .missingReference(.building) }

        venue.address = Address(address: name.isEmpty ? nil : name)
        return .success(venue)
    }

    private static func applyBuilding(
        categoryValue: String?,
        name: String,
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue else { return .missingReference(.building) }

        let category = resolvedCategory(BuildingCategory.self, rawValue: categoryValue)
        venue.buildings.append(Building(name: name.isEmpty ? nil : name, category: category))
        return .success(venue)
    }

    private static func applyFootprint(
        draft: IMDFDrawingDraftResult,
        categoryValue: String?,
        references: IMDFAuthoringReferenceSelection,
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue else { return .missingReference(.building) }
        guard let buildingID = references.buildingID,
              let buildingIndex = venue.buildings.firstIndex(where: { $0.id == buildingID }) else {
            return .missingReference(.building)
        }

        let category = resolvedCategory(FootprintCategory.self, rawValue: categoryValue)
        venue.buildings[buildingIndex].footprint = Footprint(
            category: category,
            coordinates: coordinates(from: draft)
        )
        return .success(venue)
    }

    private static func applyLevel(
        draft: IMDFDrawingDraftResult,
        categoryValue: String?,
        name: String,
        shortName: String,
        references: IMDFAuthoringReferenceSelection,
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue else { return .missingReference(.building) }
        guard let buildingID = references.buildingID,
              let buildingIndex = venue.buildings.firstIndex(where: { $0.id == buildingID }) else {
            return .missingReference(.building)
        }

        let category = resolvedCategory(LevelCategory.self, rawValue: categoryValue)
        let nextOrdinal = (venue.buildings[buildingIndex].levels.map(\.ordinal).max() ?? -1) + 1
        let level = Level(
            name: name,
            category: category,
            ordinal: nextOrdinal,
            shortName: shortName.isEmpty ? nil : shortName,
            coordinates: coordinates(from: draft)
        )
        venue.buildings[buildingIndex].levels.append(level)
        return .success(venue)
    }

    private static func applyUnit(
        draft: IMDFDrawingDraftResult,
        categoryValue: String?,
        name: String,
        references: IMDFAuthoringReferenceSelection,
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue else { return .missingReference(.level) }
        guard let levelID = references.levelID,
              let location = levelLocation(id: levelID, in: venue) else {
            return .missingReference(.level)
        }

        let category = resolvedCategory(UnitCategory.self, rawValue: categoryValue)
        let unit = Unit(name: name.isEmpty ? nil : name, category: category, coordinates: coordinates(from: draft))
        venue.buildings[location.buildingIndex].levels[location.levelIndex].units.append(unit)
        return .success(venue)
    }

    private static func applyOpening(
        draft: IMDFDrawingDraftResult,
        categoryValue: String?,
        references: IMDFAuthoringReferenceSelection,
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue else { return .missingReference(.level) }
        guard let levelID = references.levelID,
              let location = levelLocation(id: levelID, in: venue) else {
            return .missingReference(.level)
        }

        let category = resolvedCategory(OpeningCategory.self, rawValue: categoryValue)
        let opening = Opening(category: category, coordinates: coordinates(from: draft))
        venue.buildings[location.buildingIndex].levels[location.levelIndex].openings.append(opening)
        return .success(venue)
    }

    private static func applyAmenity(
        draft: IMDFDrawingDraftResult,
        categoryValue: String?,
        name: String,
        references: IMDFAuthoringReferenceSelection,
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue else { return .missingReference(.unit) }
        guard let unitID = references.unitID,
              let location = unitLocation(id: unitID, in: venue) else {
            return .missingReference(.unit)
        }

        let category = resolvedCategory(AmenityCategory.self, rawValue: categoryValue)
        let amenity = Amenity(
            name: name.isEmpty ? nil : name,
            category: category,
            coordinate: coordinates(from: draft).first
        )
        venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex]
            .amenities.append(amenity)
        return .success(venue)
    }

    private static func applyAnchor(
        draft: IMDFDrawingDraftResult,
        references: IMDFAuthoringReferenceSelection,
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue, let coordinate = coordinates(from: draft).first else {
            return .missingReference(.unit)
        }
        guard let unitID = references.unitID,
              let location = unitLocation(id: unitID, in: venue) else {
            return .missingReference(.unit)
        }

        venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex]
            .anchors.append(Anchor(coordinate: coordinate))
        return .success(venue)
    }

    private static func applyOccupant(
        categoryValue: String?,
        name: String,
        references: IMDFAuthoringReferenceSelection,
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue else { return .missingReference(.unit) }
        guard let unitID = references.unitID,
              let location = unitLocation(id: unitID, in: venue) else {
            return .missingReference(.unit)
        }
        guard let anchorID = references.anchorID,
              venue.buildings[location.buildingIndex].levels[location.levelIndex]
                .units[location.unitIndex].anchors.contains(where: { $0.id == anchorID }) else {
            return .missingReference(.anchor)
        }

        let category = categoryValue.flatMap(OccupantCategory.init(rawValue:))
        let occupant = Occupant(name: name, category: category, anchorID: anchorID)
        venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex]
            .occupants.append(occupant)
        return .success(venue)
    }

    private static func applyDetail(
        draft: IMDFDrawingDraftResult,
        name: String,
        references: IMDFAuthoringReferenceSelection,
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue else { return .missingReference(.level) }
        guard let levelID = references.levelID,
              let location = levelLocation(id: levelID, in: venue) else {
            return .missingReference(.level)
        }

        let detail = Detail(name: name.isEmpty ? nil : name, coordinates: coordinates(from: draft))
        venue.buildings[location.buildingIndex].levels[location.levelIndex].details.append(detail)
        return .success(venue)
    }

    private static func applyFixture(
        draft: IMDFDrawingDraftResult,
        categoryValue: String?,
        name: String,
        references: IMDFAuthoringReferenceSelection,
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue else { return .missingReference(.level) }
        guard let levelID = references.levelID,
              let location = levelLocation(id: levelID, in: venue) else {
            return .missingReference(.level)
        }

        let category = resolvedCategory(FixtureCategory.self, rawValue: categoryValue)
        let fixture = Fixture(
            name: name.isEmpty ? nil : name,
            category: category,
            coordinates: coordinates(from: draft)
        )
        venue.buildings[location.buildingIndex].levels[location.levelIndex].fixtures.append(fixture)
        return .success(venue)
    }

    private static func applyGeofence(
        draft: IMDFDrawingDraftResult,
        categoryValue: String?,
        name: String,
        references: IMDFAuthoringReferenceSelection,
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue else { return .missingReference(.level) }
        guard let levelID = references.levelID,
              let location = levelLocation(id: levelID, in: venue) else {
            return .missingReference(.level)
        }

        let category = resolvedCategory(GeofenceCategory.self, rawValue: categoryValue)
        let geofence = Geofence(
            name: name.isEmpty ? nil : name,
            category: category,
            coordinates: coordinates(from: draft)
        )
        venue.buildings[location.buildingIndex].levels[location.levelIndex].geofences.append(geofence)
        return .success(venue)
    }

    private static func applyKiosk(
        draft: IMDFDrawingDraftResult,
        name: String,
        references: IMDFAuthoringReferenceSelection,
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue else { return .missingReference(.level) }
        guard let levelID = references.levelID,
              let location = levelLocation(id: levelID, in: venue) else {
            return .missingReference(.level)
        }

        let kiosk = Kiosk(name: name.isEmpty ? nil : name, coordinates: coordinates(from: draft))
        venue.buildings[location.buildingIndex].levels[location.levelIndex].kiosks.append(kiosk)
        return .success(venue)
    }

    private static func applySection(
        draft: IMDFDrawingDraftResult,
        categoryValue: String?,
        name: String,
        references: IMDFAuthoringReferenceSelection,
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue else { return .missingReference(.level) }
        guard let levelID = references.levelID,
              let location = levelLocation(id: levelID, in: venue) else {
            return .missingReference(.level)
        }

        let category = resolvedCategory(SectionCategory.self, rawValue: categoryValue)
        let section = Section(
            name: name.isEmpty ? nil : name,
            category: category,
            coordinates: coordinates(from: draft)
        )
        venue.buildings[location.buildingIndex].levels[location.levelIndex].sections.append(section)
        return .success(venue)
    }

    private static func applyRelationship(
        categoryValue: String?,
        references: IMDFAuthoringReferenceSelection,
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue,
              let originID = references.originID,
              let destinationID = references.destinationID,
              originID != destinationID else {
            return .invalidRelationshipEndpoints
        }

        let featureIDs = allFeatureIDs(in: venue)
        guard featureIDs.contains(originID), featureIDs.contains(destinationID) else {
            return .invalidRelationshipEndpoints
        }

        let category = resolvedCategory(RelationshipCategory.self, rawValue: categoryValue)
        venue.relationships.append(
            Relationship(
                category: category,
                originID: originID,
                destinationID: destinationID
            )
        )
        return .success(venue)
    }

    private static func coordinates(from draft: IMDFDrawingDraftResult) -> [Coordinate] {
        draft.coordinates.map { Coordinate(latitude: $0.latitude, longitude: $0.longitude) }
    }

    private static func resolvedCategory<Category: RawRepresentable & CaseIterable>(
        _ type: Category.Type,
        rawValue: String?
    ) -> Category where Category.RawValue == String {
        rawValue.flatMap(Category.init(rawValue:)) ?? Category.allCases.first!
    }

    private static func levelLocation(
        id: UUID,
        in venue: Venue
    ) -> (buildingIndex: Int, levelIndex: Int)? {
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
                if let unitIndex = venue.buildings[buildingIndex].levels[levelIndex].units
                    .firstIndex(where: { $0.id == id }) {
                    return (buildingIndex, levelIndex, unitIndex)
                }
            }
        }
        return nil
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
        return ids
    }
}
