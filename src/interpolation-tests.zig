const std = @import("std");
const EnvValue = @import("env-value.zig").EnvValue;
const EnvKey = @import("env-key.zig").EnvKey;
const nextKey = @import("env-reader.zig").nextKey;
const nextValue = @import("env-reader.zig").nextValue;
const EnvPair = @import("env-pair.zig").EnvPair;
const InterpolationHelper = @import("interpolation-helper.zig");
const free_interpolation_array = InterpolationHelper.free_interpolation_array;
const interpolate_value = InterpolationHelper.interpolate_value;
const testing = std.testing;

test "int value" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = arena.allocator(); // prob best with arena but for tests...
    const file =
        try std.fs.cwd().openFile("test-files/sample-interpolated.env", .{});
    defer file.close();
    //   //todo: use allocation. but this is ok for now.
    //
    var key = try allocator.alloc(u8, 100); //buffer for repeat reads
    defer allocator.free(key);
    var value = try allocator.alloc(u8, 100); //buffer for repeat reads
    defer allocator.free(value);
    var envKey1 = EnvKey{};
    try envKey1.init(allocator, key);
    var envValue1 = EnvValue{};
    try envValue1.init(allocator, value);
    defer free_interpolation_array(&envValue1);
    //
    const envPair1 = EnvPair{ .key = &envKey1, .value = &envValue1 };
    std.debug.print("Reading key  \n", .{});
    try nextKey(file.reader(), &envKey1);
    std.debug.print("Reading Value  \n", .{});
    try nextValue(file.reader(), &envValue1);
    std.debug.print("Read   \n", .{});
    try envKey1.finalize_key();

    defer envKey1.free_key();
    try envValue1.finalize_value();
    std.debug.print("Read key {s} \n", .{envKey1.key});
    std.debug.print("Read Value {s} \n", .{envValue1.value});
    defer envValue1.free_value();

    var envKey2 = EnvKey{};
    try envKey2.init(allocator, key);
    var envValue2 = EnvValue{};
    try envValue2.init(allocator, value);
    defer free_interpolation_array(&envValue2);
    //
    const envPair2 = EnvPair{ .key = &envKey2, .value = &envValue2 };
    std.debug.print("Reading key  \n", .{});
    try nextKey(file.reader(), &envKey2);

    try nextValue(file.reader(), &envValue2);
    std.debug.print("Read   \n", .{});
    try envKey2.finalize_key();
    defer envKey2.free_key();
    try envValue2.finalize_value();
    defer envValue2.free_value();
    std.debug.print("Read key {s} \n", .{envKey2.key});
    std.debug.print("Read Value {s} \n", .{envValue2.value});

    const items: []EnvPair = try allocator.alloc(EnvPair, 2);
    items[0] = envPair2;
    items[1] = envPair1;
    defer allocator.free(items);
    try interpolate_value(&envValue2, items);
    //   std.debug.print("Output:  {s}={s} \n", .{ envKey2.key.*, envValue2.value.* });
    //   try std.testing.expect(std.mem.eql(u8, envValue2.value.*[0..4], "beta"));
}
