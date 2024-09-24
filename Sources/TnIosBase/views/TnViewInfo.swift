//
//  TnAlert.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 9/15/21.
//

import Foundation
import SwiftUI

struct TnViewInfo<TAlertType> {
    var alertShow: Bool = false
    var alertType: TAlertType? = nil
    var alertTitle: String = ""
    var alertMessage: String = ""
    
    var inProgress: Bool = false
    
    var passwordShow = false
    var password = ""
    var passwordError = ""
}

protocol TnViewInfoDelegate: View {
    associatedtype TAlertType
    var pageInfo: State<TnViewInfo<TAlertType>> {get set}
    var presentationMode: Binding<PresentationMode> {get}
    
    // alertable
    func getCustomAlert(type: TAlertType) -> Alert?

    // password
    func passwordRequired() -> Bool
    func passwordDescription() -> String
    func passwordChecker(password: String, onOK: () -> Void, onError: () -> Void)
}

extension TnViewInfoDelegate {
    static func initPageInfo(_ populator: ((inout TnViewInfo<TAlertType>) -> Void)? = nil) -> State<TnViewInfo<TAlertType>> {
        var pageInfo = TnViewInfo<TAlertType>()
        populator?(&pageInfo)
        
        return State<TnViewInfo>(wrappedValue: pageInfo)
    }
    
    func showAlert(type: TAlertType?, title: String? = nil, message: String? = nil) {
        DispatchQueue.main.asyncAfter(deadline: .now()+0.01) {
            pageInfo.wrappedValue.alertShow = true
            pageInfo.wrappedValue.alertType = type
            
            if title != nil {
                pageInfo.wrappedValue.alertTitle = title!
            }
            if message != nil {
                pageInfo.wrappedValue.alertMessage = message!
            }
        }
    }
    
    func showAlert(_ type: TAlertType) {
        showAlert(type: type, title: nil, message: nil)
    }
    
    func alertError(title: String = "Error !!!", message: String? = nil) -> Alert {
        Alert(
            title: Text((pageInfo.wrappedValue.alertTitle.isEmpty ? title : pageInfo.wrappedValue.alertTitle).lz()),
            message: Text((message ?? pageInfo.wrappedValue.alertMessage).lz()),
            dismissButton: .default(Text("Close".lz()))
        )
    }

    func alertInformation(title: String = "Information", message: String? = nil, onClose: (() -> ())? = nil) -> Alert {
        Alert(
            title: Text(title.lz()),
            message: Text((message ?? pageInfo.wrappedValue.alertMessage).lz()),
            dismissButton: .default(Text("Close".lz())) {
                onClose?()
            }
        )
    }

    func alertConfirm(title: String = "Confirmation", message: String, onOK: @escaping () -> Void, onCancel: (() -> Void)? = nil) -> Alert {
        Alert(
            title: Text(title.lz()),
            message: Text(message.lz()),
            primaryButton: .default(Text("OK".lz())) {
                onOK()
            },
            secondaryButton: .cancel() {
                onCancel?()
            }
        )
    }

    func alertWarning(title: String = "Confirmation", message: String, onOK: @escaping () -> Void, onCancel: (() -> Void)? = nil) -> Alert {
        Alert(
            title: Text(title.lz()).foregroundColor(.red),
            message: Text(message.lz()).foregroundColor(.red),
            primaryButton: .destructive(Text("OK".lz())) {
                onOK()
            },
            secondaryButton: .cancel() {
                onCancel?()
            }
        )
    }

    /// default implementation
    func getCustomAlert(type: TAlertType) -> Alert? {
        return nil
    }

    func getAlert() -> Alert {
        if let type = pageInfo.wrappedValue.alertType, let alert = getCustomAlert(type: type) {
            return alert
        }
        return alertError()
    }
}

