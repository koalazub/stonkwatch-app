import SwiftUI

struct SettingsView: View {
    @State private var appSettings = AppSettings.shared
    @State private var showingAppearancePicker = false
    @State private var showingSummarizationPicker = false
    @State private var showingModelDownloadSheet = false
    @State private var downloadProgress: Double = 0
    @State private var isDownloading = false
    @State private var currentTier: SummarizationTier = .auto
    @State private var coreMLDownloaded: Bool = false
    @State private var isSyncing = false
    @State private var syncStatusText = "Not connected"
    @State private var lastSyncText = "Never"

    private let summarizationService = SummarizationService.shared
    private let turso = TursoSyncEngine.shared
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - AI Summarization Section
                Section {
                    // Current Tier Display
                    HStack {
                        Image(systemName: currentTierIcon)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AI Summarization")
                                .font(.body)
                            Text(currentTier.badge)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .task {
                        currentTier = await summarizationService.getCurrentTier()
                        coreMLDownloaded = await summarizationService.isCoreMLModelDownloaded()
                    }
                    
                    // Tier Selection
                    Button(action: { showingSummarizationPicker = true }) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .foregroundStyle(Color.accentColor)
                            Text("Summarization Mode")
                            Spacer()
                            Text(appSettings.summarizationTier.displayName)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.primary)
                    
                    // Core ML Model Management
                    if appSettings.summarizationTier == .coreML || appSettings.summarizationTier == .auto {
                        CoreMLModelRow(
                            isDownloaded: coreMLDownloaded,
                            onDownload: { showingModelDownloadSheet = true },
                            onDelete: { Task { await summarizationService.deleteCoreMLModel() } }
                        )
                    }
                } header: {
                    Text("AI Summarization")
                } footer: {
                    Text("All summarization happens on-device for privacy. Zero API costs.")
                        .font(.caption)
                }
                
                // MARK: - Appearance Section
                Section("Appearance") {
                    Button(action: { showingAppearancePicker = true }) {
                        HStack {
                            Image(systemName: appSettings.appearance.icon)
                                .foregroundStyle(Color.accentColor)
                            Text("Appearance")
                            Spacer()
                            Text(appSettings.appearance.label)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
                
                // MARK: - Account Section
                Section("Account") {
                    Label("Profile", systemImage: "person.circle")
                    Label("Notifications", systemImage: "bell")
                }
                
                // MARK: - AI Preferences Section
                Section("AI Preferences") {
                    Label("Briefing Schedule", systemImage: "clock")
                    Label("Summary Detail Level", systemImage: "text.alignleft")
                    Label("Language", systemImage: "globe")
                }
                
                // MARK: - Data Section
                Section("Data") {
                    Label("Manage Watchlist", systemImage: "star")
                    Label("Connected Accounts", systemImage: "link")
                }
                
                // MARK: - Sync Section
                Section {
                    HStack {
                        Image(systemName: syncIcon)
                            .foregroundStyle(syncColor)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Turso Sync")
                                .font(.body)
                            Text(syncStatusText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if isSyncing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }

                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        Text("Last sync")
                        Spacer()
                        Text(lastSyncText)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }

                    Button(action: performManualSync) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 24)
                            Text("Sync Now")
                        }
                    }
                    .disabled(isSyncing)
                } header: {
                    Text("Data Sync")
                } footer: {
                    Text("Syncs your watchlist and preferences with StonkWatch every 5 minutes.")
                        .font(.caption)
                }
                .task {
                    await refreshSyncStatus()
                }

