//
//  MainViewController.swift
//  VKTest
//
//  Created by Артём Калинин on 04.02.2022.
//

import UIKit
import AVFoundation

final class MainViewController: UIViewController {

    // MARK: - Constants

    private enum Constants {
        static let infoLabelText = "Введите URL видеоресурса:"
        static let submitButtonText = "Загрузить"
        static let submitButtonCornerRadius: CGFloat = 5.0
        static let textFieldCornerRadius: CGFloat = 5.0
        static let textFieldBorderWidth: CGFloat = 1.0
        static let playButtonName = "play.fill"
        static let pauseButtonName = "pause.fill"
        static let forwardsButtonName = "goforward.15"
        static let backwardsButtonName = "gobackward.15"
        static let muteButtonName = "speaker.fill"
        static let unmuteButtonName = "speaker.slash.fill"
        static let fullScreenButtonName = "square.filled.on.square"
        static let timeIntervalToJump: Double = 15.0
        static let timescale: Double = 1000
        static let infoLabelTopIndent: CGFloat = 50.0
        static let urlTextFieldTopIndent: CGFloat = 30.0
        static let urlTextFieldLeadingIndent: CGFloat = 40.0
        static let urlTextFieldHeight: CGFloat = 30.0
        static let submitButtonTopIndent: CGFloat = 30.0
        static let submitButtonHeight: CGFloat = 30.0
        static let submitButtonWidth: CGFloat = 100.0
        static let playerViewTopIndent: CGFloat = 30.0
        static let playerViewAspectRatio: CGFloat = 16.0 / 9.0
        static let forwardsButtonTopIndent: CGFloat = 20.0
        static let controlButtonLeadingSpacing: CGFloat = 30.0
        static let controlButtonTrailingSpacing: CGFloat = -30.0
        static let alertControllerTitle = "Ошибка"
        static let alertActionTitle = "ОК"
    }

    // MARK: - Private properties

    private var player = AVPlayer()
    private var playerLayer = AVPlayerLayer()
    private var isVideoPlaying = false
    private var isVideoMuted = false

    // MARK: - Private computed properties

    private var infoLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.infoLabelText
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var submitButton: UIButton = {
        let button = UIButton()
        button.setTitle(Constants.submitButtonText, for: .normal)
        button.addTarget(self, action: #selector(submitPressed), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = Constants.submitButtonCornerRadius
        return button
    }()

    private var urlTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.layer.cornerRadius = Constants.textFieldCornerRadius
        textField.layer.borderWidth = Constants.textFieldBorderWidth
        textField.layer.borderColor = UIColor.black.cgColor
        return textField
    }()

    private var playerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
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

    private var fullScreenButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: Constants.fullScreenButtonName), for: .normal)
        button.addTarget(self, action: #selector(fullScreenPressed), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    // MARK: - Deinitialization

    deinit {
        player.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        urlTextField.delegate = self
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(UIInputViewController.dismissKeyboard)
        )
        view.addGestureRecognizer(tap)

        playerView.addSubview(activityIndicator)
        view.addSubviews(
            infoLabel,
            urlTextField,
            submitButton,
            playerView,
            forwardsButton,
            playPauseButton,
            backwardsButton,
            muteButton,
            fullScreenButton
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
           let currentItem = player.currentItem {
            do {
                try checkCurrentItemStatus(currentItem.status)
            } catch let error as PlayerError {
                showAlert(with: error.description)
            } catch let error {
                showAlert(with: error.localizedDescription)
            }

            activityIndicator.stopAnimating()
        }
    }

    // MARK: - Private methods

    private func checkCurrentItemStatus(_ status: AVPlayerItem.Status) throws {
        switch status {
        case .readyToPlay:
            activateButtons()
        case .failed:
            deactivateButtons(submitDeactivationNeeded: false)
            throw PlayerError.wrongURL
        case .unknown:
            deactivateButtons(submitDeactivationNeeded: false)
            throw PlayerError.unknown
        @unknown default:
            deactivateButtons(submitDeactivationNeeded: false)
            throw PlayerError.unknown
        }
    }

    private func configurePlayer() throws {
        guard
            let inputText = urlTextField.text,
            !inputText.isEmpty else {
            throw PlayerError.emptyInput
        }

        guard let URL = URL(string: inputText) else {
            throw PlayerError.notURLConvertible
        }

        player = AVPlayer(url: URL)

        player.currentItem?.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayerItem.status),
            options: [.old, .new],
            context: nil
        )

        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resize

        playerView.layer.addSublayer(playerLayer)
    }

}

// MARK: - Appearance

