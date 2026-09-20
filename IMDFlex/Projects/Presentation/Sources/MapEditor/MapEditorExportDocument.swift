import SwiftUI
import UniformTypeIdentifiers

/// Wraps an already-built `imdf.zip` archive so `.fileExporter` can hand it to the user;
/// the archive is always generated ahead of time, so reading a document back in is never used.
struct MapEditorExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.zip] }
    static var writableContentTypes: [UTType] { [.zip] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