                // MARK: - About Section
                Section("About") {
                    Label("Version 1.0", systemImage: "info.circle")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAppearancePicker) {
                AppearancePickerSheet(
                    currentAppearance: appSettings.appearance,
                    onSelect: { appearance in
                        appSettings.setAppearance(appearance)
                    }
                )
            }
            .sheet(isPresented: $showingSummarizationPicker) {
                SummarizationTierPickerSheet(
                    currentTier: appSettings.summarizationTier,
                    onSelect: { tier in
                        appSettings.setSummarizationTier(tier)
                    }
                )
            }
            .sheet(isPresented: $showingModelDownloadSheet) {
                ModelDownloadSheet(
                    isDownloading: $isDownloading,
                    progress: $downloadProgress,
                    onDownload: downloadModel
                )
            }
        }
    }
    
    private var currentTierIcon: String {
        switch currentTier {
        case .appleIntelligence:
            return "sparkles"
        case .coreML:
            return "brain.head.profile"
        case .extractive:
            return "bolt.fill"
        case .auto:
            return "wand.and.stars"
        }
    }
    
    private var syncIcon: String {
        if isSyncing { return "arrow.clockwise" }
        if syncStatusText.contains("Connected") { return "checkmark.icloud.fill" }
        return "xmark.icloud"
    }

    private var syncColor: Color {
        if isSyncing { return .blue }
        if syncStatusText.contains("Connected") { return .green }
        return .secondary
    }

    private func refreshSyncStatus() async {
        let state = await turso.getConnectionState()
        switch state {
        case .connected(let lastSync):
            syncStatusText = "Connected"
            if let lastSync {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .abbreviated
                lastSyncText = formatter.localizedString(for: lastSync, relativeTo: Date())
            } else {
                lastSyncText = "Not yet synced"
            }
        case .syncing:
            syncStatusText = "Syncing..."
        case .connecting:
            syncStatusText = "Connecting..."
        case .disconnected:
            syncStatusText = "Disconnected"
        case .error:
            syncStatusText = "Sync error"
        }
    }

    private func performManualSync() {
        isSyncing = true
        Task {
            do {
                _ = try await turso.forceSync()
            } catch {}
            await refreshSyncStatus()
            isSyncing = false
        }
    }

    private func downloadModel() {
        isDownloading = true
        downloadProgress = 0
        
        Task {
            do {
                try await summarizationService.downloadCoreMLModel { progress in
                    Task { @MainActor in
                        downloadProgress = progress
                    }
                }
                isDownloading = false
            } catch {
                isDownloading = false
                print("Download failed: \(error)")
            }
        }
    }
}

// MARK: - Core ML Model Row

struct CoreMLModelRow: View {
    let isDownloaded: Bool
    let onDownload: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "arrow.down.circle")
                .foregroundStyle(isDownloaded ? .green : .orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Core ML Model")
                    .font(.body)
                Text(isDownloaded ? "Downloaded (200 MB)" : "Not downloaded")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isDownloaded {
                Button("Delete", action: onDelete)
                    .font(.caption)
                    .foregroundStyle(.red)
            } else {
                Button("Download", action: onDownload)
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
    }
}

// MARK: - Model Download Sheet

struct ModelDownloadSheet: View {
    @Binding var isDownloading: Bool
    @Binding var progress: Double
    let onDownload: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.accentColor)
                
                Text("Download AI Model")
                    .font(.title2.bold())
                
                Text("Download the Core ML model for on-device summarization. This enables high-quality AI summaries without internet connection.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Label("200 MB download", systemImage: "arrow.down.circle")
                    Label("Works offline", systemImage: "wifi.slash")
                    Label("Completely private", systemImage: "lock.fill")
                    Label("Zero API costs", systemImage: "dollarsign.circle")
                }
                .foregroundStyle(.secondary)
                
                if isDownloading {
                    VStack(spacing: 8) {
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                        Text("\(Int(progress * 100))% downloaded")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                } else {
                    Button(action: onDownload) {
                        Text("Download Model")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Summarization Tier Picker

struct SummarizationTierPickerSheet: View {
    let currentTier: SummarizationTier
    let onSelect: (SummarizationTier) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Choose Summarization Mode") {
                    ForEach(SummarizationTier.allCases, id: \.self) { tier in
                        Button(action: {
                            onSelect(tier)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: tier.icon)
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tier.displayName)
                                        .font(.body)
                                    
                                    Text(tier.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                if currentTier == tier {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
                
                Section {
                    Text("Apple Intelligence requires iPhone 15 Pro or later. Core ML model provides similar quality on all devices.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Summarization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Appearance Picker Sheet

struct AppearancePickerSheet: View {
    let currentAppearance: AppAppearance
    let onSelect: (AppAppearance) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Choose Appearance") {
                    ForEach(AppAppearance.allCases, id: \.self) { appearance in
                        Button(action: {
                            onSelect(appearance)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: appearance.icon)
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(appearance.label)
                                        .font(.body)
                                    
                                    Text(description(for: appearance))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                if currentAppearance == appearance {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
                
                Section {
                    Text("Changes apply immediately across the app.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func description(for appearance: AppAppearance) -> String {
        switch appearance {
        case .system:
            return "Follows your device settings"
        case .light:
            return "Always uses light mode"
        case .dark:
            return "Always uses dark mode"
        }
    }
}

// MARK: - ModelDownloadStatus Extension

extension ModelDownloadStatus {
    var isDownloaded: Bool {
        if case .downloaded = self {
            return true
        }
        return false
    }
}

#Preview {
    SettingsView()
}
