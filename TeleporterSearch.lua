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

----------------------------------------

TeleporterSearchTypeNode = {}

function TeleporterSearchTypeNode.new(searchType)
    local node = {}
    setmetatable(node, {__index=TeleporterSearchTypeNode})
    node.searchType = searchType
    return node
end

function TeleporterSearchTypeNode.MatchSpell(self, spell)
    if self.searchType == "item" then
        return spell:IsItem()
    elseif self.searchType == "spell" then
        return spell:IsSpell()
    elseif self.searchType == "dungeon" then
        return spell:IsDungeonSpell()
    else
        return false
    end
end

----------------------------------------

TeleporterSearch = {}

TeleporterSearch.SearchAll = 0
TeleporterSearch.SearchZone = 1
TeleporterSearch.SearchDungeon = 2
TeleporterSearch.SearchExpansion = 3
TeleporterSearch.SearchName = 4

function TeleporterSearch.Create(searchString)
    local phrase = ""
    for i=1,#searchString do
        local char = searchString:sub(i, i)
        if char == ":" then
            local endString = searchString:sub(i+1, #searchString)
            if phrase == "name" then
                return TeleporterSearchLeafNode.new(endString, TeleporterSearch.SearchName)
            elseif phrase == "zone" then
                return TeleporterSearchLeafNode.new(endString, TeleporterSearch.SearchZone)
            elseif phrase == "expansion" then
                return TeleporterSearchLeafNode.new(endString, TeleporterSearch.SearchExpansion)
            elseif phrase == "dungeon" then
                return TeleporterSearchLeafNode.new(endString, TeleporterSearch.SearchDungeon)
            elseif phrase == "type" then
                return TeleporterSearchTypeNode.new(string.lower(endString))
            else
                phrase = phrase .. char
            end
        else
            phrase = phrase .. char
        end
    end
    return TeleporterSearchLeafNode.new(searchString, TeleporterSearch.SearchAll)
end