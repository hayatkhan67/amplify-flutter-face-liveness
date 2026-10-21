import Flutter
import SwiftUI
import FaceLiveness
import Amplify

class FaceLivenessView: NSObject, FlutterPlatformView {
    private var _view: UIView

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?,
        handler: EventStreamHadler
    ) {
        _view = UIView()
        super.init()
        
        createNativeView(view: _view, arguments: args, handler: handler)
    }

    func view() -> UIView {
        return _view
    }
    
    func createNativeView(view _view: UIView, arguments args: Any?, handler: EventStreamHadler){
        guard let args = args as? [String: Any] else { return }
        
        let keyWindows = UIApplication.shared.windows.first(where: { $0.isKeyWindow}) ?? UIApplication.shared.windows.first
        let topController = keyWindows?.rootViewController
        
        let vc = UIHostingController(
            rootView: NativeView(
                sessionId: args["sessionId"] as! String,
                region: args["region"] as! String,
                primaryColor: Color(argb: args["primaryColor"]),
                semanticLabel: args["semanticLabel"] as? String,
                handler: handler
            )
        )
        
        let swiftUiView = vc.view!
        swiftUiView.translatesAutoresizingMaskIntoConstraints = false
        
        topController?.addChild(vc)
        _view.addSubview(swiftUiView)
        
        NSLayoutConstraint.activate(
            [
                swiftUiView.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
                swiftUiView.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
                swiftUiView.topAnchor.constraint(equalTo: _view.topAnchor),
                swiftUiView.bottomAnchor.constraint(equalTo:  _view.bottomAnchor)
            ])
        
        vc.didMove(toParent: topController)
    }
}

struct NativeView: View {
    let sessionId: String
    let region: String
    let primaryColor: Color?
    let semanticLabel: String?
    let handler: EventStreamHadler

    @State private var isPresentingLiveness = true

    init(sessionId: String, region: String, primaryColor: Color?, semanticLabel: String?, handler: EventStreamHadler) {
        self.sessionId = sessionId
        self.region = region
        self.primaryColor = primaryColor
        self.semanticLabel = semanticLabel
        self.handler = handler
    }

    var body: some View {
        // Amplify's FaceLivenessDetectorView has no documented color/theme
        // API (unlike the Android component, which accepts a Material3
        // ColorScheme) — `.tint()` is a best-effort accent override that
        // standard SwiftUI controls respect; it won't restyle anything the
        // view draws itself, and the color-cycling liveness challenge is
        // never themeable by AWS design regardless of platform.
        FaceLivenessDetectorView(
            sessionID: self.sessionId,
            region: self.region,
            isPresented: $isPresentingLiveness,
            onCompletion: { result in
                switch result {
                case .success:
                    handler.onComplete()
                case .failure(let error):
                    switch error {
                    case .userCancelled:
                        handler.onError(code: "userCancelled")
                        return
                    case .sessionTimedOut:
                        handler.onError(code: "sessionTimedOut")
                        return
                    case .sessionNotFound:
                        handler.onError(code: "sessionNotFound")
                        return
                    default:
                        handler.onError(code: "error")
                        return
                    }
                default:
                    return
                }
            }
        )
        .tint(primaryColor)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(semanticLabel ?? "Face verification camera")
    }
}

extension Color {
    /// Builds a `Color` from an ARGB32 int (as produced by Dart's
    /// `Color.toARGB32()`), or `nil` when `value` isn't a number — lets the
    /// view fall back to its own default tint.
    init?(argb value: Any?) {
        guard let number = value as? NSNumber else { return nil }
        let argb = number.uint32Value
        let a = Double((argb >> 24) & 0xFF) / 255.0
        let r = Double((argb >> 16) & 0xFF) / 255.0
        let g = Double((argb >> 8) & 0xFF) / 255.0
        let b = Double(argb & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
} 