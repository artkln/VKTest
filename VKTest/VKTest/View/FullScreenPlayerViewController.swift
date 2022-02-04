//
//  FullScreenPlayerViewController.swift
//  VKTest
//
//  Created by Артём Калинин on 31.01.2022.
//

import UIKit
import AVFoundation

final class FullScreenPlayerViewController: UIViewController {
    
    // MARK: - Private properties

    private let playerView = UIView()
    private let currentTimeLabel = UILabel()
    private let durationLabel = UILabel()
    private let timeSlider = UISlider()
    private let topContainerView = UIView()
    private let bottomContainerView = UIView()
    private let playPauseButton = UIButton()
    private let forwardsButton = UIButton()
    private let backwardsButton = UIButton()
    private let dismissButton = UIButton()
    
    private var player = AVPlayer()
    private var playerLayer = AVPlayerLayer()
    private var isVideoPlaying = false
    private var playerItemContext = 0
    private var currentTime = CMTime()
    
    // MARK: - Initialization
    
    convenience init(url: URL, currentTime: CMTime) {
        self.init(nibName: nil, bundle: nil)
        self.currentTime = currentTime
        configurePlayer(url: url)
    }

    deinit {
        player.currentItem?.removeObserver(self, forKeyPath: "duration")
    }

    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        view.addGestureRecognizer(tap)

        topContainerView.addSubviews(currentTimeLabel, durationLabel, timeSlider)
        bottomContainerView.addSubviews(playPauseButton, backwardsButton, forwardsButton, dismissButton)
        view.addSubviews(playerView, bottomContainerView, topContainerView)
        
        setupConstraints()
        configureAppearance()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = playerView.bounds
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if keyPath == "duration",
           let curentItem = player.currentItem,
           curentItem.duration.seconds > 0.0 {
            durationLabel.text = getStringTime(from: player.currentItem!.duration)
        }
    }

}

// MARK: - Private methods

private extension FullScreenPlayerViewController {

    func configurePlayer(url: URL) {
        player = AVPlayer(url: url)

        player.currentItem?.addObserver(self, forKeyPath: "duration", options: [.new, .initial], context: nil)
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.status), options: [.old, .new], context: &playerItemContext)
        addTimeObserver()

        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resize
        
        playerView.layer.addSublayer(playerLayer)
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

private extension FullScreenPlayerViewController {
    
