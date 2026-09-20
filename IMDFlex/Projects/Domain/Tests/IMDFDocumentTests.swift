import Domain
import XCTest

final class IMDFDocumentTests: XCTestCase {
    func test_whenVenueIsFlattened_thenFeaturesAreIndexedByStableIDsAndOrderIsPreserved() throws {
        // Given
        let anchor = Anchor(coordinate: Coordinate(latitude: 1, longitude: 2))
        let unit = Unit(id: UUID(), name: "Lobby", category: .lobby, anchors: [anchor])
        let level = Level(
            id: UUID(),
            name: "Level 1",
            ordinal: 1,
            units: [unit]
        )
        let footprint = Footprint(coordinates: [
            Coordinate(latitude: 1, longitude: 2),
            Coordinate(latitude: 2, longitude: 3),
            Coordinate(latitude: 3, longitude: 4)
        ])
        let building = Building(id: UUID(), name: "Main", levels: [level], footprint: footprint)
        let venue = Venue(
            id: UUID(),
            name: "Venue",
            category: .museum,
            buildings: [building]
        )

        // When
        let document = IMDFDocument(venue: venue)

        // Then
        XCTAssertNil(document.addressID)
        XCTAssertEqual(document.buildingIDs, [building.id])
        XCTAssertEqual(document.levelIDsByBuildingID[building.id], [level.id])
        XCTAssertEqual(document.unitIDsByLevelID[level.id], [unit.id])
        XCTAssertEqual(document.anchorIDsByUnitID[unit.id], [anchor.id])
        XCTAssertEqual(document.venueIDByBuildingID[building.id], venue.id)
        XCTAssertEqual(document.buildingIDByLevelID[level.id], building.id)
        XCTAssertEqual(document.levelIDByUnitID[unit.id], level.id)
        XCTAssertEqual(document.unitIDByAnchorID[anchor.id], unit.id)
        XCTAssertEqual(document.buildings[building.id]?.levelIDs, [level.id])
        XCTAssertEqual(document.buildings[building.id]?.footprintID, footprint.id)
        XCTAssertEqual(document.footprints[footprint.id]?.id, footprint.id)
    }

    func test_whenFlatDocumentIsMaterialized_thenNestedOwnershipAndReferencesAreRestored() throws {
        // Given
        let address = Address(address: "1 Main Street")
        let occupant = Occupant(name: "Shop", addressID: address.id)
        let unit = Unit(id: UUID(), name: "Lobby", category: .lobby, occupants: [occupant])
        let level = Level(id: UUID(), name: "Level 1", ordinal: 1, units: [unit], addressID: address.id)
        let building = Building(id: UUID(), name: "Main", levels: [level], addressID: address.id)
        let venue = Venue(
            name: "Venue",
            category: .museum,
            buildings: [building],
            address: address
        )

        // When
        let materialized = IMDFDocument(venue: venue).materializedVenue()

        // Then
        XCTAssertEqual(IMDFDocument(venue: venue).addressID, address.id)
        XCTAssertEqual(materialized.address?.id, address.id)
        XCTAssertEqual(materialized.buildings.first?.id, building.id)
        XCTAssertEqual(materialized.buildings.first?.levels.first?.id, level.id)
        XCTAssertEqual(materialized.buildings.first?.levels.first?.units.first?.occupants.first?.id, occupant.id)
        XCTAssertEqual(materialized.buildings.first?.addressID, address.id)
    }

    func test_whenDocumentLooksUpParentsAndRelationships_thenItUsesIDsInsteadOfNestedTraversal() {
        // Given
        let unit = Unit(category: .lobby)
        let level = Level(id: UUID(), name: "Level 1", ordinal: 1, units: [unit])
        let building = Building(name: "Main", levels: [level])
        let relationship = Relationship(
            category: .stairs,
            originID: unit.id,
            destinationID: level.id
        )
        let venue = Venue(
            name: "Venue",
            category: .museum,
            buildings: [building],
            relationships: [relationship]
        )
        let document = IMDFDocument(venue: venue)

        // When
        let parent = document.level(forUnitID: unit.id)
        let references = document.relationshipsReferencing(unit.id)

        // Then
        XCTAssertEqual(parent?.id, level.id)
        XCTAssertEqual(references.map(\.id), [relationship.id])
    }

