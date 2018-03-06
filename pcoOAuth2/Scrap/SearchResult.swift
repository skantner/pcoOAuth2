
class ResultArray:Codable {
    var resultCount = 0
    var results = [SearchResult]()
}

class SearchResult:Codable {
    var artistName = ""
    var trackName = ""
    var name:String {
        return trackName
    }
}
