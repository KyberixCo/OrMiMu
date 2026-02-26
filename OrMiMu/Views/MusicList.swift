//
//  MusicList.swift
//  OrMiMu
//
//  Created by Manuel Galindo on 7/02/24.
//

import SwiftUI
import SwiftData
import AppKit

enum SongField {
    case title, artist, album, genre

    var displayName: String {
        switch self {
        case .title: return "Title"
        case .artist: return "Artist"
        case .album: return "Album"
        case .genre: return "Genre"
        }
    }
}

// Wrapper for bulk edit sheet
struct BulkEditContext: Identifiable {
    let id = UUID()
    let songs: [SongItem]
}

struct MusicListView: View {
    var songs: [SongItem]
    @Binding var playableSong: URL?
    var currentPlaylist: PlaylistItem? = nil

    @Query private var playlists: [PlaylistItem]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var audioPlayerManager: AudioPlayerManager
    @EnvironmentObject var statusManager: StatusManager

    @State private var selectedSongIDs = Set<SongItem.ID>()

    // Sorting State
    @AppStorage("librarySortKey") private var sortKey: String = "title"
    @AppStorage("librarySortAscending") private var sortAscending: Bool = true
    @State private var sortOrder = [KeyPathComparator(\SongItem.title)]

    // Search State
    @State private var searchText = ""

    // Metadata Editing State
    @State private var songToEdit: SongItem?
    @State private var editingField: SongField?
    @State private var bulkEditContext: BulkEditContext?

    // New Playlist Creation
    @State private var showNewPlaylistAlert = false
    @State private var pendingPlaylistSongs: Set<SongItem.ID> = []

