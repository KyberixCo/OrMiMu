//
//  DeviceManagerView.swift
//  OrMiMu
//
//  Created by Kyberix on 08/02/26.
//

import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

struct DeviceManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var statusManager: StatusManager
    @EnvironmentObject var context: DeviceManagerContext

    @Query(sort: \PlaylistItem.name) private var allPlaylists: [PlaylistItem]

    @State private var showFileImporter = false

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header / Device Selection
            HStack(spacing: 20) {
                Image(systemName: "externaldrive.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.kyberixWhite)

                VStack(alignment: .leading, spacing: 4) {
                    Text("EXTERNAL DEVICE MANAGER")
                        .kyberixHeader()
                    if let url = context.deviceRoot {
                        Text(url.path)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(Color.kyberixWhite)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else {
                        Text("NO DEVICE SELECTED")
                            .font(.caption)
                            .foregroundStyle(Color.kyberixGrey)
                    }
                }

                Spacer()

                Button("SELECT DEVICE") {
                    showFileImporter = true
                }
                .buttonStyle(KyberixBlockButton())
            }
            .padding(20)
            .background(Color.kyberixBlack)
            .overlay(Rectangle().frame(height: 1).foregroundColor(Color.kyberixGrey), alignment: .bottom)

            if let _ = context.deviceRoot {
                ScrollView {
                    VStack(spacing: 24) {

                        // MARK: - Device Info & Stats
                        VStack(alignment: .leading, spacing: 0) {
                            Text("DEVICE INFORMATION")
                                .kyberixHeader()
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.kyberixBlack)
                                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.kyberixGrey), alignment: .bottom)

                            HStack(alignment: .top, spacing: 0) {
                                // Left: Text Fields
                                VStack(spacing: 0) {
                                    KyberixFormRow(label: "ALIAS", text: $context.config.alias)
                                        .onChange(of: context.config.alias) { _, _ in context.saveConfig() }
                                    KyberixFormRow(label: "DESCRIPTION", text: $context.config.description)
                                        .onChange(of: context.config.description) { _, _ in context.saveConfig() }
                                }
                                .frame(maxWidth: .infinity)

                                Rectangle().fill(Color.kyberixGrey).frame(width: 1)

                                // Right: Storage
                                VStack(alignment: .leading, spacing: 12) {
                                    if let info = context.volumeInfo {
                                        let totalGB = Double(info.total) / 1_000_000_000
                                        let freeGB = Double(info.free) / 1_000_000_000
                                        let usedGB = totalGB - freeGB
                                        let percent = totalGB > 0 ? usedGB / totalGB : 0

                                        Text("STORAGE USAGE")
                                            .kyberixHeader()
                                            .font(.caption2)

                                        KyberixGeometricProgress(value: percent, height: 12)

                                        HStack {
                                            Text("\(String(format: "%.1f", freeGB)) GB FREE")
                                            Spacer()
                                            Text("\(String(format: "%.1f", totalGB)) GB TOTAL")
                                        }
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(Color.kyberixGrey)
                                    } else {
                                        Text("STORAGE INFO UNAVAILABLE")
                                            .font(.caption)
                                            .foregroundStyle(Color.kyberixGrey)
                                    }
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .border(Color.kyberixGrey, width: 1)

                        // MARK: - Sync Settings
                        VStack(alignment: .leading, spacing: 0) {
                            Text("CONFIGURATION")
                                .kyberixHeader()
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.kyberixBlack)
                                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.kyberixGrey), alignment: .bottom)

                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("TARGET FORMAT")
                                        .kyberixHeader()
                                        .font(.caption2)
                                    Spacer()
                                    Picker("Format", selection: $context.targetFormat) {
                                        Text("MP3 (Universal)").tag("mp3")
                                        Text("AAC (M4A)").tag("m4a")
                                        Text("FLAC (Lossless)").tag("flac")
                                    }
                                    .pickerStyle(.menu)
                                    .frame(width: 150)
                                    .onChange(of: context.targetFormat) { _, newValue in
                                        context.config.supportedFormats = [newValue]
                                        context.saveConfig()
                                    }
                                }

                                Divider().overlay(Color.kyberixGrey)

                                Toggle("SIMPLE DEVICE MODE (FLAT STRUCTURE)", isOn: $context.config.isSimpleDevice)
                                    .toggleStyle(.switch)
                                    .onChange(of: context.config.isSimpleDevice) { _, _ in context.saveConfig() }
                                    .foregroundStyle(Color.kyberixWhite)

                                if context.config.isSimpleDevice {
                                    Toggle("RANDOMIZE ORDER (0001_SONG...)", isOn: $context.config.randomizeCopy)
                                        .toggleStyle(.switch)
                                        .padding(.leading)
                                        .onChange(of: context.config.randomizeCopy) { _, _ in context.saveConfig() }
                                        .foregroundStyle(Color.kyberixWhite)
                                }

                                Text(context.config.isSimpleDevice ?
                                     "FILES WILL BE PLACED IN THE ROOT FOLDER." :
                                     "FILES WILL BE ORGANIZED IN FOLDERS BY PLAYLIST.")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(Color.kyberixGrey)
                            }
                            .padding(16)
                        }
                        .border(Color.kyberixGrey, width: 1)

                        // MARK: - Content Selection
                        VStack(alignment: .leading, spacing: 0) {
                            Text("SELECT PLAYLISTS TO SYNC")
                                .kyberixHeader()
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.kyberixBlack)
                                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.kyberixGrey), alignment: .bottom)

                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach(allPlaylists) { playlist in
                                        HStack {
                                            Toggle(isOn: Binding(
                                                get: { context.selectedPlaylists.contains(playlist.id) },
                                                set: { isSelected in
                                                    if isSelected {
                                                        context.selectedPlaylists.insert(playlist.id)
                                                    } else {
                                                        context.selectedPlaylists.remove(playlist.id)
                                                    }
                                                }
                                            )) {
                                                Text(playlist.name)
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundStyle(context.selectedPlaylists.contains(playlist.id) ? Color.kyberixWhite : Color.kyberixGrey)
                                            }
                                            .toggleStyle(.checkbox)

                                            Spacer()

                                            Text("\(playlist.songs?.count ?? 0) SONGS")
                                                .font(.system(.caption, design: .monospaced))
                                                .foregroundStyle(Color.kyberixGrey)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(Color.kyberixBlack)
                                        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.kyberixGrey.opacity(0.3)), alignment: .bottom)
                                    }
                                }
                            }
                            .frame(height: 200)
                        }
                        .border(Color.kyberixGrey, width: 1)

                        // MARK: - Actions
                        HStack {
                            Button("EXPORT CSV LIST") {
                                exportCSV()
                            }
                            .buttonStyle(KyberixBlockButton())

                            Spacer()

                            Button(action: startSync) {
                                HStack(spacing: 8) {
                                    if context.isSyncing {
                                        ProgressView().controlSize(.small).tint(Color.kyberixBlack)
                                    }
                                    Text(context.isSyncing ? "SYNCING..." : "SYNC NOW")
                                }
                            }
                            .buttonStyle(KyberixBlockButton())
                            .disabled(context.isSyncing || context.selectedPlaylists.isEmpty)
                        }
                        .padding(.bottom, 40)

                    }
                    .padding(24)
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "externaldrive.badge.plus")
                        .font(.system(size: 60, weight: .ultraLight))
                        .foregroundStyle(Color.kyberixGrey)
                    Text("SELECT A FOLDER OR DRIVE TO MANAGE")
                        .kyberixHeader()
                        .foregroundStyle(Color.kyberixGrey)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.kyberixBlack)
            }
        }
        .background(Color.kyberixBlack)
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.folder], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    context.deviceRoot = url
                    context.refreshDeviceState()
                }
            case .failure(let error):
                statusManager.statusMessage = "Error selecting folder: \(error.localizedDescription)"
            }
        }
    }

    private func startSync() {
        guard let url = context.deviceRoot else { return }

        context.isSyncing = true
        statusManager.isBusy = true

        let playlistsToSync = allPlaylists.filter { context.selectedPlaylists.contains($0.id) }
        let playlistDTOs = playlistsToSync.map { playlist in
            PlaylistDTO(
                id: playlist.id,
                name: playlist.name,
                songs: (playlist.songs ?? []).map { song in
                    SongDTO(
                        id: song.id,
                        title: song.title,
                        artist: song.artist,
                        album: song.album,
                        filePath: song.filePath
                    )
                }
            )
        }

        let currentConfig = context.config
        let status = self.statusManager

        Task {
            do {
                try await Task.detached(priority: .userInitiated) {
                    try await DeviceService.shared.sync(playlists: playlistDTOs, to: url, config: currentConfig, status: status)
                }.value

                context.isSyncing = false
                statusManager.isBusy = false
                context.refreshDeviceState()

            } catch {
                context.isSyncing = false
                statusManager.isBusy = false
                statusManager.statusMessage = "Sync failed: \(error.localizedDescription)"
            }
        }
    }

    private func exportCSV() {
        guard let deviceRoot = context.deviceRoot else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "Device_Music_List.csv"

        panel.begin { response in
            if response == .OK, let outputURL = panel.url {
                generateAndSaveCSV(to: outputURL, deviceRoot: deviceRoot)
            }
        }
    }

    private func generateAndSaveCSV(to outputURL: URL, deviceRoot: URL) {
        let manifest = DeviceService.shared.loadManifest(from: deviceRoot)
        let descriptor = FetchDescriptor<SongItem>()
        let allSongs = (try? modelContext.fetch(descriptor)) ?? []
        let lookup = Dictionary(grouping: allSongs, by: { $0.id.uuidString }).mapValues { $0.first! }

        var csvString = "Relative Path,Title,Artist,Album,Duration,Format\n"
        let sortedFiles = manifest.files.sorted(by: { $0.key < $1.key })

        for (path, songID) in sortedFiles {
            var title = "Unknown (ID: \(songID))"
            var artist = ""
            var album = ""
            var duration = ""
            var format = ""

            if let song = lookup[songID] {
                title = song.title.replacingOccurrences(of: "\"", with: "\"\"")
                artist = song.artist.replacingOccurrences(of: "\"", with: "\"\"")
                album = song.album.replacingOccurrences(of: "\"", with: "\"\"")
                duration = formatDuration(song.duration)
                format = song.fileExtension
            }

            let row = "\"\(path)\",\"\(title)\",\"\(artist)\",\"\(album)\",\"\(duration)\",\"\(format)\"\n"
            csvString += row
        }

        do {
            try csvString.write(to: outputURL, atomically: true, encoding: .utf8)
            statusManager.statusMessage = "CSV Exported successfully."
        } catch {
            statusManager.statusMessage = "Failed to export CSV: \(error.localizedDescription)"
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
