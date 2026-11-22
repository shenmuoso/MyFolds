import AppKit
import SwiftUI
import Testing
@testable import MyFolds

@MainActor
@Suite("Window material regression", .serialized)
struct WindowMaterialTests {
    @Test("Automatic appearance follows inherited changes and retains native controls")
    func inheritedAppearanceAndControls() async throws {
        let application = NSApplication.shared, old = NSApplication.shared.appearance
        defer { application.appearance = old }
        let controller = MaterialContentController(content: WindowControls().frame(width: 70, height: 22))
        controller.surface.windowID = "MyFolds.test.controls"
        let window = NSWindow(contentViewController: controller)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.isReleasedWhenClosed = false; window.setContentSize(NSSize(width: 240, height: 160))
        defer { window.close() }
        controller.surface.windowAppearance = "system"
        controller.surface.configureWindow()
        window.contentView?.layoutSubtreeIfNeeded()
        for name in [NSAppearance.Name.darkAqua, .aqua, .darkAqua, .aqua] {
            application.appearance = NSAppearance(named: name)
            try await Task.sleep(for: .milliseconds(80))
            window.contentView?.layoutSubtreeIfNeeded()
            #expect(window.appearance == nil)
            #expect(controller.appearanceState.scheme == (name == .darkAqua ? .dark : .light))
            let controls = try #require(findControls(window.contentView))
            #expect(controls.nativeButtons.count == 3)
            #expect(controls.nativeButtons.allSatisfy { !$0.isHidden && $0.superview === controls && $0.window === window })
        }
        controller.surface.windowAppearance = "light"; controller.surface.configureWindow()
        application.appearance = NSAppearance(named: .darkAqua)
        try await Task.sleep(for: .milliseconds(80))
        #expect(controller.appearanceState.scheme == .light)
        controller.surface.windowAppearance = "system"; controller.surface.configureWindow()
        #expect(controller.appearanceState.scheme == .dark)
    }

    private func findControls(_ view: NSView?) -> ControlsView? {
        guard let view else { return nil }
        if let controls = view as? ControlsView { return controls }
        return view.subviews.lazy.compactMap { findControls($0) }.first
    }

    @Test("Preferences update both hosted windows and survive reopening")
    func preferencesDriveWindows() async throws {
        _ = NSApplication.shared
        let domain = "MyFolds.material-test.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: domain))
        defer { defaults.removePersistentDomain(forName: domain) }
        let preferences = Preferences(defaults: defaults)
        var windows: [NSWindow] = []
        defer { windows.forEach { $0.close() } }
        for id in ["main", "settings"] {
            let controller = NSHostingController(rootView: WindowMaterial(preferences: preferences, identifier: "MyFolds.test.\(id)") { Color.clear })
            controller.safeAreaRegions = []
            let window = NSWindow(contentViewController: controller)
            window.isReleasedWhenClosed = false
            window.setContentSize(NSSize(width: 240, height: 160))
            window.contentView?.layoutSubtreeIfNeeded()
            windows.append(window)
        }
        for appearance in ["light", "dark"] {
            preferences.appearance = appearance
            for reduced in [true, false, true] {
                preferences.reduceTransparency = reduced
                // Let the actual SwiftUI observation/render pass apply the new
                // preference. Never call configureWindow from this test.
                try await Task.sleep(for: .milliseconds(80))
                for window in windows {
                    window.setContentSize(NSSize(width: 300, height: 200))
                    window.contentView?.layoutSubtreeIfNeeded()
                    let surface = try #require(findSurface(in: window.contentView))
                    #expect(surface.wantsOpaque == reduced)
                    #expect(window.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == (appearance == "dark" ? .darkAqua : .aqua))
                    if reduced { try expectSolid(surface) }
                }
            }
        }
        let restored = Preferences(defaults: defaults)
        #expect(restored.reduceTransparency)
        #expect(restored.appearance == "dark")
        let reopened = NSWindow(contentViewController: NSHostingController(rootView: WindowMaterial(preferences: restored, identifier: "MyFolds.test.reopened") { Color.clear }))
        reopened.isReleasedWhenClosed = false
        defer { reopened.close() }
        reopened.setContentSize(NSSize(width: 300, height: 200))
        reopened.contentView?.layoutSubtreeIfNeeded()
        try await Task.sleep(for: .milliseconds(80))
        let surface = try #require(findSurface(in: reopened.contentView))
        #expect(surface.wantsOpaque)
        try expectSolid(surface)
    }

