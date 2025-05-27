import AVFoundation
import SwiftUI

class TBPlayer: ObservableObject {
    private var windupSound: AVAudioPlayer
    private var dingSound: AVAudioPlayer
    private var tickingSound: AVAudioPlayer
    private var darkSound: AVAudioPlayer
    private var rainySound: AVAudioPlayer

    @AppStorage("windupVolume") var windupVolume: Double = 1.0 {
        didSet {
            setVolume(windupSound, windupVolume)
        }
    }
    @AppStorage("dingVolume") var dingVolume: Double = 1.0 {
        didSet {
            setVolume(dingSound, dingVolume)
        }
    }
    @AppStorage("tickingVolume") var tickingVolume: Double = 1.0 {
        didSet {
            setVolume(tickingSound, tickingVolume)
        }
    }
    
    @AppStorage("darkVolume") var darkVolume: Double = 0.0 {
        didSet {
            setVolume(darkSound, darkVolume)
        }
    }

    @AppStorage("rainyVolume") var rainyVolume: Double = 0.0 {
        didSet {
            setVolume(rainySound, rainyVolume)
        }
    }
        
    private func setVolume(_ sound: AVAudioPlayer, _ volume: Double) {
        sound.setVolume(Float(volume), fadeDuration: 0)
    }

    init() {
        let windupSoundAsset = NSDataAsset(name: "windup")
        let dingSoundAsset = NSDataAsset(name: "ding")
        let tickingSoundAsset = NSDataAsset(name: "ticking")
        let darkSoundAsset = NSDataAsset(name: "dark")
        let rainySoundAsset = NSDataAsset(name: "rainy")

        let wav = AVFileType.wav.rawValue
        do {
            windupSound = try AVAudioPlayer(data: windupSoundAsset!.data, fileTypeHint: wav)
            dingSound = try AVAudioPlayer(data: dingSoundAsset!.data, fileTypeHint: wav)
            tickingSound = try AVAudioPlayer(data: tickingSoundAsset!.data, fileTypeHint: wav)
            darkSound = try AVAudioPlayer(data: darkSoundAsset!.data, fileTypeHint: wav)
            rainySound = try AVAudioPlayer(data: rainySoundAsset!.data, fileTypeHint: wav)
        } catch {
            fatalError("Error initializing players: \(error)")
        }

        windupSound.prepareToPlay()
        dingSound.prepareToPlay()
        tickingSound.numberOfLoops = -1
        tickingSound.prepareToPlay()
        darkSound.prepareToPlay()
        darkSound.numberOfLoops = -1
        rainySound.prepareToPlay()
        rainySound.numberOfLoops = -1

        setVolume(windupSound, windupVolume)
        setVolume(dingSound, dingVolume)
        setVolume(tickingSound, tickingVolume)
        setVolume(rainySound, rainyVolume)
        setVolume(darkSound, darkVolume)
    }

    func playWindup() {
        windupSound.play()
    }

    func playDing() {
        dingSound.play()
    }

    func startTicking() {
        tickingSound.play()
    }

    func startDark() {
        darkSound.play()
    }
    
    func startRainy() {
        rainySound.play()
    }

    func stopTicking() {
        tickingSound.stop()
    }
    
    func stopDark() {
        darkSound.stop()
    }
    
    func stopRainy() {
        rainySound.stop()
    }
}
