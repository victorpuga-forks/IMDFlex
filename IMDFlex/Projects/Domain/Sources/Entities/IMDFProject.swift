import Foundation

/// 앱 내 프로젝트 관리 모델
public struct IMDFProject: Identifiable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var venue: Venue?
    public var document: IMDFDocument?
    public var createdAt: Date
    public var updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id, name, venue, document, createdAt, updatedAt
    }
    
    public init(
        id: UUID = UUID(),
        name: String,
        venue: Venue? = nil,
        document: IMDFDocument? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.venue = venue
        self.document = document
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var currentDocument: IMDFDocument? {
        document ?? venue.map(IMDFDocument.init(venue:))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let legacyVenue = try container.decodeIfPresent(Venue.self, forKey: .venue)
        let decodedDocument = try Self.decodeDocumentIfPresent(from: container)
        document = decodedDocument
        // Keep the legacy in-memory API usable while persistence stores only the flat document.
        venue = decodedDocument?.materializedVenue() ?? legacyVenue
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    private static func decodeDocumentIfPresent(
        from container: KeyedDecodingContainer<CodingKeys>
    ) throws -> IMDFDocument? {
        guard container.contains(.document) else { return nil }
        do {
            return try container.decode(IMDFDocument.self, forKey: .document)
        } catch {
            guard container.contains(.venue) else { throw error }
            return nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        if let document {
            try container.encode(document, forKey: .document)
        } else {
            try container.encodeIfPresent(venue, forKey: .venue)
        }
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
