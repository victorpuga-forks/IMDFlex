import Domain
import Foundation

public struct IMDFAuthoringReferenceOption: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let feature: IMDFAuthoringFeature
    public let title: String
    public let context: String

    public init(id: UUID, feature: IMDFAuthoringFeature, title: String, context: String) {
        self.id = id
        self.feature = feature
        self.title = title
        self.context = context
    }
}

public enum IMDFAuthoringReferenceCatalog {
    public static func options(
        for reference: IMDFAuthoringReference,
        in venue: Venue?,
        excluding excludedID: UUID? = nil
    ) -> [IMDFAuthoringReferenceOption] {
        guard let venue else { return [] }

        switch reference {
        case .building:
            return venue.buildings.map {
                option(id: $0.id, feature: .building, title: $0.name, context: "Building")
            }
        case .level, .levelOrBuilding:
            let buildings = venue.buildings.flatMap { building in
                building.levels.map {
                    option(
                        id: $0.id,
                        feature: .level,
                        title: $0.name,
                        context: [$0.shortName, building.name].compactMap { $0 }.joined(separator: " · ")
                    )
                }
            }
            if reference == .levelOrBuilding {
                return venue.buildings.map {
                    option(id: $0.id, feature: .building, title: $0.name, context: "Building")
                } + buildings
            }
            return buildings
        case .unit:
            return venue.buildings.flatMap { building in
                building.levels.flatMap { level in
                    level.units.map {
                        option(
                            id: $0.id,
                            feature: .unit,
                            title: $0.name,
                            context: [level.name, building.name].compactMap { $0 }.joined(separator: " · ")
                        )
                    }
                }
            }
        case .anchor:
            return venue.buildings.flatMap { building in
                building.levels.flatMap { level in
                    level.units.flatMap { unit in
                        unit.anchors.map {
                            option(
                                id: $0.id,
                                feature: .anchor,
                                title: nil,
                                context: [unit.name, level.name, building.name]
                                    .compactMap { $0 }
                                    .joined(separator: " · ")
                            )
                        }
                    }
                }
            }
        case .relationshipEndpoints, .relationshipOrigin, .relationshipDestination:
            return allFeatures(in: venue).filter { $0.id != excludedID }
        }
    }

    private static func allFeatures(in venue: Venue) -> [IMDFAuthoringReferenceOption] {
        var options: [IMDFAuthoringReferenceOption] = [
            option(id: venue.id, feature: .venue, title: venue.name, context: "Venue")
        ]

        if let address = venue.address {
            options.append(option(id: address.id, feature: .address, title: address.address, context: "Address"))
        }

        for building in venue.buildings {
            options.append(option(id: building.id, feature: .building, title: building.name, context: "Building"))
            if let footprint = building.footprint {
                options.append(option(id: footprint.id, feature: .footprint, title: building.name, context: "Footprint"))
            }
            for level in building.levels {
                options.append(option(id: level.id, feature: .level, title: level.name, context: building.name ?? "Level"))
                options += level.units.flatMap { unit in
                    var values = [option(id: unit.id, feature: .unit, title: unit.name, context: level.name)]
                    values += unit.anchors.map {
                        option(id: $0.id, feature: .anchor, title: nil, context: unit.name ?? "Anchor")
                    }
                    values += unit.amenities.map {
                        option(id: $0.id, feature: .amenity, title: $0.name, context: unit.name ?? "Amenity")
                    }
                    values += unit.occupants.map {
                        option(id: $0.id, feature: .occupant, title: $0.name, context: unit.name ?? "Occupant")
                    }
                    return values
                }
                options += level.openings.map {
                    option(id: $0.id, feature: .opening, title: $0.name, context: level.name)
                }
                options += level.details.map {
                    option(id: $0.id, feature: .detail, title: $0.name, context: level.name)
                }
                options += level.fixtures.map {
                    option(id: $0.id, feature: .fixture, title: $0.name, context: level.name)
                }
                options += level.geofences.map {
                    option(id: $0.id, feature: .geofence, title: $0.name, context: level.name)
                }
                options += level.kiosks.map {
                    option(id: $0.id, feature: .kiosk, title: $0.name, context: level.name)
                }
                options += level.sections.map {
                    option(id: $0.id, feature: .section, title: $0.name, context: level.name)
                }
            }
        }
        return options
    }

    private static func option(
        id: UUID,
        feature: IMDFAuthoringFeature,
        title: String?,
        context: String
    ) -> IMDFAuthoringReferenceOption {
        IMDFAuthoringReferenceOption(
            id: id,
            feature: feature,
            title: title?.isEmpty == false ? (title ?? feature.title) : feature.title,
            context: context
        )
    }
}
