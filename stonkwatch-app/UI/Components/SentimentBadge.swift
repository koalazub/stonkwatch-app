import SwiftUI

struct SentimentBadge: View {
    let level: SentimentLevel

    var body: some View {
        Text(level.label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(AppTheme.sentimentColor(for: level).opacity(0.15))
            .foregroundStyle(AppTheme.sentimentColor(for: level))
            .clipShape(Capsule())
    }
}

#Preview {
    HStack {
        ForEach(SentimentLevel.allCases, id: \.self) { level in
            SentimentBadge(level: level)
        }
    }
    .padding()
}
