import DesignSystem
import Domain
import MapKit
import SwiftUI

public struct MapEditorView: View {
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var viewModel: MapEditorViewModel

    public init(project: IMDFProject, service: any MapEditorServicing) {
        _viewModel = State(initialValue: MapEditorViewModel(project: project, service: service))
    }

    public var body: some View {
        ZStack {
            MapReader { proxy in
                Map(position: $cameraPosition)
                    .mapStyle(.standard)
                    .onTapGesture(coordinateSpace: .local) { screenPoint in
                        guard let coordinate = proxy.convert(screenPoint, from: .local) else { return }
                        viewModel.authoringState.appendDraftCoordinate(
                            IMDFDraftCoordinate(
                                longitude: coordinate.longitude,
                                latitude: coordinate.latitude
                            )
                        )
                    }
            }
            .ignoresSafeArea(edges: .bottom)

            VStack(spacing: IMDFSpacing.md) {
                HStack(alignment: .top, spacing: IMDFSpacing.md) {
                    Spacer(minLength: 0)

                    MapEditorInspector(viewModel: viewModel)
                        .frame(width: 300)
                }

                Spacer(minLength: 0)

                MapEditorFeatureToolbar(state: viewModel.authoringState)
            }
            .padding(IMDFSpacing.lg)
        }
        .navigationTitle(viewModel.project.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(MapEditorText.export, systemImage: MapEditorSymbol.export) {}
                    Button(MapEditorText.settings, systemImage: MapEditorSymbol.settings) {}
                } label: {
                    Image(systemName: MapEditorSymbol.more)
                }
                .accessibilityLabel(MapEditorText.editorActions)
            }
        }
        .alert(
            alertTitle,
            isPresented: isPresentingAlert,
            presenting: viewModel.alert
        ) { _ in
            Button(MapEditorText.alertOK) {}
        } message: { alert in
            Text(MapEditorText.alertMessage(for: alert))
        }
    }

    private var alertTitle: String {
        guard let alert = viewModel.alert else { return "" }
        return MapEditorText.alertTitle(for: alert)
    }

    private var isPresentingAlert: Binding<Bool> {
        Binding(
            get: { viewModel.alert != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.dismissAlert()
                }
            }
        )
    }
}
