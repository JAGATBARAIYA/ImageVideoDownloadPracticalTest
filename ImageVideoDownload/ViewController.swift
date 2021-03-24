//
//  ViewController.swift
//  ImageVideoDownload
//
//  Created by Jagat Dave on 24/03/21.
//

import UIKit
import AVFoundation
import Lottie

let videoURL = "https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4"
let imageURL = "https://homepages.cae.wisc.edu/~ece533/images/airplane.png"

class ViewController: UIViewController, URLSessionDelegate, URLSessionDownloadDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var audioView: UIView!
    @IBOutlet weak var lblImageDownloadPercentage: UILabel!
    @IBOutlet weak var lblVideoDownloadPercentage: UILabel!
    @IBOutlet weak var btnPlayPause: UIButton!
    
    var player: AVPlayer!
    var session: URLSession?
    var dataTask: URLSessionDataTask?
    var animationImage: LOTAnimationView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.startDownloadImage()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func startDownloadImage() {
        let url = URL(string: imageURL)!
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        self.session?.downloadTask(with: url).resume()
    }

    func startDownloadVide() {
        let url = URL(string: videoURL)!
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        self.session?.downloadTask(with: url).resume()
        
        let alarm = URL(string: videoURL)!
        do {
            try alarm.download(to: .documentDirectory) { url, error in
                guard let url = url else { return }
                self.player = AVPlayer(url: url)
                let playerLayer = AVPlayerLayer(player: self.player)
                playerLayer.frame = self.videoView.bounds
                self.videoView.layer.addSublayer(playerLayer)
                self.player.play()
            }
        } catch {
            print(error)
        }
    }
    
    @IBAction func btnPlayPauseTapped(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        self.animationImage = LOTAnimationView(name: "music_sound")
        self.animationImage.contentMode = .scaleAspectFit
        self.animationImage.clipsToBounds = true
        self.animationImage.loopAnimation = true
        self.audioView.addSubview(self.animationImage)
        self.btnPlayPause.setTitle("Play Audio", for: .selected)
        self.btnPlayPause.setTitle("Stop Audio", for: .normal)

        if sender.isSelected {
            let url = Bundle.main.url(forResource: "music", withExtension: "mp3")
            self.player = AVPlayer.init(url: url!)
            self.player.play()

            self.animationImage.play()
        } else {
            self.player.pause()
            self.animationImage.stop()
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let percentage = totalBytesWritten*100/totalBytesExpectedToWrite;
        DispatchQueue.main.async {
            if self.lblImageDownloadPercentage.isHidden {
                self.lblVideoDownloadPercentage.text = "\(percentage)%"
            } else {
                self.lblImageDownloadPercentage.text = "\(percentage)%"
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let data = try? Data(contentsOf: location) {
            if let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.lblImageDownloadPercentage.isHidden = true
                    self.imageView.contentMode = .scaleAspectFit
                    self.imageView.clipsToBounds = true
                    self.imageView.image = image
                    self.startDownloadVide()
                }
            } else {
                self.lblVideoDownloadPercentage.isHidden = true
                let playerLayer = AVPlayerLayer(player: player)
                playerLayer.frame = self.videoView.bounds
                self.videoView.layer.addSublayer(playerLayer)
                player.play()
            }
        }
    }
}

extension URL {
    func download(to directory: FileManager.SearchPathDirectory, using fileName: String? = nil, overwrite: Bool = false, completion: @escaping (URL?, Error?) -> Void) throws {
        let directory = try FileManager.default.url(for: directory, in: .userDomainMask, appropriateFor: nil, create: true)
        let destination: URL
        if let fileName = fileName {
            destination = directory
                .appendingPathComponent(fileName)
                .appendingPathExtension(self.pathExtension)
        } else {
            destination = directory
            .appendingPathComponent(lastPathComponent)
        }
        if !overwrite, FileManager.default.fileExists(atPath: destination.path) {
            completion(destination, nil)
            return
        }
        URLSession.shared.downloadTask(with: self) { location, _, error in
            guard let location = location else {
                completion(nil, error)
                return
            }
            do {
                if overwrite, FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.moveItem(at: location, to: destination)
                completion(destination, nil)
            } catch {
                print(error)
            }
        }.resume()
    }
}
