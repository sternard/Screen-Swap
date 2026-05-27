import ApplicationServices
import CoreGraphics
import Foundation
import ScreenSwapCore

@main
struct ScreenSwapApp {
    static func main() {
        let runner = ScreenSwapRunner()
        runner.run()
    }
}

final class ScreenSwapRunner {
    func run() {
        guard ensureAccessibilityPermission() else {
            log("Screen Swap needs Accessibility access. Enable it in System Settings > Privacy & Security > Accessibility, then run it again.")
            return
        }

        let displays = currentDisplays()
        guard displays.count > 1 else {
            log("Connect at least two displays before running Screen Swap.")
            return
        }

        let windows = currentWindows()
        guard !windows.isEmpty else {
            return
        }

        let fullScreenWindows = exitFullScreenWindows(windows)
        let refreshedWindows = windowsAfterExitingFullScreen(fullScreenWindows)
        let windowFrames = refreshedWindows.map { WindowFrame(id: $0.id, frame: $0.frame) }
        let moves = ScreenSwapPlanner.plannedMoves(windows: windowFrames, displays: displays)
        let windowsByID = Dictionary(uniqueKeysWithValues: refreshedWindows.map { ($0.id, $0) })

        for move in moves {
            guard let window = windowsByID[move.windowID] else {
                continue
            }
            setFrame(move.targetFrame, for: window.axWindow)
        }
    }

    private func ensureAccessibilityPermission() -> Bool {
        let trusted = AXIsProcessTrusted()
        if trusted {
            return true
        }

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    private func currentDisplays() -> [DisplayFrame] {
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &count) == .success, count > 0 else {
            return []
        }

        var displayIDs = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetActiveDisplayList(count, &displayIDs, &count) == .success else {
            return []
        }

        return displayIDs.prefix(Int(count)).map { displayID in
            DisplayFrame(id: displayID, frame: CGDisplayBounds(displayID))
        }
    }

    private func currentWindows() -> [ManagedWindow] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let rawWindows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        return rawWindows.compactMap { info in
            guard
                let windowID = info[kCGWindowNumber as String] as? UInt32,
                let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t,
                let layer = info[kCGWindowLayer as String] as? Int,
                layer == 0,
                let bounds = info[kCGWindowBounds as String] as? [String: Any],
                let frame = CGRect(dictionaryRepresentation: bounds as CFDictionary),
                frame.width > 1,
                frame.height > 1
            else {
                return nil
            }

            guard let axWindow = axWindow(pid: ownerPID, windowID: windowID) else {
                return nil
            }

            return ManagedWindow(id: windowID, pid: ownerPID, frame: frame, axWindow: axWindow)
        }
    }

    private func axWindow(pid: pid_t, windowID: UInt32) -> AXUIElement? {
        let app = AXUIElementCreateApplication(pid)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &value) == .success,
              let windows = value as? [AXUIElement] else {
            return nil
        }

        for window in windows {
            var id = CGWindowID(0)
            guard _AXUIElementGetWindow(window, &id) == .success else {
                continue
            }
            if id == windowID {
                return window
            }
        }

        return nil
    }

    private func exitFullScreenWindows(_ windows: [ManagedWindow]) -> [ManagedWindow] {
        var changedWindows: [ManagedWindow] = []

        for window in windows {
            var value: CFTypeRef?
            guard AXUIElementCopyAttributeValue(window.axWindow, "AXFullScreen" as CFString, &value) == .success,
                  let isFullScreen = value as? Bool,
                  isFullScreen else {
                continue
            }

            AXUIElementSetAttributeValue(window.axWindow, "AXFullScreen" as CFString, kCFBooleanFalse)
            changedWindows.append(window)
        }

        return changedWindows
    }

    private func windowsAfterExitingFullScreen(_ fullScreenWindows: [ManagedWindow]) -> [ManagedWindow] {
        var latestWindows = currentWindows()
        guard !fullScreenWindows.isEmpty else {
            return latestWindows
        }

        let expectedWindowIDs = Set(fullScreenWindows.map(\.id))
        let deadline = Date().addingTimeInterval(5.0)
        while Date() < deadline {
            latestWindows = currentWindows()
            let visibleWindowIDs = Set(latestWindows.map(\.id))

            if !containsFullScreenWindow(fullScreenWindows),
               expectedWindowIDs.isSubset(of: visibleWindowIDs) {
                Thread.sleep(forTimeInterval: 0.15)
                return currentWindows()
            }

            Thread.sleep(forTimeInterval: 0.1)
        }

        return latestWindows
    }

    private func containsFullScreenWindow(_ windows: [ManagedWindow]) -> Bool {
        windows.contains { window in
            var value: CFTypeRef?
            guard AXUIElementCopyAttributeValue(window.axWindow, "AXFullScreen" as CFString, &value) == .success,
                  let isFullScreen = value as? Bool else {
                return false
            }

            return isFullScreen
        }
    }

    private func setFrame(_ frame: CGRect, for window: AXUIElement) {
        var origin = frame.origin
        var size = frame.size

        if let position = AXValueCreate(.cgPoint, &origin) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, position)
        }

        if let dimensions = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, dimensions)
        }
    }

    private func log(_ message: String) {
        FileHandle.standardError.write(Data("Screen Swap: \(message)\n".utf8))
    }
}

struct ManagedWindow {
    var id: UInt32
    var pid: pid_t
    var frame: CGRect
    var axWindow: AXUIElement
}

@_silgen_name("_AXUIElementGetWindow")
func _AXUIElementGetWindow(_ axUiElement: AXUIElement, _ out: UnsafeMutablePointer<CGWindowID>) -> AXError