    private func findSurface(in view: NSView?) -> MaterialView? {
        guard let view else { return nil }
        if let surface = view as? MaterialView { return surface }
        return view.subviews.lazy.compactMap { findSurface(in: $0) }.first
    }

    private func expectSolid(_ surface: MaterialView) throws {
        surface.window?.backgroundColor = .clear
        let bitmap = try #require(surface.bitmapImageRepForCachingDisplay(in: surface.bounds))
        surface.cacheDisplay(in: surface.bounds, to: bitmap)
        for (x, y) in [(20, 20), (150, 100), (280, 180)] {
            #expect(try #require(bitmap.colorAt(x: x, y: y)).alphaComponent > 0.999)
        }
    }

    @Test("Opaque fallback survives hosted content, theme changes and repeated toggles")
    func hostedFallback() throws {
        _ = NSApplication.shared
        let controller = MaterialContentController(content: Color.clear)
        let window = NSWindow(contentViewController: controller)
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 240, height: 160))
        defer { window.close() }
        let surface = controller.surface
        surface.windowID = "MyFolds.test.hosted"
        var brightness: [CGFloat] = []
        for appearance in ["light", "dark", "light"] {
            surface.windowAppearance = appearance
            for reduced in [false, true, false, true] {
                surface.wantsOpaque = reduced
                surface.configureWindow()
                window.backgroundColor = .clear
                surface.layoutSubtreeIfNeeded()
                #expect(window.contentViewController === controller)
                guard reduced else { continue }
                let bitmap = try #require(surface.bitmapImageRepForCachingDisplay(in: surface.bounds))
                surface.cacheDisplay(in: surface.bounds, to: bitmap)
                let color = try #require(bitmap.colorAt(x: 120, y: 80)?.usingColorSpace(.sRGB))
                #expect(color.alphaComponent > 0.999)
                brightness.append(color.redComponent)
            }
        }
        #expect(brightness[0] > brightness[2] + 0.4)
        #expect(abs(brightness[0] - brightness[4]) < 0.01)
    }

    @Test("Reduce Transparency draws opaque pixels even in a clear window", arguments: ["light", "dark"])
    func opaqueFallback(appearance: String) throws {
        _ = NSApplication.shared
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 240, height: 160), styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        let surface = MaterialView(frame: NSRect(x: 0, y: 0, width: 240, height: 160))
        surface.windowID = "MyFolds.test.direct"
        window.contentView = surface
        defer { window.close() }
        surface.windowAppearance = appearance

        // SwiftUI's transparent window container must never become the only
        // remaining layer when Reduce Transparency hides the backdrop effect.
        for reduced in [true, false, true] {
            surface.wantsOpaque = reduced
            surface.configureWindow()
            window.backgroundColor = .clear
            surface.layoutSubtreeIfNeeded()
            guard reduced else { continue }
            let bitmap = try #require(surface.bitmapImageRepForCachingDisplay(in: surface.bounds))
            surface.cacheDisplay(in: surface.bounds, to: bitmap)
            for point in [(20, 20), (120, 80), (220, 140)] {
                let color = try #require(bitmap.colorAt(x: point.0, y: point.1)?.usingColorSpace(.sRGB))
                #expect(color.alphaComponent > 0.999, "Reduce Transparency must paint a solid surface, not reveal the desktop")
            }
        }
    }
}
