import Foundation
import Domain

/// Builds an IMDF archive from the app's project model.
public final class IMDFExporter: IMDFExporterProtocol, Sendable {
    public init() {}

    public func export(_ venue: Venue) async throws -> Data {
        let files = try IMDFArchiveBuilder(venue: venue).makeFiles()
        return try ZipArchiveWriter(files: files).makeArchive()
    }
}

private struct IMDFArchiveBuilder {
    let venue: Venue

    func makeFiles() throws -> [String: Data] {
        var files: [String: Data] = [:]

        files["manifest.json"] = try encode(manifest())
        files["address.geojson"] = try encode(collection(addressFeatures()))
        files["venue.geojson"] = try encode(collection([venueFeature()]))
        files["building.geojson"] = try encode(collection(buildingFeatures()))
        files["footprint.geojson"] = try encode(collection(footprintFeatures()))
        files["level.geojson"] = try encode(collection(levelFeatures()))
        files["unit.geojson"] = try encode(collection(unitFeatures()))
        files["anchor.geojson"] = try encode(collection(anchorFeatures()))
        files["opening.geojson"] = try encode(collection(openingFeatures()))
        files["amenity.geojson"] = try encode(collection(amenityFeatures()))
        files["occupant.geojson"] = try encode(collection(occupantFeatures()))
        files["detail.geojson"] = try encode(collection(detailFeatures()))
        files["fixture.geojson"] = try encode(collection(fixtureFeatures()))
        files["geofence.geojson"] = try encode(collection(geofenceFeatures()))
        files["kiosk.geojson"] = try encode(collection(kioskFeatures()))
        files["relationship.geojson"] = try encode(collection(relationshipFeatures()))
        files["section.geojson"] = try encode(collection(sectionFeatures()))

        return files
    }

    private func manifest() -> [String: Any] {
        [
            "version": "1.0.0"
        ]
    }

    private func collection(_ features: [[String: Any]]) -> [String: Any] {
        [
            "type": "FeatureCollection",
            "features": features
        ]
    }

    private func encode(_ object: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    }

    private func addressFeatures() -> [[String: Any]] {
        guard let address = venue.address else { return [] }

        return [
            feature(
                id: address.id,
                featureType: "address",
                geometry: NSNull(),
                properties: compact([
                    "address": address.address,
                    "locality": address.locality,
                    "province": address.province,
                    "country": address.country,
                    "postal_code": address.postalCode,
                    "postal_code_ext": address.postalCodeExtension,
                    "unit": address.unit
                ])
            )
        ]
    }

    private func venueFeature() -> [String: Any] {
        let coordinates = venueBoundaryCoordinates()

        return feature(
            id: venue.id,
            featureType: "venue",
            geometry: polygonGeometry(coordinates),
            properties: compact([
                "name": localized(venue.name),
                "category": venue.category.rawValue,
                "address_id": venue.address?.id.uuidString,
                "alt_name": localized(venue.alternateName),
                "display_point": displayPoint(venue.displayPoint, fallback: coordinates),
                "hours": venue.hours,
                "phone": venue.phone,
                "website": venue.website?.absoluteString,
                "restriction": venue.restriction
            ])
        )
    }

    private func buildingFeatures() -> [[String: Any]] {
        venue.buildings.map { building in
            feature(
                id: building.id,
                featureType: "building",
                geometry: NSNull(),
                properties: compact([
                    "category": building.category.rawValue,
                    "name": localized(building.name),
                    "alt_name": localized(building.alternateName),
                    "address_id": building.addressID?.uuidString ?? venue.address?.id.uuidString,
                    "restriction": building.restriction,
                    "venue_id": venue.id.uuidString,
                    "display_point": displayPoint(
                        building.displayPoint,
                        fallback: building.footprint?.coordinates ?? []
                    )
                ])
            )
        }
    }

