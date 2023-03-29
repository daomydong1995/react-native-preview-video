//
//  RangeControlTrackLayer.swift
//  ImprovePerformance
//
//  Created by Beacon on 9/03/2023.
//

import UIKit
import AVFoundation
import Photos
import MobileCoreServices
import AVKit

class PreviewVideoViewController: UIViewController {
    
    @IBOutlet weak var videoPlayer: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var videoTimeControl: TimeControl!
    @IBOutlet weak var frameContainerView: UIView!
    @IBOutlet weak var rangeControl: RangeControl!
    @IBOutlet weak var trimView: UIView!
    @IBOutlet weak var viewTimeCenterConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var currentTimeLabel: UILabel!
    var videoUrl: URL?
    var isPlaying = true
    var playbackTimeCheckerTimer: Timer! = nil
    let playerObserver: Any? = nil
    
    let exportSession: AVAssetExportSession! = nil
    var player: AVPlayer!
    var playerItem: AVPlayerItem!
    var playerLayer: AVPlayerLayer!
    var asset: AVAsset!
    var originalImage: UIImage?

    var videoStartTime: CGFloat = 0.0
    var videoStopTime: CGFloat  = 0.0
    var videoThumbTime: CMTime!
    var videoThumbTimeSeconds: Float!
    
    var videoPlaybackPosition: CGFloat = 0.0
    var cache:NSCache<AnyObject, AnyObject>!
    
