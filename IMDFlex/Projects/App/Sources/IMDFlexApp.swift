import SwiftUI
import Domain
import Data
import Presentation

@main
struct IMDFlexApp: App {
    private let projectRepository = ProjectRepository()
    
    var body: some Scene {
        WindowGroup {
            let useCase = ProjectUseCase(repository: projectRepository)
            let exportService = MapEditorExportService(exporter: IMDFExporter())
            ProjectHomeView(service: useCase, mapEditorService: useCase, mapEditorExportService: exportService)
        }
    }
}
