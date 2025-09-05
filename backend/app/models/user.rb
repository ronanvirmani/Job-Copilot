class User < ApplicationRecord
    encrypts :google_access_token
    encrypts :google_refresh_token
end
