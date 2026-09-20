import Foundation

public enum MapEditorAlert: Equatable, Sendable {
    case missingParent
    case unsupported
    case saveFailed
    case exportFailed
    case deletionBlocked([UUID])
}
