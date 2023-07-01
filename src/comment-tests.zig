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

test "read two pairs and interpolate one" {
    const file =
        try std.fs.cwd().openFile("test-files/sample-interpolated.env", .{});
    defer file.close();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();
    var group: EnvGroup = EnvGroup{};
    group.init(&allocator);
    var buffer = try allocator.alloc(u8, 100);
    defer allocator.free(buffer);

    try preInitPairs(&group, 2, buffer);
    defer freePairs(&group);

    try nextPair(file.reader(), &group.pairs[0]);
        try nextPair(file.reader(), &group.pairs[1]);
    std.debug.print("Output:  {s}={s} \n", .{ group.pairs[0].key.key, group.pairs[0].value.value });
    std.debug.print("Output:  {s}={s} \n", .{ group.pairs[1].key.key, group.pairs[1].value.value });
    try interpolate_value(group.pairs[1].value, group.pairs);
    std.debug.print("Interpolated Output:  {s}={s} \n", .{ group.pairs[1].key.key, group.pairs[1].value.value });
        try std.testing.expect(std.mem.eql(u8, group.pairs[1].value.value, "beta"));
    //   std.debug.print("Output:  {s}={s} \n", .{ envKey2.key.*, envValue2.value.* });
    //   try std.testing.expect(std.mem.eql(u8, envValue2.value.*[0..4], "beta"));
}


