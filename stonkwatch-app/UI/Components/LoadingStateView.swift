import SwiftUI

struct LoadingStateView: View {
    var message: String = "Loading your briefing..."

    var body: some View {
        ContentUnavailableView {
            ProgressView()
                .controlSize(.large)
        } description: {
            Text(message)
                .foregroundStyle(.secondary)
        }
    }
}

struct ErrorStateView: View {
    let error: Error
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Something went wrong", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Try Again", action: retry)
                .buttonStyle(.bordered)
        }
    }
}

#Preview("Loading") {
    LoadingStateView()
}

#Preview("Error") {
    ErrorStateView(error: APIError.invalidResponse) {}
}
