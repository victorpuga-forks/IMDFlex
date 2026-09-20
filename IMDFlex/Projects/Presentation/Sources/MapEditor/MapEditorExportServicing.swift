import Domain
import Foundation

/// Map Editor's export dependency boundary. Composes the Domain preflight validator with the
/// Data-layer exporter without exposing either's concrete implementation to Presentation.
public protocol MapEditorExportServicing: Sendable {
    func preflight(_ venue: Venue) -> [IMDFPreflightIssue]
    func exportArchive(_ venue: Venue) async throws -> Data
}

public struct MapEditorExportService: MapEditorExportServicing {
    private let exporter: any IMDFExporterProtocol
    private let validator: any IMDFPreflightValidating

    public init(
        exporter: any IMDFExporterProtocol,
        validator: any IMDFPreflightValidating = IMDFPreflightValidator()
    ) {
        self.exporter = exporter
        self.validator = validator
    }

    public func preflight(_ venue: Venue) -> [IMDFPreflightIssue] {
        validator.validate(venue)
    }

    public func exportArchive(_ venue: Venue) async throws -> Data {
        try await exporter.export(venue)
    }
}
