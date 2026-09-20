import Domain

public enum MapEditorFeatureBuilderOutcome: Equatable {
    case success(Venue)
    case missingParent
    case unsupported

    /// `Venue` isn't `Equatable`, so a successful outcome only compares the venue's identity.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.missingParent, .missingParent), (.unsupported, .unsupported):
            true
        case (.success(let lhsVenue), .success(let rhsVenue)):
            lhsVenue.id == rhsVenue.id
        default:
            false
        }
    }
}

/// Turns a finished drawing draft into the right Domain entity and attaches it to the venue.
///
/// There is no UI yet to choose which building/level/unit a new child feature belongs to when
/// more than one exists, so every case always targets the first matching parent it finds.
/// `relationship` needs two arbitrary existing feature endpoints with no picker to choose them,
/// so it always reports `.unsupported`.
public enum MapEditorFeatureBuilder {
    public static func apply(
        feature: IMDFAuthoringFeature,
        draft: IMDFDrawingDraftResult,
        categoryValue: String?,
        name: String,
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
            applyFootprint(draft: draft, categoryValue: categoryValue, to: venue)
        case .level:
            applyLevel(draft: draft, categoryValue: categoryValue, name: name, to: venue)
        case .unit:
            applyUnit(draft: draft, categoryValue: categoryValue, name: name, to: venue)
        case .opening:
            applyOpening(draft: draft, categoryValue: categoryValue, to: venue)
        case .amenity:
            applyAmenity(draft: draft, categoryValue: categoryValue, name: name, to: venue)
        case .anchor:
            applyAnchor(draft: draft, to: venue)
        case .occupant:
            applyOccupant(categoryValue: categoryValue, name: name, to: venue)
        case .detail:
            applyDetail(draft: draft, name: name, to: venue)
        case .fixture:
            applyFixture(draft: draft, categoryValue: categoryValue, name: name, to: venue)
        case .geofence:
            applyGeofence(draft: draft, categoryValue: categoryValue, name: name, to: venue)
        case .kiosk:
            applyKiosk(draft: draft, name: name, to: venue)
        case .relationship:
            .unsupported
        case .section:
            applySection(draft: draft, categoryValue: categoryValue, name: name, to: venue)
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
        guard var venue else { return .missingParent }

        venue.address = Address(address: name.isEmpty ? nil : name)
        return .success(venue)
    }

    private static func applyBuilding(
        categoryValue: String?,
        name: String,
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue else { return .missingParent }

        let category = resolvedCategory(BuildingCategory.self, rawValue: categoryValue)
        venue.buildings.append(Building(name: name.isEmpty ? nil : name, category: category))
        return .success(venue)
    }

    private static func applyFootprint(
        draft: IMDFDrawingDraftResult,
        categoryValue: String?,
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue, let buildingIndex = firstBuildingIndex(venue) else { return .missingParent }

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
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue, let buildingIndex = firstBuildingIndex(venue) else { return .missingParent }

        let category = resolvedCategory(LevelCategory.self, rawValue: categoryValue)
        let nextOrdinal = (venue.buildings[buildingIndex].levels.map(\.ordinal).max() ?? -1) + 1
        let level = Level(
            name: name,
            category: category,
            ordinal: nextOrdinal,
            coordinates: coordinates(from: draft)
        )
        venue.buildings[buildingIndex].levels.append(level)
        return .success(venue)
    }

    private static func applyUnit(
        draft: IMDFDrawingDraftResult,
        categoryValue: String?,
        name: String,
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue, let location = firstLevelLocation(venue) else { return .missingParent }

        let category = resolvedCategory(UnitCategory.self, rawValue: categoryValue)
        let unit = Unit(name: name.isEmpty ? nil : name, category: category, coordinates: coordinates(from: draft))
        venue.buildings[location.buildingIndex].levels[location.levelIndex].units.append(unit)
        return .success(venue)
    }

    private static func applyOpening(
        draft: IMDFDrawingDraftResult,
        categoryValue: String?,
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue, let location = firstLevelLocation(venue) else { return .missingParent }

        let category = resolvedCategory(OpeningCategory.self, rawValue: categoryValue)
        let opening = Opening(category: category, coordinates: coordinates(from: draft))
        venue.buildings[location.buildingIndex].levels[location.levelIndex].openings.append(opening)
        return .success(venue)
    }

