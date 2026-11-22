import Foundation
import UniformTypeIdentifiers

public enum OpeningCategory: String, CaseIterable, Identifiable, Sendable {
    case text, image, video, audio, office, markdown, html, pdf, archive
    public var id: String { rawValue }
    public var supportsBuiltIn: Bool { [.text, .image, .video, .markdown, .html, .pdf, .archive].contains(self) }
    public var title: String {
        switch self {
        case .text: "文本"
        case .image: "图片"
        case .video: "视频"
        case .audio: "音频"
        case .office: "Office 文档"
        case .markdown: "Markdown 文档"
        case .html: "HTML 网页"
        case .pdf: "PDF 文档"
        case .archive: "压缩包"
        }
    }
    public var symbol: String {
        switch self {
        case .text: "doc.text"
        case .image: "photo"
        case .video: "film"
        case .audio: "music.note"
        case .office: "doc.richtext"
        case .markdown: "text.document"
        case .html: "globe"
        case .pdf: "doc"
        case .archive: "doc.zipper"
        }
    }
    public var extensions: [String] {
        switch self {
        case .text: ["txt", "log", "csv", "json", "jsonc", "yaml", "yml", "toml", "xml", "ini", "conf", "swift", "py", "js", "jsx", "ts", "tsx", "css", "scss", "less", "sh", "bash", "zsh", "fish", "java", "kt", "kts", "c", "h", "cpp", "cc", "cxx", "hpp", "hh", "cs", "go", "rs", "sql"]
        case .image: ["jpg", "jpeg", "png", "heic", "gif", "webp", "tif", "tiff", "bmp", "svg", "avif", "raw"]
        case .video: ["mp4", "mov", "m4v", "mkv", "avi", "webm", "mpeg", "mpg"]
        case .audio: ["mp3", "m4a", "aac", "wav", "flac", "aiff", "ogg"]
        case .office: ["doc", "docx", "docm", "dot", "dotx", "xls", "xlsx", "xlsm", "xlsb", "xlt", "xltx", "ppt", "pptx", "pptm", "pps", "ppsx", "odt", "ods", "odp"]
        case .markdown: ["md", "markdown", "mdown", "mkd"]
        case .html: ["html", "htm", "xhtml"]
        case .pdf: ["pdf"]
        case .archive: ["zip", "7z", "rar", "tar", "gz", "bz2", "xz", "tgz", "tbz2", "txz"]
        }
    }
    public var sampleDescription: String { extensions.prefix(4).map { "." + $0 }.joined(separator: "、") }
    public var contentTypes: [UTType] {
        switch self {
        case .text: [.plainText, .text]
        case .image: [.jpeg, .png, .image]
        case .video: [.mpeg4Movie, .movie]
        case .audio: [.mp3, .audio]
        case .office: ["docx", "xlsx", "pptx"].compactMap { UTType(filenameExtension: $0) }
        case .markdown: [UTType(filenameExtension: "md") ?? .plainText]
        case .html: [.html]
        case .pdf: [.pdf]
        case .archive: [.zip, .archive]
        }
    }
    public static func matching(fileExtension: String, typeIdentifier: String) -> [Self] {
        let ext = fileExtension.lowercased()
        let type = UTType(typeIdentifier)
        // Specific document families precede the broad text fallback.
        return [.markdown, .html, .office, .pdf, .image, .video, .audio, .archive, .text].filter { category in
            if category.extensions.contains(ext) { return true }
            switch category {
            case .text: return type?.conforms(to: .text) == true
            case .image: return type?.conforms(to: .image) == true
            case .video: return type?.conforms(to: .movie) == true
            case .audio: return type?.conforms(to: .audio) == true
            case .html: return type?.conforms(to: .html) == true
            case .pdf: return type?.conforms(to: .pdf) == true
            case .archive: return type?.conforms(to: .archive) == true
            default: return false
            }
        }
    }
}
