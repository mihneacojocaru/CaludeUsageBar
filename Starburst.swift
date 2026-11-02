import AppKit

func drawStarburst(in rect: NSRect, color: NSColor) {
    let center = NSPoint(x: rect.midX, y: rect.midY)
    let radius = min(rect.width, rect.height) / 2
    let lengths: [CGFloat] = [1.0, 0.72, 0.9, 0.68, 0.96, 0.74, 0.86, 0.7, 1.0, 0.66, 0.92, 0.76]
    color.setStroke()
    for (index, length) in lengths.enumerated() {
        let angle = CGFloat(index) / CGFloat(lengths.count) * 2 * .pi + .pi / 2
        let path = NSBezierPath()
        path.lineWidth = radius * 0.2
        path.lineCapStyle = .round
        path.move(to: NSPoint(x: center.x + cos(angle) * radius * 0.12, y: center.y + sin(angle) * radius * 0.12))
        path.line(to: NSPoint(x: center.x + cos(angle) * radius * 0.88 * length, y: center.y + sin(angle) * radius * 0.88 * length))
        path.stroke()
    }
}
