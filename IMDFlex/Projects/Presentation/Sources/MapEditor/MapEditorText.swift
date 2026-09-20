import Foundation

enum MapEditorText {
    static let export = localized("mapEditor.action.export", defaultValue: "Export")
    static let settings = localized("mapEditor.action.settings", defaultValue: "Settings")
    static let editorActions = localized("mapEditor.accessibility.editorActions", defaultValue: "Editor actions")
    static let geometry = localized("mapEditor.inspector.geometry", defaultValue: "Geometry")
    static let draftPoints = localized("mapEditor.inspector.draftPoints", defaultValue: "Draft points")
    static let status = localized("mapEditor.inspector.status", defaultValue: "Status")
    static let ready = localized("mapEditor.status.ready", defaultValue: "Ready")
    static let draft = localized("mapEditor.status.draft", defaultValue: "Draft")
    static let requirements = localized("mapEditor.inspector.requirements", defaultValue: "Requirements")
    static let category = localized("mapEditor.requirement.category", defaultValue: "Category")
    static let references = localized("mapEditor.requirement.references", defaultValue: "References")
    static let none = localized("mapEditor.requirement.none", defaultValue: "None")
    static let linked = localized("mapEditor.requirement.linked", defaultValue: "Linked")
    static let selectReference = localized("mapEditor.requirement.selectReference", defaultValue: "Select")
    static let removePoint = localized("mapEditor.action.removePoint", defaultValue: "Remove point")
    static let cancelDraft = localized("mapEditor.action.cancelDraft", defaultValue: "Cancel draft")
    static let finishDraft = localized("mapEditor.action.finishDraft", defaultValue: "Finish draft")
    static let name = localized("mapEditor.inspector.name", defaultValue: "Name")
    static let namePlaceholder = localized("mapEditor.inspector.namePlaceholder", defaultValue: "Enter a name")
    static let shortName = localized("mapEditor.inspector.shortName", defaultValue: "Short Name")
    static let shortNamePlaceholder = localized(
        "mapEditor.inspector.shortNamePlaceholder",
        defaultValue: "e.g. L1"
    )
    static let saved = localized("mapEditor.inspector.saved", defaultValue: "Saved")

    static let mode = localized("mapEditor.accessibility.mode", defaultValue: "Editor mode")
    static let alternateName = localized("mapEditor.field.alternateName", defaultValue: "Alternate name")
    static let accessibility = localized("mapEditor.field.accessibility", defaultValue: "Accessibility")
    static let hours = localized("mapEditor.field.hours", defaultValue: "Hours")
    static let phone = localized("mapEditor.field.phone", defaultValue: "Phone")
    static let website = localized("mapEditor.field.website", defaultValue: "Website")
    static let restriction = localized("mapEditor.field.restriction", defaultValue: "Restriction")
    static let correlationID = localized("mapEditor.field.correlationID", defaultValue: "Correlation ID")
    static let insertMode = localized("mapEditor.mode.insert", defaultValue: "Insert")
    static let viewMode = localized("mapEditor.mode.view", defaultValue: "View")

    static let sidebarTitle = localized("mapEditor.sidebar.title", defaultValue: "Features")
    static let sidebarEmpty = localized("mapEditor.sidebar.empty", defaultValue: "No features yet")

    static let save = localized("mapEditor.action.save", defaultValue: "Save")
    static let nothingToEdit = localized(
        "mapEditor.detail.nothingToEdit",
        defaultValue: "Nothing to edit yet. Select a feature from the map or the list."
    )

    static let points = localized("mapEditor.points.title", defaultValue: "Points")
    static let addPoint = localized("mapEditor.points.addPoint", defaultValue: "Add point")
    static let addingPoint = localized("mapEditor.points.addingPoint", defaultValue: "Tap the map to add a point")
    static let advanced = localized("mapEditor.points.advanced", defaultValue: "Advanced")
    static let reorderPoints = localized("mapEditor.points.reorder", defaultValue: "Reorder points")
    static let moveUp = localized("mapEditor.points.moveUp", defaultValue: "Move up")
    static let moveDown = localized("mapEditor.points.moveDown", defaultValue: "Move down")

    private static let pointFormat = localized("mapEditor.points.pointFormat", defaultValue: "Point %1$lld")

    static func point(number: Int) -> String {
        String(format: pointFormat, locale: .current, number)
    }

