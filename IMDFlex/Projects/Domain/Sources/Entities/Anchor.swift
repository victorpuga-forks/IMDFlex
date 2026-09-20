import Foundation

/// IMDF Anchor - occupant, fixture, kiosk 등이 참조하는 위치 기준점
public struct Anchor: Identifiable, Codable, Sendable {
    public let id: UUID
    public var coordinate: Coordinate
    public var addressID: UUID?

    public init(id: UUID = UUID(), coordinate: Coordinate, addressID: UUID? = nil) {
        self.id = id
        self.coordinate = coordinate
        self.addressID = addressID
    }
}
