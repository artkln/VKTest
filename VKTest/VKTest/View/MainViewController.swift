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
    
    private var player = AVPlayer()
    private var playerLayer = AVPlayerLayer()
    private var isVideoPlaying = false
    
    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        
        urlTextField.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)

        view.addSubviews(infoLabel, submitButton, urlTextField, playerView, playPauseButton, backwardsButton, forwardsButton, fullScreenButton)
        
        setupConstraints()
        configureAppearance()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = playerView.bounds
    }

}

// MARK: - Appearance

private extension MainViewController {

    func configureAppearance() {
        view.backgroundColor = .white

        configureInfoLabel()
        configurePlayerView()
        configureTextField()
        configurePlayPauseButton()
        configureSubmitButton()
        configureBackwardsButton()
        configureForwardsButton()
        configureFullScreenButton()
    }
    
    func configureInfoLabel() {
        infoLabel.text = "Введите URL видеоресурса:"
        infoLabel.textAlignment = .center
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func configurePlayerView() {
        playerView.backgroundColor = .black
        playerView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func configureTextField() {
        urlTextField.translatesAutoresizingMaskIntoConstraints = false
        urlTextField.layer.cornerRadius = 5.0
        urlTextField.layer.borderWidth = 1.0
        urlTextField.layer.borderColor = UIColor.black.cgColor
    }
    
    func configurePlayPauseButton() {
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playPauseButton.addTarget(self, action: #selector(playPausePressed), for: .touchUpInside)
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func configureSubmitButton() {
        submitButton.setTitle("Загрузить", for: .normal)
        submitButton.addTarget(self, action: #selector(submitPressed), for: .touchUpInside)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.setTitleColor(.systemBlue, for: .normal)
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
    
    func configureFullScreenButton() {
        fullScreenButton.setImage(UIImage(systemName: "square.filled.on.square"), for: .normal)
        fullScreenButton.addTarget(self, action: #selector(fullScreenPressed), for: .touchUpInside)
        fullScreenButton.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func setupConstraints() {
        let safeArea = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            playerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            playerView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            playerView.widthAnchor.constraint(equalTo: playerView.heightAnchor, multiplier: 16.0/9.0),
            
            infoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            infoLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 50.0),
            
            urlTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            urlTextField.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 30.0),
            urlTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50.0),
            urlTextField.heightAnchor.constraint(equalToConstant: 30.0),
            
            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            submitButton.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 30.0),
            
            backwardsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 115.0),
            backwardsButton.topAnchor.constraint(equalTo: playerView.bottomAnchor, constant: 20),
            
            playPauseButton.leadingAnchor.constraint(equalTo: backwardsButton.trailingAnchor, constant: 30.0),
            playPauseButton.topAnchor.constraint(equalTo: backwardsButton.topAnchor),
            
            forwardsButton.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 30.0),
            forwardsButton.topAnchor.constraint(equalTo: playPauseButton.topAnchor),
            
            fullScreenButton.leadingAnchor.constraint(equalTo: forwardsButton.trailingAnchor, constant: 30.0),
            fullScreenButton.topAnchor.constraint(equalTo: forwardsButton.topAnchor)
        ])
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
        guard let URL = URL(string: urlTextField.text ?? "") else {
            return
        }

        player = AVPlayer(url: URL)

        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resize
        
        playerView.layer.addSublayer(playerLayer)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func fullScreenPressed(_ sender: Any) {
        guard let URL = URL(string: urlTextField.text ?? "") else {
            return
        }
        player.pause()
        let currentTime = player.currentTime()
        
        let vc = FullScreenPlayerViewController(url: URL, currentTime: currentTime)
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }

}

extension MainViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        urlTextField.resignFirstResponder()
        return true
    }

}
