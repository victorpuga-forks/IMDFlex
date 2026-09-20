import Foundation

/// 프로젝트 관리 UseCase
public final class ProjectUseCase: Sendable {
    private let repository: ProjectRepositoryProtocol
    
    public init(repository: ProjectRepositoryProtocol) {
        self.repository = repository
    }
    
    public func createProject(name: String) async throws -> IMDFProject {
        let project = IMDFProject(name: name)
        try await repository.save(project)
        return project
    }
    
    public func loadProjects() async throws -> [IMDFProject] {
        let projects = try await repository.fetchAll()
        var migratedProjects: [IMDFProject] = []
        migratedProjects.reserveCapacity(projects.count)

        for project in projects {
            guard project.document == nil, let venue = project.venue else {
                migratedProjects.append(project)
                continue
            }

            let migrated = IMDFProject(
                id: project.id,
                name: project.name,
                venue: venue,
                document: IMDFDocument(venue: venue),
                createdAt: project.createdAt,
                updatedAt: project.updatedAt
            )
            try await repository.save(migrated)
            migratedProjects.append(migrated)
        }

        return migratedProjects
    }
    
    public func updateProject(_ project: IMDFProject) async throws {
        var updated = project
        updated = IMDFProject(
            id: project.id,
            name: project.name,
            venue: project.venue,
            document: project.currentDocument,
            createdAt: project.createdAt,
            updatedAt: Date()
        )
        try await repository.save(updated)
    }
    
    public func deleteProject(id: UUID) async throws {
        try await repository.delete(id: id)
    }
}
