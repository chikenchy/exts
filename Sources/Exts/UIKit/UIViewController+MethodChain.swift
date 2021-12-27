#if canImport(UIKit)

import UIKit

extension UIViewController {
    
    func addNC() -> UINavigationController {
        if let nc = self as? UINavigationController {
            return nc
        }
        
        return UINavigationController(rootViewController: self)
    }
}

#endif
