import Domain
import Foundation

/// A saved feature reduced to just what the map needs to draw it.
public struct MapEditorFeatureShape: Identifiable, Equatable, Sendable {
    public enum Geometry: Equatable, Sendable {
        case polygon([Coordinate])
        case line([Coordinate])
        case point(Coordinate)
    }

    public let id: UUID
    public let feature: IMDFAuthoringFeature
    public let title: String?
    public let geometry: Geometry
}

/// Flattens a venue's nested features into map-drawable shapes.
///
/// There's no level switcher yet, so every level's features are shown at once. `address`,
/// `occupant`, and `relationship` carry no geometry of their own and are never drawn.
public enum MapEditorFeatureShapeBuilder {
    public static func shapes(for venue: Venue?) -> [MapEditorFeatureShape] {
        guard let venue else { return [] }

        var shapes: [MapEditorFeatureShape] = []

        if !venue.coordinates.isEmpty {
            shapes.append(.init(id: venue.id, feature: .venue, title: venue.name, geometry: .polygon(venue.coordinates)))
        }

        for building in venue.buildings {
            if let footprint = building.footprint, !footprint.coordinates.isEmpty {
                shapes.append(
                    .init(id: footprint.id, feature: .footprint, title: building.name, geometry: .polygon(footprint.coordinates))
                )
            }

            for level in building.levels {
                shapes.append(contentsOf: Self.shapes(for: level))
            }
        }

        return shapes
    }

    private static func shapes(for level: Level) -> [MapEditorFeatureShape] {
        var shapes: [MapEditorFeatureShape] = []

        if !level.coordinates.isEmpty {
            shapes.append(.init(id: level.id, feature: .level, title: level.name, geometry: .polygon(level.coordinates)))
        }

        for unit in level.units {
            if !unit.coordinates.isEmpty {
                shapes.append(.init(id: unit.id, feature: .unit, title: unit.name, geometry: .polygon(unit.coordinates)))
            }

            for amenity in unit.amenities {
                if let coordinate = amenity.coordinate {
                    shapes.append(.init(id: amenity.id, feature: .amenity, title: amenity.name, geometry: .point(coordinate)))
                }
            }

            for anchor in unit.anchors {
                shapes.append(.init(id: anchor.id, feature: .anchor, title: nil, geometry: .point(anchor.coordinate)))
            }
        }

        for opening in level.openings where !opening.coordinates.isEmpty {
            shapes.append(.init(id: opening.id, feature: .opening, title: nil, geometry: .line(opening.coordinates)))
        }

        for detail in level.details where !detail.coordinates.isEmpty {
            shapes.append(.init(id: detail.id, feature: .detail, title: detail.name, geometry: .line(detail.coordinates)))
        }

        for fixture in level.fixtures where !fixture.coordinates.isEmpty {
            shapes.append(.init(id: fixture.id, feature: .fixture, title: fixture.name, geometry: .polygon(fixture.coordinates)))
        }

        for geofence in level.geofences where !geofence.coordinates.isEmpty {
            shapes.append(
                .init(id: geofence.id, feature: .geofence, title: geofence.name, geometry: .polygon(geofence.coordinates))
            )
        }

        for kiosk in level.kiosks where !kiosk.coordinates.isEmpty {
            shapes.append(.init(id: kiosk.id, feature: .kiosk, title: kiosk.name, geometry: .polygon(kiosk.coordinates)))
        }

        for section in level.sections where !section.coordinates.isEmpty {
            shapes.append(.init(id: section.id, feature: .section, title: section.name, geometry: .polygon(section.coordinates)))
        }

        return shapes
    }
}
