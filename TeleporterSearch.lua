local TeleporterSearchLeafNode = {}

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

local TeleporterSearchTypeNode = {}

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
    elseif self.searchType == "raid" then
        return spell:IsRaidSpell()
    else
        return false
    end
end

----------------------------------------

local TeleporterSearchNotNode = {}

function TeleporterSearchNotNode.new(subExpr)
    local node = {}
    setmetatable(node, {__index=TeleporterSearchNotNode})
    node.subExpr = subExpr
    return node
end

function TeleporterSearchNotNode.MatchSpell(self, spell)
    return not self.subExpr:MatchSpell(spell)
end

----------------------------------------

local TeleporterSearchOrNode = {}

function TeleporterSearchOrNode.new(subExpr1, subExpr2)
    local node = {}
    setmetatable(node, {__index=TeleporterSearchOrNode})
    node.subExpr1 = subExpr1
    node.subExpr2 = subExpr2
    return node
end

function TeleporterSearchOrNode.MatchSpell(self, spell)
    return self.subExpr1:MatchSpell(spell) or self.subExpr2:MatchSpell(spell)
end

----------------------------------------

local TeleporterSearchAndNode = {}

function TeleporterSearchAndNode.new(subExpr1, subExpr2)
    local node = {}
    setmetatable(node, {__index=TeleporterSearchAndNode})
    node.subExpr1 = subExpr1
    node.subExpr2 = subExpr2
    return node
end

function TeleporterSearchAndNode.MatchSpell(self, spell)
    return self.subExpr1:MatchSpell(spell) and self.subExpr2:MatchSpell(spell)
end

----------------------------------------

TeleporterSearch = {}

TeleporterSearch.SearchAll = 0
TeleporterSearch.SearchZone = 1
TeleporterSearch.SearchDungeon = 2
TeleporterSearch.SearchExpansion = 3
TeleporterSearch.SearchName = 4

local function trim(str)
    return string.gsub(str, '^%s*(.-)%s*$', '%1')
end

function TeleporterSearch.Create(searchString)
    local phrase = ""
    local subString = ""
    local paranCount = 0
    local currentExpression = nil
    for i=1,#searchString do
        local char = searchString:sub(i, i)
        if char == ":" and paranCount == 0 then
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
        elseif char == "(" then
            paranCount = paranCount + 1
            if paranCount == 1 then
                subString = ""
            end
        elseif char == ")" then
            paranCount = paranCount - 1
            if paranCount == 0 then
                local subExpr = TeleporterSearch.Create(subString)

                local op = string.lower(trim(phrase))

                if op == "not" then
                    currentExpression = TeleporterSearchNotNode.new(subExpr)
                elseif op == "or" then
                    if currentExpression then
                        currentExpression = TeleporterSearchOrNode.new(currentExpression, subExpr)
                    else
                        currentExpression = subExpr
                    end
                elseif op == "and" then
                    if currentExpression then
                        currentExpression = TeleporterSearchAndNode.new(currentExpression, subExpr)
                    else
                        currentExpression = subExpr
                    end
                elseif op == "or not" then
                    subExpr = TeleporterSearchNotNode.new(subExpr)
                    if currentExpression then
                        currentExpression = TeleporterSearchOrNode.new(currentExpression, subExpr)
                    else
                        currentExpression = subExpr
                    end
                elseif op == "and not" then
                    subExpr = TeleporterSearchNotNode.new(subExpr)
                    if currentExpression then
                        currentExpression = TeleporterSearchAndNode.new(currentExpression, subExpr)
                    else
                        currentExpression = subExpr
                    end
                else
                    currentExpression = subExpr
                end
            end
        elseif paranCount > 0 then
            subString = subString .. char
        else
            phrase = phrase .. char
        end
    end
    return currentExpression or TeleporterSearchLeafNode.new(searchString, TeleporterSearch.SearchAll)
end