    private func footprintFeatures() -> [[String: Any]] {
        venue.buildings.compactMap { building in
            guard let footprint = building.footprint else { return nil }

            return feature(
                id: footprint.id,
                featureType: "footprint",
                geometry: polygonGeometry(footprint.coordinates),
                properties: compact([
                    "category": footprint.category.rawValue,
                    "building_id": building.id.uuidString,
                    "name": localized(footprint.name)
                ])
            )
        }
    }

    private func levelFeatures() -> [[String: Any]] {
        venue.buildings.flatMap { building in
            building.levels.map { level in
                let coordinates = levelBoundaryCoordinates(for: level, building: building)

                return feature(
                    id: level.id,
                    featureType: "level",
                    geometry: polygonGeometry(coordinates),
                    properties: compact([
                        "category": level.category.rawValue,
                        "name": localized(level.name),
                        "alt_name": localized(level.alternateName),
                        "short_name": localized(level.shortName),
                        "ordinal": level.ordinal,
                        "address_id": level.addressID?.uuidString ?? venue.address?.id.uuidString,
                        "outdoor": level.outdoor,
                        "restriction": level.restriction,
                        "building_id": building.id.uuidString,
                        "display_point": displayPoint(level.displayPoint, fallback: coordinates)
                    ])
                )
            }
        }
    }

    private func unitFeatures() -> [[String: Any]] {
        venue.buildings.flatMap { building in
            building.levels.flatMap { level in
                level.units.map { unit in
                    feature(
                        id: unit.id,
                        featureType: "unit",
                        geometry: polygonGeometry(unit.coordinates),
                        properties: compact([
                            "category": unit.category.rawValue,
                            "name": localized(unit.name),
                            "alt_name": localized(unit.alternateName),
                            "accessibility": unit.accessibility,
                            "restriction": unit.restriction,
                            "level_id": level.id.uuidString,
                            "building_id": building.id.uuidString,
                            "display_point": displayPoint(unit.displayPoint, fallback: unit.coordinates)
                        ])
                    )
                }
            }
        }
    }

    private func openingFeatures() -> [[String: Any]] {
        venue.buildings.flatMap { building in
            building.levels.flatMap { level in
                level.openings.map { opening in
                    feature(
                        id: opening.id,
                        featureType: "opening",
                        geometry: lineGeometry(opening.coordinates),
                        properties: compact([
                            "category": opening.category.rawValue,
                            "name": localized(opening.name),
                            "alt_name": localized(opening.alternateName),
                            "access_control": opening.accessControl?.rawValue,
                            "accessibility": opening.accessibility,
                            "door": opening.door,
                            "level_id": level.id.uuidString,
                            "building_id": building.id.uuidString,
                            "display_point": displayPoint(opening.displayPoint, fallback: opening.coordinates)
                        ])
                    )
                }
            }
        }
    }

    private func anchorFeatures() -> [[String: Any]] {
        venue.buildings.flatMap { building in
            building.levels.flatMap { level in
                level.units.flatMap { unit in
                    unit.anchors.map { anchor in
                        feature(
                            id: anchor.id,
                            featureType: "anchor",
                            geometry: pointGeometry(anchor.coordinate),
                            properties: compact([
                                "unit_id": unit.id.uuidString,
                                "level_id": level.id.uuidString,
                                "building_id": building.id.uuidString,
                                "address_id": (anchor.addressID ?? venue.address?.id)?.uuidString
                            ])
                        )
                    }
                }
            }
        }
    }

    private func amenityFeatures() -> [[String: Any]] {
        venue.buildings.flatMap { building in
            building.levels.flatMap { level in
                level.units.flatMap { unit in
                    unit.amenities.map { amenity in
                        feature(
                            id: amenity.id,
                            featureType: "amenity",
                            geometry: pointGeometry(amenity.coordinate),
                            properties: compact([
                                "category": amenity.category.rawValue,
                                "name": localized(amenity.name),
                                "alt_name": localized(amenity.alternateName),
                                "accessibility": amenity.accessibility,
                                "address_id": amenity.addressID?.uuidString ?? venue.address?.id.uuidString,
                                "correlation_id": amenity.correlationID,
                                "hours": amenity.hours,
                                "phone": amenity.phone,
                                "website": amenity.website?.absoluteString,
                                "unit_id": unit.id.uuidString,
                                "level_id": level.id.uuidString,
                                "building_id": building.id.uuidString,
                                "display_point": displayPoint(amenity.displayPoint, fallback: [amenity.coordinate].compactMap { $0 })
                            ])
                        )
                    }
                }
            }
        }
    }