    func configureAppearance() {
        view.backgroundColor = .clear

        configurePlayerView()
        configureContainerViews()
        configurePlayPauseButton()
        configureBackwardsButton()
        configureForwardsButton()
        configureDismissButton()
        configureCurrentTimeLabel()
        configureDurationLabel()
        configureSlider()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
            UIView.animate(withDuration: 0.3) {
                self.topContainerView.alpha = 0
                self.bottomContainerView.alpha = 0
            }
        }
    }
    
    func configurePlayerView() {
        playerView.backgroundColor = .black
        playerView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func configureContainerViews() {
        topContainerView.backgroundColor = .systemGray4
        topContainerView.translatesAutoresizingMaskIntoConstraints = false

        bottomContainerView.backgroundColor = .systemGray4
        bottomContainerView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func configurePlayPauseButton() {
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playPauseButton.addTarget(self, action: #selector(playPausePressed), for: .touchUpInside)
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func configureBackwardsButton() {
        backwardsButton.setImage(UIImage(systemName: "gobackward.15"), for: .normal)
        backwardsButton.addTarget(self, action: #selector(backwardsPressed), for: .touchUpInside)
        backwardsButton.translatesAutoresizingMaskIntoConstraints = false
    }

    func configureForwardsButton() {
        forwardsButton.setImage(UIImage(systemName: "goforward.15"), for: .normal)
        forwardsButton.addTarget(self, action: #selector(forwardsPressed), for: .touchUpInside)
        forwardsButton.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func configureDismissButton() {
        dismissButton.setImage(UIImage(systemName: "clear.fill"), for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissPressed), for: .touchUpInside)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func configureCurrentTimeLabel() {
        currentTimeLabel.text = "00:00"
        currentTimeLabel.textAlignment = .right
        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func configureDurationLabel() {
        durationLabel.text = "00:00"
        durationLabel.textAlignment = .left
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func configureSlider(){
        timeSlider.value = 0.0
        timeSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        timeSlider.translatesAutoresizingMaskIntoConstraints = false
    }

    func setupConstraints() {
        let safeArea = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            playerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            playerView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            playerView.widthAnchor.constraint(equalTo: playerView.heightAnchor, multiplier: 16.0/9.0),
            
            bottomContainerView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            bottomContainerView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            bottomContainerView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            bottomContainerView.heightAnchor.constraint(equalToConstant: 60.0),
            
            topContainerView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            topContainerView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            topContainerView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            topContainerView.heightAnchor.constraint(equalToConstant: 60.0),
            
            backwardsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 115.0),
            backwardsButton.centerYAnchor.constraint(equalTo: bottomContainerView.centerYAnchor),
            
            playPauseButton.leadingAnchor.constraint(equalTo: backwardsButton.trailingAnchor, constant: 30.0),
            playPauseButton.centerYAnchor.constraint(equalTo: bottomContainerView.centerYAnchor),
            
            forwardsButton.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 30.0),
            forwardsButton.centerYAnchor.constraint(equalTo: bottomContainerView.centerYAnchor),
            
            dismissButton.leadingAnchor.constraint(equalTo: forwardsButton.trailingAnchor, constant: 30.0),
            dismissButton.centerYAnchor.constraint(equalTo: bottomContainerView.centerYAnchor),
            
            timeSlider.centerYAnchor.constraint(equalTo: topContainerView.centerYAnchor),
            
            currentTimeLabel.centerYAnchor.constraint(equalTo: topContainerView.centerYAnchor),
            currentTimeLabel.leadingAnchor.constraint(equalTo: topContainerView.leadingAnchor, constant: 8.0),
            currentTimeLabel.widthAnchor.constraint(equalToConstant: 60.0),
            currentTimeLabel.trailingAnchor.constraint(equalTo: timeSlider.leadingAnchor, constant: -20.0),
            
            durationLabel.centerYAnchor.constraint(equalTo: topContainerView.centerYAnchor),
            durationLabel.leadingAnchor.constraint(equalTo: timeSlider.trailingAnchor, constant: 20.0),
            durationLabel.widthAnchor.constraint(equalToConstant: 60.0),
            durationLabel.trailingAnchor.constraint(equalTo: topContainerView.trailingAnchor, constant: -8.0),
        ])
    }
    
}

// MARK: - Actions

@objc
extension FullScreenPlayerViewController {
    
    func playPausePressed(_ sender: UIButton) {
        if isVideoPlaying {
            player.pause()
            sender.setImage(UIImage(systemName: "play.fill"), for: .normal)
        } else {
            player.play()
            sender.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        }
        
        isVideoPlaying.toggle()
    }
    
    func forwardsPressed(_ sender: Any) {
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
    
    func backwardsPressed(_ sender: Any) {
        let currentTime = CMTimeGetSeconds(player.currentTime())
        var newTime = currentTime - 15.0
        
        if newTime < 0 {
            newTime = 0
        }
        
        let time: CMTime = CMTimeMake(value: Int64(newTime * 1000), timescale: 1000)
        player.seek(to: time)
    }
    
    func sliderValueChanged(_ sender: UISlider) {
        player.seek(to: CMTimeMake(value: Int64(sender.value * 1000), timescale: 1000))
    }
    
    func onTap() {
        UIView.animate(withDuration: 0.3) {
            self.topContainerView.alpha = 1
            self.bottomContainerView.alpha = 1
        }

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
            UIView.animate(withDuration: 0.3) {
                self.topContainerView.alpha = 0
                self.bottomContainerView.alpha = 0
            }
        }
    }
    
    func dismissPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

}
