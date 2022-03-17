local GUI = {}
local SCRW = ScrW()
local SCRH = ScrH()
local LAST_WORKSHOP = "Collection URL or ID here"
local MENU_VERSION = "2.2"
local DATA_CACHE = {}

--------------------------------------------------------------------------------
-- Create is_running_menu_install.txt to notify the client that a menu version
-- is indeed installed
--------------------------------------------------------------------------------
local text = 
    "Version "..MENU_VERSION.."\n"..
    "Dearest user,\n\n"..

    "Please don't delete me, otherwise Workshop Collector will break!\n"..
    "Don't you love workarounds?\n\n"..

    "Yours truly,\n"..
    "Lemon\n"
file.CreateDir("workshop_collector")
file.Write("workshop_collector/is_running_menu_install.txt", text)

--------------------------------------------------------------------------------
-- Find the ID from a given URL or ID
--------------------------------------------------------------------------------
GUI.GetWorkshopID = function(p_string)
    return string.match(p_string, "%d+")
end

--------------------------------------------------------------------------------
-- Collate data and do things to process them
-- -TODO- Logic here is %$^@&$% awful
--------------------------------------------------------------------------------
GUI.CollateData = function(p_collection_id, p_meta_table, p_content_table)
    local data = {}
    data.id = p_collection_id
    data.name = p_meta_table["response"]["publishedfiledetails"][1]["title"]
    -- Get list of workshop items in collection
    local content_data = {}
    if p_content_table.response.collectiondetails[1].children then
        for _,v in pairs(p_content_table.response.collectiondetails[1].children) do
            table.insert(content_data, v.publishedfileid)
        end
        data.content = content_data

        -- Successful workshop collection operation, save it
        LAST_WORKSHOP = "https://steamcommunity.com/sharedfiles/filedetails/?id="..p_collection_id
        GUI.EnableSubmitButton(data)
    else
        -- Workshop item, but not a collection
        GUI.DisableSubmitButton(true)
    end
end

--------------------------------------------------------------------------------
-- Find the content of a collection ID
--------------------------------------------------------------------------------
GUI.QueryCollectionContent = function(p_collection_id, p_meta_table)
    local url = "https://api.steampowered.com/ISteamRemoteStorage/GetCollectionDetails/v1/?"
    local params = {}
    params["collectioncount"] = "1"
    params["publishedfileids[0]"] = tostring(p_collection_id)
    http.Post(url, params,

    -- onSuccess func
    function(body, length, headers, code)
        if code == 200 then
            GUI.CollateData(p_collection_id, p_meta_table, util.JSONToTable(body))
        else
            GUI.DisableSubmitButton()
            print("Bad collection request for", p_collection_id)
        end
    end,

    -- onFailure function
    function(message)
        print("Failed collection content request OUTRIGHT for", p_collection_id)
        GUI.DisableSubmitButton()
    end)
end

--------------------------------------------------------------------------------
-- Find the metadata of a collection ID
--------------------------------------------------------------------------------
GUI.QueryCollectionMetadata = function(p_collection_id)
    local url = "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/?"
    local params = {} 
    params["itemcount"] = "1"
    params["publishedfileids[0]"] = tostring(p_collection_id)
    http.Post(url, params, 

    -- onSuccess function
    function(body, length, headers, code)
        if code == 200 then
            GUI.QueryCollectionContent(p_collection_id, util.JSONToTable(body))
        else
            GUI.DisableSubmitButton()
            print("Bad metadata request for", p_collection_id)
        end
    end,

    -- onFailure function
    function(message)
        print("Failed collection metadata request OUTRIGHT for", p_collection_id)
        GUI.DisableSubmitButton()
    end)
end


--------------------------------------------------------------------------------
-- Call both REST queries implicitly
--------------------------------------------------------------------------------
GUI.GetWorkshopInfo = function(p_collection_id)
    GUI.QueryCollectionMetadata(p_collection_id)
end

