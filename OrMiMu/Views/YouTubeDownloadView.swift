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
        Form {
            if !downloadManager.dependenciesInstalled {
                Section(header: Text("DEPENDENCIES").font(KyberixTheme.Font.header()).kyberixTracking()) {
                    if downloadManager.isInstallingDependencies {
                        ProgressView("Installing components (yt-dlp & ffmpeg)...")
                            .tint(KyberixTheme.white)
                    } else {
                        Button("Install Dependencies") {
                            downloadManager.installDependencies(statusManager: statusManager)
                        }
                        .buttonStyle(KyberixButtonStyle(isFilled: true))
                    }
                }
            }

            Section(header: Text("VIDEO URL").font(KyberixTheme.Font.header()).kyberixTracking()) {
                TextField("https://...", text: $downloadManager.urlString)
                    .textFieldStyle(KyberixTextFieldStyle())
            }

            Section(header: Text("SETTINGS").font(KyberixTheme.Font.header()).kyberixTracking()) {
                Picker("Format", selection: $downloadManager.selectedFormat) {
                    ForEach(downloadManager.formats, id: \.self) { format in
                        Text(format.uppercased()).tag(format)
                    }
                }
                .pickerStyle(MenuPickerStyle())

                if downloadManager.selectedFormat == "mp3" || downloadManager.selectedFormat == "m4a" {
                    Picker("Bitrate (kbps)", selection: $downloadManager.selectedBitrate) {
                        ForEach(downloadManager.bitrates, id: \.self) { bitrate in
                            Text(bitrate).tag(bitrate)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }

            Section(header: Text("METADATA OVERRIDE (OPTIONAL)").font(KyberixTheme.Font.header()).kyberixTracking()) {
                TextField("Artist", text: $downloadManager.artist)
                    .textFieldStyle(KyberixTextFieldStyle())
                TextField("Album", text: $downloadManager.album)
                    .textFieldStyle(KyberixTextFieldStyle())
                TextField("Genre", text: $downloadManager.genre)
                    .textFieldStyle(KyberixTextFieldStyle())
                TextField("Year", text: $downloadManager.year)
                    .textFieldStyle(KyberixTextFieldStyle())
            }

            if downloadManager.isDownloading {
                VStack(spacing: 8) {
                    KyberixProgressView(value: statusManager.progress)
                    Text(statusManager.statusDetail.isEmpty ? "Downloading..." : statusManager.statusDetail)
                        .font(KyberixTheme.Font.caption())
                        .foregroundStyle(KyberixTheme.white)

                    Button("Stop Download") {
                        downloadManager.cancelDownload(statusManager: statusManager)
                    }
                    .buttonStyle(KyberixButtonStyle(isFilled: false))
                }
                .padding(.vertical)
            } else {
                HStack {
                    Button("Download") {
                        downloadManager.startDownload(statusManager: statusManager, modelContext: modelContext)
                    }
                    .buttonStyle(KyberixButtonStyle(isFilled: true))
                    .disabled(downloadManager.urlString.isEmpty || !downloadManager.dependenciesInstalled)

                    if !downloadManager.failedDownloads.isEmpty {
                        Spacer()
                        Button("Show Failed Items (\(downloadManager.failedDownloads.count))") {
                            showFailedDownloads = true
                        }
                        .buttonStyle(KyberixButtonStyle(isFilled: false, color: .red))
                    }
                }
                .padding(.vertical)
            }

            if !statusManager.logOutput.isEmpty {
                Section(header: Text("PROCESS LOG").font(KyberixTheme.Font.header()).kyberixTracking()) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            Text(statusManager.logOutput)
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(4)
                                .id("bottom")
                                .foregroundStyle(KyberixTheme.white)
                        }
                        .frame(height: 150)
                        .background(KyberixTheme.black)
                        .border(KyberixTheme.divider, width: 1)
                        .onChange(of: statusManager.logOutput) { _ in
                            withAnimation {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(KyberixTheme.black)
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
        VStack(alignment: .leading) {
            HStack {
                Text("FAILED DOWNLOADS")
                    .font(KyberixTheme.Font.header())
                    .kyberixTracking()
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(KyberixButtonStyle(isFilled: false))
            }
            .padding()

            Table(items) {
                TableColumn(value: \.title) { item in
                    Text(item.title)
                } label: {
                    Text("TITLE")
                        .font(KyberixTheme.Font.header())
                        .kyberixTracking()
                }
                TableColumn(value: \.url) { item in
                    Text(item.url)
                } label: {
                    Text("URL")
                        .font(KyberixTheme.Font.header())
                        .kyberixTracking()
                }
                TableColumn(value: \.error) { item in
                    Text(item.error)
                } label: {
                    Text("ERROR")
                        .font(KyberixTheme.Font.header())
                        .kyberixTracking()
                }
            }

            HStack {
                Spacer()
                Button("Download CSV") {
                    saveCSV()
                }
                .buttonStyle(KyberixButtonStyle(isFilled: true))
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 300)
        .background(KyberixTheme.black)
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
