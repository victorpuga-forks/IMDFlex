import DesignSystem
import SwiftUI

struct MapEditorDraftControls: View {
    let state: FeatureAuthoringToolState
    let onFinish: () async -> Void

    var body: some View {
        HStack(spacing: IMDFSpacing.sm) {
            IMDFToolButton(MapEditorText.removePoint, systemImage: MapEditorSymbol.remove) {
                state.removeLastDraftPoint()
            }
            .disabled(state.draftedPointCount == 0)

            IMDFToolButton(MapEditorText.cancelDraft, systemImage: MapEditorSymbol.cancel) {
                state.cancel()
            }

            IMDFToolButton(
                MapEditorText.finishDraft,
                systemImage: MapEditorSymbol.finish
            ) {
                Task {
                    await onFinish()
                }
            }
            .role(.primary)
            .disabled(!state.canFinish)
        }
    }
}
