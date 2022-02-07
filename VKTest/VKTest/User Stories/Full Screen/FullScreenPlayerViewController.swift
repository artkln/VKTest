//
//  FullScreenPlayerViewController.swift
//  VKTest
//
//  Created by Артём Калинин on 31.01.2022.
//

import UIKit
import AVFoundation

final class FullScreenPlayerViewController: UIViewController {

    // MARK: - Constants

    private enum Constants {
        static let timeLabelInitialText = "00:00"
        static let sliderInitialValue: Float = 0.0
        static let currentTimeObserverInterval: Double = 0.5
        static let secondsInHour: Double = 3600
        static let secondsInMinute: Double = 60
        static let minutesInHour: Int = 60
        static let durationFormatWithHours = "%i:%02i:%02i"
        static let durationFormatWithMinutes = "%02i:%02i"
        static let disappearingControlsDuration: TimeInterval = 0.3
        static let appearingControlsDuration: TimeInterval = 0.3
        static let playButtonName = "play.fill"
        static let pauseButtonName = "pause.fill"
        static let forwardsButtonName = "goforward.15"
        static let backwardsButtonName = "gobackward.15"
        static let muteButtonName = "speaker.fill"
        static let unmuteButtonName = "speaker.slash.fill"
        static let dismissButtonName = "clear.fill"
        static let timeIntervalToJump: Float64 = 15.0
        static let timescale: Double = 1000
        static let playerViewAspectRatio: CGFloat = 16.0 / 9.0
        static let topContainerViewHeight: CGFloat = 60.0
        static let bottomContainerViewHeight: CGFloat = 60.0
        static let controlButtonLeadingSpacing: CGFloat = 30.0
        static let controlButtonTrailingSpacing: CGFloat = -30.0
        static let currentTimeLabelWidth: CGFloat = 60.0
        static let currentTimeLabelLeadingIndent: CGFloat = 8.0
        static let currentTimeLabelTrailingIndent: CGFloat = -20.0
        static let durationLabelWidth: CGFloat = 60.0
        static let durationLabelLeadingIndent: CGFloat = 20.0
        static let durationLabelTrailingIndent: CGFloat = -8.0
    }

    // MARK: - Properties

    var onFullScreenClosed: ((CMTime) -> Void)?

    // MARK: - Private properties

    private var player = AVPlayer()
    private var playerLayer = AVPlayerLayer()
    private var isVideoPlaying = false
    private var isVideoMuted = false
    private var currentTime = CMTime()

    // MARK: - Private computed properties

