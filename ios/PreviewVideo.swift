import UIKit
@objc(PreviewVideo)
class PreviewVideo: NSObject {
    @objc(showPreviewVideo:withResolver:withRejecter:)
    func showPreviewVideo(_ data: NSDictionary,
                          resolver resolve: @escaping RCTPromiseResolveBlock,
                          rejecter reject: RCTPromiseRejectBlock) -> Void {
        do {
            DispatchQueue.main.async {
                let vc = PreviewVideoViewController()
                vc.modalPresentationStyle = .fullScreen
                if let url = data["url"] as? String {
                    vc.videoUrl = URL(string: url)
                    vc.returnVideoUrl = { url in
                        resolve(url.absoluteString)
                    }
                    let controller = RCTPresentedViewController()
                    controller?.present(vc, animated: true)
                }
            }
        } catch {
            resolve(false)
        }
    }
}
