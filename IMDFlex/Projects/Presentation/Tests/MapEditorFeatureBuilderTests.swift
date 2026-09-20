import XCTest
@testable import Presentation
import Domain

final class MapEditorFeatureBuilderTests: XCTestCase {
    func test_whenVenueFeatureIsFinishedWithNoExistingVenue_thenANewVenueIsCreated() throws {
        // Given
        let draft = makeDraft(geometry: .polygon, pointCount: 3)

        // When
        let outcome = MapEditorFeatureBuilder.apply(
            feature: .venue,
            draft: draft,
            categoryValue: VenueCategory.airport.rawValue,
            name: "Suwon Convention Center",
            to: nil
        )

        // Then
        let venue = try XCTUnwrap(outcome.venue)
        XCTAssertEqual(venue.name, "Suwon Convention Center")
        XCTAssertEqual(venue.category, .airport)
        XCTAssertEqual(venue.coordinates.count, 3)
    }

    func test_whenVenueFeatureIsFinishedWithAnExistingVenue_thenTheExistingVenueIsUpdatedInPlace() throws {
        // Given
        let existingBuilding = Building(name: "Terminal 1")
        let existingVenue = Venue(name: "Old Name", category: .hotel, buildings: [existingBuilding])
        let draft = makeDraft(geometry: .polygon, pointCount: 3)

        // When
        let outcome = MapEditorFeatureBuilder.apply(
            feature: .venue,
            draft: draft,
            categoryValue: VenueCategory.museum.rawValue,
            name: "New Name",
            to: existingVenue
        )

        // Then
        let venue = try XCTUnwrap(outcome.venue)
        XCTAssertEqual(venue.id, existingVenue.id)
        XCTAssertEqual(venue.name, "New Name")
        XCTAssertEqual(venue.category, .museum)
        XCTAssertEqual(venue.buildings.map(\.id), [existingBuilding.id])
    }

    func test_whenBuildingFeatureIsFinishedWithAnExistingVenue_thenABuildingIsAppended() throws {
        // Given
        let venue = Venue(name: "Venue", category: .airport)
        let draft = makeDraft(geometry: .form, pointCount: 0)

        // When
        let outcome = MapEditorFeatureBuilder.apply(
            feature: .building,
            draft: draft,
            categoryValue: BuildingCategory.transit.rawValue,
            name: "Terminal 1",
            to: venue
        )

        // Then
        let updatedVenue = try XCTUnwrap(outcome.venue)
        XCTAssertEqual(updatedVenue.buildings.count, 1)
        XCTAssertEqual(updatedVenue.buildings.first?.name, "Terminal 1")
        XCTAssertEqual(updatedVenue.buildings.first?.category, .transit)
    }

    func test_whenBuildingFeatureIsFinishedWithNoVenue_thenOutcomeIsMissingParent() {
        // Given
        let draft = makeDraft(geometry: .form, pointCount: 0)

        // When
        let outcome = MapEditorFeatureBuilder.apply(
            feature: .building,
            draft: draft,
            categoryValue: BuildingCategory.transit.rawValue,
            name: "Terminal 1",
            to: nil
        )

        // Then
        XCTAssertEqual(outcome, .missingParent)
    }

    func test_whenFootprintFeatureIsFinishedForABuildingWithAnExistingFootprint_thenTheFootprintIsReplaced() throws {
        // Given
        let oldFootprint = Footprint(category: .ground, coordinates: [Coordinate(latitude: 1, longitude: 1)])
        let building = Building(name: "Terminal 1", footprint: oldFootprint)
        let venue = Venue(name: "Venue", category: .airport, buildings: [building])
        let draft = makeDraft(geometry: .polygon, pointCount: 3)

        // When
        let outcome = MapEditorFeatureBuilder.apply(
            feature: .footprint,
            draft: draft,
            categoryValue: FootprintCategory.subterranean.rawValue,
            name: "",
            to: venue
        )

        // Then
        let updatedVenue = try XCTUnwrap(outcome.venue)
        let footprint = try XCTUnwrap(updatedVenue.buildings.first?.footprint)
        XCTAssertEqual(footprint.category, .subterranean)
        XCTAssertEqual(footprint.coordinates.count, 3)
    }

    func test_whenLevelFeatureIsFinishedForABuildingWithExistingLevels_thenOrdinalIncrementsFromTheMax() throws {
        // Given
        let existingLevels = [
            Level(name: "Ground", ordinal: 0),
            Level(name: "First", ordinal: 1)
        ]
        let building = Building(name: "Terminal 1", levels: existingLevels)
        let venue = Venue(name: "Venue", category: .airport, buildings: [building])
        let draft = makeDraft(geometry: .polygon, pointCount: 3)

        // When
        let outcome = MapEditorFeatureBuilder.apply(
            feature: .level,
            draft: draft,
            categoryValue: LevelCategory.parking.rawValue,
            name: "Parking Level",
            to: venue
        )

        // Then
        let updatedVenue = try XCTUnwrap(outcome.venue)
        let newLevel = try XCTUnwrap(updatedVenue.buildings.first?.levels.last)
        XCTAssertEqual(updatedVenue.buildings.first?.levels.count, 3)
        XCTAssertEqual(newLevel.name, "Parking Level")
        XCTAssertEqual(newLevel.ordinal, 2)
    }

    func test_whenLevelFeatureIsFinishedWithNoBuilding_thenOutcomeIsMissingParent() {
        // Given
        let venue = Venue(name: "Venue", category: .airport)
        let draft = makeDraft(geometry: .polygon, pointCount: 3)

        // When
        let outcome = MapEditorFeatureBuilder.apply(
            feature: .level,
            draft: draft,
            categoryValue: LevelCategory.parking.rawValue,
            name: "Level",
            to: venue
        )

        // Then
        XCTAssertEqual(outcome, .missingParent)
    }