    private var playerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let currentTimeLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.timeLabelInitialText
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.timeLabelInitialText
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let timeSlider: UISlider = {
        let slider = UISlider()
        slider.value = Constants.sliderInitialValue
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()

    private let topContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let bottomContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var playPauseButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: Constants.playButtonName), for: .normal)
        button.addTarget(self, action: #selector(playPausePressed), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var forwardsButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: Constants.forwardsButtonName), for: .normal)
        button.addTarget(self, action: #selector(forwardsPressed), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var backwardsButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: Constants.backwardsButtonName), for: .normal)
        button.addTarget(self, action: #selector(backwardsPressed), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var muteButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: Constants.muteButtonName), for: .normal)
        button.addTarget(self, action: #selector(mutePressed), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let dismissButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: Constants.dismissButtonName), for: .normal)
        button.addTarget(self, action: #selector(dismissPressed), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    

    // MARK: - Initialization

    convenience init(url: URL, currentTime: CMTime) {
        self.init(nibName: nil, bundle: nil)
        self.currentTime = currentTime
        configurePlayer(with: url)
    }

    // MARK: - Deinitialization

    deinit {
        player.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        view.addGestureRecognizer(tap)

        topContainerView.addSubviews(
            timeSlider,
            durationLabel,
            currentTimeLabel
        )

        bottomContainerView.addSubviews(
            backwardsButton,
            playPauseButton,
            forwardsButton,
            muteButton,
            dismissButton
        )

        view.addSubviews(
            playerView,
            topContainerView,
            bottomContainerView
        )

        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = playerView.bounds
    }

    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayerItem.status),
           let currentItem = player.currentItem,
           currentItem.status == .readyToPlay {
            durationLabel.text = getStringTime(from: currentItem.duration)
            player.seek(to: currentTime)
        }
    }

}

// MARK: - Private methods

private extension FullScreenPlayerViewController {

    func configurePlayer(with url: URL) {
        player = AVPlayer(url: url)

        player.currentItem?.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayerItem.status),
            options: [.old, .new],
            context: nil
        )
        addCurrentTimeObserver()

        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resize

        playerView.layer.addSublayer(playerLayer)
    }

    func addCurrentTimeObserver() {
        let interval = CMTime(
            seconds: Constants.currentTimeObserverInterval,
            preferredTimescale: CMTimeScale(NSEC_PER_SEC)
        )

        _ = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            guard
                let self = self,
                let currentItem = self.player.currentItem else {
                return
            }

            self.timeSlider.maximumValue = Float(currentItem.duration.seconds)
            self.timeSlider.minimumValue = Constants.sliderInitialValue
            self.timeSlider.value = Float(currentItem.currentTime().seconds)
            self.currentTimeLabel.text = self.getStringTime(from: currentItem.currentTime())
        }
    }

    func getStringTime(from time: CMTime) -> String {
        let totalSeconds = CMTimeGetSeconds(time)
        let hours = Int(totalSeconds / Constants.secondsInHour)
        let minutes = Int(totalSeconds / Constants.secondsInMinute) % Constants.minutesInHour
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: Constants.secondsInMinute))

        if hours > 0 {
            return String(format: Constants.durationFormatWithHours, arguments: [hours, minutes, seconds])
        } else {
            return String(format: Constants.durationFormatWithMinutes, arguments: [minutes, seconds])
        }
    }

}

// MARK: - Appearance

private extension FullScreenPlayerViewController {

    func setupUI() {
        view.backgroundColor = .clear
        
        NSLayoutConstraint.activate([
            playerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.widthAnchor.constraint(
                equalTo: playerView.heightAnchor,
                multiplier: Constants.playerViewAspectRatio
            ),
            
            topContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topContainerView.heightAnchor.constraint(equalToConstant: Constants.topContainerViewHeight),
            
            bottomContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomContainerView.heightAnchor.constraint(equalToConstant: Constants.bottomContainerViewHeight),
            
            forwardsButton.centerXAnchor.constraint(equalTo: bottomContainerView.centerXAnchor),
            forwardsButton.centerYAnchor.constraint(equalTo: bottomContainerView.centerYAnchor),
            
            playPauseButton.trailingAnchor.constraint(
                equalTo: forwardsButton.leadingAnchor,
                constant: Constants.controlButtonTrailingSpacing
            ),
            playPauseButton.centerYAnchor.constraint(equalTo: bottomContainerView.centerYAnchor),
            
            backwardsButton.trailingAnchor.constraint(
                equalTo: playPauseButton.leadingAnchor,
                constant: Constants.controlButtonTrailingSpacing
            ),
            backwardsButton.centerYAnchor.constraint(equalTo: bottomContainerView.centerYAnchor),
            
            muteButton.leadingAnchor.constraint(
                equalTo: forwardsButton.trailingAnchor,
                constant: Constants.controlButtonLeadingSpacing
            ),
            muteButton.centerYAnchor.constraint(equalTo: bottomContainerView.centerYAnchor),
            
            dismissButton.leadingAnchor.constraint(
                equalTo: muteButton.trailingAnchor,
                constant: Constants.controlButtonLeadingSpacing
            ),
            dismissButton.centerYAnchor.constraint(equalTo: bottomContainerView.centerYAnchor),
            
            timeSlider.centerYAnchor.constraint(equalTo: topContainerView.centerYAnchor),
            
            currentTimeLabel.centerYAnchor.constraint(equalTo: topContainerView.centerYAnchor),
            currentTimeLabel.leadingAnchor.constraint(
                equalTo: topContainerView.leadingAnchor,
                constant: Constants.currentTimeLabelLeadingIndent
            ),
            currentTimeLabel.widthAnchor.constraint(equalToConstant: Constants.currentTimeLabelWidth),
            currentTimeLabel.trailingAnchor.constraint(
                equalTo: timeSlider.leadingAnchor,
                constant: Constants.currentTimeLabelTrailingIndent
            ),
            
            durationLabel.centerYAnchor.constraint(equalTo: topContainerView.centerYAnchor),
            durationLabel.leadingAnchor.constraint(
                equalTo: timeSlider.trailingAnchor,
                constant: Constants.durationLabelLeadingIndent
            ),
            durationLabel.widthAnchor.constraint(equalToConstant: Constants.durationLabelWidth),
            durationLabel.trailingAnchor.constraint(
                equalTo: topContainerView.trailingAnchor,
                constant: Constants.durationLabelTrailingIndent
            )
        ])

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
            UIView.animate(withDuration: Constants.disappearingControlsDuration) {
                self.topContainerView.alpha = 0
                self.bottomContainerView.alpha = 0
            }
        }
    }

    func pauseVideo() {
        player.pause()
        playPauseButton.setImage(UIImage(systemName: Constants.playButtonName), for: .normal)
        isVideoPlaying = false
    }

    func playVideo() {
        player.play()
        playPauseButton.setImage(UIImage(systemName: Constants.pauseButtonName), for: .normal)
        isVideoPlaying = true
    }

}