    func test_whenProjectHasFlatDocument_thenJSONUsesObjectsAndDoesNotEncodeLegacyVenue() throws {
        // Given
        let venue = Venue(name: "Venue", category: .museum)
        let project = IMDFProject(name: "Project", venue: venue, document: IMDFDocument(venue: venue))
        let encoder = JSONEncoder()

        // When
        let object = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: encoder.encode(project)) as? [String: Any]
        )
        let document = try XCTUnwrap(object["document"] as? [String: Any])
        let addresses = try XCTUnwrap(document["addresses"] as? [String: Any])

        // Then
        XCTAssertNil(object["venue"])
        XCTAssertNotNil(addresses)
        XCTAssertFalse(document.keys.contains("buildings") && document["buildings"] is [[Any]])
    }

    func test_whenProjectWithFlatDocumentIsDecoded_thenLegacyVenueIsMaterializedForReaders() throws {
        // Given
        let address = Address(
            id: UUID(),
            address: "1 Main Street",
            locality: "Cupertino",
            country: "US"
        )
        let venue = Venue(
            name: "Venue",
            category: .museum,
            address: address
        )
        let project = IMDFProject(
            name: "Project",
            venue: venue,
            document: IMDFDocument(venue: venue)
        )
        let data = try JSONEncoder().encode(project)

        // When
        let decoded = try JSONDecoder().decode(IMDFProject.self, from: data)

        // Then
        XCTAssertEqual(decoded.document?.addressID, address.id)
        XCTAssertEqual(decoded.venue?.address?.id, address.id)
        XCTAssertEqual(decoded.venue?.name, venue.name)
    }

    func test_whenLegacyUUIDDictionaryArrayIsDecoded_thenProjectRemainsReadable() throws {
        // Given
        let projectID = UUID()
        let venueID = UUID()
        let addressID = UUID()
        let json = """
        {
          "id": "\(projectID.uuidString)",
          "name": "Legacy",
          "venue": {
            "id": "\(venueID.uuidString)",
            "name": "Venue",
            "category": "museum",
            "coordinates": [],
            "buildings": [],
            "address": null,
            "relationships": [],
            "alternateName": null,
            "displayPoint": null,
            "hours": null,
            "phone": null,
            "website": null,
            "restriction": null
          },
          "document": {
            "venue": {
              "id": "\(venueID.uuidString)",
              "name": "Venue",
              "category": "museum",
              "coordinates": [],
              "buildings": [],
              "address": null,
              "relationships": [],
              "alternateName": null,
              "displayPoint": null,
              "hours": null,
              "phone": null,
              "website": null,
              "restriction": null
            },
            "addresses": ["\(addressID.uuidString)", {"id": "\(addressID.uuidString)"}],
            "buildings": [], "footprints": [], "levels": [], "units": [],
            "openings": [], "amenities": [], "anchors": [], "occupants": [],
            "details": [], "fixtures": [], "geofences": [], "kiosks": [],
            "sections": [], "relationships": [],
            "buildingIDs": [],
            "venueIDByBuildingID": [], "footprintIDByBuildingID": [],
            "buildingIDByLevelID": [], "levelIDByUnitID": [],
            "levelIDByOpeningID": [], "levelIDByDetailID": [],
            "levelIDByFixtureID": [], "levelIDByGeofenceID": [],
            "levelIDByKioskID": [], "levelIDBySectionID": [],
            "unitIDByAnchorID": [], "unitIDByAmenityID": [],
            "unitIDByOccupantID": [],
            "levelIDsByBuildingID": [], "unitIDsByLevelID": [],
            "openingIDsByLevelID": [], "detailIDsByLevelID": [],
            "fixtureIDsByLevelID": [], "geofenceIDsByLevelID": [],
            "kioskIDsByLevelID": [], "sectionIDsByLevelID": [],
            "anchorIDsByUnitID": [], "amenityIDsByUnitID": [],
            "occupantIDsByUnitID": [], "relationshipIDs": []
          },
          "createdAt": 0,
          "updatedAt": 0
        }
        """

        // When
        let project = try JSONDecoder().decode(IMDFProject.self, from: Data(json.utf8))

        // Then
        XCTAssertEqual(project.document?.addresses[addressID]?.id, addressID)
    }
}
