//
//  PlayerViewController.swift
//  VKTest
//
//  Created by Артём Калинин on 31.01.2022.
//

import UIKit
import AVFoundation

final class PlayerViewController: UIViewController {

    @IBOutlet private weak var playerView: UIView!
    @IBOutlet private weak var currentTimeLabel: UILabel!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var timeSlider: UISlider!
    
    private var player = AVPlayer()
    private var playerLayer = AVPlayerLayer()
    private var isVideoPlaying = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let URL = URL(string: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4") else {
            return
        }
        
        player = AVPlayer(url: URL)
        
        player.currentItem?.addObserver(self, forKeyPath: "duration", options: [.new, .initial], context: nil)
        addTimeObserver()

        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resize
        
        playerView.layer.addSublayer(playerLayer)
        
    }
    
    deinit {
        player.currentItem?.removeObserver(self, forKeyPath: "duration")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        playerLayer.frame = playerView.bounds
    }
    
    func addTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        _ = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] time in
            guard let currentItem = self?.player.currentItem else {
                return
            }
            
            self?.timeSlider.maximumValue = Float(currentItem.duration.seconds)
            self?.timeSlider.minimumValue = 0
            self?.timeSlider.value = Float(currentItem.currentTime().seconds)
            self?.currentTimeLabel.text = self?.getStringTime(from: currentItem.currentTime())
        }
    }
    
    @IBAction func playPausePressed(_ sender: UIButton) {
        if isVideoPlaying {
            player.pause()
            sender.setImage(UIImage(systemName: "play"), for: .normal)
        } else {
            player.play()
            sender.setImage(UIImage(systemName: "pause"), for: .normal)
        }
        
        isVideoPlaying.toggle()
    }
    
    @IBAction func forwardsPressed(_ sender: Any) {
        guard let duration = player.currentItem?.duration else {
            return
        }
        
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = currentTime + 15.0
        
        if newTime < (CMTimeGetSeconds(duration) - 15.0) {
            let time: CMTime = CMTimeMake(value: Int64(newTime * 1000), timescale: 1000)
            player.seek(to: time)
        }
    }
    
    
    @IBAction func backwardsPressed(_ sender: Any) {
        let currentTime = CMTimeGetSeconds(player.currentTime())
        var newTime = currentTime - 15.0
        
        if newTime < 0 {
            newTime = 0
        }
        
        let time: CMTime = CMTimeMake(value: Int64(newTime * 1000), timescale: 1000)
        player.seek(to: time)
    }
    
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        player.seek(to: CMTimeMake(value: Int64(sender.value * 1000), timescale: 1000))
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if keyPath == "duration",
           let duration = player.currentItem?.duration.seconds,
           duration > 0.0 {
            durationLabel.text = getStringTime(from: player.currentItem!.duration)
        }
    }
    
    func getStringTime(from time: CMTime) -> String {
        let totalSeconds = CMTimeGetSeconds(time)
        let hours = Int(totalSeconds / 3600)
        let minutes = Int(totalSeconds / 60) % 60
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return String(format: "%i:%02i:%02i", arguments: [hours, minutes, seconds])
        } else {
            return String(format: "%02i:%02i", arguments: [minutes, seconds])
        }
    }
}

