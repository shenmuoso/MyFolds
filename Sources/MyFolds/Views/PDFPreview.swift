import SwiftUI
import PDFKit

struct PDFPreview: View {
    let url: URL
    @State private var document: PDFDocument?
    @State private var error: String?
    var body: some View {
        Group {
            if let document { NativePDFView(document: document) }
            else if let error { ContentUnavailableView("无法查看 PDF", systemImage: "doc", description: Text(error)) }
            else { ProgressView("正在读取 PDF…").frame(maxWidth: .infinity, maxHeight: .infinity) }
        }.task(id: url) {
            do { let result = try await PDFLoader.load(url); try Task.checkCancellation(); document = result }
            catch is CancellationError { }
            catch { self.error = error.localizedDescription }
        }
    }
}

private enum PDFLoader {
    @concurrent static func load(_ url: URL) async throws -> sending PDFDocument {
        let bytes = try Data(contentsOf: url)
        guard let document = PDFDocument(data: bytes) else { throw CocoaError(.fileReadCorruptFile) }
        return document
    }
}

private struct NativePDFView: NSViewRepresentable {
    let document: PDFDocument
    func makeNSView(context: Context) -> PDFView {
        let view = PDFView(); view.autoScales = true; view.displayMode = .singlePageContinuous
        view.backgroundColor = .clear; view.document = document
        return view
    }
    func updateNSView(_ view: PDFView, context: Context) { if view.document !== document { view.document = document } }
}
