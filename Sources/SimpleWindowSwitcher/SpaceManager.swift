import Foundation
import CoreGraphics

class SpaceManager {
    /// Returns the set of active Space IDs across all connected displays.
    static func getActiveSpaceIDs() -> Set<Int> {
        var activeSpaces = Set<Int>()
        
        guard let connFunc = PrivateApis.SLSMainConnectionID,
              let copyFunc = PrivateApis.CGSCopyManagedDisplaySpaces else {
            NSLog("[SimpleWindowSwitcher] [SpaceManager] SLSMainConnectionID or CGSCopyManagedDisplaySpaces is not available.")
            return activeSpaces
        }
        
        let conn = connFunc()
        guard let displaySpaces = copyFunc(conn) as? [[String: Any]] else {
            NSLog("[SimpleWindowSwitcher] [SpaceManager] Failed to get managed display spaces.")
            return activeSpaces
        }
        
        for displayDict in displaySpaces {
            if let currentSpace = displayDict["Current Space"] as? [String: Any],
               let spaceID = currentSpace["ManagedSpaceID"] as? Int {
                activeSpaces.insert(spaceID)
            }
        }
        
        return activeSpaces
    }

    /// Returns the array of Space IDs associated with a specific window.
    /// Uses selector = 7 (kCGSSpaceAll) to query all spaces the window resides on.
    static func getSpaceIDs(forWindowID windowID: CGWindowID) -> [Int] {
        guard let connFunc = PrivateApis.SLSMainConnectionID,
              let copySpacesFunc = PrivateApis.CGSCopySpacesForWindows else {
            return []
        }
        
        let conn = connFunc()
        let array = [windowID] as CFArray
        guard let spaceIDsCF = copySpacesFunc(conn, 7, array) else {
            return []
        }
        
        return spaceIDsCF as? [Int] ?? []
    }
}