// MARK: - Actions

@objc
extension FullScreenPlayerViewController {

    func playPausePressed(_ sender: UIButton) {
        isVideoPlaying ? pauseVideo() : playVideo()
    }

    func forwardsPressed(_ sender: Any) {
        guard let duration = player.currentItem?.duration else {
            return
        }

        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = currentTime + Constants.timeIntervalToJump

        if newTime < (CMTimeGetSeconds(duration) - Constants.timeIntervalToJump) {
            let time: CMTime = CMTimeMake(
                value: Int64(newTime * Constants.timescale),
                timescale: Int32(Constants.timescale)
            )
            player.seek(to: time)
        }
    }

    func backwardsPressed(_ sender: Any) {
        let currentTime = CMTimeGetSeconds(player.currentTime())
        var newTime = currentTime - Constants.timeIntervalToJump

        if newTime < 0 {
            newTime = 0
        }

        let time: CMTime = CMTimeMake(
            value: Int64(newTime * Constants.timescale),
            timescale: Int32(Constants.timescale)
        )
        player.seek(to: time)
    }

    func sliderValueChanged(_ sender: UISlider) {
        player.seek(to: CMTimeMake(
                            value: Int64(Double(sender.value) * Constants.timescale),
                            timescale: Int32(Constants.timescale)
                    ))
    }

    func onTap() {
        UIView.animate(withDuration: Constants.appearingControlsDuration) {
            self.topContainerView.alpha = 1
            self.bottomContainerView.alpha = 1
        }

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
            UIView.animate(withDuration: Constants.disappearingControlsDuration) {
                self.topContainerView.alpha = 0
                self.bottomContainerView.alpha = 0
            }
        }
    }

    func dismissPressed(_ sender: Any) {
        onFullScreenClosed?(player.currentTime())
        dismiss(animated: true, completion: nil)
        pauseVideo()
    }

    func mutePressed(_ sender: UIButton) {
        if isVideoMuted {
            player.isMuted = false
            sender.setImage(UIImage(systemName: Constants.muteButtonName), for: .normal)
        } else {
            player.isMuted = true
            sender.setImage(UIImage(systemName: Constants.unmuteButtonName), for: .normal)
        }

        isVideoMuted.toggle()
    }

}
