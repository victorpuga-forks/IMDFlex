import Domain
import Foundation
import Observation

public enum IMDFAuthoringGeometry: String, Codable, CaseIterable, Hashable, Sendable {
    case point
    case line
    case polygon
    case form

    public var minimumPointCount: Int {
        switch self {
        case .point: 1
        case .line: 2
        case .polygon: 3
        case .form: 0
        }
    }
}

public enum IMDFAuthoringReference: String, Codable, CaseIterable, Hashable, Sendable {
    case building
    case level
    case unit
    case anchor
    case levelOrBuilding
    /// Deprecated. Use relationshipOrigin and relationshipDestination.
    case relationshipEndpoints
    case relationshipOrigin
    case relationshipDestination
}

public enum IMDFAuthoringFeature: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case address
    case venue
    case building
    case footprint
    case level
    case unit
    case opening
    case amenity
    case anchor
    case occupant
    case detail
    case fixture
    case geofence
    case kiosk
    case relationship
    case section

    public var id: String { rawValue }

    public var contract: IMDFAuthoringContract {
        switch self {
        case .address:
            .init(feature: self, geometry: .form, requiresName: true)
        case .venue:
            .init(
                feature: self,
                geometry: .polygon,
                requiresCategory: true,
                requiresName: true,
                categoryFeature: .venue
            )
        case .building:
            .init(feature: self, geometry: .form, requiresCategory: true, categoryFeature: .building)
        case .footprint:
            .init(
                feature: self,
                geometry: .polygon,
                requiresCategory: true,
                requiredReferences: [.building],
                categoryFeature: .footprint
            )
        case .level:
            .init(
                feature: self,
                geometry: .polygon,
                requiresCategory: true,
                requiresName: true,
                requiresShortName: true,
                requiredReferences: [.building],
                categoryFeature: .level
            )
        case .unit:
            .init(
                feature: self,
                geometry: .polygon,
                requiresCategory: true,
                requiredReferences: [.level],
                categoryFeature: .unit
            )
        case .opening:
            .init(
                feature: self,
                geometry: .line,
                requiresCategory: true,
                requiredReferences: [.level],
                categoryFeature: .opening
            )
        case .amenity:
            .init(
                feature: self,
                geometry: .point,
                requiresCategory: true,
                requiredReferences: [.unit],
                categoryFeature: .amenity
            )
        case .anchor:
            .init(feature: self, geometry: .point, requiredReferences: [.unit])
        case .occupant:
            .init(
                feature: self,
                geometry: .form,
                requiresCategory: true,
                requiresName: true,
                requiredReferences: [.anchor],
                categoryFeature: .occupant
            )
        case .detail:
            .init(feature: self, geometry: .line, requiredReferences: [.level])
        case .fixture:
            .init(
                feature: self,
                geometry: .polygon,
                requiresCategory: true,
                requiredReferences: [.level],
                categoryFeature: .fixture
            )
        case .geofence:
            .init(
                feature: self,
                geometry: .polygon,
                requiresCategory: true,
                requiredReferences: [.level],
                categoryFeature: .geofence
            )
        case .kiosk:
            .init(feature: self, geometry: .polygon, requiredReferences: [.level])
        case .relationship:
            .init(
                feature: self,
                geometry: .form,
                requiresCategory: true,
                requiredReferences: [.relationshipOrigin, .relationshipDestination],
                categoryFeature: .relationship
            )
        case .section:
            .init(
                feature: self,
                geometry: .polygon,
                requiresCategory: true,
                requiredReferences: [.level],
                categoryFeature: .section
            )
        }
    }
}

public struct IMDFAuthoringContract: Codable, Equatable, Sendable {
    public let feature: IMDFAuthoringFeature
    public let geometry: IMDFAuthoringGeometry
    public let requiresCategory: Bool
    public let requiresName: Bool
    public let requiresShortName: Bool
    public let requiredReferences: [IMDFAuthoringReference]
    public let categoryFeature: IMDFCategoryFeature?

    public init(
        feature: IMDFAuthoringFeature,
        geometry: IMDFAuthoringGeometry,
        requiresCategory: Bool = false,
        requiresName: Bool = false,
        requiresShortName: Bool = false,
        requiredReferences: [IMDFAuthoringReference] = [],
        categoryFeature: IMDFCategoryFeature? = nil
    ) {
        self.feature = feature
        self.geometry = geometry
        self.requiresCategory = requiresCategory
        self.requiresName = requiresName
        self.requiresShortName = requiresShortName
        self.requiredReferences = requiredReferences
        self.categoryFeature = categoryFeature
    }
}