    private func occupantFeatures() -> [[String: Any]] {
        venue.buildings.flatMap { building in
            building.levels.flatMap { level in
                level.units.flatMap { unit in
                    unit.occupants.map { occupant in
                        feature(
                            id: occupant.id,
                            featureType: "occupant",
                            geometry: NSNull(),
                            properties: compact([
                                "name": localized(occupant.name),
                                "alt_name": localized(occupant.alternateName),
                                "address_id": occupant.addressID?.uuidString,
                                "correlation_id": occupant.correlationID,
                                "category": occupant.category?.rawValue,
                                "anchor_id": occupant.anchorID?.uuidString,
                                "phone": occupant.phone,
                                "website": occupant.website?.absoluteString,
                                "hours": occupant.hours,
                                "restriction": occupant.restriction,
                                "display_point": displayPoint(occupant.displayPoint, fallback: [])
                            ])
                        )
                    }
                }
            }
        }
    }

    private func detailFeatures() -> [[String: Any]] {
        venue.buildings.flatMap { building in
            building.levels.flatMap { level in
                level.details.map { detail in
                    feature(
                        id: detail.id,
                        featureType: "detail",
                        geometry: lineGeometry(detail.coordinates),
                        properties: compact([
                            "name": localized(detail.name),
                            "level_id": level.id.uuidString,
                            "building_id": building.id.uuidString
                        ])
                    )
                }
            }
        }
    }

    private func fixtureFeatures() -> [[String: Any]] {
        venue.buildings.flatMap { building in
            building.levels.flatMap { level in
                level.fixtures.map { fixture in
                    feature(
                        id: fixture.id,
                        featureType: "fixture",
                        geometry: polygonGeometry(fixture.coordinates),
                        properties: compact([
                            "category": fixture.category.rawValue,
                            "name": localized(fixture.name),
                            "level_id": level.id.uuidString,
                            "building_id": building.id.uuidString,
                            "anchor_ids": uuidStrings(fixture.anchorIDs),
                            "display_point": displayPoint(nil, fallback: fixture.coordinates)
                        ])
                    )
                }
            }
        }
    }

    private func geofenceFeatures() -> [[String: Any]] {
        venue.buildings.flatMap { building in
            building.levels.flatMap { level in
                level.geofences.map { geofence in
                    feature(
                        id: geofence.id,
                        featureType: "geofence",
                        geometry: polygonGeometry(geofence.coordinates),
                        properties: compact([
                            "category": geofence.category.rawValue,
                            "name": localized(geofence.name),
                            "level_id": level.id.uuidString,
                            "building_id": building.id.uuidString,
                            "display_point": displayPoint(nil, fallback: geofence.coordinates)
                        ])
                    )
                }
            }
        }
    }

    private func kioskFeatures() -> [[String: Any]] {
        venue.buildings.flatMap { building in
            building.levels.flatMap { level in
                level.kiosks.map { kiosk in
                    feature(
                        id: kiosk.id,
                        featureType: "kiosk",
                        geometry: polygonGeometry(kiosk.coordinates),
                        properties: compact([
                            "name": localized(kiosk.name),
                            "level_id": level.id.uuidString,
                            "building_id": building.id.uuidString,
                            "anchor_ids": uuidStrings(kiosk.anchorIDs),
                            "display_point": displayPoint(nil, fallback: kiosk.coordinates)
                        ])
                    )
                }
            }
        }
    }

