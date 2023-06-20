const EnvGroup = @import("env-group.zig").EnvGroup;
const freePairs = @import("env-reader.zig").freePairs;
const preInitPairs = @import("env-reader.zig").preInitPairs;
const std = @import("std");
const EnvPair = @import("env-pair.zig").EnvPair;
test "init pairs test" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator();
    var group: EnvGroup = EnvGroup{};
    group.init(allocator);
    try preInitPairs(&group, 10);
    errdefer freePairs(&group);
}