    var filteredSongs: [SongItem] {
        if searchText.isEmpty {
            return songs
        } else {
            return songs.filter { song in
                song.title.localizedCaseInsensitiveContains(searchText) ||
                song.artist.localizedCaseInsensitiveContains(searchText) ||
                song.album.localizedCaseInsensitiveContains(searchText) ||
                song.genre.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var sortedSongs: [SongItem] {
        return filteredSongs.sorted(using: sortOrder)
    }

    var body: some View {
        VStack(spacing: 0) {
            MusicListHeader(sortKey: $sortKey, sortAscending: $sortAscending)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(sortedSongs.enumerated()), id: \.element.id) { index, song in
                        MusicListRow(
                            song: song,
                            isSelected: selectedSongIDs.contains(song.id),
                            isPlaying: playableSong?.path == song.filePath,
                            onPlay: { playSong(song) },
                            onSelect: { handleSelection(for: song) }
                        )
                        .contextMenu {
                            let idsToActOn: Set<SongItem.ID> = selectedSongIDs.contains(song.id) ? selectedSongIDs : [song.id]
                            contextMenuContent(for: idsToActOn)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .animation(.linear(duration: 0.2), value: sortedSongs)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.kyberixBlack)
        .searchable(text: $searchText, placement: .automatic, prompt: "SEARCH SONGS")
        .onChange(of: sortKey) { _, _ in updateSortOrder() }
        .onChange(of: sortAscending) { _, _ in updateSortOrder() }
        .onAppear {
            updateSortOrder()
        }
        .sheet(item: $songToEdit) { song in
            EditMetadataView(song: song, initialField: editingField)
        }
        .sheet(item: $bulkEditContext) { context in
            BulkEditMetadataView(songs: context.songs)
        }
        .playlistNameAlert(
            isPresented: $showNewPlaylistAlert,
            title: "New Playlist",
            message: "Enter a name for the new playlist.",
            initialName: "New Playlist"
        ) { name in
            createNewPlaylist(name: name, with: pendingPlaylistSongs)
            pendingPlaylistSongs = []
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func contextMenuContent(for selectedIDs: Set<SongItem.ID>) -> some View {
        if !selectedIDs.isEmpty {
            Button("Edit Metadata") {
                let selectedSongs = sortedSongs.filter { selectedIDs.contains($0.id) }
                if selectedSongs.count == 1, let first = selectedSongs.first {
                    editSong(first, field: .title)
                } else if selectedSongs.count > 1 {
                    bulkEditContext = BulkEditContext(songs: selectedSongs)
                }
            }

            Divider()

            Button("Convert to Default Format") {
                if let firstID = selectedIDs.first, let song = songs.first(where: { $0.id == firstID }) {
                    convertToDefaultFormat(song)
                }
            }

            Button("Play") {
                if let firstID = selectedIDs.first, let song = songs.first(where: { $0.id == firstID }) {
                    playSong(song)
                }
            }

            Divider()

            if let currentPlaylist = currentPlaylist {
                Button("Remove from Playlist") {
                    removeFromPlaylist(playlist: currentPlaylist, songIDs: selectedIDs)
                }
            } else {
                Menu("Add to Playlist") {
                    ForEach(playlists) { playlist in
                        Button(playlist.name) {
                            addToPlaylist(playlist: playlist, songIDs: selectedIDs)
                        }
                    }
                    Divider()
                    Button("New Playlist") {
                        pendingPlaylistSongs = selectedIDs
                        showNewPlaylistAlert = true
                    }
                }
            }

            Divider()

            Button("Delete from Library") {
                deleteFromLibrary(songIDs: selectedIDs)
            }
        }
    }

    // MARK: - Private Methods

    private func handleSelection(for song: SongItem) {
        if NSEvent.modifierFlags.contains(.command) {
            if selectedSongIDs.contains(song.id) {
                selectedSongIDs.remove(song.id)
            } else {
                selectedSongIDs.insert(song.id)
            }
        } else {
            // Simple click selects only this, clearing others
            selectedSongIDs = [song.id]
        }
    }

    private func editSong(_ song: SongItem, field: SongField) {
        editingField = field
        songToEdit = song
    }

    private func updateMetadata(song: SongItem, field: SongField, value: String) {
        switch field {
        case .title: song.title = value
        case .artist: song.artist = value
        case .album: song.album = value
        case .genre: song.genre = value
        }

        Task {
            do {
                try await MetadataService.updateMetadata(
                    filePath: song.filePath,
                    title: song.title,
                    artist: song.artist,
                    album: song.album,
                    genre: song.genre,
                    year: song.year
                )
            } catch {
                print("Failed to save inline metadata: \(error)")
            }
        }
    }

    private func updateSortOrder() {
        let order: SortOrder = sortAscending ? .forward : .reverse
        switch sortKey {
        case "title":         sortOrder = [KeyPathComparator(\SongItem.title, order: order)]
        case "artist":        sortOrder = [KeyPathComparator(\SongItem.artist, order: order)]
        case "album":         sortOrder = [KeyPathComparator(\SongItem.album, order: order)]
        case "genre":         sortOrder = [KeyPathComparator(\SongItem.genre, order: order)]
        case "fileExtension": sortOrder = [KeyPathComparator(\SongItem.fileExtension, order: order)]
        case "duration":      sortOrder = [KeyPathComparator(\SongItem.duration, order: order)]
        default:              sortOrder = [KeyPathComparator(\SongItem.title, order: order)]
        }
    }

    private func saveSortOrder(_ newOrder: [KeyPathComparator<SongItem>]) {
        // Not used with manual sortKey binding anymore, but kept if needed
    }

    private func playSong(_ song: SongItem) {
        let queueItems = sortedSongs.map { (url: URL(fileURLWithPath: $0.filePath), title: $0.title, artist: $0.artist) }
        if let index = sortedSongs.firstIndex(where: { $0.id == song.id }) {
            audioPlayerManager.setQueue(queueItems, startAtIndex: index)
            playableSong = URL(fileURLWithPath: song.filePath)
        }
    }

    private func addToPlaylist(playlist: PlaylistItem, songIDs: Set<SongItem.ID>) {
        let selectedSongs = sortedSongs.filter { songIDs.contains($0.id) }
        if playlist.songs == nil { playlist.songs = [] }
        playlist.songs?.append(contentsOf: selectedSongs)
    }

    private func removeFromPlaylist(playlist: PlaylistItem, songIDs: Set<SongItem.ID>) {
        playlist.songs = playlist.songs?.filter { !songIDs.contains($0.id) }
    }

    private func createNewPlaylist(name: String, with songIDs: Set<SongItem.ID>) {
        let selectedSongs = sortedSongs.filter { songIDs.contains($0.id) }
        let newPlaylist = PlaylistItem(name: name, songs: selectedSongs)
        modelContext.insert(newPlaylist)
    }

    private func convertToDefaultFormat(_ song: SongItem) {
        let defaultFormat = UserDefaults.standard.string(forKey: "downloadFormat") ?? "mp3"
        let defaultBitrate = UserDefaults.standard.string(forKey: "downloadBitrate") ?? "256"

        guard song.fileExtension.lowercased() != defaultFormat.lowercased() else { return }

        Task {
            do {
                try await ConversionService.convert(
                    song: song,
                    to: defaultFormat,
                    bitrate: defaultBitrate,
                    statusManager: statusManager
                )
                try? modelContext.save()
            } catch {
                statusManager.statusMessage = "Conversion failed: \(error.localizedDescription)"
            }
        }
    }

    private func deleteFromLibrary(songIDs: Set<SongItem.ID>) {
        let songsToDelete = sortedSongs.filter { songIDs.contains($0.id) }
        for song in songsToDelete {
            modelContext.delete(song)
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
