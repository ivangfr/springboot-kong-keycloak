local user_info = kong.request.get_header("X-Userinfo")

local username = "unknown"
local preferred_username = "unknown"
if user_info then
    user_info_dec = ngx.decode_base64(user_info)
    username = string.match(user_info_dec, "\"username\":\"(.-)\"")
    preferred_username = string.match(user_info_dec, "\"preferred_username\":\"(.-)\"")
end

kong.service.request.add_header("X-Username", username)
kong.service.request.add_header("X-Preferred-Username", preferred_username)
