import SwiftUI

struct DigestCardView: View {
    let digest: Digest

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            header
            Text(digest.summary)
                .font(.digestBody)
                .foregroundStyle(.primary)
            if !digest.keyPoints.isEmpty {
                keyPointsList
            }
            footer
        }
        .cardStyle()
    }

    private var header: some View {
        HStack {
            if let ticker = digest.ticker {
                Text(ticker)
                    .font(.tickerSymbol)
                    .foregroundStyle(AppTheme.sentimentColor(for: digest.sentiment))
            }
            Text(digest.title)
                .font(.sectionHeader)
                .lineLimit(2)
            Spacer()
            SentimentBadge(level: digest.sentiment)
        }
    }

    private var keyPointsList: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            ForEach(digest.keyPoints, id: \.self) { point in
                HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                    Circle()
                        .fill(AppTheme.sentimentColor(for: digest.sentiment))
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    Text(point)
                        .font(.digestCaption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Label("\(digest.sourceCount) sources", systemImage: "doc.text")
            Spacer()
            Text(digest.generatedAt.relativeDescription)
        }
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
}

#Preview {
    DigestCardView(digest: .mock())
        .padding()
}
