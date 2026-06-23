// Generates AppIcon.iconset PNGs from the broom+sparkle design (app.jsx AppIcon).
// Usage: swift Tools/make_icon.swift <output-iconset-dir>
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

func color(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

func renderIcon(_ size: CGFloat) -> CGImage {
    let cs = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8,
                        bytesPerRow: 0, space: cs,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    // Work in a top-left origin (like the SVG) by flipping.
    ctx.translateBy(x: 0, y: size)
    ctx.scaleBy(x: 1, y: -1)

    // macOS icon grid: rounded square inset ~10% with shadow padding around it.
    let pad = size * 0.10
    let rect = CGRect(x: pad, y: pad, width: size - 2 * pad, height: size - 2 * pad)
    let radius = rect.width * 0.225
    let squircle = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)

    // Soft drop shadow behind the squircle.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -size * 0.012), blur: size * 0.03,
                  color: color(0x0A52D6, 0.35))
    ctx.addPath(squircle)
    ctx.setFillColor(color(0x0A6DFF))
    ctx.fillPath()
    ctx.restoreGState()

    // Blue gradient fill (≈160°, top → bottom-right).
    ctx.saveGState()
    ctx.addPath(squircle)
    ctx.clip()
    let grad = CGGradient(colorsSpace: cs,
                          colors: [color(0x3A9BFF), color(0x0A6DFF), color(0x0A52D6)] as CFArray,
                          locations: [0, 0.55, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: rect.minX, y: rect.minY),
                           end: CGPoint(x: rect.maxX, y: rect.maxY), options: [])

    // Glyph drawn in a centered 24×24 space at 56% of the squircle.
    let g = rect.width * 0.56
    let ox = rect.minX + (rect.width - g) / 2
    let oy = rect.minY + (rect.height - g) / 2
    let u = g / 24
    func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x * u, y: oy + y * u) }

    // Broom head — rounded rect rotated -32° about (3.5,14.5), white 95%.
    ctx.saveGState()
    let pivot = P(3.5, 14.5)
    ctx.translateBy(x: pivot.x, y: pivot.y)
    ctx.rotate(by: -32 * .pi / 180)
    ctx.translateBy(x: -pivot.x, y: -pivot.y)
    let broom = CGPath(roundedRect: CGRect(x: ox + 3.5 * u, y: oy + 14.5 * u, width: 11 * u, height: 6 * u),
                       cornerWidth: 1.4 * u, cornerHeight: 1.4 * u, transform: nil)
    ctx.addPath(broom)
    ctx.setFillColor(color(0xFFFFFF, 0.95))
    ctx.fillPath()
    ctx.restoreGState()

    // Sparkle — M14.5 3.5 l1 3 3 1 -3 1 -1 3 -1 -3 -3 -1 z, white.
    let sp = CGMutablePath()
    sp.move(to: P(14.5, 3.5))
    sp.addLine(to: P(15.5, 6.5))
    sp.addLine(to: P(18.5, 7.5))
    sp.addLine(to: P(15.5, 8.5))
    sp.addLine(to: P(14.5, 11.5))
    sp.addLine(to: P(13.5, 8.5))
    sp.addLine(to: P(10.5, 7.5))
    sp.addLine(to: P(13.5, 6.5))
    sp.closeSubpath()
    ctx.addPath(sp)
    ctx.setFillColor(color(0xFFFFFF))
    ctx.fillPath()
    ctx.restoreGState()

    return ctx.makeImage()!
}

func writePNG(_ image: CGImage, to url: URL) {
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

guard CommandLine.arguments.count > 1 else {
    FileHandle.standardError.write("usage: make_icon.swift <output-iconset-dir>\n".data(using: .utf8)!)
    exit(1)
}
let outDir = URL(fileURLWithPath: CommandLine.arguments[1])
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

// (filename, pixel size) per the .iconset spec.
let variants: [(String, CGFloat)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]
for (name, px) in variants {
    writePNG(renderIcon(px), to: outDir.appendingPathComponent(name))
}
print("wrote \(variants.count) icon PNGs to \(outDir.path)")
