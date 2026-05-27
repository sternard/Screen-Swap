import CoreGraphics

public struct DisplayFrame: Equatable, Sendable {
    public var id: UInt32
    public var frame: CGRect

    public init(id: UInt32, frame: CGRect) {
        self.id = id
        self.frame = frame
    }

    public static func == (lhs: DisplayFrame, rhs: DisplayFrame) -> Bool {
        lhs.id == rhs.id && lhs.frame.equalTo(rhs.frame)
    }
}

public struct WindowFrame: Equatable, Sendable {
    public var id: UInt32
    public var frame: CGRect

    public init(id: UInt32, frame: CGRect) {
        self.id = id
        self.frame = frame
    }

    public static func == (lhs: WindowFrame, rhs: WindowFrame) -> Bool {
        lhs.id == rhs.id && lhs.frame.equalTo(rhs.frame)
    }
}

public struct WindowMove: Equatable, Sendable {
    public var windowID: UInt32
    public var targetFrame: CGRect

    public init(windowID: UInt32, targetFrame: CGRect) {
        self.windowID = windowID
        self.targetFrame = targetFrame
    }

    public static func == (lhs: WindowMove, rhs: WindowMove) -> Bool {
        lhs.windowID == rhs.windowID && lhs.targetFrame.equalTo(rhs.targetFrame)
    }
}
