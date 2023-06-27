const std = @import("std");
const EnvValue = @import("env-value.zig").EnvValue;
const EnvKey = @import("env-key.zig").EnvKey;
const nextKey = @import("env-reader.zig").nextKey;
const nextValue = @import("env-reader.zig").nextValue;
const EnvPair = @import("env-pair.zig").EnvPair;
const InterpolationHelper = @import("interpolation-helper.zig");
const EnvGroup = @import("env-group.zig").EnvGroup;
const freePairs = @import("env-reader.zig").freePairs;
const preInitPairs = @import("env-reader.zig").preInitPairs;
const nextPair = @import("env-reader.zig").nextPair;
const free_interpolation_array = InterpolationHelper.free_interpolation_array;
const interpolate_value = InterpolationHelper.interpolate_value;
const testing = std.testing;


test "Read a single quoted heredoc that has interpolation in it" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();
    var group: EnvGroup = EnvGroup{};
    group.init(&allocator);
    var buffer = try allocator.alloc(u8, 100);
    defer allocator.free(buffer);

    try preInitPairs(&group, 1, buffer);
    defer freePairs(&group);

    const file =
        try std.fs.cwd().openFile("test-files/sample-interpolated-single-quote-heredoc.env", .{});
    const reader = file.reader();
    defer file.close();
    try nextPair(reader, &group.pairs[0]);
    var firstOne = group.values[0];
    try interpolate_value(&firstOne, group.pairs);
    std.debug.print("Output:  {s}={s} \n", .{ group.pairs[0].key.key, group.pairs[0].value.value });
    try std.testing.expect(std.mem.eql(u8, group.pairs[0].value.value[0..7], "${beta}"));
}