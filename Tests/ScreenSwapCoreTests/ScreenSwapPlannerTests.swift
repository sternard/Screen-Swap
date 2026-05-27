import CoreGraphics
import XCTest
@testable import ScreenSwapCore

final class ScreenSwapPlannerTests: XCTestCase {
    func testTwoDisplaysSwapWindowPositions() {
        let displays = [
            DisplayFrame(id: 1, frame: CGRect(x: 0, y: 0, width: 1920, height: 1080)),
            DisplayFrame(id: 2, frame: CGRect(x: 1920, y: 0, width: 1920, height: 1080))
        ]
        let windows = [
            WindowFrame(id: 10, frame: CGRect(x: 100, y: 120, width: 800, height: 600)),
            WindowFrame(id: 20, frame: CGRect(x: 2200, y: 80, width: 500, height: 400))
        ]

        let moves = ScreenSwapPlanner.plannedMoves(windows: windows, displays: displays)

        XCTAssertEqual(moves, [
            WindowMove(windowID: 10, targetFrame: CGRect(x: 2020, y: 120, width: 800, height: 600)),
            WindowMove(windowID: 20, targetFrame: CGRect(x: 280, y: 80, width: 500, height: 400))
        ])
    }

    func testMoreThanTwoDisplaysRotateLeftToRight() {
        let displays = [
            DisplayFrame(id: 1, frame: CGRect(x: 0, y: 0, width: 1000, height: 800)),
            DisplayFrame(id: 2, frame: CGRect(x: 1000, y: 0, width: 1000, height: 800)),
            DisplayFrame(id: 3, frame: CGRect(x: 2000, y: 0, width: 1000, height: 800))
        ]
        let windows = [
            WindowFrame(id: 1, frame: CGRect(x: 10, y: 20, width: 300, height: 200)),
            WindowFrame(id: 2, frame: CGRect(x: 1010, y: 20, width: 300, height: 200)),
            WindowFrame(id: 3, frame: CGRect(x: 2010, y: 20, width: 300, height: 200))
        ]

        let moves = ScreenSwapPlanner.plannedMoves(windows: windows, displays: displays)

        XCTAssertEqual(moves.map(\.targetFrame.origin.x), [1010, 2010, 10])
    }

    func testDifferentSizedDisplaysScaleWindowFrame() {
        let displays = [
            DisplayFrame(id: 1, frame: CGRect(x: 0, y: 0, width: 1000, height: 1000)),
            DisplayFrame(id: 2, frame: CGRect(x: 1000, y: 0, width: 2000, height: 500))
        ]
        let windows = [
            WindowFrame(id: 7, frame: CGRect(x: 100, y: 200, width: 300, height: 400))
        ]

        let moves = ScreenSwapPlanner.plannedMoves(windows: windows, displays: displays)

        XCTAssertEqual(moves, [
            WindowMove(windowID: 7, targetFrame: CGRect(x: 1200, y: 100, width: 600, height: 200))
        ])
    }

    func testIgnoresWindowsThatAreNotOnAConnectedDisplay() {
        let displays = [
            DisplayFrame(id: 1, frame: CGRect(x: 0, y: 0, width: 1000, height: 800)),
            DisplayFrame(id: 2, frame: CGRect(x: 1000, y: 0, width: 1000, height: 800))
        ]
        let windows = [
            WindowFrame(id: 1, frame: CGRect(x: -5000, y: -5000, width: 300, height: 200))
        ]

        let moves = ScreenSwapPlanner.plannedMoves(windows: windows, displays: displays)

        XCTAssertTrue(moves.isEmpty)
    }

    func testSingleDisplayProducesNoMoves() {
        let moves = ScreenSwapPlanner.plannedMoves(
            windows: [WindowFrame(id: 1, frame: CGRect(x: 10, y: 10, width: 100, height: 100))],
            displays: [DisplayFrame(id: 1, frame: CGRect(x: 0, y: 0, width: 1000, height: 800))]
        )

        XCTAssertTrue(moves.isEmpty)
    }
}
