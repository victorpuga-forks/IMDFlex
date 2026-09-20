import Foundation

/// IMDF Amenity - 편의시설
public struct Amenity: Identifiable, Codable, Sendable {
    public let id: UUID
    public var name: String?
    public var category: AmenityCategory
    public var coordinate: Coordinate?
    public var alternateName: String?
    public var accessibility: String?
    public var addressID: UUID?
    public var correlationID: String?
    public var hours: String?
    public var phone: String?
    public var website: URL?
    public var displayPoint: Coordinate?
    
    public init(
        id: UUID = UUID(),
        name: String? = nil,
        category: AmenityCategory,
        coordinate: Coordinate? = nil,
        alternateName: String? = nil,
        accessibility: String? = nil,
        addressID: UUID? = nil,
        correlationID: String? = nil,
        hours: String? = nil,
        phone: String? = nil,
        website: URL? = nil,
        displayPoint: Coordinate? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.coordinate = coordinate
        self.alternateName = alternateName
        self.accessibility = accessibility
        self.addressID = addressID
        self.correlationID = correlationID
        self.hours = hours
        self.phone = phone
        self.website = website
        self.displayPoint = displayPoint
    }
}

public enum AmenityCategory: String, Codable, CaseIterable, Sendable {
    case atm
    case elevator
    case escalator
    case stairs
    case restroom
    case restroomMale = "restroom.male"
    case restroomFemale = "restroom.female"
    case restroomUnisex = "restroom.unisex"
    case drinkingWater = "drinkingfountain"
    case information
    case ticketMachine = "ticketing"
    case parking
    case chargingStation = "powerchargingstation"
    case firstAid = "firstaid"
    case unspecified
}
