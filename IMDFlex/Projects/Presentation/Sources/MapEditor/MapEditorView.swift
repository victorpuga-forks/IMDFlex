import CoreLocation
import DesignSystem
import Domain
import Foundation
import MapKit
import SwiftUI

public struct MapEditorView: View {
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var viewModel: MapEditorViewModel

    public init(project: IMDFProject, service: any MapEditorServicing) {
        _viewModel = State(initialValue: MapEditorViewModel(project: project, service: service))
    }

    public var body: some View {
        HStack(spacing: 0) {
            MapEditorFeatureSidebar(viewModel: viewModel)
                .frame(width: 260)
                .padding(IMDFSpacing.lg)

            ZStack {
                MapReader { proxy in
                    Map(position: $cameraPosition, selection: shapeSelectionBinding) {
                        ForEach(viewModel.featureShapes) { shape in
                            mapContent(for: shape)
                        }
                    }
                    .mapStyle(.standard)
                    .onTapGesture(coordinateSpace: .local) { screenPoint in
                        guard viewModel.mode == .insert else { return }
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

                        if viewModel.mode == .insert {
                            MapEditorInspector(viewModel: viewModel)
                                .frame(width: 300)
                        } else {
                            MapEditorFeatureDetailPanel(viewModel: viewModel)
                                .frame(width: 300)
                        }
                    }

                    Spacer(minLength: 0)

                    VStack(spacing: IMDFSpacing.sm) {
                        IMDFPanel {
                            Picker(MapEditorText.mode, selection: modeBinding) {
                                ForEach(MapEditorMode.allCases, id: \.self) { mode in
                                    Text(mode.title).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }
                        .accessibilityLabel(MapEditorText.mode)

                        if viewModel.mode == .insert {
                            MapEditorFeatureToolbar(state: viewModel.authoringState)
                        }
                    }
                }
                .padding(IMDFSpacing.lg)
            }
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

    private var modeBinding: Binding<MapEditorMode> {
        Binding(get: { viewModel.mode }, set: { viewModel.setMode($0) })
    }

    /// A `.constant(nil)` in Insert mode so overlay tap-to-select can't swallow draft-point taps.
    private var shapeSelectionBinding: Binding<UUID?> {
        guard viewModel.mode == .view else { return .constant(nil) }

        return Binding(
            get: { viewModel.selectedShapeID },
            set: { id in
                if let id {
                    viewModel.select(id: id)
                } else {
                    viewModel.clearSelection()
                }
            }
        )
    }

    @MapContentBuilder
    private func mapContent(for shape: MapEditorFeatureShape) -> some MapContent {
        let color = MapEditorFeatureColor.color(for: shape.feature)
        let isSelected = shape.id == viewModel.selectedShapeID

        switch shape.geometry {
        case .polygon(let coordinates):
            MapPolygon(coordinates: coordinates.map(coordinate))
                .foregroundStyle(color.opacity(isSelected ? 0.5 : 0.25))
                .stroke(color, lineWidth: isSelected ? 4 : 2)
                .tag(shape.id)
        case .line(let coordinates):
            MapPolyline(coordinates: coordinates.map(coordinate))
                .stroke(color, lineWidth: isSelected ? 5 : 3)
                .tag(shape.id)
        case .point(let point):
            Marker(shape.title ?? shape.feature.title, systemImage: shape.feature.systemImage, coordinate: coordinate(point))
                .tint(color)
                .tag(shape.id)
        }
    }

    private func coordinate(_ coordinate: Coordinate) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
