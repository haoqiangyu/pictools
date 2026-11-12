// Rasterize the existing Pictools brand paths for the native iOS launch image.
// Run from the repository root: swift scripts/generate_launch_icon.swift
import AppKit

let directory = "ios/Runner/Assets.xcassets/LaunchImage.imageset"
for scale in 1...3 {
  let side = 96 * scale
  let context = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8,
                          bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  context.translateBy(x: 0, y: CGFloat(side))
  context.scaleBy(x: CGFloat(side) / 128, y: -CGFloat(side) / 128)
  context.setFillColor(CGColor(srgbRed: 200/255, green: 71/255, blue: 37/255, alpha: 1))
  context.addPath(CGPath(roundedRect: CGRect(x: 0, y: 0, width: 128, height: 128),
                        cornerWidth: 28, cornerHeight: 28, transform: nil))
  context.fillPath()
  context.setStrokeColor(CGColor(gray: 1, alpha: 1))
  context.setLineWidth(10)
  context.setLineCap(.round)
  context.move(to: CGPoint(x: 31, y: 57))
  context.addLine(to: CGPoint(x: 31, y: 36))
  context.addQuadCurve(to: CGPoint(x: 36, y: 31), control: CGPoint(x: 31, y: 31))
  context.addLine(to: CGPoint(x: 57, y: 31))
  context.move(to: CGPoint(x: 71, y: 97))
  context.addLine(to: CGPoint(x: 92, y: 97))
  context.addQuadCurve(to: CGPoint(x: 97, y: 92), control: CGPoint(x: 97, y: 97))
  context.addLine(to: CGPoint(x: 97, y: 71))
  context.strokePath()
  context.setFillColor(CGColor(gray: 1, alpha: 1))
  context.move(to: CGPoint(x: 38, y: 87))
  for p in [CGPoint(x:38,y:73), CGPoint(x:54,y:57), CGPoint(x:72,y:75), CGPoint(x:87,y:60), CGPoint(x:87,y:87)] {
    context.addLine(to: p)
  }
  context.closePath(); context.fillPath()
  context.fillEllipse(in: CGRect(x: 76, y: 36, width: 16, height: 16))
  let image = NSBitmapImageRep(cgImage: context.makeImage()!)
  let suffix = scale == 1 ? "" : "@\(scale)x"
  try image.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(directory)/LaunchImage\(suffix).png"))
}
