//
//  YouTubeDownloadView.swift
//  OrMiMu
//
//  Created by Kyberix on 2024-05-22.
//

import SwiftUI
import SwiftData

struct YouTubeDownloadView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var statusManager: StatusManager
    @EnvironmentObject var downloadManager: DownloadManager
    @State private var showFailedDownloads = false

    var body: some View {
        HStack(spacing: 0) {
            // MARK: - Left Column: Input Form
            VStack(spacing: 0) {
                // Header
                Text("DOWNLOAD SETTINGS")
                    .kyberixHeader()
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.kyberixBlack)
                    .overlay(Rectangle().frame(height: 1).foregroundColor(Color.kyberixGrey), alignment: .bottom)

                ScrollView {
                    VStack(spacing: 0) {
                        // URL Input
                        KyberixFormRow(label: "VIDEO URL", text: $downloadManager.urlString, placeholder: "https://youtube.com/...")

                        // Format Picker (Custom Row)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("FORMAT")
                                .font(.caption2)
                                .bold()
                                .kerning(1.0)
                                .foregroundStyle(Color.kyberixWhite)

                            HStack {
                                Picker("Format", selection: $downloadManager.selectedFormat) {
                                    ForEach(downloadManager.formats, id: \.self) { format in
                                        Text(format.uppercased()).tag(format)
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                                .frame(width: 100)

                                if downloadManager.selectedFormat == "mp3" || downloadManager.selectedFormat == "m4a" {
                                    Picker("Bitrate", selection: $downloadManager.selectedBitrate) {
                                        ForEach(downloadManager.bitrates, id: \.self) { bitrate in
                                            Text(bitrate).tag(bitrate)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .labelsHidden()
                                    .frame(width: 100)
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.kyberixBlack)
                        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.kyberixGrey), alignment: .bottom)

                        // Metadata Fields
                        KyberixFormRow(label: "ARTIST (OVERRIDE)", text: $downloadManager.artist, placeholder: "Optional")
                        KyberixFormRow(label: "ALBUM (OVERRIDE)", text: $downloadManager.album, placeholder: "Optional")
                        KyberixFormRow(label: "GENRE (OVERRIDE)", text: $downloadManager.genre, placeholder: "Optional")
                        KyberixFormRow(label: "YEAR (OVERRIDE)", text: $downloadManager.year, placeholder: "Optional")
                    }
                    .padding(.bottom, 20)
                }

                // Action Area
                VStack(spacing: 16) {
                    if downloadManager.isDownloading {
                        KyberixGeometricProgress(value: statusManager.progress, height: 4)
                        Text(statusManager.statusDetail.isEmpty ? "DOWNLOADING..." : statusManager.statusDetail.uppercased())
                            .font(.caption)
                            .foregroundStyle(Color.kyberixWhite)

                        Button("STOP DOWNLOAD") {
                            downloadManager.cancelDownload(statusManager: statusManager)
                        }
                        .buttonStyle(KyberixBlockButton())
                    } else {
                        Button("START DOWNLOAD") {
                            downloadManager.startDownload(statusManager: statusManager, modelContext: modelContext)
                        }
                        .buttonStyle(KyberixBlockButton())
                        .disabled(downloadManager.urlString.isEmpty || !downloadManager.dependenciesInstalled)
                    }
                }
                .padding(24)
                .background(Color.kyberixBlack)
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.kyberixGrey), alignment: .top)
            }
            .background(Color.kyberixBlack)

            // Divider
            Rectangle()
                .fill(Color.kyberixGrey)
                .frame(width: 1)

            // MARK: - Right Column: Queue / Log
            VStack(spacing: 0) {
                // Header
                Text("PROCESS LOG")
                    .kyberixHeader()
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.kyberixBlack)
                    .overlay(Rectangle().frame(height: 1).foregroundColor(Color.kyberixGrey), alignment: .bottom)

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            if statusManager.logOutput.isEmpty {
                                Text("Waiting for tasks...")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(Color.kyberixGrey)
                                    .padding()
                            } else {
                                Text(statusManager.logOutput)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(Color.kyberixWhite)
                                    .padding()
                                    .id("bottom")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .onChange(of: statusManager.logOutput) { _, _ in
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }

                if !downloadManager.failedDownloads.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("FAILED ITEMS (\(downloadManager.failedDownloads.count))")
                            .kyberixHeader()
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.kyberixBlack)
                            .overlay(Rectangle().frame(height: 1).foregroundColor(Color.kyberixGrey), alignment: .top)

                        List(downloadManager.failedDownloads, id: \.url) { item in
                            HStack {
                                Text(item.title)
                                    .lineLimit(1)
                                    .foregroundStyle(Color.kyberixWhite)
                                Spacer()
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundStyle(.red)
                            }
                            .listRowBackground(Color.kyberixBlack)
                        }
                        .frame(height: 150)
                        .scrollContentBackground(.hidden)

                        HStack {
                            Spacer()
                            Button("VIEW DETAILS") {
                                showFailedDownloads = true
                            }
                            .buttonStyle(KyberixBlockButton())
                            .scaleEffect(0.8)
                        }
                        .padding()
                    }
                }
            }
            .background(Color.kyberixBlack)
        }
        .background(Color.kyberixBlack)
        .onAppear {
            downloadManager.checkDependencies()
        }
        .sheet(isPresented: $showFailedDownloads) {
            FailedDownloadsView(items: downloadManager.failedDownloads)
        }
    }
}

struct FailedDownloadsView: View {
    var items: [DownloadManager.FailedDownloadItem]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("FAILED DOWNLOADS").kyberixHeader().font(.headline)
                Spacer()
                Button("CLOSE") {
                    dismiss()
                }
                .buttonStyle(KyberixBlockButton())
            }
            .padding()
            .background(Color.kyberixBlack)
            .overlay(Rectangle().frame(height: 1).foregroundColor(Color.kyberixGrey), alignment: .bottom)

            Table(items) {
                TableColumn("TITLE") { item in
                    Text(item.title).kyberixBody()
                }

                TableColumn("URL") { item in
                    Text(item.url).kyberixBody()
                }

                TableColumn("ERROR") { item in
                    Text(item.error).kyberixBody()
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.kyberixBlack)

            HStack {
                Spacer()
                Button("EXPORT CSV") {
                    saveCSV()
                }
                .buttonStyle(KyberixBlockButton())
            }
            .padding()
            .background(Color.kyberixBlack)
            .overlay(Rectangle().frame(height: 1).foregroundColor(Color.kyberixGrey), alignment: .top)
        }
        .frame(minWidth: 600, minHeight: 400)
        .background(Color.kyberixBlack)
    }

    private func saveCSV() {
        let header = "Title,URL,Error\n"
        let csvContent = items.map { item in
            let escapedTitle = item.title.replacingOccurrences(of: "\"", with: "\"\"")
            let escapedError = item.error.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escapedTitle)\",\"\(item.url)\",\"\(escapedError)\""
        }.joined(separator: "\n")

        let finalString = header + csvContent

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "failed_downloads.csv"

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try finalString.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    print("Failed to save CSV: \(error)")
                }
            }
        }
    }
}