    static let alertOK = localized("mapEditor.alert.ok", defaultValue: "OK")
    static let missingParentAlertTitle = localized(
        "mapEditor.alert.missingParent.title",
        defaultValue: "Add a parent feature first"
    )
    static let missingParentAlertMessage = localized(
        "mapEditor.alert.missingParent.message",
        defaultValue: "This feature needs another feature to exist first. Check the References requirement above, add that feature, then finish this draft again."
    )
    static let unsupportedAlertTitle = localized("mapEditor.alert.unsupported.title", defaultValue: "Not supported yet")
    static let unsupportedAlertMessage = localized(
        "mapEditor.alert.unsupported.message",
        defaultValue: "This feature type can't be finished from the map editor yet."
    )
    static let saveFailedAlertTitle = localized("mapEditor.alert.saveFailed.title", defaultValue: "Couldn't save")
    static let saveFailedAlertMessage = localized(
        "mapEditor.alert.saveFailed.message",
        defaultValue: "Your change couldn't be saved. Try again."
    )
    static let exportFailedAlertTitle = localized("mapEditor.alert.exportFailed.title", defaultValue: "Couldn't export")
    static let exportFailedAlertMessage = localized(
        "mapEditor.alert.exportFailed.message",
        defaultValue: "Your IMDF archive couldn't be generated. Try again."
    )

    static let preflightTitle = localized("mapEditor.preflight.title", defaultValue: "Preflight Check")
    static let preflightAllClear = localized("mapEditor.preflight.allClear", defaultValue: "No issues found")
    static let preflightBlockedMessage = localized(
        "mapEditor.preflight.blockedMessage",
        defaultValue: "Resolve the errors below before exporting."
    )
    static let preflightValidatorHint = localized(
        "mapEditor.preflight.validatorHint",
        defaultValue: "After exporting, verify imdf.zip with Apple's IMDF Validator before submission."
    )
    static let preflightExport = localized("mapEditor.preflight.export", defaultValue: "Export imdf.zip")
    static let preflightClose = localized("mapEditor.preflight.close", defaultValue: "Close")
    static let preflightError = localized("mapEditor.preflight.error", defaultValue: "Error")
    static let preflightWarning = localized("mapEditor.preflight.warning", defaultValue: "Warning")

    static let address = localized("mapEditor.feature.address", defaultValue: "Address")
    static let venue = localized("mapEditor.feature.venue", defaultValue: "Venue")
    static let building = localized("mapEditor.feature.building", defaultValue: "Building")
    static let footprint = localized("mapEditor.feature.footprint", defaultValue: "Footprint")
    static let level = localized("mapEditor.feature.level", defaultValue: "Level")
    static let unit = localized("mapEditor.feature.unit", defaultValue: "Unit")
    static let opening = localized("mapEditor.feature.opening", defaultValue: "Opening")
    static let amenity = localized("mapEditor.feature.amenity", defaultValue: "Amenity")
    static let anchor = localized("mapEditor.feature.anchor", defaultValue: "Anchor")
    static let occupant = localized("mapEditor.feature.occupant", defaultValue: "Occupant")
    static let detail = localized("mapEditor.feature.detail", defaultValue: "Detail")
    static let fixture = localized("mapEditor.feature.fixture", defaultValue: "Fixture")
    static let geofence = localized("mapEditor.feature.geofence", defaultValue: "Geofence")
    static let kiosk = localized("mapEditor.feature.kiosk", defaultValue: "Kiosk")
    static let relationship = localized("mapEditor.feature.relationship", defaultValue: "Relationship")
    static let section = localized("mapEditor.feature.section", defaultValue: "Section")

    static let point = localized("mapEditor.geometry.point", defaultValue: "Point")
    static let line = localized("mapEditor.geometry.line", defaultValue: "Line")
    static let polygon = localized("mapEditor.geometry.polygon", defaultValue: "Polygon")
    static let form = localized("mapEditor.geometry.form", defaultValue: "Form")

    static let levelOrBuilding = localized("mapEditor.reference.levelOrBuilding", defaultValue: "Level or building")
    static let endpoints = localized("mapEditor.reference.endpoints", defaultValue: "Endpoints")
    static let origin = localized("mapEditor.reference.origin", defaultValue: "Origin")
    static let destination = localized("mapEditor.reference.destination", defaultValue: "Destination")

    private static let draftProgressFormat = localized(
        "mapEditor.draft.progressFormat",
        defaultValue: "%1$lld/%2$lld"
    )

    static func draftProgress(current: Int, required: Int) -> String {
        String(format: draftProgressFormat, locale: .current, current, required)
    }

    static func referenceList(_ references: [String]) -> String {
        references.formatted(.list(type: .and, width: .narrow))
    }

    static func alertTitle(for alert: MapEditorAlert) -> String {
        switch alert {
        case .missingParent: missingParentAlertTitle
        case .unsupported: unsupportedAlertTitle
        case .saveFailed: saveFailedAlertTitle
        case .exportFailed: exportFailedAlertTitle
        }
    }

    static func alertMessage(for alert: MapEditorAlert) -> String {
        switch alert {
        case .missingParent: missingParentAlertMessage
        case .unsupported: unsupportedAlertMessage
        case .saveFailed: saveFailedAlertMessage
        case .exportFailed: exportFailedAlertMessage
        }
    }

    private static func localized(
        _ key: StaticString,
        defaultValue: String.LocalizationValue
    ) -> String {
        String(
            localized: key,
            defaultValue: defaultValue,
            bundle: .imdfPresentation
        )
    }
}