    func test_whenAmenityFeatureIsFinishedForALevelWithAUnit_thenAmenityIsAppendedWithItsCoordinate() throws {
        // Given
        let unit = Unit(category: .lobby)
        let level = Level(name: "Ground", ordinal: 0, units: [unit])
        let building = Building(name: "Terminal 1", levels: [level])
        let venue = Venue(name: "Venue", category: .airport, buildings: [building])
        let draft = makeDraft(geometry: .point, pointCount: 1)

        // When
        let outcome = MapEditorFeatureBuilder.apply(
            feature: .amenity,
            draft: draft,
            categoryValue: AmenityCategory.atm.rawValue,
            name: "Lobby ATM",
            to: venue
        )

        // Then
        let updatedVenue = try XCTUnwrap(outcome.venue)
        let amenity = try XCTUnwrap(updatedVenue.buildings.first?.levels.first?.units.first?.amenities.first)
        XCTAssertEqual(amenity.name, "Lobby ATM")
        XCTAssertEqual(amenity.category, .atm)
        XCTAssertNotNil(amenity.coordinate)
    }

    func test_whenAnchorFeatureIsFinishedForALevelWithAUnit_thenAnchorIsAppended() throws {
        // Given
        let unit = Unit(category: .lobby)
        let level = Level(name: "Ground", ordinal: 0, units: [unit])
        let building = Building(name: "Terminal 1", levels: [level])
        let venue = Venue(name: "Venue", category: .airport, buildings: [building])
        let draft = makeDraft(geometry: .point, pointCount: 1)

        // When
        let outcome = MapEditorFeatureBuilder.apply(
            feature: .anchor,
            draft: draft,
            categoryValue: nil,
            name: "",
            to: venue
        )

        // Then
        let updatedVenue = try XCTUnwrap(outcome.venue)
        XCTAssertEqual(updatedVenue.buildings.first?.levels.first?.units.first?.anchors.count, 1)
    }

    func test_whenOccupantFeatureIsFinishedForAUnitWithAnAnchor_thenOccupantIsAppendedWiredToThatAnchor() throws {
        // Given
        let anchor = Anchor(coordinate: Coordinate(latitude: 37.5, longitude: 127.0))
        let unit = Unit(category: .foodService, anchors: [anchor])
        let level = Level(name: "Ground", ordinal: 0, units: [unit])
        let building = Building(name: "Terminal 1", levels: [level])
        let venue = Venue(name: "Venue", category: .airport, buildings: [building])
        let draft = makeDraft(geometry: .form, pointCount: 0)

        // When
        let outcome = MapEditorFeatureBuilder.apply(
            feature: .occupant,
            draft: draft,
            categoryValue: OccupantCategory.restaurant.rawValue,
            name: "Noodle Bar",
            to: venue
        )

        // Then
        let updatedVenue = try XCTUnwrap(outcome.venue)
        let occupant = try XCTUnwrap(updatedVenue.buildings.first?.levels.first?.units.first?.occupants.first)
        XCTAssertEqual(occupant.name, "Noodle Bar")
        XCTAssertEqual(occupant.category, .restaurant)
        XCTAssertEqual(occupant.anchorID, anchor.id)
    }

    func test_whenOccupantFeatureIsFinishedWithNoAnchorAnywhereInTheVenue_thenOutcomeIsMissingParent() {
        // Given
        let unit = Unit(category: .foodService)
        let level = Level(name: "Ground", ordinal: 0, units: [unit])
        let building = Building(name: "Terminal 1", levels: [level])
        let venue = Venue(name: "Venue", category: .airport, buildings: [building])
        let draft = makeDraft(geometry: .form, pointCount: 0)

        // When
        let outcome = MapEditorFeatureBuilder.apply(
            feature: .occupant,
            draft: draft,
            categoryValue: OccupantCategory.restaurant.rawValue,
            name: "Noodle Bar",
            to: venue
        )

        // Then
        XCTAssertEqual(outcome, .missingParent)
    }

    func test_whenUnitFeatureIsFinishedWithNoLevel_thenOutcomeIsMissingParent() {
        // Given
        let building = Building(name: "Terminal 1")
        let venue = Venue(name: "Venue", category: .airport, buildings: [building])
        let draft = makeDraft(geometry: .polygon, pointCount: 3)

        // When
        let outcome = MapEditorFeatureBuilder.apply(
            feature: .unit,
            draft: draft,
            categoryValue: UnitCategory.room.rawValue,
            name: "Room",
            to: venue
        )

        // Then
        XCTAssertEqual(outcome, .missingParent)
    }

    func test_whenRelationshipFeatureIsFinished_thenOutcomeIsUnsupported() {
        // Given
        let venue = Venue(name: "Venue", category: .airport)
        let draft = makeDraft(geometry: .form, pointCount: 0)

        // When
        let outcome = MapEditorFeatureBuilder.apply(
            feature: .relationship,
            draft: draft,
            categoryValue: RelationshipCategory.elevator.rawValue,
            name: "",
            to: venue
        )

        // Then
        XCTAssertEqual(outcome, .unsupported)
    }

    private func makeDraft(geometry: IMDFAuthoringGeometry, pointCount: Int) -> IMDFDrawingDraftResult {
        let coordinates = (0..<pointCount).map { index in
            IMDFDraftCoordinate(longitude: 127.0 + Double(index) * 0.001, latitude: 37.0 + Double(index) * 0.001)
        }
        return IMDFDrawingDraftResult(geometry: geometry, coordinates: coordinates)
    }
}

private extension MapEditorFeatureBuilderOutcome {
    var venue: Venue? {
        if case .success(let venue) = self {
            return venue
        }
        return nil
    }
}
