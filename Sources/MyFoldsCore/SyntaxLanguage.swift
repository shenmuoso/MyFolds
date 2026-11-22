import Foundation

public enum SyntaxLanguage: String, CaseIterable, Identifiable, Sendable {
    case plain, swift, python, javascript, typescript, java, kotlin, c, cpp, csharp, go, rust, html, xml, css, json, yaml, toml, shell, sql, markdown, diff, log, ini, dockerfile, makefile
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .diff: "Diff / Patch"
        case .log: "Log"
        case .ini: "INI / ENV"
        case .dockerfile: "Dockerfile"
        case .makefile: "Makefile"
        case .plain: "纯文本"
        case .swift: "Swift"
        case .python: "Python"
        case .javascript: "JavaScript"
        case .typescript: "TypeScript"
        case .java: "Java"
        case .kotlin: "Kotlin"
        case .c: "C"
        case .cpp: "C++"
        case .csharp: "C#"
        case .go: "Go"
        case .rust: "Rust"
        case .html: "HTML"
        case .xml: "XML"
        case .css: "CSS"
        case .json: "JSON"
        case .yaml: "YAML"
        case .toml: "TOML"
        case .shell: "Shell"
        case .sql: "SQL"
        case .markdown: "Markdown"
        }
    }
    public static func named(_ name: String) -> Self? {
        switch name.lowercased() {
        case "diff", "patch": .diff
        case "log": .log
        case "ini", "cfg", "conf", "properties", "env": .ini
        case "mk", "make", "makefile": .makefile
        case "containerfile", "dockerfile": .dockerfile
        case "txt", "text", "plaintext": .plain
        case "py", "python": .python
        case "js", "jsx", "javascript": .javascript
        case "ts", "tsx", "typescript": .typescript
        case "kt", "kts", "kotlin": .kotlin
        case "h", "c": .c
        case "c++", "cc", "cpp", "cxx", "hpp", "hh": .cpp
        case "cs", "c#", "csharp": .csharp
        case "rs", "rust": .rust
        case "htm", "xhtml", "html": .html
        case "xml", "plist", "xsl", "xsd": .xml
        case "css", "scss", "less": .css
        case "json", "jsonc", "json5": .json
        case "yml", "yaml": .yaml
        case "sh", "bash", "zsh", "fish", "shell": .shell
        case "md", "markdown", "mdown", "mkd": .markdown
        default: Self(rawValue: name.lowercased())
        }
    }
    public static func detect(url: URL, text: String) -> Self {
        let filename = url.lastPathComponent.lowercased()
        if ["dockerfile", "containerfile"].contains(filename) || filename.hasPrefix("dockerfile.") { return .dockerfile }
        if ["makefile", "gnumakefile"].contains(filename) { return .makefile }
        if filename == ".env" || filename.hasPrefix(".env.") { return .ini }
        if filename.contains(".log.") && Int(url.pathExtension) != nil { return .log }
        if let language = named(url.pathExtension) { return language }
        if [".zshrc", ".bashrc", ".bash_profile", ".zprofile"].contains(url.lastPathComponent) { return .shell }
        let firstLine = text.prefix(200).split(separator: "\n").first ?? ""
        if firstLine.hasPrefix("#!") {
            if firstLine.contains("python") { return .python }
            if firstLine.contains("node") { return .javascript }
            if firstLine.contains("sh") || firstLine.contains("fish") { return .shell }
        }
        return .plain
    }
}
