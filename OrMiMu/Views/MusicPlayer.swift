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
        VStack(spacing: 4) {
            // Top: Song Info + Shuffle/Repeat
            HStack {
                // Left: Artwork
                if let artwork = audioPlayerManager.currentArtwork {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .border(Color.kyberixGrey, width: 1)
                } else {
                    KyberixIcon(name: "music.note", size: 30)
                        .frame(width: 30, height: 30)
                        .padding(15)
                        .background(Color.kyberixBlack)
                        .overlay(Rectangle().stroke(Color.kyberixGrey, lineWidth: 1))
                }

                VStack(alignment: .leading) {
                    Text(audioPlayerManager.currentTitle.isEmpty ? (playableSong?.deletingPathExtension().lastPathComponent ?? "UNKNOWN SONG") : audioPlayerManager.currentTitle)
                        .kyberixHeader()
                        .lineLimit(1)
                    Text(audioPlayerManager.currentArtist.isEmpty ? "UNKNOWN ARTIST" : audioPlayerManager.currentArtist)
                        .font(.caption)
                        .foregroundStyle(Color.kyberixGrey)
                }

                Spacer()

                Button(action: { audioPlayerManager.toggleShuffle() }) {
                    KyberixIcon(name: "shuffle")
                        .foregroundStyle(audioPlayerManager.isShuffle ? Color.kyberixWhite : Color.kyberixGrey)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)

                Button(action: { audioPlayerManager.previous() }) {
                    KyberixIcon(name: "backward")
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
                    KyberixIcon(name: audioPlayerManager.isPlaying ? "pause.circle" : "play.circle", size: 40)
                }
                .buttonStyle(.plain)

                Button(action: { audioPlayerManager.next() }) {
                    KyberixIcon(name: "forward")
                }
                .buttonStyle(.plain)

            }
            .padding(.horizontal)

            // Middle: Scrubbing Slider
            HStack(spacing: 8) {
                Text(formatTime(audioPlayerManager.currentTime))
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(Color.kyberixWhite)

                KyberixSlider(value: Binding(
                    get: { audioPlayerManager.currentTime },
                    set: { audioPlayerManager.seek(to: $0) }
                ), range: 0...(audioPlayerManager.duration > 0 ? audioPlayerManager.duration : 1))

                Text(formatTime(audioPlayerManager.duration))
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(Color.kyberixWhite)
                
                
                Spacer()
                
                HStack {
                    KyberixIcon(name: "speaker", size: 12)
                    KyberixSlider(value: Binding(
                        get: { audioPlayerManager.volume },
                        set: { audioPlayerManager.setVolume($0) }
                    ), range: 0...1)
                    .frame(width: 80)
                    KyberixIcon(name: "speaker.wave.3", size: 12)
                }
            }
            .padding(.horizontal)

        }
        .padding(.vertical, 8)
        .background(Color.kyberixBlack)
        .onAppear {
            if let song = playableSong, !audioPlayerManager.isPlaying {
            }
        }
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
