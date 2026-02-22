TeleporterSearchLeafNode = {}

function TeleporterSearchLeafNode.new(searchString, searchType)
    local node = {}
    setmetatable(node, {__index=TeleporterSearchLeafNode})
    node.searchString = searchString
    node.searchType = searchType
    return node
end

function TeleporterSearchLeafNode.MatchSpell(self, spell)
    return spell:MatchesSearch(self.searchString, self.searchType)
end

TeleporterSearch = {}

TeleporterSearch.SearchAll = 0
TeleporterSearch.SearchZone = 1
TeleporterSearch.SearchDungeon = 2
TeleporterSearch.SearchExpansion = 3
TeleporterSearch.SearchName = 4

function TeleporterSearch.Create(searchString)
    local node = TeleporterSearchLeafNode.new(searchString, TeleporterSearch.SearchAll)
    return node
end