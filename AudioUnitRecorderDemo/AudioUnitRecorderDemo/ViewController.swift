//
//  ViewController.swift
//  AudioUnitRecorderDemo
//
//  Created by EZen on 2024/12/02.
//

import UIKit

class ViewController: UIViewController {
    
    private lazy var url: URL = {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        let url = URL(fileURLWithPath: path!).appending(component: "recording.pcm")
        return url
    }()
    
    private lazy var recorder = AudioUnitRecorder(url: url)
    private lazy var player = AudioUnitPlayer()
    
    private lazy var stack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.alignment = .fill
        s.distribution = .fillProportionally
        s.translatesAutoresizingMaskIntoConstraints = false
        s.spacing = 10
        return s
    }()
    
    private lazy var recordingControl: UIButton = {
        let r = UIButton()
        r.titleLabel?.font = .systemFont(ofSize: 12, weight: .heavy)
        r.setTitle("开始录音", for: .normal)
        r.setTitle("停止录音", for: .selected)
        r.setTitleColor(.black, for: .normal)
        r.setTitleColor(.red, for: .selected)
        r.backgroundColor = .systemGreen
        r.layer.cornerRadius = 5
        r.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        r.layer.masksToBounds = true
        r.translatesAutoresizingMaskIntoConstraints = false
        r.addTarget(self, action: #selector(_tapRecording(_:)), for: .touchUpInside)
        return r
    }()
    
    private lazy var playingControl: UIButton = {
        let p = UIButton()
        p.titleLabel?.font = .systemFont(ofSize: 12, weight: .heavy)
        p.setTitle("开始播放", for: .normal)
        p.setTitle("停止播放", for: .selected)
        p.setTitleColor(.black, for: .normal)
        p.setTitleColor(.red, for: .selected)
        p.backgroundColor = .systemBlue
        p.layer.cornerRadius = 5
        p.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        p.layer.masksToBounds = true
        p.translatesAutoresizingMaskIntoConstraints = false
        p.addTarget(self, action: #selector(_playRecordedAudio(_:)), for: .touchUpInside)
        return p
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        recorder.delegate = self
        
        stack.addArrangedSubview(recordingControl)
        stack.addArrangedSubview(playingControl)
        view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 60),
            stack.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -60),
            recordingControl.heightAnchor.constraint(equalToConstant: 40),
            playingControl.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    @objc
    private func _tapRecording(_ sender: UIButton) {
        
        switch sender.isSelected {
        case true:
            
            sender.isSelected = false
            /// 结束录音
            recorder.stop()
            
        case false:
            
            sender.isSelected = true
            /// 开始录音
            recorder.prepareToRecord()
            recorder.record()
        }
    }
    
    @objc
    private func _playRecordedAudio(_ sender: UIButton) {
        
        switch sender.isSelected {
            case true:
            
            sender.isSelected = false
            /// 停止播放
            player.stop()
            
        case false:
            
            sender.isSelected = true
            /// 开始播放
            if recorder.isRecording {
                recorder.stop()
            }
            
            
            player.play()
        }
    }
}


extension ViewController: EGAAudioRecorderDelegate {
    
    func audioRecorder(_ recorder: AudioUnitRecorder, data: Data, didRecordAudioAtPeakAudioLevel level: Float, withUpdatedDuration duration: TimeInterval) {
        print("录音实时数据: \(data.count)")
        player.appendAudioData(data)
    }
    
    func audioRecorderErrorOccurred(_ recorder: AudioUnitRecorder, error: any Error) {
        
    }
}
