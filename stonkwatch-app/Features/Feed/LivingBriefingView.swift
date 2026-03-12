import SwiftUI

struct LivingBriefingView: View {
    @State private var viewModel = LivingBriefingViewModel()
    @State private var selectedDigest: Digest?
    @State private var showingTransparencySheet = false
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.digests.isEmpty {
                    LoadingStateView(message: "Preparing your briefing...")
                } else if let error = viewModel.error, viewModel.digests.isEmpty {
                    ErrorStateView(error: error) {
                        Task { await viewModel.loadBriefing() }
                    }
                } else {
                    briefingContent
                }
            }
            .navigationTitle("Briefing")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingTransparencySheet) {
                if let digest = selectedDigest {
                    TransparencySheet(digest: digest, onDismiss: { showingTransparencySheet = false })
                }
            }
        }
        .onAppear {
            viewModel.startLivingUpdates()
        }
        .onDisappear {
            viewModel.stopLivingUpdates()
        }
    }
    
    private var briefingContent: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.lg) {
                livingHeader
                
                if viewModel.newDevelopmentsCount > 0 {
                    newDevelopmentsBadge
                }
                
                ForEach(viewModel.digests) { digest in
                    LivingDigestCard(
                        digest: digest,
                        freshness: viewModel.freshness(for: digest),
                        onTransparencyTap: {
                            selectedDigest = digest
                            showingTransparencySheet = true
                        },
                        onActionTap: { action in
                            viewModel.executeAction(action, for: digest)
                        }
                    )
                    .id(digest.id)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, AppTheme.Spacing.xl)
        }
    }
    
    private var livingHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text(greetingText)
                    .font(.largeTitle.bold())
                Spacer()
                LivingIndicator(lastUpdate: viewModel.lastUpdateTime)
            }
            
            Text("Your market intelligence is continuously monitored.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if let lastUpdate = viewModel.lastUpdateTime {
                Text("Last significant update: \(lastUpdate.relativeDescription)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, AppTheme.Spacing.md)
    }
    
    private var newDevelopmentsBadge: some View {
        HStack {
            Image(systemName: "bolt.fill")
                .foregroundStyle(.yellow)
            Text("\(viewModel.newDevelopmentsCount) new development\(viewModel.newDevelopmentsCount == 1 ? "" : "s") since you last checked")
                .font(.subheadline.weight(.medium))
            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .background(.yellow.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
}

// MARK: - Living Indicator

struct LivingIndicator: View {
    let lastUpdate: Date?
    @State private var isPulsing = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isActive ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .opacity(isPulsing ? 0.7 : 1.0)
            
            Text("LIVE")
                .font(.caption2.weight(.bold))
                .foregroundStyle(isActive ? .green : .secondary)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
    
    private var isActive: Bool {
        guard let lastUpdate else { return false }
        return Date().timeIntervalSince(lastUpdate) < 300 // Active if updated within 5 min
    }
}

// MARK: - Living Digest Card

struct LivingDigestCard: View {
    let digest: Digest
    let freshness: ContentFreshness
    let onTransparencyTap: () -> Void
    let onActionTap: (PredictedAction) -> Void
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Header with ticker, title, sentiment, and freshness
            headerSection
            
            // AI Summary with confidence indication
            summarySection
            
            // Key points with visual hierarchy
            if !digest.keyPoints.isEmpty && isExpanded {
                keyPointsSection
            }
            
            // Predictive actions based on content
            PredictiveActionsBar(digest: digest, onActionTap: onActionTap)
            
            // Footer with transparency and metadata
            footerSection
        }
        .padding(AppTheme.Spacing.lg)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))
        .opacity(freshness.opacity)
        .overlay(freshnessBorder)
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                isExpanded.toggle()
            }
        }
    }
    
    private var headerSection: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    if let ticker = digest.ticker {
                        Text(ticker)
                            .font(.tickerSymbol)
                            .foregroundStyle(AppTheme.sentimentColor(for: digest.sentiment))
                    }
                    FreshnessBadge(freshness: freshness)
                }
                
                Text(digest.title)
                    .font(.sectionHeader)
                    .lineLimit(2)
            }
            
            Spacer()
            
            SentimentBadge(level: digest.sentiment)
        }
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            SelectableText(text: digest.summary) { selectedText in
                // Handle text selection for "Ask about this"
                print("Selected: \(selectedText)")
            }
            .font(.digestBody)
            .foregroundStyle(.primary)
            
            // Confidence indicator
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(.secondary)
                Text("AI Confidence: \(Int(digest.confidence * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var keyPointsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            ForEach(digest.keyPoints, id: \.self) { point in
                HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(AppTheme.sentimentColor(for: digest.sentiment))
                        .padding(.top, 6)
                    
                    Text(point)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.top, AppTheme.Spacing.sm)
    }
    
    private var footerSection: some View {
        HStack {
            // Transparency button
            Button(action: onTransparencyTap) {
                HStack(spacing: 4) {
                    Image(systemName: "doc.text.magnifyingglass")
                    Text("\(digest.sourceCount) sources")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.accentColor)
            }
            
            Spacer()
            
            Text(digest.generatedAt.relativeDescription)
                .font(.caption)
                .foregroundStyle(.tertiary)
            
            if isExpanded {
                Image(systemName: "chevron.up")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.top, AppTheme.Spacing.sm)
    }
    
    @ViewBuilder
    private var background: some View {
        switch freshness {
        case .fresh:
            Color.green.opacity(0.03)
        case .recent:
            Color.clear.background(.regularMaterial)
        case .aging:
            Color.yellow.opacity(0.03)
        case .stale:
            Color.gray.opacity(0.05)
        }
    }
    
    private var freshnessBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
            .stroke(freshness.borderColor, lineWidth: freshness == .fresh ? 2 : 0)
    }
}

