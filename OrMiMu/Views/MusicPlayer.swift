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
        HStack(spacing: 20) {
            // MARK: - Left: Artwork & Info
            HStack(spacing: 12) {
                if let artwork = audioPlayerManager.currentArtwork {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .border(Color.kyberixGrey, width: 1)
                        .clipped()
                } else {
                    Rectangle()
                        .stroke(Color.kyberixGrey, lineWidth: 1)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.kyberixGrey)
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(audioPlayerManager.currentTitle.isEmpty ? (playableSong?.deletingPathExtension().lastPathComponent ?? "UNKNOWN SONG") : audioPlayerManager.currentTitle)
                        .kyberixHeader()
                        .lineLimit(1)
                    Text(audioPlayerManager.currentArtist.isEmpty ? "UNKNOWN ARTIST" : audioPlayerManager.currentArtist)
                        .font(.caption2)
                        .foregroundStyle(Color.kyberixGrey)
                        .lineLimit(1)
                }
            }
            .frame(width: 250, alignment: .leading)

            Spacer()

            // MARK: - Center: Controls
            VStack(spacing: 8) {
                // Playback Buttons
                HStack(spacing: 24) {
                    Button(action: { audioPlayerManager.toggleShuffle() }) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 14))
                            .foregroundStyle(audioPlayerManager.isShuffle ? Color.kyberixWhite : Color.kyberixGrey)
                    }
                    .buttonStyle(.plain)

                    Button(action: { audioPlayerManager.previous() }) {
                        Image(systemName: "backward.end.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.kyberixWhite)
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
                        Image(systemName: audioPlayerManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.kyberixWhite)
                    }
                    .buttonStyle(.plain)

                    Button(action: { audioPlayerManager.next() }) {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.kyberixWhite)
                    }
                    .buttonStyle(.plain)

                    Button(action: { /* Repeat Logic - Placeholder */ }) {
                        Image(systemName: "repeat")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.kyberixGrey)
                    }
                    .buttonStyle(.plain)
                }

                // Progress Bar
                HStack(spacing: 8) {
                    Text(formatTime(audioPlayerManager.currentTime))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.kyberixGrey)
                        .frame(width: 35, alignment: .trailing)

                    KyberixGeometricSlider(value: Binding(
                        get: { audioPlayerManager.currentTime },
                        set: { audioPlayerManager.seek(to: $0) }
                    ), range: 0...(audioPlayerManager.duration > 0 ? audioPlayerManager.duration : 1))
                    .frame(height: 10)

                    Text(formatTime(audioPlayerManager.duration))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.kyberixGrey)
                        .frame(width: 35, alignment: .leading)
                }
                .frame(maxWidth: 400)
            }

            Spacer()

            // MARK: - Right: Volume
            HStack(spacing: 8) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.kyberixGrey)
                
                KyberixGeometricSlider(value: Binding(
                    get: { audioPlayerManager.volume },
                    set: { audioPlayerManager.setVolume($0) }
                ), range: 0...1)
                .frame(width: 80, height: 10)
                
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.kyberixGrey)
            }
            .frame(width: 150, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.kyberixBlack)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.kyberixGrey), alignment: .top)
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

// Local Geometric Slider Component
struct KyberixGeometricSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let rangeSpan = range.upperBound - range.lowerBound
            let progress = rangeSpan > 0 ? (value - range.lowerBound) / rangeSpan : 0
            let thumbSize: CGFloat = 6
            let xOffset = width * CGFloat(progress) - (thumbSize / 2)

            ZStack(alignment: .center) {
                // Hit Area
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())

                // Track (Background Line)
                Rectangle()
                    .fill(Color.kyberixGrey)
                    .frame(height: 1)

                // Active Track (Progress Line)
                HStack {
                    Rectangle()
                        .fill(Color.kyberixWhite)
                        .frame(width: max(0, min(width, width * CGFloat(progress))), height: 1)
                    Spacer(minLength: 0)
                }

                // Thumb (Small Square)
                HStack {
                    Rectangle()
                        .fill(Color.kyberixWhite)
                        .frame(width: thumbSize, height: thumbSize)
                        .offset(x: xOffset)
                    Spacer(minLength: 0)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let newValue = range.lowerBound + Double(gesture.location.x / width) * rangeSpan
                        value = min(max(range.lowerBound, newValue), range.upperBound)
                    }
            )
        }
    }
}
