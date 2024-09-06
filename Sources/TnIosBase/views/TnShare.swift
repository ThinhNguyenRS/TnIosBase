//
//  TnShare.swift
//  TkgFaceSpot
//
//  Created by Thinh Nguyen on 10/11/21.
//

import SwiftUI

struct TnShareView: UIViewControllerRepresentable {
    var items: [Any]
    var excludeTypes: [UIActivity.ActivityType] = [.copyToPasteboard, .addToReadingList]
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<TnShareView>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.excludedActivityTypes = excludeTypes
        return controller
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<TnShareView>) {}
}

func share(items: [Any], excludeTypes: [UIActivity.ActivityType] = [.copyToPasteboard, .addToReadingList]) {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first
          else { return }
    
    if let rootController = window.rootViewController {
        let vc = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        vc.excludedActivityTypes = excludeTypes
        vc.popoverPresentationController?.sourceView = rootController.view
        rootController.present(vc, animated: true)
    }
}

class TestActivity: UIActivity {
    override var activityType: UIActivity.ActivityType? {
        UIActivity.ActivityType.saveToCameraRoll
    }
    
    override init() {
        super.init()
    }
}