// MARK: - Freshness System

enum ContentFreshness {
    case fresh       // < 15 min
    case recent      // 15-60 min
    case aging       // 1-4 hours
    case stale       // > 4 hours
    
    var opacity: Double {
        switch self {
        case .fresh: return 1.0
        case .recent: return 1.0
        case .aging: return 0.9
        case .stale: return 0.75
        }
    }
    
    var borderColor: Color {
        switch self {
        case .fresh: return .green.opacity(0.5)
        case .recent: return .clear
        case .aging: return .yellow.opacity(0.3)
        case .stale: return .gray.opacity(0.3)
        }
    }
}

struct FreshnessBadge: View {
    let freshness: ContentFreshness
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: iconName)
            Text(label)
        }
        .font(.caption2.weight(.medium))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
    
    private var iconName: String {
        switch freshness {
        case .fresh: return "bolt.fill"
        case .recent: return "clock"
        case .aging: return "hourglass"
        case .stale: return "archivebox"
        }
    }
    
    private var label: String {
        switch freshness {
        case .fresh: return "Just In"
        case .recent: return "Recent"
        case .aging: return "Aging"
        case .stale: return "Archive"
        }
    }
    
    private var color: Color {
        switch freshness {
        case .fresh: return .green
        case .recent: return .blue
        case .aging: return .orange
        case .stale: return .gray
        }
    }
}

// MARK: - Predictive Actions

enum PredictedAction: String {
    case addToWatchlist = "Add to Watchlist"
    case setAlert = "Set Alert"
    case viewContrary = "Contrary View"
    case saveToThesis = "Save to Thesis"
    case share = "Share Insight"
    
    var icon: String {
        switch self {
        case .addToWatchlist: return "star"
        case .setAlert: return "bell.badge"
        case .viewContrary: return "arrow.left.arrow.right"
        case .saveToThesis: return "doc.text"
        case .share: return "square.and.arrow.up"
        }
    }
}

struct PredictiveActionsBar: View {
    let digest: Digest
    let onActionTap: (PredictedAction) -> Void
    
    private var suggestedActions: [PredictedAction] {
        var actions: [PredictedAction] = []
        
        if digest.ticker != nil {
            actions.append(.addToWatchlist)
        }
        
        if digest.sentiment == .bullish || digest.sentiment == .bearish {
            actions.append(.setAlert)
        }
        
        actions.append(.viewContrary)
        actions.append(.saveToThesis)
        
        return actions
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(suggestedActions, id: \.self) { action in
                    ActionChip(action: action, onTap: { onActionTap(action) })
                }
            }
        }
    }
}

struct ActionChip: View {
    let action: PredictedAction
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: action.icon)
                Text(action.rawValue)
            }
            .font(.caption.weight(.medium))
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(Color.accentColor.opacity(0.1))
            .foregroundStyle(Color.accentColor)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Selectable Text for Highlight+Ask

