//
//  TnUIKitView.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 03/08/2021.
//

import Foundation
import UIKit
import SwiftUI


struct TnUIKitRepresentable<Content: View>: UIViewControllerRepresentable {
    let viewBuilder: () -> Content
    let onAppear: (() -> Void)?
    let onDisappear: (() -> Void)?

    /// coordinator
    class TnUIKitViewCoordinator: NSObject {
        var parent: TnUIKitRepresentable
        
        init(parent: TnUIKitRepresentable) {
            self.parent = parent
        }
    }
    func makeCoordinator() -> TnUIKitViewCoordinator {
        TnUIKitViewCoordinator(parent: self)
    }
    ///

    /// controller
    class TnUIKitViewViewController: UIHostingController<Content> {
        override func viewDidLoad() {
        }
        
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
        }
        
        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
        }
    }
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let controller = TnUIKitViewViewController(rootView: viewBuilder())
        return controller
    }
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }
    ///
}
