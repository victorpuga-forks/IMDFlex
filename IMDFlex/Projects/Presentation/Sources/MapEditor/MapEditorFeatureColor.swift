import SwiftUI

/// Distinguishes feature types drawn on the map. Not a DesignSystem token since it's a
/// map-legend concern specific to the authoring editor, not a shared UI color.
enum MapEditorFeatureColor {
    static func color(for feature: IMDFAuthoringFeature) -> Color {
        switch feature {
        case .address: .gray
        case .venue: .indigo
        case .building: .brown
        case .footprint: .gray
        case .level: .blue
        case .unit: .teal
        case .opening: .orange
        case .amenity: .pink
        case .anchor: .red
        case .occupant: .pink
        case .detail: .purple
        case .fixture: .brown
        case .geofence: .yellow
        case .kiosk: .cyan
        case .relationship: .gray
        case .section: .mint
        }
    }
}
