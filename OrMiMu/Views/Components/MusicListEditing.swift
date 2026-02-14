//
//  MusicListEditing.swift
//  OrMiMu
//
//  Created by Manuel Galindo on 7/02/24.
//

import SwiftUI

// MARK: - EditableCell

struct EditableCell: View {
    var value: String
    var onCommit: (String) -> Void

    @State private var text: String = ""
    @State private var isEditing: Bool = false
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            if isEditing {
                TextField("", text: $text)
                    .textFieldStyle(KyberixTextFieldStyle())
                    .focused($isFocused)
                    .onSubmit {
                        onCommit(text)
                        isEditing = false
                    }
                    .onAppear {
                        text = value
                        isFocused = true
                    }
                    .onChange(of: isFocused) { _, focused in
                        if !focused && isEditing {
                            onCommit(text)
                            isEditing = false
                        }
                    }
            } else {
                Text(value)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .kyberixBody()
                    .onTapGesture(count: 2) {
                        isEditing = true
                    }
            }
        }
    }
}

// MARK: - EditMetadataView

struct EditMetadataView: View {
    var song: SongItem
    var initialField: SongField?

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var artist: String = ""
    @State private var album: String = ""
    @State private var genre: String = ""

    @FocusState private var focusedField: SongField?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("EDIT METADATA").kyberixHeader().font(.title3)

            VStack(alignment: .leading) {
                Text("TITLE").kyberixHeader()
                KyberixTextField(title: "Title", text: $title)
                    .focused($focusedField, equals: .title)
            }
            VStack(alignment: .leading) {
                Text("ARTIST").kyberixHeader()
                KyberixTextField(title: "Artist", text: $artist)
                    .focused($focusedField, equals: .artist)
            }
            VStack(alignment: .leading) {
                Text("ALBUM").kyberixHeader()
                KyberixTextField(title: "Album", text: $album)
                    .focused($focusedField, equals: .album)
            }
            VStack(alignment: .leading) {
                Text("GENRE").kyberixHeader()
                KyberixTextField(title: "Genre", text: $genre)
                    .focused($focusedField, equals: .genre)
            }

            HStack {
                KyberixButton(title: "Cancel") {
                    dismiss()
                }
                Spacer()
                KyberixButton(title: "Save") {
                    save()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top)
        }
        .padding()
        .frame(minWidth: 300)
        .background(Color.kyberixBlack)
        .onAppear {
            title = song.title
            artist = song.artist
            album = song.album
            genre = song.genre
            focusedField = initialField
        }
    }

    private func save() {
        song.title = title
        song.artist = artist
        song.album = album
        song.genre = genre

        Task {
            do {
                try await MetadataService.updateMetadata(
                    filePath: song.filePath,
                    title: title,
                    artist: artist,
                    album: album,
                    genre: genre
                )
            } catch {
                print("Failed to save metadata to file: \(error)")
            }
        }
        dismiss()
    }
}

// MARK: - BulkEditMetadataView

struct BulkEditMetadataView: View {
    var songs: [SongItem]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var statusManager: StatusManager

    @State private var artist: String = ""
    @State private var album: String = ""
    @State private var genre: String = ""
    @State private var year: String = ""

    @State private var updateArtist = false
    @State private var updateAlbum = false
    @State private var updateGenre = false
    @State private var updateYear = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("EDIT METADATA FOR \(songs.count) ITEMS").kyberixHeader().font(.title3)

            VStack(alignment: .leading) {
                HStack {
                    Toggle("", isOn: $updateArtist).labelsHidden()
                    Text("ARTIST").kyberixHeader()
                }
                KyberixTextField(title: "Artist", text: $artist)
                    .disabled(!updateArtist)
            }

            VStack(alignment: .leading) {
                HStack {
                    Toggle("", isOn: $updateAlbum).labelsHidden()
                    Text("ALBUM").kyberixHeader()
                }
                KyberixTextField(title: "Album", text: $album)
                    .disabled(!updateAlbum)
            }

            VStack(alignment: .leading) {
                HStack {
                    Toggle("", isOn: $updateGenre).labelsHidden()
                    Text("GENRE").kyberixHeader()
                }
                KyberixTextField(title: "Genre", text: $genre)
                    .disabled(!updateGenre)
            }

            VStack(alignment: .leading) {
                HStack {
                    Toggle("", isOn: $updateYear).labelsHidden()
                    Text("YEAR").kyberixHeader()
                }
                KyberixTextField(title: "Year", text: $year)
                    .disabled(!updateYear)
            }

            HStack {
                KyberixButton(title: "Cancel") { dismiss() }
                Spacer()
                KyberixButton(title: "Save") { save() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.top)
        }
        .padding()
        .frame(minWidth: 400)
        .background(Color.kyberixBlack)
    }

    func save() {
        let newArtist = updateArtist ? artist : ""
        let newAlbum = updateAlbum ? album : ""
        let newGenre = updateGenre ? genre : ""
        let newYear = updateYear ? year : ""
        let shouldUpdateArtist = updateArtist
        let shouldUpdateAlbum = updateAlbum
        let shouldUpdateGenre = updateGenre
        let shouldUpdateYear = updateYear

        let totalCount = songs.count

        Task {
            await MainActor.run {
                statusManager.isBusy = true
                statusManager.progress = 0.0
                statusManager.statusMessage = "Updating metadata..."
            }

            for (index, song) in songs.enumerated() {
                let finalArtist = shouldUpdateArtist ? newArtist : song.artist
                let finalAlbum = shouldUpdateAlbum ? newAlbum : song.album
                let finalGenre = shouldUpdateGenre ? newGenre : song.genre
                let finalYear = shouldUpdateYear ? newYear : song.year

                if shouldUpdateArtist || shouldUpdateAlbum || shouldUpdateGenre || shouldUpdateYear {
                    try? await MetadataService.updateMetadata(
                        filePath: song.filePath,
                        title: song.title,
                        artist: finalArtist,
                        album: finalAlbum,
                        genre: finalGenre,
                        year: finalYear
                    )

                    await MainActor.run {
                        if shouldUpdateArtist { song.artist = finalArtist }
                        if shouldUpdateAlbum  { song.album  = finalAlbum  }
                        if shouldUpdateGenre  { song.genre  = finalGenre  }
                        if shouldUpdateYear   { song.year   = finalYear   }

                        statusManager.progress = Double(index + 1) / Double(totalCount)
                        statusManager.statusMessage = "Updating metadata (\(index + 1)/\(totalCount))..."
                    }
                }
            }

            await MainActor.run {
                statusManager.isBusy = false
                statusManager.statusMessage = "Metadata update complete."
                statusManager.progress = 0.0
            }
        }
        dismiss()
    }
}