extension TnViewInfoDelegate {
    func passwordChecker(password: String, onOK: () -> Void, onError: () -> Void) {
    }
    func passwordRequired() -> Bool {
        false
    }
    func passwordDescription() -> String {
        ""
    }
}

extension TnViewInfoDelegate {
    private func initView<TView: View>(@ViewBuilder view: () -> TView) -> some View {
        ZStack {
            Group {
                if passwordRequired() && pageInfo.wrappedValue.passwordShow {
                    VStack {
                        tnText(passwordDescription())
                            .foregroundColor(.orange)
                        VStack {
                            TnPasswordField(label: "Password", value: pageInfo.projectedValue.password)
                            tnTextButton("OK") {
                                passwordChecker(
                                    password: pageInfo.wrappedValue.password,
                                    onOK: {
                                        pageInfo.wrappedValue.passwordError = ""
                                        pageInfo.wrappedValue.passwordShow = false
                                    },
                                    onError: {
                                        pageInfo.wrappedValue.passwordError = "Wrong password, try again !"
                                    }
                                )
                            }
                            tnText(pageInfo.wrappedValue.passwordError)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color.dark_4_magnesium)
                    }
                    .padding()
                } else {
                    view()
                }
            }
            if pageInfo.wrappedValue.inProgress {
                tnProgressView()
            }
        }
        .tnPageFill()
        .alert(isPresented: pageInfo.projectedValue.alertShow) {
            getAlert()
        }
    }
    
    private func makePageView<TView: View, TTrailingButton: View>(
        title: String?,
        presentation: Binding<PresentationMode>?,
        trailingButton: TTrailingButton?,
        @ViewBuilder view: () -> TView) -> some View {
        VStack {
            if presentation != nil || title != nil {
                HStack {
                    if presentation != nil {
                        tnButton(Image.iconClosePage, action: {presentation!.wrappedValue.dismiss()})
                    }
                    Spacer()
                    if title != nil {
                        tnText(title!).bold()
                    }
                    Spacer()
                    if trailingButton != nil {
                        trailingButton
                    }
                }
                Divider()
                Spacer()
            }
            view()
        }
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }

    func initView<TView: View, TTrailingButton: View>(title: String? = nil, presentation: Binding<PresentationMode>? = nil, trailingButton: TTrailingButton, @ViewBuilder view: () -> TView) -> some View {
        return initView(view: {
                makePageView(title: title, presentation: presentation, trailingButton: trailingButton, view: view)
            }
        )
    }

    func initView<TView: View>(title: String? = nil, presentation: Binding<PresentationMode>? = nil, @ViewBuilder view: () -> TView) -> some View {
        return initView(view: {
                makePageView(title: title, presentation: presentation, trailingButton: EmptyView(), view: view)
            }
        )
    }

    func showLoading(_ show: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now()+0.001) {
            self.pageInfo.wrappedValue.inProgress = show
        }
    }
    
    func doCatch(
        name: String = "",
        type: TAlertType? = nil,
        title: String = "Error !!!",
        hideKb: Bool = true,
        action: @escaping () throws -> Void,
        onSuccess: (() -> Void)? = nil,
        onError: (() -> Void)? = nil,
        onComplete: (() -> Void)? = nil) {
        
        TnLogger.debug("TnViewInfoDelegate", "doCatch", name)
        
        if hideKb {
            hideKeyboard()
        }
        showLoading(true)
        
        DispatchQueue.global().asyncAfter(deadline: .now()+0.01) {
            do {
                TnLogger.debug("TnViewInfoDelegate", "doCatch", "action", name)
                try action()
                TnLogger.debug("TnViewInfoDelegate", "doCatch", "action", "success", name)
            } catch {
                showAlert(type: type, title: title, message: error.localizedDescription)
                onError?()
            }
            showLoading(false)
            onComplete?()
            TnLogger.debug("TnViewInfoDelegate", "doCatch", "complete", name)
        }
    }
    
    func dismissView() {
        DispatchQueue.main.async {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