    private static func applyAmenity(
        draft: IMDFDrawingDraftResult,
        categoryValue: String?,
        name: String,
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue, let location = firstUnitLocation(venue) else { return .missingParent }

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
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue, let location = firstUnitLocation(venue), let coordinate = coordinates(from: draft).first else {
            return .missingParent
        }

        venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex]
            .anchors.append(Anchor(coordinate: coordinate))
        return .success(venue)
    }

    private static func applyOccupant(
        categoryValue: String?,
        name: String,
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue, let location = firstAnchorLocation(venue) else { return .missingParent }

        let category = categoryValue.flatMap(OccupantCategory.init(rawValue:))
        let anchorID = venue.buildings[location.buildingIndex].levels[location.levelIndex]
            .units[location.unitIndex].anchors[location.anchorIndex].id
        let occupant = Occupant(name: name, category: category, anchorID: anchorID)
        venue.buildings[location.buildingIndex].levels[location.levelIndex].units[location.unitIndex]
            .occupants.append(occupant)
        return .success(venue)
    }

    private static func applyDetail(
        draft: IMDFDrawingDraftResult,
        name: String,
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue, let location = firstLevelLocation(venue) else { return .missingParent }

        let detail = Detail(name: name.isEmpty ? nil : name, coordinates: coordinates(from: draft))
        venue.buildings[location.buildingIndex].levels[location.levelIndex].details.append(detail)
        return .success(venue)
    }

    private static func applyFixture(
        draft: IMDFDrawingDraftResult,
        categoryValue: String?,
        name: String,
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue, let location = firstLevelLocation(venue) else { return .missingParent }

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
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue, let location = firstLevelLocation(venue) else { return .missingParent }

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
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue, let location = firstLevelLocation(venue) else { return .missingParent }

        let kiosk = Kiosk(name: name.isEmpty ? nil : name, coordinates: coordinates(from: draft))
        venue.buildings[location.buildingIndex].levels[location.levelIndex].kiosks.append(kiosk)
        return .success(venue)
    }

    private static func applySection(
        draft: IMDFDrawingDraftResult,
        categoryValue: String?,
        name: String,
        to venue: Venue?
    ) -> MapEditorFeatureBuilderOutcome {
        guard var venue, let location = firstLevelLocation(venue) else { return .missingParent }

        let category = resolvedCategory(SectionCategory.self, rawValue: categoryValue)
        let section = Section(
            name: name.isEmpty ? nil : name,
            category: category,
            coordinates: coordinates(from: draft)
        )
        venue.buildings[location.buildingIndex].levels[location.levelIndex].sections.append(section)
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

    private static func firstBuildingIndex(_ venue: Venue) -> Int? {
        venue.buildings.indices.first
    }

    private static func firstLevelLocation(_ venue: Venue) -> (buildingIndex: Int, levelIndex: Int)? {
        for buildingIndex in venue.buildings.indices {
            if let levelIndex = venue.buildings[buildingIndex].levels.indices.first {
                return (buildingIndex, levelIndex)
            }
        }
        return nil
    }

    private static func firstUnitLocation(
        _ venue: Venue
    ) -> (buildingIndex: Int, levelIndex: Int, unitIndex: Int)? {
        for buildingIndex in venue.buildings.indices {
            for levelIndex in venue.buildings[buildingIndex].levels.indices {
                if let unitIndex = venue.buildings[buildingIndex].levels[levelIndex].units.indices.first {
                    return (buildingIndex, levelIndex, unitIndex)
                }
            }
        }
        return nil
    }

    private static func firstAnchorLocation(
        _ venue: Venue
    ) -> (buildingIndex: Int, levelIndex: Int, unitIndex: Int, anchorIndex: Int)? {
        for buildingIndex in venue.buildings.indices {
            for levelIndex in venue.buildings[buildingIndex].levels.indices {
                for unitIndex in venue.buildings[buildingIndex].levels[levelIndex].units.indices {
                    let anchors = venue.buildings[buildingIndex].levels[levelIndex].units[unitIndex].anchors
                    if let anchorIndex = anchors.indices.first {
                        return (buildingIndex, levelIndex, unitIndex, anchorIndex)
                    }
                }
            }
        }
        return nil
    }
}
