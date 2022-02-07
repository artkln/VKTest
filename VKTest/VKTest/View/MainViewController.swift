//
//  MainViewController.swift
//  VKTest
//
//  Created by Артём Калинин on 04.02.2022.
//

import UIKit
import AVFoundation

final class MainViewController: UIViewController {
    
    // MARK: - Private properties
    
    private let infoLabel = UILabel()
    private let submitButton = UIButton()
    private let urlTextField = UITextField()
    private let playerView = UIView()
    private let playPauseButton = UIButton()
    private let forwardsButton = UIButton()
    private let backwardsButton = UIButton()
    private let fullScreenButton = UIButton()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    private var player = AVPlayer()
    private var playerLayer = AVPlayerLayer()
    private var isVideoPlaying = false

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
        guard let inputText = urlTextField.text,
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

    func configureAppearance() {
        view.backgroundColor = .white

        configureInfoLabel()
        configureTextField()
        configureSubmitButton()
        configurePlayerView()
        configureActivityIndicator()
        configurePlayPauseButton()
        configureBackwardsButton()
        configureForwardsButton()
        configureFullScreenButton()

        deactivateButtons(submitDeactivationNeeded: false)
    }
    
    func configureInfoLabel() {
        infoLabel.text = "Введите URL видеоресурса:"
        infoLabel.textAlignment = .center
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(infoLabel)
        
        NSLayoutConstraint.activate([
            infoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            infoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50.0)
        ])
    }
    
    func configureTextField() {
        urlTextField.translatesAutoresizingMaskIntoConstraints = false
        urlTextField.layer.cornerRadius = 5.0
        urlTextField.layer.borderWidth = 1.0
        urlTextField.layer.borderColor = UIColor.black.cgColor
        
        view.addSubview(urlTextField)
        
        NSLayoutConstraint.activate([
            urlTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            urlTextField.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 30.0),
            urlTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40.0),
            urlTextField.heightAnchor.constraint(equalToConstant: 30.0)
        ])
    }

    func configureSubmitButton() {
        submitButton.setTitle("Загрузить", for: .normal)
        submitButton.addTarget(self, action: #selector(submitPressed), for: .touchUpInside)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.backgroundColor = .systemBlue
        submitButton.layer.cornerRadius = 5.0
        
        view.addSubview(submitButton)
        
        NSLayoutConstraint.activate([
            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            submitButton.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 30.0),
            submitButton.heightAnchor.constraint(equalToConstant: 30.0),
            submitButton.widthAnchor.constraint(equalToConstant: 100.0)
        ])
    }
    
    func configurePlayerView() {
        playerView.backgroundColor = .black
        playerView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(playerView)
        
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: submitButton.bottomAnchor, constant: 30),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.widthAnchor.constraint(equalTo: playerView.heightAnchor, multiplier: 16.0/9.0)
        ])
    }
    
    func configureActivityIndicator() {
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        playerView.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: playerView.centerYAnchor)
        ])
    }
    
    func configurePlayPauseButton() {
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playPauseButton.addTarget(self, action: #selector(playPausePressed), for: .touchUpInside)
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(playPauseButton)
        
        NSLayoutConstraint.activate([
            playPauseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playPauseButton.topAnchor.constraint(equalTo: playerView.bottomAnchor, constant: 20)
        ])
    }
    
    func configureBackwardsButton() {
        backwardsButton.setImage(UIImage(systemName: "gobackward.15"), for: .normal)
        backwardsButton.addTarget(self, action: #selector(backwardsPressed), for: .touchUpInside)
        backwardsButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(backwardsButton)
        
        NSLayoutConstraint.activate([
            backwardsButton.trailingAnchor.constraint(equalTo: playPauseButton.leadingAnchor, constant: -30.0),
            backwardsButton.topAnchor.constraint(equalTo: playPauseButton.topAnchor)
        ])
    }

    func configureForwardsButton() {
        forwardsButton.setImage(UIImage(systemName: "goforward.15"), for: .normal)
        forwardsButton.addTarget(self, action: #selector(forwardsPressed), for: .touchUpInside)
        forwardsButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(forwardsButton)
        
        NSLayoutConstraint.activate([
            forwardsButton.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 30.0),
            forwardsButton.topAnchor.constraint(equalTo: playPauseButton.topAnchor)
        ])
    }
    
    func configureFullScreenButton() {
        fullScreenButton.setImage(UIImage(systemName: "square.filled.on.square"), for: .normal)
        fullScreenButton.addTarget(self, action: #selector(fullScreenPressed), for: .touchUpInside)
        fullScreenButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(fullScreenButton)
        
        NSLayoutConstraint.activate([
            fullScreenButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20.0),
            fullScreenButton.topAnchor.constraint(equalTo: playPauseButton.topAnchor)
        ])
    }

    func showAlert(with description: String) {
        let alert = UIAlertController(title: "Ошибка", message: description, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
    
    func activateButtons() {
        submitButton.isEnabled = true
        submitButton.alpha = 1
        backwardsButton.isEnabled = true
        playPauseButton.isEnabled = true
        forwardsButton.isEnabled = true
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
        fullScreenButton.isEnabled = false
    }

}

// MARK: - Actions

@objc
extension MainViewController {
    
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
            self?.player.seek(to: fullScreenTime)
        }

        self.present(vc, animated: true, completion: nil)
        player.pause()
    }

}

// MARK: - UITextFieldDelegate

extension MainViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        urlTextField.resignFirstResponder()
        return true
    }

}
