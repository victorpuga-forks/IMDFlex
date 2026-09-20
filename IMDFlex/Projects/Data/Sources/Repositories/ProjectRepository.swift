import Foundation
import Domain

public enum ProjectRepositoryError: Error, Sendable {
    case failedToDecode(url: URL, underlying: Error)
}

/// 파일 기반 프로젝트 저장소
public final class ProjectRepository: ProjectRepositoryProtocol, @unchecked Sendable {
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder = JSONDecoder()
    
    private var projectsDirectory: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("Projects", isDirectory: true)
    }
    
    public init() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        self.encoder = encoder
        try? fileManager.createDirectory(at: projectsDirectory, withIntermediateDirectories: true)
    }
    
    public func fetchAll() async throws -> [IMDFProject] {
        let files = try fileManager.contentsOfDirectory(at: projectsDirectory, includingPropertiesForKeys: nil)
        var projects: [IMDFProject] = []
        for url in files where url.pathExtension == "json" {
            do {
                let data = try Data(contentsOf: url)
                projects.append(try decoder.decode(IMDFProject.self, from: data))
            } catch {
                throw ProjectRepositoryError.failedToDecode(url: url, underlying: error)
            }
        }
        return projects.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    public func fetch(id: UUID) async throws -> IMDFProject? {
        let url = projectsDirectory.appendingPathComponent("\(id.uuidString).json")
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try decoder.decode(IMDFProject.self, from: data)
    }
    
    public func save(_ project: IMDFProject) async throws {
        let url = projectsDirectory.appendingPathComponent("\(project.id.uuidString).json")
        let data = try encoder.encode(project)
        try data.write(to: url)
    }
    
    public func delete(id: UUID) async throws {
        let url = projectsDirectory.appendingPathComponent("\(id.uuidString).json")
        try fileManager.removeItem(at: url)
    }
}