--------------------------------------------------------------------------------
-- Populate Table with IDs and names
--------------------------------------------------------------------------------
GUI.PopulateItemIDs = function(p_item_list)
    local url = "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/?"
    local params = {} 
    params["itemcount"] = tostring(#p_item_list)

    local i = 0
    for _,v in pairs(p_item_list) do
        params["publishedfileids["..tostring(i).."]"] = tostring(v)
        i = i + 1
    end
    http.Post(url, params, 

    -- onSuccess function
    function(body, length, headers, code)
        if code == 200 then
            data = util.JSONToTable(body)

            -- We have all id,name pairs, make them the new list
            GUI.Display:Clear()
            for _,v in pairs(data.response.publishedfiledetails) do
                GUI.Display:AddLine(v.publishedfileid, v.title or "***Deleted Item***")
            end
        else
            GUI.DisableSubmitButton()
            print("Bad metadata request for workshop item", p_item_id)
        end
    end,

    -- onFailure function
    function(message)
        print("Something went wrong while fetching workshop item names")    
    end)
end

--------------------------------------------------------------------------------
-- Enable Functionality
-- Populates just IDs, initially
--------------------------------------------------------------------------------
GUI.EnableSubmitButton = function(p_data)
    DATA_CACHE = p_data
    GUI.Submit:SetEnabled(true)
    -- -TODO- make green
    GUI.Submit:ColorTo(Color(50,50,200), 1, 0)
    GUI.DispLabel:SetEnabled(false)
    GUI.DispLabel:SetText(p_data.name)
    GUI.Display:SetEnabled(true)
    GUI.Display:Clear()
    for _,v in pairs(p_data.content) do
        GUI.Display:AddLine(v, "")
    end
    GUI.PopulateItemIDs(p_data.content)
end

--------------------------------------------------------------------------------
-- Disable Functionality
--------------------------------------------------------------------------------
GUI.DisableSubmitButton = function(p_visible_error)
    p_visible_error = p_visible_error or false
    GUI.Submit:SetEnabled(false)
    GUI.Submit:ColorTo(Color(255,255,255), 1, 0)
    GUI.Display:SetEnabled(false)
    GUI.DispLabel:SetEnabled(false)
    GUI.DispLabel:SetText("Collection")
    GUI.Display:Clear()
    if p_visible_error then
        Derma_Message("Supplied item is probably not a Garry's Mod Collection...", "Error")
    end
end

--------------------------------------------------------------------------------
-- Load Menu
--------------------------------------------------------------------------------
local function WorkshopCollectorMenu()
    -- Frame
    local frame_width = SCRW/4
    local frame_height = SCRH/4
    local frame_posx = SCRW/2 - frame_width/2
    local frame_posy = SCRH/2 - frame_height/2
    GUI.Frame = vgui.Create("DFrame")
    GUI.Frame:SetTitle("Workshop Collector v"..MENU_VERSION)
    GUI.Frame:SetSize(frame_width, frame_height)
    file.CreateDir("workshop_collector")
    file.Write("workshop_collector/is_running_menu_install.txt", text)
    GUI.Frame:SetPos(frame_posx, frame_posy)
    GUI.Frame:SetDraggable(true)
    GUI.Frame:ShowCloseButton(true)
    GUI.Frame:SetDeleteOnClose(false)
    GUI.Frame:MakePopup()

    -- Input
    GUI.EntryLabel = vgui.Create("DLabel", GUI.Frame)
    GUI.EntryLabel:SetPos(10, 30)
    GUI.EntryLabel:SetSize(frame_width - 20, 20)
    GUI.EntryLabel:SetText("Link or ID of a Workshop collection:")
    GUI.Entry = vgui.Create("DTextEntry", GUI.Frame)
    GUI.Entry:SetPos(10, 50)
    GUI.Entry:SetSize(frame_width - 20, 20)
    GUI.Entry:SetText(LAST_WORKSHOP)
    GUI.Query = vgui.Create("DButton", GUI.Frame)
    GUI.Query:SetPos(10, 70)
    GUI.Query:SetSize((frame_width - 20)/2, 20)
    GUI.Query:SetText("Select Collection")

    file.CreateDir("workshop_collector")
    file.Write("workshop_collector/is_running_menu_install.txt", text)
    GUI.Submit = vgui.Create("DButton", GUI.Frame)
    GUI.Submit:SetPos(frame_width/2, 70)
    GUI.Submit:SetSize((frame_width - 20)/2, 20)
    GUI.Submit:SetText("Create Preset")
    GUI.Submit:SetEnabled(false)

    -- Display
    GUI.DispLabel = vgui.Create("DLabel", GUI.Frame)
    GUI.DispLabel:SetPos(10, 90)
    GUI.DispLabel:SetSize(frame_width - 20, 20)
    GUI.DispLabel:SetText("Collection")
    GUI.DispLabel:SetEnabled(false)
    GUI.Display = vgui.Create("DListView", GUI.Frame)
    GUI.Display:SetPos(10, 110)
    GUI.Display:SetSize(frame_width - 20, (frame_height - 120))
    GUI.Display:SetMultiSelect(false)
    GUI.Display:AddColumn("ID"):SetMaxWidth(100)
    GUI.Display:AddColumn("Name")
    GUI.Display:SetEnabled(false)

    -- If URL/ID is present, auto-populate
    local onload_id = GUI.GetWorkshopID(GUI.Entry:GetText())
    if onload_id then
        GUI.GetWorkshopInfo(onload_id)
    end

    -- Select Collection
    GUI.Query.DoClick = function()
        -- Get ID or exit
        local id = GUI.GetWorkshopID(GUI.Entry:GetText())
        if not id then
            GUI.DisableSubmitButton()
            Derma_Message("Please supply a valid workshop collection URL or ID", "Error")
            return
        end
        GUI.DisableSubmitButton()
        GUI.GetWorkshopInfo(id)
    end
    
    -- Submit Collection
    GUI.Submit.DoClick = function()
        local preset_name = DATA_CACHE.name.." ("..DATA_CACHE.id..")"
        local preset_json = LoadAddonPresets()
        local presets = {} -- In case the user has no presets
        if preset_json then
            presets = util.JSONToTable(preset_json)
        end
        presets[preset_name] = {}
        
        target_preset = presets[preset_name]
        target_preset.disabled = {}
        target_preset.enabled = DATA_CACHE.content
        target_preset.name = preset_name
        target_preset.newAction = ""
        
        SaveAddonPresets(util.TableToJSON(presets))
        surface.PlaySound("ui/chat_display_text.wav")
        Derma_Message("Preset \""..preset_name.."\" created! \n\nYour game must be restarted for this to take effect.")
    end

    -- View workshop item
    function GUI.Display:DoDoubleClick(lineID, line)
        local workshop_id = line:GetColumnText(1)
        gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/?id="..workshop_id)
    end
end

concommand.Add("workshop_collector_menu", WorkshopCollectorMenu)
