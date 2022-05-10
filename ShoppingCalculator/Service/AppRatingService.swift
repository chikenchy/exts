import Foundation
import SwiftRater

final class AppRatingService {
    
    func setup() {
        SwiftRater.daysUntilPrompt = 7
        SwiftRater.usesUntilPrompt = 10
        SwiftRater.significantUsesUntilPrompt = 5
        SwiftRater.daysBeforeReminding = 1
        SwiftRater.showLaterButton = true
//        SwiftRater.debugMode = true
        
        SwiftRater.appLaunched()
    }
    
    @discardableResult
    func check(host: UIViewController? = UIApplication.shared.connectedScenes.filter { $0.activationState == .foregroundActive }.first(where: { $0 is UIWindowScene }).flatMap({ $0 as? UIWindowScene })?.windows.first(where: \.isKeyWindow)?.rootViewController) -> Bool {
        return SwiftRater.check(host: host)
    }
    
    func incrementSignificantUsageCount() {
        SwiftRater.incrementSignificantUsageCount()
    }
    
}