    let preferredTimescale: Int32 = 1000000000
    let numberFrame = 30
    var thumbnailImage = UIImage()
    let sectionInsets = UIEdgeInsets(top: 5.0, left: 0.0 , bottom: 5.0, right: 0.0)
    var image: UIImage?
    var smallImage: UIImage?
    var baseImage: UIImage?
    var filterIndex    = 0
    let context        = CIContext(options: nil)
    var avVideoComposition: AVVideoComposition!
    var lastFilterIndex = 0
    var returnVideoUrl: ((_ url: URL) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterBackground), name: UIApplication.willResignActiveNotification, object: nil)
        
        self.setupUI()
        self.setupNavigationBar()

        if let url = self.videoUrl {
            self.asset = AVAsset.init(url: url)
            self.image = self.asset.videoToUIImage()
            self.originalImage = self.image
            smallImage = resizeImage(image: self.image!)
        }
        
        self.createPlayer()
    
        Task {
            await self.previewVideo(self.videoUrl!)
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.pauseVideo()
    }
    
    func setupUI() {
        playButton.borderRounded()
        videoTimeControl.trackingLocation = trackingLocation(_:)
        videoTimeControl.beginLocation = beginTracking(_: )
        videoTimeControl.endLocation = endTracking(_: )

        let rangeWidth = rangeControl.bounds.width - 2*rangeControl.thumbWidth
        viewTimeCenterConstraint.constant = -1/2 * rangeWidth + 1
    }
    
    func setupNavigationBar() {
        self.navigationController?.navigationBar.barTintColor = .brown
        let leftButton = UIButton.init(type: UIButton.ButtonType.custom)
        leftButton.isExclusiveTouch = true
        leftButton.addTarget(self, action: #selector(tappedLeftBarButton(sender:)), for: UIControl.Event.touchUpInside)
        leftButton.setTitle("Back", for: UIControl.State.normal)
        leftButton.titleLabel?.textAlignment = .right
        leftButton.setTitleColor(.white, for: .normal)
        let leftTextWidth = sizeOf(aString: "Back", andFont: UIFont.systemFont(ofSize: 18), maxSize: CGSize(width: 60, height:   44)).width
        
        leftButton.frame = CGRect(x: 0, y: 0, width: leftTextWidth, height: 44)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: leftButton)
        
        let rightButton = UIButton.init(type: UIButton.ButtonType.custom)
        rightButton.isExclusiveTouch = true
        rightButton.addTarget(self, action: #selector(tappedRightBarButton(sender:)), for: UIControl.Event.touchUpInside)
        rightButton.setTitle("Trim", for: UIControl.State.normal)
        rightButton.titleLabel?.textAlignment = .left
        rightButton.setTitleColor(.white, for: .normal)
        let rightTextWidth = sizeOf(aString: "Trim", andFont: UIFont.systemFont(ofSize: 18), maxSize: CGSize(width: 60, height:   44)).width
        
        rightButton.frame = CGRect(x: 0, y: 0, width: rightTextWidth, height: 44)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(customView: rightButton)
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = .darkGray
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        navigationController?.navigationBar.tintColor = .black
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    func resizeImage(image: UIImage) -> UIImage {
        let ratio: CGFloat = 0.3
        let resizedSize = CGSize(width: Int(image.size.width * ratio), height: Int(image.size.width * ratio))
        UIGraphicsBeginImageContext(resizedSize)
        image.draw(in: CGRect(x: 0, y: 0, width: resizedSize.width, height: resizedSize.width))
        
        guard let resizedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return image
        }
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    func trackingLocation(_ offset: CGPoint) {
        let timelineWidth = (rangeControl.bounds.width - 2*rangeControl.thumbWidth)
        let currentX = timelineWidth/2 + viewTimeCenterConstraint.constant + offset.x

        var currentTime = currentX/timelineWidth * CGFloat(videoThumbTimeSeconds)

        if currentTime > videoStopTime {
            currentTime = videoStopTime
        }
        if currentTime < videoStartTime {
            currentTime = videoStartTime
        }
        
        viewTimeCenterConstraint.constant  = (currentTime/CGFloat(videoThumbTimeSeconds) - 1/2) * timelineWidth
        _ = updateCurrentTime()
        seekVideo(toPos: currentTime)
        print("tracking: \(offset.x)")

    }
    
    func beginTracking(_ offset: CGPoint) {
        self.tapOnVideoPlayer()
        let currentTime = updateCurrentTime()
        seekVideo(toPos: currentTime)
        print("begin: \(offset.x)")
    }
    
    func endTracking(_ offset: CGPoint) {
        let currentTime = updateCurrentTime()
        if currentTime >= videoStopTime {
            return
        }
        playButton_tapped(playButton)
    }
    
    func updateCurrentTime() -> Double {
        let currentX = (rangeControl.bounds.width - 2*rangeControl.thumbWidth)/2 + viewTimeCenterConstraint.constant
        let currentTime = currentX/(rangeControl.bounds.width - 2*rangeControl.thumbWidth) * CGFloat(videoThumbTimeSeconds)
        currentTimeLabel.text = "\(getTimeString(totalTime: currentTime - videoStartTime))"
        return currentTime
    }
    
    // MARK: - IBAction
    @IBAction func playButton_tapped(_ sender: Any) {
        self.playVideo()
        isPlaying = true
        self.playButton.isHidden = true
    }
    
    @objc
    func tappedLeftBarButton(sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @objc
    func tappedRightBarButton(sender: UIButton) {
        if player.timeControlStatus == .playing {
            self.player.pause()
        }
        Task {
            await self.cropVideo(startTime: Float(self.videoStartTime), endTime: Float(self.videoStopTime))
        }
    }
    
    // MARK: - Load view method
    func createPlayer() {
        player = AVPlayer()
        self.cache = NSCache()
    }
    
    func previewVideo(_ url: URL) async {
        if let videoThumbnail = getThumbnailImage(forUrl: url) {
                thumbnailImage = videoThumbnail
        }
        asset   = AVURLAsset.init(url: url as URL)
        
        do {
            if #available(iOS 15, *) {
                videoThumbTimeSeconds      = try await Float(asset.load(.duration).seconds)
            } else {
                videoThumbTimeSeconds      = Float(asset.duration.seconds)
            }
            videoStartTime = 0.0
            videoStopTime = CGFloat(videoThumbTimeSeconds)
            
            self.currentTimeLabel.text = "\(getTimeString(totalTime: TimeInterval(videoStartTime)))"
            self.endTimeLabel.text   = "\(getTimeString(totalTime: TimeInterval(videoStopTime)))"
            
            // Removing player if alredy exists
            if(playerLayer != nil) {
                playerLayer.removeFromSuperlayer()
            }
            
            self.view.layoutIfNeeded()
            Task {
                self.createImageFrames()
            }
            self.createRangeSlider()
            
            // Init AVPlayer
            let item:AVPlayerItem = AVPlayerItem(asset: asset)
            item.videoComposition = avVideoComposition
            player                = AVPlayer(playerItem: item)
            player.actionAtItemEnd   = AVPlayer.ActionAtItemEnd.none
            player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 30), queue: DispatchQueue.main) { [weak self] (progressTime) in
                if self?.player.currentItem?.status == AVPlayerItem.Status.readyToPlay && self?.player.timeControlStatus == .playing {
                    print ("Player Playing")
                    self?.updateProgressBar(progressTime)
                } else {
                    print("Player Pause")
                }
                
                let currentSeconds = Float(CMTimeGetSeconds(progressTime))
                if let duration = self?.videoThumbTimeSeconds, currentSeconds >= duration {
                    self?.player.seek(to: CMTime(value: 0, timescale: 1))            }
            }
            
            // Init AVPlayerLayer
            playerLayer           = AVPlayerLayer(player: player)
            playerLayer.frame     = CGRect(x: 0, y: 0, width: videoPlayer.frame.width, height: videoPlayer.bounds.height)
            playerLayer.videoGravity = .resizeAspect
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapOnVideoPlayer))
            videoPlayer.addGestureRecognizer(tap)
            videoPlayer.layer.addSublayer(playerLayer)
            
            playButton.isHidden = false
            isPlaying = false
        } catch {
            
        }
    }
    
    func createImageFrames() {
        //creating assets
        let assetImgGenerate : AVAssetImageGenerator    = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        assetImgGenerate.requestedTimeToleranceAfter    = CMTime.zero;
        assetImgGenerate.requestedTimeToleranceBefore   = CMTime.zero;
        assetImgGenerate.videoComposition = avVideoComposition
        
        assetImgGenerate.appliesPreferredTrackTransform = true
        let thumbTime: CMTime = asset.duration
        let thumbtimeSeconds  = Int(CMTimeGetSeconds(thumbTime))
//        let maxLength         = "\(thumbtimeSeconds)" as NSString
                
        let thumbAvg  = Double(thumbtimeSeconds)/Double(numberFrame)
        var startTime = Double(CMTimeGetSeconds(self.asset.duration))/Double(numberFrame)
        var startXPosition:CGFloat = 0.0
        
        //loop for 6 number of frames
        rangeControl.backgroundView.subviews.forEach({subView in
            if subView.tag == 2403 {
                subView.removeFromSuperview()
            }
        })
        let imagesFrameView = UIView(frame: CGRect(x: rangeControl.thumbWidth, y: 0, width: rangeControl.frame.width - rangeControl.thumbWidth*2, height: rangeControl.frame.height - 2*rangeControl.margin))
        imagesFrameView.backgroundColor = .clear
        imagesFrameView.tag = 2403
        
        rangeControl.setBackground(imagesFrameView)
        
        let frameWidth = CGFloat(imagesFrameView.frame.width)
        
        let time:CMTime = CMTimeMakeWithSeconds(Float64(startTime),preferredTimescale: self.preferredTimescale)
        var firstImageFrame = UIImage()
        do {
            let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
            firstImageFrame = UIImage(cgImage: img)
        } catch {
            
        }
        
        for i in 0...(self.numberFrame-1) {
            let xPositionForEach = frameWidth/CGFloat(self.numberFrame)
            let rect = CGRect(x: CGFloat(startXPosition), y: CGFloat(0), width: xPositionForEach, height: CGFloat(imagesFrameView.frame.height))
            self.addButtonFrame(frameView: imagesFrameView, image: firstImageFrame, rect: rect, tag: 10+i)
            
            startXPosition = startXPosition + xPositionForEach
        }
            
            DispatchQueue.global(qos: .background).async {
                var lastImg = self.thumbnailImage

                for i in 0...(self.numberFrame-1) {
                    
                    do {
                        let time:CMTime = CMTimeMakeWithSeconds(Float64(startTime),preferredTimescale: self.preferredTimescale)
                        let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
                        let image = UIImage(cgImage: img)
                        lastImg = image
                        DispatchQueue.main.async {
                            self.addButtonFrame(frameView: imagesFrameView, image: image, rect: CGRect.zero, tag: 10+i)
                            startTime = startTime + thumbAvg
                        }
                    }
                    catch
                        _ as NSError
                    {
                        DispatchQueue.main.async {
                            self.addButtonFrame(frameView: imagesFrameView, image: lastImg, rect: CGRect.zero, tag: 10+i)
                            startTime = startTime + thumbAvg
                        }
                        print("Image generation failed with error (error)")
                    }
                }
            }
        
    }
    
    func getThumbnailImage(forUrl url: URL) -> UIImage? {
        let asset: AVAsset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)

        do {
            let thumbnailImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60), actualTime: nil)
            return UIImage(cgImage: thumbnailImage)
        } catch let error {
            print(error)
        }
        return nil
    }
    
    func addButtonFrame(frameView: UIView, image: UIImage, rect: CGRect, tag: Int) {
        let imageButton = UIButton()
        imageButton.frame = rect
        imageButton.setImage(image, for: .normal)
        imageButton.isUserInteractionEnabled = false
        imageButton.tag = tag
        
        if let thumbView = frameView.viewWithTag(tag) {
            imageButton.frame = thumbView.frame
            thumbView.removeFromSuperview()
        }
        frameView.addSubview(imageButton)
    }
    
    //Create range slider
    func createRangeSlider() {
        rangeControl.thumbColor = UIColor.white
        rangeControl.arrowColor = UIColor.init(hex: 0x3F3E4E)
        rangeControl.trackColor = UIColor.black.withAlphaComponent(0.4)
        
        rangeControl.minValue = 0.0
        rangeControl.maxValue = videoThumbTimeSeconds
        rangeControl.lowValue = 0.0
        rangeControl.upValue = rangeControl.maxValue
        rangeControl.delegate = self
    }
    
    // MARK: - PLAYER
    func playVideo() {
        let currentTime = updateCurrentTime()

        if currentTime >= videoStopTime {
            self.seekVideo(toPos: videoStartTime)
        }
        
        self.player.play()
    }
    
    func pauseVideo() {
        self.player.pause()
    }
    
    // MARK: - Player video method
    
    @objc func tapOnVideoPlayer() {
        isPlaying = false
        playButton.isHidden = false
        self.player.pause()
    }
    
    // MARK: - Other method
    func updateProgressBar(_ progressTime:CMTime) {
        let seconds = Float(CMTimeGetSeconds(progressTime))
        print ("second ------- \(seconds) -- startT \(videoStartTime)")
        
        let rangeWidth = rangeControl.bounds.width - 2*rangeControl.thumbWidth
        viewTimeCenterConstraint.constant = CGFloat(seconds / videoThumbTimeSeconds - 1/2) * rangeWidth
        _ = updateCurrentTime()
        if seconds >= Float(videoStopTime) {
            self.player.pause()
            self.playButton.isHidden = false
            self.isPlaying = false
        }
    }
    
    //Seek video when slide
    func seekVideo(toPos pos: CGFloat) {
        let newPos = Float(pos).roundDown(places: 1)
        self.videoPlaybackPosition = CGFloat(newPos)
        let time: CMTime = CMTimeMakeWithSeconds(Float64(self.videoPlaybackPosition), preferredTimescale: preferredTimescale)
        self.player.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    }
    
    //Trim Video Function
    func cropVideo(startTime:Float, endTime:Float) async {
        let manager                 = FileManager.default
        guard let documentDirectory = try? manager.url(for: .documentDirectory,
                                                       in: .userDomainMask,
                                                       appropriateFor: nil,
                                                       create: true) else { return }
        let mediaType         = "mp4"
        
        if mediaType == UTType.movie.identifier || mediaType == "mp4" as String {
            do {
                var duration: CMTime
                if #available(iOS 15, *) {
                    duration = try await asset.load(.duration)
                } else {
                    duration      = asset.duration
                }
                let length = Float(duration.value) / Float(duration.timescale)
                print("video length: \(length) seconds")
                let currentTime = Date().stringFromDate(format: "yyyyMMddHHmmss")
                let fileName = "video_\(currentTime)_\(randomString(length: 10)).mp4"
                
                let start = startTime
                let end = endTime
                print(documentDirectory)
                var outputURL = documentDirectory.appendingPathComponent("Videos")
                try manager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
                //let name = hostent.newName()
                outputURL = outputURL.appendingPathComponent("\(fileName)")
                //Remove existing file
                _ = try? manager.removeItem(at: outputURL)
                
                guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {return}
                exportSession.outputURL = outputURL
                exportSession.outputFileType = AVFileType.mp4
                exportSession.videoComposition = avVideoComposition
                exportSession.fileLengthLimit = Int64(500*1000*1000) // 500MB
                let startTime = CMTime(seconds: Double(start ), preferredTimescale: 1000)
                let endTime = CMTime(seconds: Double(end ), preferredTimescale: 1000)
                let timeRange = CMTimeRange(start: startTime, end: endTime)
                
                exportSession.timeRange = timeRange
                exportSession.exportAsynchronously {
                    switch exportSession.status {
                    case .completed:
                        print("exported at \(outputURL)")
                        self.cropVideoComplete(URL: outputURL as URL, name: fileName)
                    case .failed:
                        print("failed \(exportSession.error?.localizedDescription ?? "")")
                        break
                    case .cancelled:
                        print("cancelled \(exportSession.error?.localizedDescription ?? "")")
                        break
                    case .unknown:
                        print("unknown \(exportSession.error?.localizedDescription ?? "")")
                        break
                    case .waiting:
                        print("waiting \(exportSession.error?.localizedDescription ?? "")")
                        break
                    case .exporting:
                        print("exporting \(exportSession.error?.localizedDescription ?? "")")
                        break
                    @unknown default:
                        break
                    }
                }
            } catch let error {
                print(error)
            }
        }
    }
    
    func cropVideoComplete(URL: URL, name: String) {
        DispatchQueue.main.async {
            if let urlCallBack = self.returnVideoUrl {
                urlCallBack(URL)
            }
            self.dismiss(animated: true)
        }
    }
            
    @objc func appEnterBackground() {
        self.tapOnVideoPlayer()
    }
    
    func getTimeString(totalTime: TimeInterval, isShowFullTime: Bool = false) -> String {
        let totalSeconds = Int(totalTime.rounded())
        let hour        = Int(totalSeconds/3600)
        let minute      = Int((totalSeconds - hour*3600)/60)
        let seconds     = Int(totalSeconds - hour*3600 - minute*60)
        
        var timeString = String.init(format: "%01d:%02d", minute, seconds)
        if hour > 0 {
            timeString = "\(hour):\(timeString)"
        }
        
        if isShowFullTime {
            timeString = String.init(format: "%02d:%02d", minute, seconds)
            if hour > 0 {
                timeString = "\(String.init(format: "%02d", hour)):\(timeString)"
            }
        }
        return timeString
    }
    
    func randomString(length: Int) -> String {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
    
    func sizeOf(aString: String, andFont aFont: UIFont, maxSize aSize: CGSize) -> CGSize {
        let sizeOfText: CGSize = aString.boundingRect(with: aSize, options: ([.usesLineFragmentOrigin, .usesFontLeading]), attributes: [ NSAttributedString.Key.font : aFont ], context: nil).size
        return sizeOfText
    }
}

extension PreviewVideoViewController: RangeControlDelegate {
    func rangeControlValueChanged(_ low: Float, _ up: Float) {
        self.player.pause()
        
        self.currentTimeLabel.text = "\(getTimeString(totalTime: 0))"
        let newEndValue = up - low
        self.endTimeLabel.text   = "\(getTimeString(totalTime: TimeInterval(newEndValue)))"
        
        if (self.rangeControl.lowThumbLayer.highlighted) {
            self.seekVideo(toPos: CGFloat(low))
        } else if (rangeControl.upThumbLayer.highlighted) {
            self.seekVideo(toPos: CGFloat(up))
        }
    }
    
    func rangeControlDidEnd() {
        self.videoStartTime = CGFloat(self.rangeControl.lowValue)
        self.videoStopTime = CGFloat(self.rangeControl.upValue)
        
        self.seekVideo(toPos: self.videoStartTime)
        if self.isPlaying {
            self.player.play()
        }
    }
}
