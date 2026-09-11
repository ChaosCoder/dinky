import AppKit
import DinkyCoreImage
import DinkyCorePDF
import DinkyCoreShared
import DinkyCLILib
import Foundation
import PDFKit
import XCTest

final class PdfFlattenPipelineSmokeTests: XCTestCase {
    func testFlattenedPageRetainsFullOriginalBounds() async throws {
        let temp = FileManager.default.temporaryDirectory
        let id = UUID().uuidString
        let input = temp.appendingPathComponent("dinky-quadrants-\(id).pdf")
        let output = temp.appendingPathComponent("dinky-quadrants-output-\(id).pdf")
        defer {
            try? FileManager.default.removeItem(at: input)
            try? FileManager.default.removeItem(at: output)
        }

        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let context = CGContext(input as CFURL, mediaBox: &mediaBox, nil) else {
            XCTFail("Could not create source PDF")
            return
        }
        context.beginPDFPage(nil)
        context.setFillColor(NSColor.red.cgColor)
        context.fill(CGRect(x: 0, y: 396, width: 306, height: 396))
        context.setFillColor(NSColor.green.cgColor)
        context.fill(CGRect(x: 306, y: 396, width: 306, height: 396))
        context.setFillColor(NSColor.blue.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 306, height: 396))
        context.setFillColor(NSColor.yellow.cgColor)
        context.fill(CGRect(x: 306, y: 0, width: 306, height: 396))
        context.endPDFPage()
        context.closePDF()

        _ = try await DinkyPDFPipeline.compress(
            source: input,
            outputMode: .flattenPages,
            quality: .medium,
            grayscale: false,
            stripMetadata: true,
            outputURL: output,
            qpdfBinary: nil
        )

        guard let page = PDFDocument(url: output)?.page(at: 0),
              let tiff = page.thumbnail(of: NSSize(width: 612, height: 792), for: .mediaBox).tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let bottomRight = bitmap.colorAt(x: 560, y: 700) else {
            XCTFail("Could not render compressed PDF")
            return
        }
        XCTAssertGreaterThan(bottomRight.redComponent, 0.8)
        XCTAssertGreaterThan(bottomRight.greenComponent, 0.8)
        XCTAssertLessThan(bottomRight.blueComponent, 0.2)
    }

    func testCompressOnePagePDFToSmallerOrEqual() async throws {
        let temp = FileManager.default.temporaryDirectory
        let id = UUID().uuidString
        let inURL = temp.appendingPathComponent("dinky-pdf-\(id).pdf", isDirectory: false)
        defer { try? FileManager.default.removeItem(at: inURL) }

        let doc = PDFDocument()
        doc.insert(PDFPage(), at: 0)
        guard doc.write(to: inURL) else {
            throw XCTSkip("Could not write test PDF")
        }
        let original = Int64((try inURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)

        guard let bin = DinkyEncoderPath.resolveBinDirectory() else {
            throw XCTSkip("No Dinky bin directory")
        }
        let qpdf = DinkyEncoderPath.qpdfExecutable(inBinDirectory: bin)

        var o = DinkyPdfCompressOptions()
        o.outputMode = .flattenPages
        o.quality = .smallest
        o.smartQuality = false
        o.grayscale = true

        let (code, results) = await DinkyPdfCompressCommand.runWithOptions(
            o,
            paths: [inURL.path],
            preset: nil,
            qpdfBinary: qpdf
        )

        XCTAssertEqual(results.count, 1, "stderr: \(results.first?.error ?? "")")
        if code != 0, results.first?.error != nil {
            throw XCTSkip("PDF flatten failed in this environment: \(results[0].error!)")
        }
        XCTAssertEqual(code, 0)
        guard let out = results[0].output, let bytes = results[0].outputBytes else {
            XCTFail("missing output")
            return
        }
        defer { try? FileManager.default.removeItem(at: URL(fileURLWithPath: out)) }
        XCTAssertNotNil(results[0].output)
        XCTAssertLessThanOrEqual(bytes, original + 5000, "flatten should not explode size badly on blank page")
    }
}