    private func relationshipFeatures() -> [[String: Any]] {
        venue.relationships.map { relationship in
            feature(
                id: relationship.id,
                featureType: "relationship",
                geometry: NSNull(),
                properties: compact([
                    "category": relationship.category.rawValue,
                    "direction": relationship.direction?.rawValue,
                    "origin_id": relationship.originID.uuidString,
                    "destination_id": relationship.destinationID.uuidString
                ])
            )
        }
    }

    private func sectionFeatures() -> [[String: Any]] {
        venue.buildings.flatMap { building in
            building.levels.flatMap { level in
                level.sections.map { section in
                    feature(
                        id: section.id,
                        featureType: "section",
                        geometry: polygonGeometry(section.coordinates),
                        properties: compact([
                            "category": section.category.rawValue,
                            "name": localized(section.name),
                            "level_id": level.id.uuidString,
                            "building_id": building.id.uuidString,
                            "display_point": displayPoint(nil, fallback: section.coordinates)
                        ])
                    )
                }
            }
        }
    }

    private func feature(
        id: UUID,
        featureType: String,
        geometry: Any,
        properties: [String: Any]
    ) -> [String: Any] {
        [
            "id": id.uuidString,
            "type": "Feature",
            "feature_type": featureType,
            "geometry": geometry,
            "properties": properties
        ]
    }

    private func polygonGeometry(_ coordinates: [Coordinate]) -> [String: Any] {
        [
            "type": "Polygon",
            "coordinates": [closedRing(coordinates).map(position)]
        ]
    }

    private func lineGeometry(_ coordinates: [Coordinate]) -> [String: Any] {
        [
            "type": "LineString",
            "coordinates": coordinates.map(position)
        ]
    }

    private func pointGeometry(_ coordinate: Coordinate?) -> Any {
        guard let coordinate else { return NSNull() }
        return [
            "type": "Point",
            "coordinates": position(coordinate)
        ]
    }

    private func displayPoint(
        _ explicit: Coordinate?,
        fallback coordinates: [Coordinate]
    ) -> [String: Any]? {
        if let explicit {
            return [
                "type": "Point",
                "coordinates": position(explicit)
            ]
        }

        guard !coordinates.isEmpty else { return nil }
        let latitude = coordinates.map(\.latitude).reduce(0, +) / Double(coordinates.count)
        let longitude = coordinates.map(\.longitude).reduce(0, +) / Double(coordinates.count)

        return [
            "type": "Point",
            "coordinates": [longitude, latitude]
        ]
    }

    private func venueBoundaryCoordinates() -> [Coordinate] {
        if !venue.coordinates.isEmpty {
            return venue.coordinates
        }

        let footprintCoordinates = venue.buildings.compactMap(\.footprint).flatMap(\.coordinates)
        return enclosingRing(for: footprintCoordinates)
    }

    private func levelBoundaryCoordinates(for level: Level, building: Building) -> [Coordinate] {
        if !level.coordinates.isEmpty {
            return level.coordinates
        }

        return building.footprint?.coordinates ?? []
    }

    private func enclosingRing(for coordinates: [Coordinate]) -> [Coordinate] {
        guard let first = coordinates.first else { return [] }

        var minLatitude = first.latitude
        var maxLatitude = first.latitude
        var minLongitude = first.longitude
        var maxLongitude = first.longitude

        for coordinate in coordinates.dropFirst() {
            minLatitude = min(minLatitude, coordinate.latitude)
            maxLatitude = max(maxLatitude, coordinate.latitude)
            minLongitude = min(minLongitude, coordinate.longitude)
            maxLongitude = max(maxLongitude, coordinate.longitude)
        }

        return [
            Coordinate(latitude: minLatitude, longitude: minLongitude),
            Coordinate(latitude: minLatitude, longitude: maxLongitude),
            Coordinate(latitude: maxLatitude, longitude: maxLongitude),
            Coordinate(latitude: maxLatitude, longitude: minLongitude)
        ]
    }

    private func closedRing(_ coordinates: [Coordinate]) -> [Coordinate] {
        guard let first = coordinates.first, let last = coordinates.last else { return coordinates }
        guard first != last else { return coordinates }
        return coordinates + [first]
    }

