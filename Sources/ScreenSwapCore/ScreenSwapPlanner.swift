import CoreGraphics

public enum ScreenSwapPlanner {
    public static func plannedMoves(
        windows: [WindowFrame],
        displays: [DisplayFrame],
        minimumVisibleArea: CGFloat = 1
    ) -> [WindowMove] {
        let orderedDisplays = displays
            .filter { !$0.frame.isNull && !$0.frame.isEmpty }
            .sorted { lhs, rhs in
                if lhs.frame.minX == rhs.frame.minX {
                    return lhs.frame.minY < rhs.frame.minY
                }
                return lhs.frame.minX < rhs.frame.minX
            }

        guard orderedDisplays.count > 1 else {
            return []
        }

        return windows.compactMap { window in
            guard let sourceIndex = bestDisplayIndex(
                for: window.frame,
                in: orderedDisplays,
                minimumVisibleArea: minimumVisibleArea
            ) else {
                return nil
            }

            let targetIndex = orderedDisplays.index(after: sourceIndex) == orderedDisplays.endIndex
                ? orderedDisplays.startIndex
                : orderedDisplays.index(after: sourceIndex)
            let targetFrame = translate(
                window.frame,
                from: orderedDisplays[sourceIndex].frame,
                to: orderedDisplays[targetIndex].frame
            )
            return WindowMove(windowID: window.id, targetFrame: targetFrame)
        }
    }

    private static func bestDisplayIndex(
        for windowFrame: CGRect,
        in displays: [DisplayFrame],
        minimumVisibleArea: CGFloat
    ) -> Array<DisplayFrame>.Index? {
        var best: (index: Array<DisplayFrame>.Index, area: CGFloat)?

        for index in displays.indices {
            let intersection = windowFrame.intersection(displays[index].frame)
            let area = max(0, intersection.width) * max(0, intersection.height)
            guard area >= minimumVisibleArea else {
                continue
            }

            if best == nil || area > best!.area {
                best = (index, area)
            }
        }

        return best?.index
    }

    private static func translate(_ frame: CGRect, from source: CGRect, to target: CGRect) -> CGRect {
        let relativeX = source.width == 0 ? 0 : (frame.minX - source.minX) / source.width
        let relativeY = source.height == 0 ? 0 : (frame.minY - source.minY) / source.height
        let widthScale = source.width == 0 ? 1 : target.width / source.width
        let heightScale = source.height == 0 ? 1 : target.height / source.height

        return CGRect(
            x: target.minX + relativeX * target.width,
            y: target.minY + relativeY * target.height,
            width: frame.width * widthScale,
            height: frame.height * heightScale
        ).integral
    }
}
