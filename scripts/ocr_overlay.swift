import Cocoa
import Vision

// Usage: ocr_extract <input.png> [--json]
guard CommandLine.arguments.count >= 2 else {
    FileHandle.standardError.write("Usage: ocr_extract <input.png> [--json]\n".data(using: .utf8)!)
    exit(1)
}

let inputPath = CommandLine.arguments[1]
let asJSON = CommandLine.arguments.contains("--json")

guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: inputPath) as CFURL, nil),
      let cgImage = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
    FileHandle.standardError.write("Cannot open image\n".data(using: .utf8)!)
    exit(1)
}

let W = CGFloat(cgImage.width)
let H = CGFloat(cgImage.height)

let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.usesLanguageCorrection = true
// Korean + English + Japanese/Chinese for mixed content
request.recognitionLanguages = ["ko-KR", "en-US", "ja-JP", "zh-Hans"]

let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
do {
    try handler.perform([request])
} catch {
    FileHandle.standardError.write("OCR failed: \(error)\n".data(using: .utf8)!)
    exit(1)
}

struct Line {
    let text: String
    let confidence: Float
    let x1: Int, y1: Int, x2: Int, y2: Int
    var cx: Int { (x1 + x2) / 2 }
    var cy: Int { (y1 + y2) / 2 }
}

var lines: [Line] = []
for obs in (request.results ?? []) {
    guard let cand = obs.topCandidates(1).first else { continue }
    let b = obs.boundingBox  // normalized, origin bottom-left
    // Convert to top-left pixel coordinates
    let px1 = Int((b.minX * W).rounded())
    let px2 = Int((b.maxX * W).rounded())
    let py1 = Int(((1 - b.maxY) * H).rounded())
    let py2 = Int(((1 - b.minY) * H).rounded())
    lines.append(Line(text: cand.string, confidence: cand.confidence,
                      x1: px1, y1: py1, x2: px2, y2: py2))
}

// Sort top-to-bottom, then left-to-right
lines.sort { a, b in (a.y1, a.x1) < (b.y1, b.x1) }

if asJSON {
    let arr: [[String: Any]] = lines.enumerated().map { (i, l) in
        [
            "index": i + 1,
            "text": l.text,
            "confidence": Double(l.confidence),
            "bounds": "[\(l.x1),\(l.y1)][\(l.x2),\(l.y2)]",
            "center": [l.cx, l.cy]
        ]
    }
    let payload: [String: Any] = ["source": "ocr", "count": arr.count, "elements": arr]
    if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
       let str = String(data: data, encoding: .utf8) {
        print(str)
    }
} else {
    print("OCR text lines (\(lines.count) found):")
    for (i, l) in lines.enumerated() {
        let pct = Int(l.confidence * 100)
        print(String(format: "[%2d] (%4d,%4d) %3d%%  %@", i + 1, l.cx, l.cy, pct, l.text))
    }
}