@MainActor
@Observable
public final class FeatureAuthoringToolState {
    public private(set) var selectedFeature: IMDFAuthoringFeature
    public private(set) var drawingDraft: DrawingDraftState
    public private(set) var selectedCategoryValue: String?
    public private(set) var name: String
    public private(set) var shortName: String
    public private(set) var selectedReferences: [IMDFAuthoringReference: UUID]

    public init(
        selectedFeature: IMDFAuthoringFeature = .unit,
        drawingDraft: DrawingDraftState? = nil,
        selectedCategoryValue: String? = nil,
        name: String = "",
        shortName: String = "",
        selectedReferences: [IMDFAuthoringReference: UUID] = [:]
    ) {
        self.selectedFeature = selectedFeature
        self.drawingDraft = drawingDraft ?? DrawingDraftState(geometry: selectedFeature.contract.geometry)
        self.selectedCategoryValue = selectedCategoryValue ?? Self.defaultCategoryValue(for: selectedFeature)
        self.name = name
        self.shortName = shortName
        self.selectedReferences = selectedReferences
    }

    public var contract: IMDFAuthoringContract {
        selectedFeature.contract
    }

    public var hasSelectedCategory: Bool {
        selectedCategoryValue != nil
    }

    public var canFinish: Bool {
        hasEnoughGeometry && hasRequiredCategory && hasRequiredName && hasRequiredShortName && hasRequiredReferences
    }

    public var remainingPointCount: Int {
        drawingDraft.remainingPointCount
    }

    public var draftedPointCount: Int {
        drawingDraft.pointCount
    }

    public var draftedCoordinates: [IMDFDraftCoordinate] {
        drawingDraft.coordinates
    }

    public var isCategorySatisfied: Bool {
        hasRequiredCategory
    }

    public var missingReferences: [IMDFAuthoringReference] {
        contract.requiredReferences.filter { selectedReferences[$0] == nil }
    }

    public func selectFeature(_ feature: IMDFAuthoringFeature) {
        selectedFeature = feature
        resetDraft()
    }

    public func appendDraftCoordinate(_ coordinate: IMDFDraftCoordinate) {
        drawingDraft.append(coordinate)
    }

    public func removeLastDraftPoint() {
        drawingDraft.removeLastCoordinate()
    }

    public func selectCategory(_ value: String) {
        selectedCategoryValue = value
    }

    public func setName(_ name: String) {
        self.name = name
    }

    public func setShortName(_ shortName: String) {
        self.shortName = shortName
    }

    public func selectReference(_ id: UUID, for reference: IMDFAuthoringReference) {
        selectedReferences[reference] = id
    }

    @available(*, deprecated, message: "Select a concrete reference ID instead.")
    public func satisfyReference(_ reference: IMDFAuthoringReference) {
        selectedReferences[reference] = UUID()
    }

    @available(*, deprecated, message: "Select concrete reference IDs instead.")
    public func satisfyRequiredReferences() {
        for reference in contract.requiredReferences {
            satisfyReference(reference)
        }
    }

    @available(*, deprecated, message: "Use selectedReferences instead.")
    public var satisfiedReferences: Set<IMDFAuthoringReference> {
        Set(selectedReferences.keys)
    }

    public func clearReference(_ reference: IMDFAuthoringReference) {
        selectedReferences.removeValue(forKey: reference)
    }

    public func selectedReferenceID(for reference: IMDFAuthoringReference) -> UUID? {
        selectedReferences[reference]
    }

    public func cancel() {
        resetDraft()
    }

    public func finishDrawingDraft() -> IMDFDrawingDraftResult? {
        guard canFinish else { return nil }

        return drawingDraft.finish()
    }

    /// Clears the draft after a successful finish while keeping the feature selection
    /// and satisfied references, so authoring several instances of the same feature stays fast.
    public func resetAfterFinish() {
        drawingDraft.setGeometry(contract.geometry)
        selectedCategoryValue = Self.defaultCategoryValue(for: selectedFeature)
        name = ""
        shortName = ""
    }

    private var hasEnoughGeometry: Bool {
        drawingDraft.canFinish
    }

    private var hasRequiredCategory: Bool {
        !contract.requiresCategory || hasSelectedCategory
    }

    private var hasRequiredName: Bool {
        !contract.requiresName || !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasRequiredShortName: Bool {
        !contract.requiresShortName || !shortName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasRequiredReferences: Bool {
        contract.requiredReferences.allSatisfy { selectedReferences[$0] != nil }
    }

    private func resetDraft() {
        drawingDraft.setGeometry(contract.geometry)
        selectedCategoryValue = Self.defaultCategoryValue(for: selectedFeature)
        name = ""
        shortName = ""
        selectedReferences = [:]
    }

    private static func defaultCategoryValue(for feature: IMDFAuthoringFeature) -> String? {
        MapEditorCategoryOptions.options(for: feature).first
    }
}
