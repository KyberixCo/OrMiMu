//
//  MusicListComponents.swift
//  OrMiMu
//
//  Created by Kyberix on 2024-05-23.
//

import SwiftUI

// Constants for column layout
struct MusicListLayout {
    static let playWidth: CGFloat = 30
    static let genreWidth: CGFloat = 100
    static let formatWidth: CGFloat = 60
    static let lengthWidth: CGFloat = 60
}

struct MusicListHeader: View {
    @Binding var sortKey: String
    @Binding var sortAscending: Bool

    private func headerButton(title: String, key: String, width: CGFloat? = nil) -> some View {
        Button(action: {
            if sortKey == key {
                sortAscending.toggle()
            } else {
                sortKey = key
                sortAscending = true
            }
        }) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.kyberixWhite)

                if sortKey == key {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8))
                        .foregroundStyle(Color.kyberixWhite)
                }
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: width, alignment: .leading)
        .frame(maxWidth: width == nil ? .infinity : nil)
    }

    var body: some View {
        HStack(spacing: 8) {
            Color.clear.frame(width: MusicListLayout.playWidth)
            headerButton(title: "TITLE", key: "title")
            headerButton(title: "ARTIST", key: "artist")
            headerButton(title: "ALBUM", key: "album")
            headerButton(title: "GENRE", key: "genre", width: MusicListLayout.genreWidth)
            headerButton(title: "FORMAT", key: "fileExtension", width: MusicListLayout.formatWidth)
            headerButton(title: "LENGTH", key: "duration", width: MusicListLayout.lengthWidth)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(height: 32)
        .background(Color.kyberixBlack)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.kyberixGrey), alignment: .bottom)
    }
}

struct MusicListRow: View {
    let song: SongItem
    let isSelected: Bool
    let isPlaying: Bool
    let onPlay: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            // Play Button
            ZStack {
                if isPlaying {
                    Image(systemName: "waveform")
                        .foregroundStyle(textColor)
                        .font(.system(size: 12))
                } else if isHovering {
                    Image(systemName: "play.fill")
                        .foregroundStyle(textColor)
                        .font(.system(size: 12))
                        .onTapGesture(perform: onPlay)
                }
            }
            .frame(width: MusicListLayout.playWidth, alignment: .center)

            // Columns
            Text(song.title)
                .lineLimit(1)
                .font(.system(size: 13))
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(song.artist)
                .lineLimit(1)
                .font(.system(size: 13))
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(song.album)
                .lineLimit(1)
                .font(.system(size: 13))
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(song.genre)
                .lineLimit(1)
                .font(.system(size: 13))
                .foregroundStyle(textColor)
                .frame(width: MusicListLayout.genreWidth, alignment: .leading)

            Text(song.fileExtension.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(textColor)
                .frame(width: MusicListLayout.formatWidth, alignment: .leading)

            Text(formatDuration(song.duration))
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(textColor)
                .frame(width: MusicListLayout.lengthWidth, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(backgroundColor)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .simultaneousGesture(TapGesture(count: 2).onEnded {
            onPlay()
        })
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.kyberixGrey.opacity(0.3)),
            alignment: .bottom
        )
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.kyberixWhite
        } else if isHovering {
            return Color.kyberixWhite
        } else {
            return Color.kyberixBlack
        }
    }

    private var textColor: Color {
        if isSelected || isHovering {
            return Color.kyberixBlack
        } else {
            return Color.kyberixWhite
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
