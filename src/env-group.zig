const std = @import("std");
const EnvPair = @import("env-pair.zig").EnvPair;
const EnvKey = @import("env-key.zig").EnvKey;
const EnvValue = @import("env-value.zig").EnvValue;


pub const EnvGroup = struct {
    pairs:[]EnvPair = undefined,
    keys:[]EnvKey = undefined,
    values:[]EnvValue = undefined,

    len:u32 = 0,
    groupIndex : u32 = 0,
    allocator:*std.mem.Allocator = undefined,
    pub fn init(self:*EnvGroup, allocator :*std.mem.Allocator) void {
        self.allocator = allocator;
        self.groupIndex= 0;
    }

};

pub fn freeGroup(self: *EnvGroup) void {
    self.allocator.free(self.keys);
    self.allocator.free(self.values);
    self.allocator.free(self.pairs);
}