private extension MainViewController {

    func setupUI() {
        view.backgroundColor = .white

        NSLayoutConstraint.activate([
            infoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            infoLabel.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: Constants.infoLabelTopIndent
            ),
            
            urlTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            urlTextField.topAnchor.constraint(
                equalTo: infoLabel.bottomAnchor,
                constant: Constants.urlTextFieldTopIndent
            ),
            urlTextField.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: Constants.urlTextFieldLeadingIndent
            ),
            urlTextField.heightAnchor.constraint(equalToConstant: Constants.urlTextFieldHeight),
            
            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            submitButton.topAnchor.constraint(
                equalTo: urlTextField.bottomAnchor,
                constant: Constants.submitButtonTopIndent
            ),
            submitButton.heightAnchor.constraint(equalToConstant: Constants.submitButtonHeight),
            submitButton.widthAnchor.constraint(equalToConstant: Constants.submitButtonWidth),
            
            playerView.topAnchor.constraint(
                equalTo: submitButton.bottomAnchor,
                constant: Constants.playerViewTopIndent
            ),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.widthAnchor.constraint(
                equalTo: playerView.heightAnchor,
                multiplier: Constants.playerViewAspectRatio
            ),
            
            activityIndicator.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
            
            forwardsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            forwardsButton.topAnchor.constraint(
                equalTo: playerView.bottomAnchor,
                constant: Constants.forwardsButtonTopIndent
            ),
            
            playPauseButton.trailingAnchor.constraint(
                equalTo: forwardsButton.leadingAnchor,
                constant: Constants.controlButtonTrailingSpacing
            ),
            playPauseButton.topAnchor.constraint(equalTo: forwardsButton.topAnchor),
            
            backwardsButton.trailingAnchor.constraint(
                equalTo: playPauseButton.leadingAnchor,
                constant: Constants.controlButtonTrailingSpacing
            ),
            backwardsButton.topAnchor.constraint(equalTo: forwardsButton.topAnchor),
            
            muteButton.leadingAnchor.constraint(
                equalTo: forwardsButton.trailingAnchor,
                constant: Constants.controlButtonLeadingSpacing
            ),
            muteButton.topAnchor.constraint(equalTo: forwardsButton.topAnchor),
            
            fullScreenButton.leadingAnchor.constraint(
                equalTo: muteButton.trailingAnchor,
                constant: Constants.controlButtonLeadingSpacing
            ),
            fullScreenButton.topAnchor.constraint(equalTo: forwardsButton.topAnchor)
        ])

        deactivateButtons(submitDeactivationNeeded: false)
    }

    func showAlert(with description: String) {
        let alert = UIAlertController(
            title: Constants.alertControllerTitle,
            message: description, preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: Constants.alertActionTitle, style: .default, handler: nil))
        present(alert, animated: true)
    }

    func activateButtons() {
        submitButton.isEnabled = true
        submitButton.alpha = 1
        backwardsButton.isEnabled = true
        playPauseButton.isEnabled = true
        forwardsButton.isEnabled = true
        muteButton.isEnabled = true
        fullScreenButton.isEnabled = true
    }

    func deactivateButtons(submitDeactivationNeeded: Bool) {
        if submitDeactivationNeeded {
            submitButton.isEnabled = false
            submitButton.alpha = 0.5
        }

        backwardsButton.isEnabled = false
        playPauseButton.isEnabled = false
        forwardsButton.isEnabled = false
        muteButton.isEnabled = false
        fullScreenButton.isEnabled = false
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
extension MainViewController {

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

    func submitPressed(_ sender: Any) {
        do {
            try configurePlayer()
        } catch let error as PlayerError {
            showAlert(with: error.description)
        } catch let error {
            showAlert(with: error.localizedDescription)
        }

        deactivateButtons(submitDeactivationNeeded: true)
        activityIndicator.startAnimating()
    }

    func dismissKeyboard() {
        view.endEditing(true)
    }

    func fullScreenPressed(_ sender: Any) {
        guard let URL = URL(string: urlTextField.text ?? "") else {
            return
        }

        let currentTime = player.currentTime()
        let vc = FullScreenPlayerViewController(url: URL, currentTime: currentTime)
        vc.modalPresentationStyle = .fullScreen
        vc.onFullScreenClosed = { [weak self] fullScreenTime in
            guard let self = self else {
                return
            }
            
            self.player.seek(to: fullScreenTime)
        }

        present(vc, animated: true, completion: nil)
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

// MARK: - UITextFieldDelegate

extension MainViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        urlTextField.resignFirstResponder()
        return true
    }

}
