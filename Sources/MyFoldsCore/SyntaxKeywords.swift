import Foundation

enum SyntaxKeywords {
    static func words(for language: SyntaxLanguage) -> Set<String> {
        let common = "true false null nil return if else for while break continue switch case default try catch throw class struct enum import public private protected static const new this self super in as is let var func function async await"
        let extra: String
        switch language {
        case .swift: extra = "actor associatedtype any some borrowing consuming protocol extension guard defer deinit init throws rethrows inout mutating nonmutating nonisolated isolated final open override weak unowned lazy typealias where get set didSet willSet do repeat fallthrough fileprivate internal package"
        case .python: extra = "False None True and assert as async await class def del elif except finally from global import in is lambda nonlocal not or pass raise with yield match case"
        case .javascript, .typescript: extra = "export from of delete typeof instanceof void undefined yield extends implements interface type namespace declare readonly abstract constructor keyof infer satisfies never unknown string number boolean symbol get set"
        case .java, .kotlin: extra = "package final abstract extends implements interface instanceof synchronized transient volatile native throws boolean byte char double float int long short void fun val when object companion override data sealed suspend inline reified by lateinit out internal expect actual"
        case .c, .cpp: extra = "auto bool char double float int long short signed unsigned void typedef union volatile extern sizeof namespace using virtual template typename constexpr noexcept nullptr inline explicit friend delete operator override final alignas decltype mutable register"
        case .csharp: extra = "namespace using override virtual sealed partial readonly event delegate get set value base lock ref out params string int bool void decimal double float long byte char object internal abstract interface record required init"
        case .go: extra = "package func map chan range go defer select fallthrough type interface make len cap append nil const var"
        case .rust: extra = "fn impl trait pub use mod crate Self mut ref match loop move unsafe extern dyn where type union enum struct let const static as in async await"
        case .shell: extra = "then fi elif do done esac function select until export local readonly declare unset source echo printf read exit"
        case .sql: extra = "select from where join inner left right outer full on as insert into values update set delete create table index drop alter primary key foreign references not null default unique and or in exists like between group by having order asc desc limit offset union all distinct case when then else end begin commit rollback with returning count sum avg min max"
        case .json, .yaml, .toml: extra = "true false null yes no on off"
        default: extra = ""
        }
        return Set((common + " " + extra).split(separator: " ").map(String.init))
    }
}