    private func position(_ coordinate: Coordinate) -> [Double] {
        [coordinate.longitude, coordinate.latitude]
    }

    private func localized(_ value: String?) -> [String: String]? {
        guard let value, !value.isEmpty else { return nil }
        return ["ko": value]
    }

    private func uuidStrings(_ ids: [UUID]) -> [String]? {
        guard !ids.isEmpty else { return nil }
        return ids.map(\.uuidString)
    }

    private func compact(_ values: [String: Any?]) -> [String: Any] {
        values.reduce(into: [:]) { result, pair in
            if let value = pair.value {
                result[pair.key] = value
            }
        }
    }
}

private struct ZipArchiveWriter {
    let files: [String: Data]

    func makeArchive() throws -> Data {
        var archive = Data()
        var centralDirectory = Data()

        for (name, data) in files.sorted(by: { $0.key < $1.key }) {
            let offset = UInt32(archive.count)
            let nameData = Data(name.utf8)
            let checksum = CRC32.checksum(data)

            archive.appendUInt32LE(0x04034b50)
            archive.appendUInt16LE(20)
            archive.appendUInt16LE(0)
            archive.appendUInt16LE(0)
            archive.appendUInt16LE(0)
            archive.appendUInt16LE(0)
            archive.appendUInt32LE(checksum)
            archive.appendUInt32LE(UInt32(data.count))
            archive.appendUInt32LE(UInt32(data.count))
            archive.appendUInt16LE(UInt16(nameData.count))
            archive.appendUInt16LE(0)
            archive.append(nameData)
            archive.append(data)

            centralDirectory.appendUInt32LE(0x02014b50)
            centralDirectory.appendUInt16LE(20)
            centralDirectory.appendUInt16LE(20)
            centralDirectory.appendUInt16LE(0)
            centralDirectory.appendUInt16LE(0)
            centralDirectory.appendUInt16LE(0)
            centralDirectory.appendUInt16LE(0)
            centralDirectory.appendUInt32LE(checksum)
            centralDirectory.appendUInt32LE(UInt32(data.count))
            centralDirectory.appendUInt32LE(UInt32(data.count))
            centralDirectory.appendUInt16LE(UInt16(nameData.count))
            centralDirectory.appendUInt16LE(0)
            centralDirectory.appendUInt16LE(0)
            centralDirectory.appendUInt16LE(0)
            centralDirectory.appendUInt16LE(0)
            centralDirectory.appendUInt32LE(0)
            centralDirectory.appendUInt32LE(offset)
            centralDirectory.append(nameData)
        }

        let centralDirectoryOffset = UInt32(archive.count)
        archive.append(centralDirectory)

        archive.appendUInt32LE(0x06054b50)
        archive.appendUInt16LE(0)
        archive.appendUInt16LE(0)
        archive.appendUInt16LE(UInt16(files.count))
        archive.appendUInt16LE(UInt16(files.count))
        archive.appendUInt32LE(UInt32(centralDirectory.count))
        archive.appendUInt32LE(centralDirectoryOffset)
        archive.appendUInt16LE(0)

        return archive
    }
}

private enum CRC32 {
    static func checksum(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xffff_ffff

        for byte in data {
            crc ^= UInt32(byte)

            for _ in 0..<8 {
                if crc & 1 == 1 {
                    crc = (crc >> 1) ^ 0xedb8_8320
                } else {
                    crc >>= 1
                }
            }
        }

        return crc ^ 0xffff_ffff
    }
}

private extension Data {
    mutating func appendUInt16LE(_ value: UInt16) {
        append(UInt8(value & 0x00ff))
        append(UInt8((value >> 8) & 0x00ff))
    }

    mutating func appendUInt32LE(_ value: UInt32) {
        append(UInt8(value & 0x0000_00ff))
        append(UInt8((value >> 8) & 0x0000_00ff))
        append(UInt8((value >> 16) & 0x0000_00ff))
        append(UInt8((value >> 24) & 0x0000_00ff))
    }
}
