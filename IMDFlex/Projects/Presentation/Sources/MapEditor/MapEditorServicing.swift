import Foundation
import Domain

/// Map Editor's dependency boundary. The concrete Domain use case conforms
/// without exposing persistence details to Presentation.
public protocol MapEditorServicing: Sendable {
    func updateProject(_ project: IMDFProject) async throws
}

extension ProjectUseCase: MapEditorServicing {}
