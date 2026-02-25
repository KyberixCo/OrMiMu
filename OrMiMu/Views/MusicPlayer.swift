//
//  MusicPlayer.swift
//  OrMiMu
//
//  Created by Polarcito on 8/02/24.
//

import SwiftUI

struct MusicPlayer: View {
    @EnvironmentObject var audioPlayerManager: AudioPlayerManager
    @Binding var playableSong: URL?
    
    var body: some View {
        VStack(spacing: 12) {
            // Top: Song Info + Controls
            HStack(alignment: .center, spacing: 16) {
                // Left: Artwork
                if let artwork = audioPlayerManager.currentArtwork {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .border(KyberixTheme.divider, width: 1)
                } else {
                    Rectangle()
                        .fill(KyberixTheme.black)
                        .border(KyberixTheme.divider, width: 1)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 20, weight: .light))
                                .foregroundColor(KyberixTheme.white)
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(audioPlayerManager.currentTitle.isEmpty ? (playableSong?.deletingPathExtension().lastPathComponent ?? "UNKNOWN SONG") : audioPlayerManager.currentTitle.uppercased())
                        .font(KyberixTheme.Font.header())
                        .kyberixTracking()
                        .lineLimit(1)
                        .foregroundStyle(KyberixTheme.white)
                    Text(audioPlayerManager.currentArtist.isEmpty ? "UNKNOWN ARTIST" : audioPlayerManager.currentArtist.uppercased())
                        .font(KyberixTheme.Font.caption())
                        .kyberixTracking()
                        .foregroundColor(Color.gray)
                }

                Spacer()

                // Controls
                HStack(spacing: 24) {
                    Button(action: { audioPlayerManager.toggleShuffle() }) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(audioPlayerManager.isShuffle ? KyberixTheme.white : Color.gray)
                    }
                    .buttonStyle(.plain)

                    Button(action: { audioPlayerManager.previous() }) {
                        Image(systemName: "backward")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(KyberixTheme.white)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        if audioPlayerManager.isPlaying {
                            audioPlayerManager.pause()
                        } else {
                             if let song = playableSong {
                                 audioPlayerManager.playAudio(from: song, title: audioPlayerManager.currentTitle, artist: audioPlayerManager.currentArtist)
                             }
                        }
                    }) {
                        Image(systemName: audioPlayerManager.isPlaying ? "pause" : "play")
                            .font(.system(size: 28, weight: .thin))
                            .foregroundColor(KyberixTheme.white)
                    }
                    .buttonStyle(.plain)

                    Button(action: { audioPlayerManager.next() }) {
                        Image(systemName: "forward")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(KyberixTheme.white)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            // Middle: Scrubbing Slider
            HStack(spacing: 12) {
                Text(formatTime(audioPlayerManager.currentTime))
                    .font(KyberixTheme.Font.caption())
                    .monospacedDigit()
                    .foregroundStyle(KyberixTheme.white)

                KyberixSlider(value: Binding(
                    get: { audioPlayerManager.currentTime },
                    set: { audioPlayerManager.seek(to: $0) }
                ), range: 0...(audioPlayerManager.duration > 0 ? audioPlayerManager.duration : 1))

                Text(formatTime(audioPlayerManager.duration))
                    .font(KyberixTheme.Font.caption())
                    .monospacedDigit()
                    .foregroundStyle(KyberixTheme.white)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "speaker")
                        .font(.caption)
                        .foregroundColor(KyberixTheme.white)

                    KyberixSlider(value: Binding(
                        get: { audioPlayerManager.volume },
                        set: { audioPlayerManager.setVolume($0) }
                    ), range: 0...1)
                    .frame(width: 80)

                    Image(systemName: "speaker.wave.3")
                        .font(.caption)
                        .foregroundColor(KyberixTheme.white)
                }
            }
            .padding(.horizontal)

        }
        .padding(.vertical, 8)
        .background(KyberixTheme.black)
        .onChange(of: audioPlayerManager.currentSongURL) { _, newURL in
            if let url = newURL {
                playableSong = url
            }
        }
    }

    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
