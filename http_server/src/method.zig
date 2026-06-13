const std = @import("std");
const Map = std.StaticStringMap;

const map = Map(Method);
const MethodMap = map.initComptime(.{.{ "GET", Method.GET }});

pub const Method = enum {
    GET,
    PUT,
    POST,
    PATCH,
    DELETE,
    OPTIONS,

    pub fn init(text: []const u8) !Method {
        return MethodMap.get(text).?;
    }

    pub fn is_supported(text: []const u8) bool {
        const method = MethodMap.get(text);
        if (method) |_| {
            return true;
        }
        return false;
    }
};
