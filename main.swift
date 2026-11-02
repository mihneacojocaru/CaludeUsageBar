import AppKit

struct Window: Decodable {
    let utilization: Double?
    let resets_at: String?
}

struct Usage: Decodable {
    let five_hour: Window?
    let seven_day: Window?
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let sessionItem = NSMenuItem(title: "Sitzung: –", action: nil, keyEquivalent: "")
    let sessionResetItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    let weeklyItem = NSMenuItem(title: "Woche: –", action: nil, keyEquivalent: "")
    let weeklyResetItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    let statusLine = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    var lastFetch = Date.distantPast

    func applicationDidFinishLaunching(_ notification: Notification) {
        item.button?.image = menuBarIcon()
        item.button?.imagePosition = .imageLeft
        item.button?.title = " …"
        let menu = NSMenu()
        menu.delegate = self
        for entry in [sessionItem, sessionResetItem, .separator(), weeklyItem, weeklyResetItem, .separator(), statusLine] {
            entry.isEnabled = false
            menu.addItem(entry)
        }
        menu.addItem(NSMenuItem(title: "Aktualisieren", action: #selector(refresh), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Usage im Browser öffnen", action: #selector(openWeb), keyEquivalent: "u"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Beenden", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
        refresh()
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in self?.refresh() }
    }

    func menuWillOpen(_ menu: NSMenu) {
        if Date().timeIntervalSince(lastFetch) > 60 { refresh() }
    }

    @objc func openWeb() {
        NSWorkspace.shared.open(URL(string: "https://claude.ai/settings/usage")!)
    }

    func accessToken() -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        task.arguments = ["find-generic-password", "-s", "Claude Code-credentials", "-w"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        guard (try? task.run()) != nil else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let oauth = json["claudeAiOauth"] as? [String: Any] else { return nil }
        return oauth["accessToken"] as? String
    }

    @objc func refresh() {
        lastFetch = Date()
        guard let token = accessToken() else { return showError("Kein Login in Claude Code gefunden") }
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/api/oauth/usage")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("claude-usage-bar", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 20
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                if code == 401 { return self.showError("Token abgelaufen – Claude Code einmal starten") }
                guard code == 200, let data, let usage = try? JSONDecoder().decode(Usage.self, from: data) else {
                    return self.showError(error?.localizedDescription ?? "HTTP \(code)")
                }
                self.render(usage)
            }
        }.resume()
    }

    func render(_ usage: Usage) {
        let session = usage.five_hour?.utilization ?? 0
        let weekly = usage.seven_day?.utilization ?? 0
        let title = NSMutableAttributedString()
        let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        title.append(NSAttributedString(string: " S ", attributes: [.font: font]))
        title.append(NSAttributedString(string: "\(Int(session.rounded()))%", attributes: [.font: font, .foregroundColor: color(session)]))
        title.append(NSAttributedString(string: "  W ", attributes: [.font: font]))
        title.append(NSAttributedString(string: "\(Int(weekly.rounded()))%", attributes: [.font: font, .foregroundColor: color(weekly)]))
        item.button?.attributedTitle = title

        sessionItem.title = "Aktuelle Sitzung: \(Int(session.rounded())) %"
        sessionResetItem.title = "   Reset \(resetText(usage.five_hour?.resets_at))"
        weeklyItem.title = "Wöchentliches Limit: \(Int(weekly.rounded())) %"
        weeklyResetItem.title = "   Reset \(resetText(usage.seven_day?.resets_at))"
        statusLine.title = "Stand \(format(Date(), "HH:mm"))"
    }

    func menuBarIcon() -> NSImage {
        let image = NSImage(size: NSSize(width: 16, height: 16), flipped: false) { rect in
            drawStarburst(in: rect, color: .black)
            return true
        }
        image.isTemplate = true
        return image
    }

    func showError(_ message: String) {
        item.button?.title = " ⚠︎"
        statusLine.title = message
    }

    func color(_ percent: Double) -> NSColor {
        switch percent {
        case 90...: return NSColor(red: 1.0, green: 0.36, blue: 0.27, alpha: 1)
        case 70...: return NSColor(red: 1.0, green: 0.69, blue: 0.0, alpha: 1)
        default: return .labelColor
        }
    }

    func parseDate(_ string: String?) -> Date? {
        guard let string else { return nil }
        // ISO8601DateFormatter rejects microsecond fractions, so drop them.
        let trimmed = string.replacingOccurrences(of: #"\.\d+"#, with: "", options: .regularExpression)
        return ISO8601DateFormatter().date(from: trimmed)
    }

    func resetText(_ string: String?) -> String {
        guard let date = parseDate(string)?.addingTimeInterval(1) else { return "–" }
        let pattern = Calendar.current.isDateInToday(date) ? "'um' HH:mm" : "EEE dd.MM. 'um' HH:mm"
        let minutes = max(0, Int(date.timeIntervalSinceNow / 60))
        let remaining = minutes >= 1440 ? "\(minutes / 1440) T \(minutes % 1440 / 60) h"
            : minutes >= 60 ? "\(minutes / 60) h \(minutes % 60) min" : "\(minutes) min"
        return "\(format(date, pattern)) (in \(remaining))"
    }

    func format(_ date: Date, _ pattern: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
