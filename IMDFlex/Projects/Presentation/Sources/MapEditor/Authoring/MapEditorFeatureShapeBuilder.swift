import Domain
import Foundation

/// A saved feature reduced to just what the map needs to draw it.
public struct MapEditorFeatureShape: Identifiable, Equatable, Sendable {
    public enum Geometry: Equatable, Sendable {
        case none
        case polygon([Coordinate])
        case line([Coordinate])
        case point(Coordinate)
    }

    public let id: UUID
    public let feature: IMDFAuthoringFeature
    public let title: String?
    public let geometry: Geometry
}

/// Flattens a venue's nested features into selectable feature descriptors.
///
/// Geometry-less features use `.none`; the sidebar can still select and edit them.
public enum MapEditorFeatureShapeBuilder {
    public static func shapes(for venue: Venue?) -> [MapEditorFeatureShape] {
        guard let venue else { return [] }

        var shapes: [MapEditorFeatureShape] = []

        shapes.append(
            .init(
                id: venue.id,
                feature: .venue,
                title: venue.name,
                geometry: venue.coordinates.isEmpty ? .none : .polygon(venue.coordinates)
            )
        )
        if let address = venue.address {
            shapes.append(.init(id: address.id, feature: .address, title: address.address, geometry: .none))
        }

        for building in venue.buildings {
            shapes.append(.init(id: building.id, feature: .building, title: building.name, geometry: .none))

            if let footprint = building.footprint {
                shapes.append(
                    .init(
                        id: footprint.id,
                        feature: .footprint,
                        title: footprint.name ?? building.name,
                        geometry: footprint.coordinates.isEmpty ? .none : .polygon(footprint.coordinates)
                    )
                )
            }

            for level in building.levels {
                shapes.append(contentsOf: Self.shapes(for: level))
            }
        }

        shapes.append(contentsOf: venue.relationships.map {
            MapEditorFeatureShape(id: $0.id, feature: .relationship, title: nil, geometry: .none)
        })

        return shapes
    }

    private static func shapes(for level: Level) -> [MapEditorFeatureShape] {
        var shapes: [MapEditorFeatureShape] = []

        shapes.append(
            .init(
                id: level.id,
                feature: .level,
                title: level.name,
                geometry: level.coordinates.isEmpty ? .none : .polygon(level.coordinates)
            )
        )

        for unit in level.units {
            shapes.append(
                .init(
                    id: unit.id,
                    feature: .unit,
                    title: unit.name,
                    geometry: unit.coordinates.isEmpty ? .none : .polygon(unit.coordinates)
                )
            )

            for amenity in unit.amenities {
                shapes.append(
                    .init(
                        id: amenity.id,
                        feature: .amenity,
                        title: amenity.name,
                        geometry: amenity.coordinate.map { .point($0) } ?? .none
                    )
                )
            }

            for anchor in unit.anchors {
                shapes.append(.init(id: anchor.id, feature: .anchor, title: nil, geometry: .point(anchor.coordinate)))
            }
            for occupant in unit.occupants {
                shapes.append(.init(id: occupant.id, feature: .occupant, title: occupant.name, geometry: .none))
            }
        }

        for opening in level.openings {
            shapes.append(
                .init(
                    id: opening.id,
                    feature: .opening,
                    title: opening.name,
                    geometry: opening.coordinates.isEmpty ? .none : .line(opening.coordinates)
                )
            )
        }

        for detail in level.details {
            shapes.append(
                .init(
                    id: detail.id,
                    feature: .detail,
                    title: detail.name,
                    geometry: detail.coordinates.isEmpty ? .none : .line(detail.coordinates)
                )
            )
        }

        for fixture in level.fixtures {
            shapes.append(
                .init(
                    id: fixture.id,
                    feature: .fixture,
                    title: fixture.name,
                    geometry: fixture.coordinates.isEmpty ? .none : .polygon(fixture.coordinates)
                )
            )
        }

        for geofence in level.geofences {
            shapes.append(
                .init(
                    id: geofence.id,
                    feature: .geofence,
                    title: geofence.name,
                    geometry: geofence.coordinates.isEmpty ? .none : .polygon(geofence.coordinates)
                )
            )
        }

        for kiosk in level.kiosks {
            shapes.append(
                .init(
                    id: kiosk.id,
                    feature: .kiosk,
                    title: kiosk.name,
                    geometry: kiosk.coordinates.isEmpty ? .none : .polygon(kiosk.coordinates)
                )
            )
        }

        for section in level.sections {
            shapes.append(
                .init(
                    id: section.id,
                    feature: .section,
                    title: section.name,
                    geometry: section.coordinates.isEmpty ? .none : .polygon(section.coordinates)
                )
            )
        }

        return shapes
    }
}
