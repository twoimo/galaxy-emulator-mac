import Cocoa
import CoreText

guard CommandLine.arguments.count >= 4 else {
    print("Usage: som_overlay <input.png> <elements.json> <output.png>")
    exit(1)
}

let inputPath = CommandLine.arguments[1]
let jsonPath = CommandLine.arguments[2]
let outputPath = CommandLine.arguments[3]

guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: inputPath) as CFURL, nil),
      let cgImage = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
    print("Cannot open image"); exit(1)
}

guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: jsonPath)),
      let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
      let elements = json["elements"] as? [[String: Any]] else {
    print("Cannot parse json"); exit(1)
}

let width = cgImage.width
let height = cgImage.height
let H = CGFloat(height)

let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil, width: width, height: height,
    bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { exit(1) }

ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))

let palette: [(CGFloat, CGFloat, CGFloat)] = [
    (0.00, 0.58, 1.00),  // vivid blue
    (0.00, 0.78, 0.45),  // green
    (1.00, 0.23, 0.23),  // red
    (1.00, 0.62, 0.00),  // orange
    (0.66, 0.33, 1.00),  // purple
]

let font = CTFontCreateWithName("Helvetica-Bold" as CFString, 30, nil)
let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)

for (idx, el) in elements.enumerated() {
    guard let bounds = el["bounds"] as? String else { continue }
    let cleaned = bounds
        .replacingOccurrences(of: "[", with: " ")
        .replacingOccurrences(of: "]", with: " ")
        .replacingOccurrences(of: ",", with: " ")
    let parts = cleaned.split(separator: " ").compactMap { Int($0) }
    guard parts.count == 4 else { continue }

    let x1 = CGFloat(parts[0])
    let y1 = CGFloat(parts[1])
    let x2 = CGFloat(parts[2])
    let y2 = CGFloat(parts[3])

    let (r, g, b) = palette[idx % palette.count]

    // Element box (convert top-down Android y to bottom-up CG y)
    let boxRect = CGRect(x: x1, y: H - y2, width: max(1, x2 - x1), height: max(1, y2 - y1))
    ctx.setFillColor(CGColor(red: r, green: g, blue: b, alpha: 0.12))
    ctx.fill(boxRect)
    ctx.setStrokeColor(CGColor(red: r, green: g, blue: b, alpha: 1.0))
    ctx.setLineWidth(4)
    ctx.stroke(boxRect)

    // Draw number label, centered inside the element box (always visible)
    let label = "\(el["index"] ?? (idx + 1))" as NSString
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white
    ]
    let attrString = NSAttributedString(string: label as String, attributes: attrs)
    let line = CTLineCreateWithAttributedString(attrString)
    let textBounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
    let textW = textBounds.width
    let textH = textBounds.height

    // Badge behind the number, anchored at element top-left
    let badgeH: CGFloat = 40
    let badgeW = textW + 20
    let badgeTopY = y2 > badgeH ? y1 : y1
    let badgeRect = CGRect(
        x: x1,
        y: H - badgeTopY - badgeH,
        width: badgeW,
        height: badgeH
    )
    ctx.setFillColor(CGColor(red: r, green: g, blue: b, alpha: 1.0))
    ctx.addPath(CGPath(roundedRect: badgeRect, cornerWidth: 6, cornerHeight: 6, transform: nil))
    ctx.fillPath()

    // Draw the number text inside the badge
    ctx.textPosition = CGPoint(
        x: badgeRect.origin.x + 10,
        y: badgeRect.origin.y + (badgeH - textH) / 2 + 6
    )
    CTLineDraw(line, ctx)
}

guard let outImage = ctx.makeImage(),
      let dest = CGImageDestinationCreateWithURL(
        URL(fileURLWithPath: outputPath) as CFURL, "public.png" as CFString, 1, nil
      ) else { exit(1) }
CGImageDestinationAddImage(dest, outImage, nil)
CGImageDestinationFinalize(dest)
print("✅ Set-of-Marks overlay saved to \(outputPath) (\(elements.count) elements tagged)")
