-- lua/blink_sources/firebase_rules.lua
-- Comprehensive Firebase Security Rules completions for blink.cmp
-- Based on official Firebase specification and documentation

--- @class blink.cmp.FirebaseRulesSource : blink.cmp.Source
local firebase_rules = {}

-- ---------- Utility Functions ----------
local function get_before_cursor()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  return line:sub(1, col), line
end

local function last_word(s)
  local w = s:match("([A-Za-z_][A-Za-z0-9_]*)%s*$")
  return w or ""
end

local function get_chain_before_cursor()
  local before = get_before_cursor()
  -- Grab the token chain like foo.bar.baz.
  local chain = before:match("([A-Za-z0-9_%.]+)%s*$") or ""
  if not chain:find("%.") then return nil end
  
  -- Clean up trailing non-identifier chars
  chain = chain:gsub("[^A-Za-z0-9_%.]+$", "")
  
  -- Split on dots
  local parts = {}
  for seg in chain:gmatch("[A-Za-z_][A-Za-z0-9_]*") do
    table.insert(parts, seg)
  end
  if #parts == 0 then return nil end
  return parts
end

local function starts_with(s, pref) 
  return pref == "" or s:sub(1, #pref) == pref 
end

local function mk(item)
  return {
    label = item.label,
    insertText = item.insertText or item.label,
    kind = item.kind or vim.lsp.protocol.CompletionItemKind.Field,
    documentation = item.documentation,
    detail = item.detail,
  }
end

local function mk_fn(label, snippet, doc, detail)
  return {
    label = label,
    insertText = snippet or (label .. "($0)"),
    kind = vim.lsp.protocol.CompletionItemKind.Function,
    documentation = doc,
    detail = detail or "function",
    insertTextFormat = 2, -- snippet
  }
end

local function mk_method(label, doc)
  return {
    label = label,
    insertText = label,
    kind = vim.lsp.protocol.CompletionItemKind.Method,
    documentation = doc,
    detail = "method",
  }
end

local function mk_keyword(label, doc)
  return {
    label = label,
    insertText = label,
    kind = vim.lsp.protocol.CompletionItemKind.Keyword,
    documentation = doc,
    detail = "keyword",
  }
end

local function mk_type(label, doc)
  return {
    label = label,
    insertText = label,
    kind = vim.lsp.protocol.CompletionItemKind.Class,
    documentation = doc,
    detail = "type",
  }
end

-- ---------- Domain Knowledge ----------

-- Firebase Security Rules keywords
local KEYWORDS = {
  "rules_version",
  "service", 
  "match",
  "function",
  "allow",
  "return",
  "if", 
  "let",
  "is",
  "in",
}

-- Firebase service names
local SERVICES = {
  "cloud.firestore",
  "firebase.storage",
}

-- Firebase operation methods
local METHODS = {
  "read", "write", "get", "list", "create", "update", "delete"
}

-- Firebase primitive types
local TYPES = {
  "null", "bool", "int", "float", "number", "string", 
  "list", "map", "set", "timestamp", "duration", "path", "latlng"
}

-- Complete scope-aware completions
local SCOPE = {
  -- request object (universal)
  request = {
    mk({ label = "auth", documentation = "Authentication information (or null if unauthenticated)" }),
    mk({ label = "method", documentation = "The method being executed (get, list, create, update, delete)" }),
    mk({ label = "path", documentation = "The relative path of the target document/object" }),
    mk({ label = "time", documentation = "Server timestamp when request is evaluated" }),
    mk({ label = "params", documentation = "Map of additional parameters (usually empty)" }),
    mk({ label = "resource", documentation = "Future state after write operations (create/update)" }),
    mk({ label = "query", documentation = "Query parameters for list operations (Firestore)" }),
  },

  -- request.auth
  ["request.auth"] = {
    mk({ label = "uid", documentation = "User's unique identifier" }),
    mk({ label = "token", documentation = "Firebase Auth token containing claims" }),
  },

  -- request.auth.token (standard claims)
  ["request.auth.token"] = {
    mk({ label = "email", documentation = "User's email address" }),
    mk({ label = "email_verified", documentation = "Email verification status" }),
    mk({ label = "phone_number", documentation = "User's phone number" }),
    mk({ label = "name", documentation = "User's display name" }),
    mk({ label = "picture", documentation = "User's profile picture URL" }),
    mk({ label = "sub", documentation = "Subject (same as uid)" }),
    mk({ label = "firebase", documentation = "Firebase-specific claims" }),
    mk({ label = "admin", documentation = "Custom admin claim (if set)" }),
    mk({ label = "roles", documentation = "Custom roles claim (if set)" }),
    mk({ label = "tenant", documentation = "Multi-tenant identifier" }),
    mk({ label = "auth_time", documentation = "Authentication timestamp" }),
  },

  -- request.auth.token.firebase
  ["request.auth.token.firebase"] = {
    mk({ label = "identities", documentation = "Map of providers to arrays of identifiers" }),
    mk({ label = "sign_in_provider", documentation = "Authentication provider used" }),
    mk({ label = "tenant", documentation = "Multi-tenant identifier" }),
  },

  -- request.path methods
  ["request.path"] = {
    mk_fn("segments", "segments()$0", "Returns list of path segments", "List<String>"),
  },

  -- request.time methods (timestamp)
  ["request.time"] = {
    mk_fn("toMillis", "toMillis()$0", "Convert to epoch milliseconds", "Integer"),
    mk_fn("date", "date()$0", "Get date portion (time set to 00:00:00)", "Timestamp"),
    mk_fn("time", "time()$0", "Get time of day as duration", "Duration"),
    mk_fn("year", "year()$0", "Get year (1-9999)", "Integer"),
    mk_fn("month", "month()$0", "Get month (1-12)", "Integer"),
    mk_fn("day", "day()$0", "Get day of month (1-31)", "Integer"),
    mk_fn("hours", "hours()$0", "Get hours (0-23)", "Integer"),
    mk_fn("minutes", "minutes()$0", "Get minutes (0-59)", "Integer"),
    mk_fn("seconds", "seconds()$0", "Get seconds (0-59)", "Integer"),
    mk_fn("nanos", "nanos()$0", "Get nanoseconds", "Integer"),
    mk_fn("dayOfWeek", "dayOfWeek()$0", "Day of week (1=Monday to 7=Sunday)", "Integer"),
    mk_fn("dayOfYear", "dayOfYear()$0", "Day of year (1-366)", "Integer"),
  },

  -- resource object (Firestore)
  resource = {
    mk({ label = "id", documentation = "Document ID" }),
    mk({ label = "data", documentation = "Map of the existing document's fields and values" }),
    mk({ label = "__name__", documentation = "Full document path" }),
  },

  -- resource.data (map methods)
  ["resource.data"] = {
    mk_fn("keys", "keys()$0", "Get list of all keys", "List<String>"),
    mk_fn("values", "values()$0", "Get list of all values", "List"),
    mk_fn("size", "size()$0", "Number of key-value pairs", "Integer"),
    mk_fn("get", "get(${1:key}, ${2:default})$0", "Get value with default fallback", "Any"),
    mk_fn("diff", "diff(${1:other})$0", "Compare two maps for differences", "MapDiff"),
  },

  -- request.resource (write operations)
  ["request.resource"] = {
    mk({ label = "data", documentation = "Map containing fields and values of pending document" }),
    mk({ label = "id", documentation = "Document ID for the pending write" }),
  },

  ["request.resource.data"] = {
    mk_fn("keys", "keys()$0", "Get list of all keys", "List<String>"),
    mk_fn("values", "values()$0", "Get list of all values", "List"),
    mk_fn("size", "size()$0", "Number of key-value pairs", "Integer"),
    mk_fn("get", "get(${1:key}, ${2:default})$0", "Get value with default fallback", "Any"),
    mk_fn("diff", "diff(${1:other})$0", "Compare two maps for differences", "MapDiff"),
  },

  -- Built-in namespaces
  math = {
    mk_fn("abs", "abs(${1:num})$0", "Absolute value", "Number"),
    mk_fn("ceil", "ceil(${1:num})$0", "Ceiling function", "Integer"),
    mk_fn("floor", "floor(${1:num})$0", "Floor function", "Integer"),
    mk_fn("round", "round(${1:num})$0", "Round to nearest integer", "Integer"),
    mk_fn("pow", "pow(${1:base}, ${2:exp})$0", "Exponentiation", "Float"),
    mk_fn("sqrt", "sqrt(${1:num})$0", "Square root", "Float"),
    mk_fn("isInfinite", "isInfinite(${1:num})$0", "Tests for ±∞", "Boolean"),
    mk_fn("isNaN", "isNaN(${1:num})$0", "Tests for NaN", "Boolean"),
  },

  hashing = {
    mk_fn("md5", "md5(${1:input})$0", "MD5 hash", "Bytes"),
    mk_fn("sha256", "sha256(${1:input})$0", "SHA-256 hash", "Bytes"),
    mk_fn("crc32", "crc32(${1:input})$0", "CRC32 hash", "Bytes"),
    mk_fn("crc32c", "crc32c(${1:input})$0", "CRC32C hash", "Bytes"),
  },

  latlng = {
    mk_fn("value", "value(${1:lat}, ${2:lng})$0", "Create LatLng from coordinates", "LatLng"),
  },

  duration = {
    mk_fn("value", "value(${1:magnitude}, ${2:unit})$0", "Create duration (units: w,d,h,m,s,ms,ns)", "Duration"),
    mk_fn("time", "time(${1:hours}, ${2:minutes}, ${3:seconds}, ${4:nanos})$0", "Create duration from time components", "Duration"),
  },

  timestamp = {
    mk_fn("value", "value(${1:epochMillis})$0", "Create timestamp from epoch milliseconds", "Timestamp"),
    mk_fn("date", "date(${1:year}, ${2:month}, ${3:day})$0", "Create timestamp from date components", "Timestamp"),
  },

  firestore = {
    mk_fn("get", "get(${1:/databases/(default)/documents/...})$0", "Cross-service Firestore read (Storage rules)", "DocumentSnapshot"),
    mk_fn("exists", "exists(${1:/databases/(default)/documents/...})$0", "Cross-service existence check", "Boolean"),
  },

  -- Top-level global functions
  [""] = {
    mk_fn("get", "get(${1:/databases/\\$(database)/documents/...})$0", "Fetch Firestore document", "DocumentSnapshot"),
    mk_fn("exists", "exists(${1:/databases/\\$(database)/documents/...})$0", "Document existence check", "Boolean"),
    mk_fn("getAfter", "getAfter(${1:/databases/...})$0", "Future doc state in batch/transaction", "DocumentSnapshot"),
    mk_fn("existsAfter", "existsAfter(${1:/databases/...})$0", "Future existence check", "Boolean"),
    mk_fn("debug", "debug(${1:value})$0", "Emulator-only logging, returns value", "Any"),
  },
}

-- Add String methods dynamically
local string_methods = {
  mk_fn("matches", "matches(${1:regex})$0", "Regular expression matching (RE2 syntax)", "Boolean"),
  mk_fn("split", "split(${1:regex})$0", "Split string by regex", "List<String>"),
  mk_fn("replace", "replace(${1:substring}, ${2:replacement})$0", "Replace all instances", "String"),
  mk_fn("lower", "lower()$0", "Convert to lowercase", "String"),
  mk_fn("upper", "upper()$0", "Convert to uppercase", "String"),
  mk_fn("size", "size()$0", "String length", "Integer"),
  mk_fn("contains", "contains(${1:substring})$0", "Contains substring check", "Boolean"),
  mk_fn("startsWith", "startsWith(${1:prefix})$0", "Starts with prefix check", "Boolean"),
  mk_fn("endsWith", "endsWith(${1:suffix})$0", "Ends with suffix check", "Boolean"),
  mk_fn("toUtf8", "toUtf8()$0", "Convert string to UTF-8 bytes", "Bytes"),
}

-- Add List methods dynamically
local list_methods = {
  mk_fn("hasAll", "hasAll(${1:items})$0", "Check if list contains all specified items", "Boolean"),
  mk_fn("hasAny", "hasAny(${1:items})$0", "Check if list contains any of the items", "Boolean"),
  mk_fn("hasOnly", "hasOnly(${1:items})$0", "Check if list contains only the items", "Boolean"),
  mk_fn("size", "size()$0", "Get list length", "Integer"),
  mk_fn("join", "join(${1:separator})$0", "Join list elements into string", "String"),
  mk_fn("toSet", "toSet()$0", "Convert list to set (removes duplicates)", "Set"),
  mk_fn("removeAll", "removeAll(${1:items})$0", "Remove all specified items (v2)", "List"),
}

-- Add Set methods dynamically  
local set_methods = {
  mk_fn("hasAll", "hasAll(${1:items})$0", "Check if set contains all items", "Boolean"),
  mk_fn("hasAny", "hasAny(${1:items})$0", "Check if set contains any items", "Boolean"),
  mk_fn("hasOnly", "hasOnly(${1:items})$0", "Check if set contains only specified items", "Boolean"),
  mk_fn("size", "size()$0", "Get set size", "Integer"),
  mk_fn("union", "union(${1:other})$0", "Set union operation", "Set"),
  mk_fn("intersection", "intersection(${1:other})$0", "Set intersection", "Set"),
  mk_fn("difference", "difference(${1:other})$0", "Set difference", "Set"),
}

-- Add Map methods dynamically
local map_methods = {
  mk_fn("keys", "keys()$0", "Get list of all keys", "List<String>"),
  mk_fn("values", "values()$0", "Get list of all values", "List"),
  mk_fn("size", "size()$0", "Number of key-value pairs", "Integer"),
  mk_fn("get", "get(${1:key}, ${2:default})$0", "Get value with default fallback", "Any"),
  mk_fn("diff", "diff(${1:other})$0", "Compare two maps for differences", "MapDiff"),
}

-- Add LatLng methods
local latlng_methods = {
  mk_fn("latitude", "latitude()$0", "Get latitude component", "Float"),
  mk_fn("longitude", "longitude()$0", "Get longitude component", "Float"),
  mk_fn("distance", "distance(${1:other})$0", "Calculate distance between points (meters)", "Float"),
}

-- Add Timestamp methods
local timestamp_methods = {
  mk_fn("toMillis", "toMillis()$0", "Convert to epoch milliseconds", "Integer"),
  mk_fn("date", "date()$0", "Get date portion (time set to 00:00:00)", "Timestamp"),
  mk_fn("time", "time()$0", "Get time of day as duration", "Duration"),
  mk_fn("year", "year()$0", "Get year (1-9999)", "Integer"),
  mk_fn("month", "month()$0", "Get month (1-12)", "Integer"),
  mk_fn("day", "day()$0", "Get day of month (1-31)", "Integer"),
  mk_fn("hours", "hours()$0", "Get hours (0-23)", "Integer"),
  mk_fn("minutes", "minutes()$0", "Get minutes (0-59)", "Integer"),
  mk_fn("seconds", "seconds()$0", "Get seconds (0-59)", "Integer"),
  mk_fn("nanos", "nanos()$0", "Get nanoseconds", "Integer"),
  mk_fn("dayOfWeek", "dayOfWeek()$0", "Day of week (1=Monday to 7=Sunday)", "Integer"),
  mk_fn("dayOfYear", "dayOfYear()$0", "Day of year (1-366)", "Integer"),
}

-- Add Duration methods
local duration_methods = {
  mk_fn("seconds", "seconds()$0", "Get total seconds in duration", "Integer"),
  mk_fn("nanos", "nanos()$0", "Get nanoseconds component", "Integer"),
}

-- MapDiff methods (v2)
local mapdiff_methods = {
  mk_fn("addedKeys", "addedKeys()$0", "Keys that were added", "Set<String>"),
  mk_fn("removedKeys", "removedKeys()$0", "Keys that were removed", "Set<String>"),
  mk_fn("changedKeys", "changedKeys()$0", "Keys that were modified", "Set<String>"),
  mk_fn("affectedKeys", "affectedKeys()$0", "All keys that changed", "Set<String>"),
  mk_fn("unchangedKeys", "unchangedKeys()$0", "Keys that remained the same", "Set<String>"),
}

-- ---------- Context-Aware Logic ----------

local function want_keywords()
  local before = get_before_cursor()
  -- Don't show keywords if we are in a member access
  if before:match("%.%s*[A-Za-z_]*$") then return false end
  
  -- Show keywords near start of line or after '{' or ';'
  if before:match("^%s*$") or before:match("[{;]%s*$") then return true end
  
  -- Also after certain keywords
  if before:match("%f[%w]allow%s+$") or 
     before:match("%f[%w]service%s+$") or 
     before:match("%f[%w]match%s+$") or
     before:match("%f[%w]function%s+$") then
    return true
  end
  return false
end

local function keyword_items(prefix)
  local items = {}
  local before = get_before_cursor()
  
  -- Context-specific completions
  if before:match("%f[%w]allow%s+$") then
    -- After "allow " - suggest methods
    for _, m in ipairs(METHODS) do
      if starts_with(m, prefix) then
        local doc = ""
        if m == "read" then doc = "Equivalent to get or list"
        elseif m == "write" then doc = "Equivalent to create, update, and delete"
        elseif m == "get" then doc = "Single document reads only"
        elseif m == "list" then doc = "Collection queries only"
        elseif m == "create" then doc = "New document writes only"
        elseif m == "update" then doc = "Existing document modifications only"
        elseif m == "delete" then doc = "Document deletions only"
        end
        table.insert(items, mk_method(m, doc))
      end
    end
    return items
  end
  
  if before:match("%f[%w]service%s+$") then
    -- After "service " - suggest service names
    for _, s in ipairs(SERVICES) do
      if starts_with(s, prefix) then
        table.insert(items, mk_keyword(s, "Firebase service declaration"))
      end
    end
    return items
  end
  
  if before:match("%f[%w]match%s+$") then
    -- After "match " - suggest path patterns
    table.insert(items, mk({
      label = "/databases/{database}/documents",
      insertText = "/databases/{${1:database}}/documents {\\n  $0\\n}",
      kind = vim.lsp.protocol.CompletionItemKind.Snippet,
      documentation = "Firestore match block template",
      insertTextFormat = 2,
    }))
    table.insert(items, mk({
      label = "/b/{bucket}/o",
      insertText = "/b/{${1:bucket}}/o {\\n  $0\\n}",
      kind = vim.lsp.protocol.CompletionItemKind.Snippet, 
      documentation = "Storage match block template",
      insertTextFormat = 2,
    }))
    return items
  end
  
  if before:match("%f[%w]rules_version%s*=%s*$") then
    -- After "rules_version =" - suggest version strings
    table.insert(items, mk({ label = "'2'", insertText = "'2'", documentation = "Rules version 2 (recommended)" }))
    table.insert(items, mk({ label = "'1'", insertText = "'1'", documentation = "Rules version 1 (legacy)" }))
    return items
  end
  
  -- General keywords
  for _, k in ipairs(KEYWORDS) do
    if starts_with(k, prefix) then
      local doc = ""
      if k == "rules_version" then doc = "Specify rules language version"
      elseif k == "service" then doc = "Declare target Firebase service"
      elseif k == "match" then doc = "Define path pattern for rules"
      elseif k == "function" then doc = "Define custom function"
      elseif k == "allow" then doc = "Define operation permissions"
      elseif k == "return" then doc = "Return expression from function"
      elseif k == "if" then doc = "Conditional expression"
      elseif k == "let" then doc = "Local variable binding (v2)"
      elseif k == "is" then doc = "Type checking operator"
      elseif k == "in" then doc = "Membership test operator"
      end
      table.insert(items, mk_keyword(k, doc))
    end
  end
  
  -- Types
  for _, t in ipairs(TYPES) do
    if starts_with(t, prefix) then
      table.insert(items, mk_type(t, "Firebase Rules type"))
    end
  end
  
  return items
end

local function get_type_methods(base_type)
  if base_type == "string" then return string_methods
  elseif base_type == "list" then return list_methods
  elseif base_type == "set" then return set_methods
  elseif base_type == "map" then return map_methods
  elseif base_type == "latlng" then return latlng_methods
  elseif base_type == "timestamp" then return timestamp_methods
  elseif base_type == "duration" then return duration_methods
  elseif base_type == "map_diff" then return mapdiff_methods
  end
  return {}
end

local function chain_items(chain, prefix)
  local key = table.concat(chain, ".")
  local items = {}
  
  -- Try exact scope match first
  local try = key
  while try do
    local scoped = SCOPE[try]
    if scoped then
      for _, it in ipairs(scoped) do
        if starts_with(it.label, prefix) then 
          table.insert(items, mk(it)) 
        end
      end
      if #items > 0 then return items end
    end
    local dot = try:match("^(.*)%.")
    try = dot
  end
  
  -- Try type-based methods for common patterns
  local head = chain[1]
  if head and #chain >= 2 then
    local second = chain[2]
    -- Handle cases like resource.data.fieldName.method() where fieldName is a string/list/etc
    if (head == "resource" or head == "request") and second == "data" and #chain > 2 then
      -- Could be any type - provide common methods
      for _, methods in pairs({string_methods, list_methods, map_methods}) do
        for _, method in ipairs(methods) do
          if starts_with(method.label, prefix) then
            table.insert(items, mk(method))
          end
        end
      end
    end
  end
  
  -- Fallback to namespace
  if SCOPE[head] then
    for _, it in ipairs(SCOPE[head]) do
      if starts_with(it.label, prefix) then 
        table.insert(items, mk(it)) 
      end
    end
  end
  
  return items
end

-- ---------- Main blink.cmp Source Implementation ----------

function firebase_rules.new(opts)
  local self = setmetatable({}, { __index = firebase_rules })
  self.opts = opts or {}
  return self
end

function firebase_rules:enabled()
  local ft = vim.bo.filetype
  return ft == "firebase_security_rules" or ft == "firebase"
end

function firebase_rules:get_completions(context, callback)
  local items = {}
  local before = get_before_cursor()
  local prefix = last_word(before)
  
  local chain = get_chain_before_cursor()
  if chain then
    -- Inside member access: suggest from scope
    items = chain_items(chain, prefix)
  else
    -- Not in member access: context-aware suggestions
    if want_keywords() then
      items = keyword_items(prefix)
    else
      -- Show global functions filtered by prefix
      for _, it in ipairs(SCOPE[""] or {}) do
        if starts_with(it.label, prefix) then 
          table.insert(items, mk(it)) 
        end
      end
      
      -- Also show common top-level scopes
      local scopes = {"request", "resource", "math", "hashing", "latlng", "duration", "timestamp", "firestore"}
      for _, scope in ipairs(scopes) do
        if starts_with(scope, prefix) then
          local doc = ""
          if scope == "request" then doc = "Request context object"
          elseif scope == "resource" then doc = "Resource context object"
          elseif scope == "math" then doc = "Mathematical functions"
          elseif scope == "hashing" then doc = "Cryptographic hash functions"
          elseif scope == "firestore" then doc = "Cross-service Firestore functions"
          end
          table.insert(items, mk({ label = scope, documentation = doc }))
        end
      end
    end
  end
  
  callback({
    is_incomplete_forward = false,
    is_incomplete_backward = false,
    items = items
  })
end

function firebase_rules:get_trigger_characters()
  return { ".", "_" }
end

return firebase_rules