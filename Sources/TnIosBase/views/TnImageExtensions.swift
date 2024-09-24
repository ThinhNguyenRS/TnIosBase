//
//  TnImageExtensions.swift
//  TnIosBase
//
//  Created by Thinh Nguyen on 12/08/2021.
//

import Foundation
import SwiftUI
import CoreImage

extension Image {
    public func tnMakeScalable(_ free: Bool = false) -> some View {
        self
            .resizable()
            .aspectRatio(contentMode: free ? .fill : .fit)
    }
    
    public func circle(_ size: CGFloat, _ backColor: Color, foreColor: Color? = nil, padding: CGFloat = 2) -> some View {
        self.tnMakeScalable()
            .frame(width: size, height: size)
            .padding(.all, padding)
            .background(backColor)
            .cornerRadius((size+padding)/2)
            .foregroundColor(foreColor)
    }
}

extension Image {
    public static var iconTKG: Image {Image("tkg")}
    public static var iconClose: Image {Image(systemName: "xmark")}
    public static var iconCloseCircle: Image {Image(systemName: "xmark.circle")}
    public static var iconCloseCircleFill: Image {Image(systemName: "xmark.circle.fill")}
    
    public static var iconClosePage: some View {Image(systemName: "chevron.backward").buttonPage().foregroundColor(.red.opacity(0.75))}
    public static var iconSavePage: some View {Image.iconSave.buttonPage().foregroundColor(.blue)}

    public static var iconOK: Image {Image(systemName: "checkmark")}
    public static var iconOKCircle: Image {Image(systemName: "checkmark.circle")}

    public static var iconApply: Image {Image(systemName: "checkmark")}
    public static var iconApplyCircle: Image {Image(systemName: "checkmark.circle")}

    public static var iconSave: Image {Image(systemName: "rectangle.and.pencil.and.ellipsis")}
    
    public static var iconDelete: Image { Image(systemName: "trash") }
    public static var iconDeletePage: some View {Image(systemName: "trash").buttonPage().foregroundColor(.red)}

    public static var iconDeleteCircle: Image {Image(systemName: "trash.circle")}

//    public static var iconMenu = Image(systemName: "ellipsis")
//    public static var iconMenu = Image(systemName: "text.justify")
    // line.horizontal.3.circle
    // ellipsis.circle.fill
    public static var iconMenu: Image {Image(systemName: "line.horizontal.3")}
    public static var iconMenuPageView: some View {
        Image(systemName: "line.horizontal.3")
            .tnMakeScalable()
            .width(28)
    }
    public static var iconMenuCircle = Image(systemName: "ellipsis.circle")
    public static var iconMenuView: some View {
        Image(systemName: "ellipsis")
        
            .frame(width: 28, height: 24)
    }
    
    public static var iconCommand: Image {Image(systemName: "command")}
    public static var iconCommandCircle: Image {Image(systemName: "command.circle")}

    public static var iconMore: Image {Image(systemName: "ellipsis")}
    
    public static var iconAdd: Image {Image(systemName: "plus")}
    public static var iconAddCircle: Image {Image(systemName: "plus.circle")}
    public static var iconAddCircleFill: Image {Image(systemName: "plus.circle.fill")}
    public static var iconAddSquare: Image {Image(systemName: "plus.square")}

    public static var iconRemove: Image {Image(systemName: "minus")}
    public static var iconRemoveCircle: Image {Image(systemName: "minus.circle")}
    public static var iconRemoveCircleFill: Image {Image(systemName: "minus.circle.fill")}

    public static var iconSearch: Image {Image(systemName: "magnifyingglass")}
    public static var iconFilter: Image {Image(systemName: "doc.text.magnifyingglass")}

    public static var iconEdit: Image {Image(systemName: "pencil")}
    public static var iconEditCircle: Image {Image(systemName: "pencil.circle")}
    public static var iconEditSquare: Image {Image(systemName: "square.and.pencil")}
    
    public static var iconSwitch: Image {Image(systemName: "switch.2")}
    
