//
//  YouTubeDownloadView.swift
//  OrMiMu
//
//  Created by Jules on 2024-05-22.
//

import SwiftUI
import SwiftData

struct YouTubeDownloadView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var statusManager: StatusManager
    @EnvironmentObject var downloadManager: DownloadManager
    @State private var showFailedDownloads = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Title
                Text("DOWNLOADS").kyberixHeader().font(.title2)

                if !downloadManager.dependenciesInstalled {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DEPENDENCIES").kyberixHeader()
                        if downloadManager.isInstallingDependencies {
                            KyberixProgressView(value: 0.5)
                            Text("Installing components (yt-dlp & ffmpeg)...").kyberixBody()
                        } else {
                            KyberixButton(title: "Install Dependencies") {
                                downloadManager.installDependencies(statusManager: statusManager)
                            }
                        }
                    }
                    .padding()
                    .border(Color.kyberixGrey, width: 1)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("VIDEO URL").kyberixHeader()
                    KyberixTextField(title: "https://...", text: $downloadManager.urlString)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("SETTINGS").kyberixHeader()
                    HStack {
                        Picker("Format", selection: $downloadManager.selectedFormat) {
                            ForEach(downloadManager.formats, id: \.self) { format in
                                Text(format.uppercased()).tag(format)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 100)
                        .accentColor(Color.kyberixWhite)

                        if downloadManager.selectedFormat == "mp3" || downloadManager.selectedFormat == "m4a" {
                            Picker("Bitrate", selection: $downloadManager.selectedBitrate) {
                                ForEach(downloadManager.bitrates, id: \.self) { bitrate in
                                    Text(bitrate).tag(bitrate)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 100)
                            .accentColor(Color.kyberixWhite)
                        }
                        Spacer()
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("METADATA OVERRIDE (OPTIONAL)").kyberixHeader()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ARTIST").kyberixHeader().font(.caption2)
                        KyberixTextField(title: "Artist", text: $downloadManager.artist)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ALBUM").kyberixHeader().font(.caption2)
                        KyberixTextField(title: "Album", text: $downloadManager.album)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("GENRE").kyberixHeader().font(.caption2)
                        KyberixTextField(title: "Genre", text: $downloadManager.genre)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("YEAR").kyberixHeader().font(.caption2)
                        KyberixTextField(title: "Year", text: $downloadManager.year)
                    }
                }

                if downloadManager.isDownloading {
                    VStack(spacing: 8) {
                        KyberixProgressView(value: statusManager.progress)
                        Text(statusManager.statusDetail.isEmpty ? "DOWNLOADING..." : statusManager.statusDetail.uppercased())
                            .font(.caption)
                            .kyberixBody()

                        KyberixButton(title: "Stop Download") {
                            downloadManager.cancelDownload(statusManager: statusManager)
                        }
                    }
                } else {
                    HStack {
                        KyberixButton(title: "Download") {
                            downloadManager.startDownload(statusManager: statusManager, modelContext: modelContext)
                        }
                        .disabled(downloadManager.urlString.isEmpty || !downloadManager.dependenciesInstalled)

                        if !downloadManager.failedDownloads.isEmpty {
                            Spacer()
                            Button("Show Failed Items (\(downloadManager.failedDownloads.count))") {
                                showFailedDownloads = true
                            }
                            .foregroundStyle(.white)
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !statusManager.logOutput.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PROCESS LOG").kyberixHeader()
                        ScrollViewReader { proxy in
                            ScrollView {
                                Text(statusManager.logOutput)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(Color.kyberixWhite)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(4)
                                    .id("bottom")
                            }
                            .frame(height: 150)
                            .background(Color.kyberixBlack)
                            .border(Color.kyberixGrey, width: 1)
                            .onChange(of: statusManager.logOutput) { _, _ in
                                withAnimation {
                                    proxy.scrollTo("bottom", anchor: .bottom)
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding()
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

    // Removing sortOrder state as we are simplifying the Table init to guarantee compilation

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("FAILED DOWNLOADS").kyberixHeader().font(.headline)
                Spacer()
                KyberixButton(title: "Close") {
                    dismiss()
                }
            }
            .padding()

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
                KyberixButton(title: "Download CSV") {
                    saveCSV()
                }
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 300)
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
