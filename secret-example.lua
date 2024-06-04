--  secret config for away
--  rename this example to secret.lua
--
--  Copyright (c) 2024 shmilee
--

local S = {}

-- OPANAI ChatGPT
S.OPANAI_API_KEY = {
    --'sk-key1',
    --'sk-key2',
}
S.OPENAI_BASE_URL = 'https://api.openai.com'

-- ChatAnywhere CA. key, arg setting
S.CA_API_USAGE = {
    --{
    --    key='sk-key1', -- required
    --    -- icon for wibox and notification, need theme['gpt_icon4'], etc.
    --    icon1='gpt_icon4', icon2='ca_icon1',  -- optional
    --    model='gpt-%',  -- default, '%'
    --    txt='count',  -- count: today.count
    --                  -- perc: balance.perc
    --                  -- default, used: balance.used
    --},
    --{
    --    key='sk-key2',
    --    icon1='gpt_icon2', icon2='gpt_icon1',
    --    model='%', txt='perc',
    --},
}

-- Weather yiketianqi
S.yiketianqi_query = nil  --{unescape=1, version='v9', appid=?, appsecret='?'}

-- article api
S.mryw_api = nil

return S