    public static var iconBack1: Image {Image(systemName: "chevron.backward")}
    public static var iconBack: Image {Image(systemName: "arrow.backward.circle.fill")}
    
    
    public static var iconArrowForward: Image {Image(systemName: "arrow.forward")}
    public static var iconArrowForwardCircle: Image {Image(systemName: "arrow.forward.circle")}

    public static var iconArrowBackward: Image {Image(systemName: "arrow.backward")}
    public static var iconArrowBackwardCircle: Image {Image(systemName: "arrow.backward.circle")}

    public static var iconArrowFirst: Image {Image(systemName: "arrow.left.to.line")}
    public static var iconArrowFirstCircle: Image {Image("arrow.left.to.line.circle")}
    // projective
    public static var iconArrowFirstView: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 28, height: 28)
            Image(systemName: "projective")
                .button(10)
                .foregroundColor(.white)
                .rotationEffect(.degrees(-90))
        }
    }
    public static var iconArrowLastView: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 28, height: 28)
            Image(systemName: "projective")
                .button(10)
                .foregroundColor(.white)
                .rotationEffect(.degrees(90))
        }
    }
    public static var iconArrowNextView: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 28, height: 28)
            Image(systemName: "chevron.forward")
                .button(14)
                .foregroundColor(.white)
        }
    }
    public static var iconArrowPrevView: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 28, height: 28)
            Image(systemName: "chevron.backward")
                .button(14)
                .foregroundColor(.white)
        }
    }
    
    public static var iconArrowTopView: some View {
        Image(systemName: "chevron.up.circle.fill")
            .button(32)
    }
    public static var iconArrowBottomView: some View {
        Image(systemName: "chevron.down.circle.fill")
            .button(32)
    }

    
    public static var iconArrowLast: Image {Image(systemName: "arrow.right.to.line")}
    public static var iconArrowLastCircle: Image {Image("arrow.right.to.line.circle")}

    public static var iconArrowtop: Image {Image(systemName: "arrow.up.to.line")}
    public static var iconArrowBottom: Image {Image(systemName: "arrow.down.to.line")}
    
    
    public static var iconCheck: Image {Image(systemName: "checkmark")}
    public static var iconCheckCircle: Image {Image(systemName: "checkmark.circle")}
    public static var iconCheckCircleFill: Image {Image(systemName: "checkmark.circle.fill")}
    
    public static var iconCheckNone: Image {Image(systemName: "circle")}
    public static var iconCheckNoneFill: Image {Image(systemName: "circle.fill")}

    public static var iconFullscreen: Image {Image(systemName: "arrow.up.backward.and.arrow.down.forward")}
    public static var iconFullscreenNone: Image {Image(systemName: "arrow.down.forward.and.arrow.up.backward")}
    
    
    public static var iconSettings: Image {Image(systemName: "gearshape.fill")}
    public static var iconSettings1: Image {Image(systemName: "gear")}
    
    public static var iconInfo: Image {Image(systemName: "info")}
    public static var iconInfoCircle: Image {Image(systemName: "info.circle")}
    
    public static var iconPhone: Image {Image(systemName: "phone")}
    public static var iconEmail: Image {Image(systemName: "mail")}

    public static var iconDownload: Image {Image(systemName: "square.and.arrow.down")}
    public static var iconUpload: Image {Image(systemName: "square.and.arrow.up")}
    
    public static var iconDevice: Image {Image(systemName: "apps.ipad.landscape")}
    public static var iconDeviceAdd: Image {Image(systemName: "externaldrive.badge.plus")}
    public static var iconDeviceManager: Image {Image(systemName: "externaldrive.connected.to.line.below.fill")}

    public static var iconLogin: Image {Image(systemName: "person.crop.circle.badge.checkmark")}
    public static var iconAccount: Image {Image(systemName: "person.crop.circle.badge.questionmark")}
    
    public static var iconReport: Image {Image(systemName: "rectangle.stack.fill.badge.person.crop")}
    public static var iconDeviceStatus: Image {Image(systemName: "waveform.path.ecg")}
    
    public static var iconPerson: Image {Image(systemName: "person")}
    public static var iconPersonAdd: Image {Image(systemName: "person.badge.plus")}
    