struct SelectableText: UIViewRepresentable {
    let text: String
    let onSelection: (String) -> Void
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isSelectable = true
        textView.isEditable = false
        textView.text = text
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.textColor = UIColor.label
        textView.backgroundColor = .clear
        textView.delegate = context.coordinator
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onSelection: onSelection)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        let onSelection: (String) -> Void
        
        init(onSelection: @escaping (String) -> Void) {
            self.onSelection = onSelection
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            if let selectedRange = textView.selectedTextRange {
                let selectedText = textView.text(in: selectedRange) ?? ""
                if !selectedText.isEmpty {
                    onSelection(selectedText)
                }
            }
        }
    }
}

// MARK: - Transparency Sheet

struct TransparencySheet: View {
    let digest: Digest
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    // Why This Matters section
                    WhyThisMattersCard(digest: digest)
                    
                    // Sources breakdown
                    SourcesSection(digest: digest)
                    
                    // Contrary view
                    ContraryViewSection(digest: digest)
                    
                    // AI reasoning
                    AIReasoningSection(digest: digest)
                }
                .padding()
            }
            .navigationTitle("Sources & Transparency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: onDismiss)
                }
            }
        }
    }
}

struct WhyThisMattersCard: View {
    let digest: Digest
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Label("Why This Matters to You", systemImage: "person.fill.questionmark")
                .font(.headline)
            
            Text("You follow \(digest.ticker ?? "this stock") and have shown interest in earnings-related news. This development could impact your portfolio by approximately 2-3% based on similar historical events.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
    }
}

struct SourcesSection: View {
    let digest: Digest
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Sources (\(digest.sourceCount))")
                .font(.headline)
            
            ForEach(0..<min(digest.sourceCount, 5), id: \.self) { index in
                SourceRow(
                    name: ["Bloomberg", "Reuters", "Twitter/X", "Reddit r/wallstreetbets", "Seeking Alpha"][index],
                    type: [.analyst, .news, .social, .community, .analyst][index],
                    snippet: "...reports indicate strong earnings beat with Services revenue hitting all-time high..."
                )
            }
        }
    }
}

struct SourceRow: View {
    let name: String
    let type: SourceType
    let snippet: String
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: type.icon)
                .foregroundStyle(type.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack {
                    Text(name)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text(type.label)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(type.color.opacity(0.1))
                        .foregroundStyle(type.color)
                        .clipShape(Capsule())
                }
                
                Text(snippet)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }
}

enum SourceType: String {
    case analyst = "Analyst"
    case news = "News"
    case social = "Social"
    case community = "Community"
    
    var icon: String {
        switch self {
        case .analyst: return "chart.line.uptrend.xyaxis"
        case .news: return "newspaper"
        case .social: return "bubble.left"
        case .community: return "person.2"
        }
    }
    
    var color: Color {
        switch self {
        case .analyst: return .purple
        case .news: return .blue
        case .social: return .cyan
        case .community: return .orange
        }
    }
    
    var label: String { rawValue }
}

struct ContraryViewSection: View {
    let digest: Digest
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: "arrow.left.arrow.right")
                Text("Contrary View")
                    .font(.headline)
            }
            
            Text("Morgan Stanley analyst maintains Underweight rating citing valuation concerns. 'While earnings beat estimates, forward guidance suggests margin compression ahead that the market isn't pricing in.'")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("This analyst correctly predicted 3 of last 4 AAPL earnings misses")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.red.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
    }
}

struct AIReasoningSection: View {
    let digest: Digest
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Label("AI Analysis Confidence", systemImage: "brain.head.profile")
                .font(.headline)
            
            HStack {
                ConfidenceMeter(value: digest.confidence)
                Spacer()
                Text("\(Int(digest.confidence * 100))%")
                    .font(.title2.bold())
                    .foregroundStyle(confidenceColor)
            }
            
            Text("High confidence based on: Multiple corroborating sources, consistent messaging across analyst and community channels, alignment with historical patterns.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
    }
    
    private var confidenceColor: Color {
        if digest.confidence > 0.8 { return .green }
        if digest.confidence > 0.6 { return .yellow }
        return .orange
    }
}

struct ConfidenceMeter: View {
    let value: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: geometry.size.width * value, height: 8)
            }
        }
        .frame(width: 100, height: 8)
    }
    
    private var color: Color {
        if value > 0.8 { return .green }
        if value > 0.6 { return .yellow }
        return .orange
    }
}

#Preview {
    LivingBriefingView()
}
