--[[ 
    EC Admin Ultimate - Secure Path Validator
    Prevents directory traversal and shell injection attacks
    Author: NRG Development
    Version: 1.0.0
]]--

local PathValidator = {}

-- Get the base resource path (our safe zone)
local BASE_PATH = GetResourcePath(GetCurrentResourceName())

-- Dangerous characters that could be used for shell injection
local DANGEROUS_CHARS = {
    '`',     -- Command substitution
    '$',     -- Variable expansion
    ';',     -- Command separator
    '|',     -- Pipe
    '&',     -- Background/AND
    '>',     -- Redirect
    '<',     -- Redirect
    '\n',    -- Newline
    '\r',    -- Carriage return
    '\\x00', -- Null byte
}

-- Dangerous patterns
local DANGEROUS_PATTERNS = {
    '%.%.',          -- Directory traversal (..)
    '%$%(',          -- Command substitution $()
    '%${',           -- Variable expansion ${}
    '~',             -- Home directory expansion
    '^[A-Z]:',       -- Windows drive letter (C:, D:, etc.)
    '^/',            -- Absolute path (Unix)
    '^\\\\',         -- UNC path (Windows)
}

---@param path string The path to validate
---@return boolean valid Whether the path is safe
---@return string|nil error Error message if invalid
function PathValidator.IsPathSafe(path)
    if not path or type(path) ~= 'string' then
        return false, 'Path must be a non-empty string'
    end
    
    -- Check for empty path
    if #path == 0 then
        return false, 'Path cannot be empty'
    end
    
    -- Check for dangerous characters
    for _, char in ipairs(DANGEROUS_CHARS) do
        if string.find(path, char, 1, true) then
            return false, string.format('Path contains forbidden character: %s', char)
        end
    end
    
    -- Check for dangerous patterns
    for _, pattern in ipairs(DANGEROUS_PATTERNS) do
        if string.find(path, pattern) then
            return false, string.format('Path contains forbidden pattern: %s', pattern)
        end
    end
    
    -- Check for quotes (shell injection risk)
    if string.find(path, '"') or string.find(path, "'") or string.find(path, '\\') then
        return false, 'Path contains quotes or backslashes'
    end
    
    return true, nil
end

---@param path string The path to validate
---@return boolean valid Whether the path is within the resource
---@return string|nil error Error message if invalid
function PathValidator.IsWithinResource(path)
    -- First check if path is safe
    local safe, err = PathValidator.IsPathSafe(path)
    if not safe then
        return false, err
    end
    
    -- Normalize both paths for comparison
    local normalizedPath = string.lower(path):gsub('\\', '/')
    local normalizedBase = string.lower(BASE_PATH):gsub('\\', '/')
    
    -- Check if the path starts with our base path
    if not string.find(normalizedPath, normalizedBase, 1, true) then
        return false, 'Path is outside resource directory'
    end
    
    return true, nil
end

---@param filename string The filename to validate
---@return boolean valid Whether the filename is safe
---@return string|nil error Error message if invalid
function PathValidator.IsFilenameSafe(filename)
    if not filename or type(filename) ~= 'string' then
        return false, 'Filename must be a non-empty string'
    end
    
    -- Check for path separators (shouldn't be in filename)
    if string.find(filename, '/') or string.find(filename, '\\') then
        return false, 'Filename cannot contain path separators'
    end
    
    -- Check for dangerous characters
    for _, char in ipairs(DANGEROUS_CHARS) do
        if string.find(filename, char, 1, true) then
            return false, string.format('Filename contains forbidden character: %s', char)
        end
    end
    
    -- Check for null bytes and control characters
    for i = 1, #filename do
        local byte = string.byte(filename, i)
        if byte < 32 or byte == 127 then
            return false, 'Filename contains control characters'
        end
    end
    
    return true, nil
end

---@param path string The path to sanitize
---@return string sanitized The sanitized path (safe for logging)
function PathValidator.SanitizeForLog(path)
    if not path then return '[nil]' end
    
    -- Replace potentially sensitive parts
    local sanitized = path:gsub(BASE_PATH, '[RESOURCE]')
    
    -- Remove any remaining absolute paths
    sanitized = sanitized:gsub('^[A-Z]:', '[DRIVE]')
    sanitized = sanitized:gsub('^/', '[ROOT]')
    
    return sanitized
end

---@param dir string The directory path to validate
---@return boolean valid Whether it's safe to create/delete
---@return string|nil error Error message if invalid
function PathValidator.CanModifyDirectory(dir)
    -- Check basic safety
    local safe, err = PathValidator.IsWithinResource(dir)
    if not safe then
        return false, err
    end
    
    -- Additional checks for directory operations
    local relativePath = dir:gsub(BASE_PATH, '')
    
    -- Prevent modification of critical directories
    local protectedDirs = {
        '/server/',
        '/client/',
        '/config/',
        '/fxmanifest.lua',
        '/config.lua',
    }
    
    for _, protected in ipairs(protectedDirs) do
        if string.find(relativePath, protected, 1, true) then
            return false, 'Cannot modify protected directory: ' .. protected
        end
    end
    
    return true, nil
end

---@param path string The path to build safely
---@param ... string Additional path components
---@return string|nil path The safe path, or nil if validation failed
---@return string|nil error Error message if failed
function PathValidator.BuildSafePath(basePath, ...)
    local components = {...}
    
    -- Validate base path
    local safe, err = PathValidator.IsWithinResource(basePath)
    if not safe then
        return nil, err
    end
    
    -- Build path by validating each component
    local fullPath = basePath
    
    for _, component in ipairs(components) do
        -- Validate component
        local componentSafe, componentErr = PathValidator.IsFilenameSafe(component)
        if not componentSafe then
            return nil, componentErr
        end
        
        -- Append to path
        fullPath = fullPath .. '/' .. component
    end
    
    -- Final validation
    safe, err = PathValidator.IsWithinResource(fullPath)
    if not safe then
        return nil, err
    end
    
    return fullPath, nil
end

-- Export the validator
_G.PathValidator = PathValidator

Logger.Info('🔒 Secure path validator loaded')

return PathValidator
