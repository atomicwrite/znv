const std = @import("std");
const EnvPair = @import("env-pair.zig").EnvPair;
const EnvKey = @import("env-key.zig").EnvKey;
const EnvValue = @import("env-value.zig").EnvValue;


pub const EnvGroup = struct {
    const Self = @This();
    pairs:[]EnvPair = undefined,
    keys:[]EnvKey = undefined,
    values:[]EnvValue = undefined,
    groupIndex : u8 = 0,
    allocator:*std.mem.Allocator = undefined,
    pub fn init(self:*EnvGroup, allocator :*std.mem.Allocator) void {
    self.allocator = allocator;
    self.groupIndex= 0;
    }
};

