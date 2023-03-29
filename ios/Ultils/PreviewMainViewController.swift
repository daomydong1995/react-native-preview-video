//
//  PreviewMainViewController.swift
//  PreviewVideo
//
//  Created by Đào Mỹ Đông on 29/03/2566 BE.
//  Copyright © 2566 BE Facebook. All rights reserved.
//

import UIKit
import Photos
import AVFoundation

class PreviewMainViewController: UIViewController, UINavigationControllerDelegate {

    @IBOutlet weak var videoView: UIView!
    var videoUrl: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        playVideo()
    }
    
    func playVideo() {
        guard let url = videoUrl else { return }
        let player = AVPlayer(url: url)
        let playerLayer: AVPlayerLayer = AVPlayerLayer.init(player: player)
        playerLayer.frame = videoView.bounds
        videoView.layer.addSublayer(playerLayer)
        player.play()
    }
    
    func getVideoUrl(_ url: URL) {
        videoUrl = url
    }
    
    @IBAction func getviewo(_ sender: UIButton) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.allowsEditing = true
        pickerController.mediaTypes = ["public.movie"]
        self.present(pickerController, animated: true)
    }
}

extension PreviewMainViewController: UIImagePickerControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let url = info[.mediaURL] as? URL else {
            return
        }
        picker.dismiss(animated: true, completion: {
             let editVideoViewController = PreviewVideoViewController()
                editVideoViewController.videoUrl = url
                editVideoViewController.returnVideoUrl = self.getVideoUrl(_:)
                let editViewNav = UINavigationController.init(rootViewController: editVideoViewController)
                editViewNav.modalPresentationStyle = .fullScreen
                self.present(editViewNav, animated: true)
        })
    }
}