//    public static var iconPersonGroup = Image(systemName: "person.3")
    public static var iconPersonGroup: Image {Image(systemName: "person.2")}
    public static var iconPersonInDevice: Image {Image(systemName: "folder.badge.person.crop")}
    

    public static var iconFaces: Image {Image(systemName: "person.2")}
    public static var iconFaceRegister: Image {Image(systemName: "person.fill.viewfinder")}
    
    public static var iconQuestion: Image {Image(systemName: "questionmark.folder.fill")}
    public static var iconCamera: Image {Image(systemName: "camera")}
    public static var iconCameraNone1: Image {Image(systemName: "waveform")}
    public static var iconCameraNone: Image {Image(systemName: "bolt.slash")}
    
    public static var iconVideo: Image {Image(systemName: "video")}

    public static var iconCameraCapture: Image {Image(systemName: "camera")}
    public static var iconQrViewfinder: Image {Image(systemName: "qrcode.viewfinder")}
    
    
    public static var iconVideoPlaying: Image {Image(systemName: "video.badge.checkmark")}
    public static var iconVideoStart: Image {Image(systemName: "video")}
    public static var iconVideoStop: Image {Image(systemName: "stop.circle")}
    

    public static var iconPhoto: Image {Image(systemName: "photo.on.rectangle")}
    public static var iconGeneral: Image {Image(systemName: "circles.hexagongrid")}
    
    public static var iconNotify: Image {Image(systemName: "bell")}
    public static var iconRecognition: Image {Image(systemName: "eye")}
    
    public static var iconPlay: Image {Image(systemName: "play")}
    public static var iconRefresh: Image {Image(systemName: "arrow.triangle.2.circlepath")}
    public static var iconRefreshCircle: Image {Image(systemName: "arrow.triangle.2.circlepath.circle")}

    public static var iconCameraNoneView: some View {
        iconCameraNone
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.white)
    }
    public static var iconConnectDevice: Image {Image(systemName: "play.tv")}
    
    public static var iconNoImage: Image {Image(systemName: "person.fill.questionmark")}

    public func button(_ height: CGFloat = 20) -> some View {
        self.tnMakeScalable()
            .height(height)
    }
    
    public func buttonPage(_ height: CGFloat = 24) -> some View {
        self.tnMakeScalable()
            .height(height)
    }
}

extension UIImage {
    public func scale(scale: CGFloat) -> UIImage {
        if scale == 1 {
            return self
        }
        let newSize = CGSize(width: self.size.width * scale, height: self.size.height * scale)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let newImage = renderer.image { (context) in
            self.draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: newSize))
        }
        return newImage
    }
    
    public func scale(newWidth: CGFloat) -> UIImage {
        let width = max(self.size.width, self.size.height)
        if width == newWidth {
            return self
        }
        return self.scale(scale: newWidth/width)
    }
    
    public func jpegData(scale: CGFloat, compressionQuality: CGFloat) -> Data {
        let image = self.scale(scale: scale)
        TnLogger.debug("UIImage", "scale", self.size, image.size)
        return image.jpegData(compressionQuality: compressionQuality)!
    }
    
    public func jpegData(maxWidth: CGFloat, compressionQuality: CGFloat) -> Data {
        let image = self.scale(newWidth: maxWidth)
        TnLogger.debug("UIImage", "scale", self.size, image.size)
        return image.jpegData(compressionQuality: compressionQuality)!
    }
}

extension CIImage {
    public func jpegData(scale: CGFloat, compressionQuality: CGFloat) -> Data {
        UIImage(ciImage: self).jpegData(scale: scale, compressionQuality: compressionQuality)
    }
    
    public func jpegData(maxWidth: CGFloat, compressionQuality: CGFloat) -> Data {
        UIImage(ciImage: self).jpegData(maxWidth: maxWidth, compressionQuality: compressionQuality)
    }
}
