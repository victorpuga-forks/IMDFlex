import Domain

/// Maps each authoring feature to the raw category values a user can pick from,
/// sourced from the concrete Domain category enum for that feature.
enum MapEditorCategoryOptions {
    static func options(for feature: IMDFAuthoringFeature) -> [String] {
        switch feature {
        case .venue:
            VenueCategory.allCases.map(\.rawValue)
        case .building:
            BuildingCategory.allCases.map(\.rawValue)
        case .footprint:
            FootprintCategory.allCases.map(\.rawValue)
        case .level:
            LevelCategory.allCases.map(\.rawValue)
        case .unit:
            UnitCategory.allCases.map(\.rawValue)
        case .opening:
            OpeningCategory.allCases.map(\.rawValue)
        case .amenity:
            AmenityCategory.allCases.map(\.rawValue)
        case .occupant:
            OccupantCategory.allCases.map(\.rawValue)
        case .fixture:
            FixtureCategory.allCases.map(\.rawValue)
        case .geofence:
            GeofenceCategory.allCases.map(\.rawValue)
        case .relationship:
            RelationshipCategory.allCases.map(\.rawValue)
        case .section:
            SectionCategory.allCases.map(\.rawValue)
        case .address, .anchor, .detail, .kiosk:
            []
        }
    }
}
