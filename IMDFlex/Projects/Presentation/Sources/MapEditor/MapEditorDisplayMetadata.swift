import DesignSystem
import Domain

extension IMDFAuthoringFeature {
    var title: String {
        switch self {
        case .address: MapEditorText.address
        case .venue: MapEditorText.venue
        case .building: MapEditorText.building
        case .footprint: MapEditorText.footprint
        case .level: MapEditorText.level
        case .unit: MapEditorText.unit
        case .opening: MapEditorText.opening
        case .amenity: MapEditorText.amenity
        case .anchor: MapEditorText.anchor
        case .occupant: MapEditorText.occupant
        case .detail: MapEditorText.detail
        case .fixture: MapEditorText.fixture
        case .geofence: MapEditorText.geofence
        case .kiosk: MapEditorText.kiosk
        case .relationship: MapEditorText.relationship
        case .section: MapEditorText.section
        }
    }

    var systemImage: String {
        MapEditorSymbol.feature(self)
    }
}

extension IMDFAuthoringGeometry {
    var title: String {
        switch self {
        case .point: MapEditorText.point
        case .line: MapEditorText.line
        case .polygon: MapEditorText.polygon
        case .form: MapEditorText.form
        }
    }

    var systemImage: String {
        MapEditorSymbol.geometry(self)
    }
}

extension MapEditorMode {
    var title: String {
        switch self {
        case .insert: MapEditorText.insertMode
        case .view: MapEditorText.viewMode
        }
    }
}

extension IMDFAuthoringReference {
    var title: String {
        switch self {
        case .building: MapEditorText.building
        case .level: MapEditorText.level
        case .unit: MapEditorText.unit
        case .anchor: MapEditorText.anchor
        case .levelOrBuilding: MapEditorText.levelOrBuilding
        case .relationshipEndpoints: MapEditorText.endpoints
        case .relationshipOrigin: MapEditorText.origin
        case .relationshipDestination: MapEditorText.destination
        }
    }
}

extension IMDFPreflightFeature {
    /// Preflight issues describe features with Domain's own feature enum; reusing the authoring
    /// feature's title keeps issue copy consistent with the sidebar/detail panel's naming.
    var title: String {
        authoringFeature.title
    }

    var systemImage: String {
        authoringFeature.systemImage
    }

    private var authoringFeature: IMDFAuthoringFeature {
        switch self {
        case .venue: .venue
        case .building: .building
        case .footprint: .footprint
        case .level: .level
        case .unit: .unit
        case .anchor: .anchor
        case .occupant: .occupant
        case .detail: .detail
        case .fixture: .fixture
        case .geofence: .geofence
        case .kiosk: .kiosk
        case .relationship: .relationship
        case .section: .section
        }
    }
}

extension IMDFPreflightSeverity {
    var title: String {
        switch self {
        case .error: MapEditorText.preflightError
        case .warning: MapEditorText.preflightWarning
        }
    }

    var badgeRole: IMDFStatusBadgeRole {
        switch self {
        case .error: .error
        case .warning: .warning
        }
    }
}
