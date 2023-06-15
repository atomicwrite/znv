const std = @import("std");
const EnvValue = @import("env-value.zig").EnvValue;
const EnvKey = @import("env-key.zig").EnvKey;
const nextKey = @import("env-reader.zig").nextKey;
const nextValue = @import("env-reader.zig").nextValue;
const EnvPair = @import("env-pair.zig").EnvPair;
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
    var key = try allocator.alloc(u8, 32768); //buffer for repeat reads
    defer allocator.free(key);
    var value = try allocator.alloc(u8, 32768); //buffer for repeat reads
    defer allocator.free(value);
    var envKey1 = EnvKey{};
    try envKey1.init(allocator, key);
    var envValue1 = EnvValue{};
    try envValue1.init(allocator, value);
    defer envValue1.free_interpolation_array();
    //
    var envPair1 = EnvPair{ .key = &envKey1, .value = &envValue1 };
    std.debug.print("Reading key  \n", .{});
    try nextKey(file.reader(), &envKey1);
    std.debug.print("Read Value  \n", .{});
    try nextValue(file.reader(), &envValue1);
    std.debug.print("Read   \n", .{});
    try envKey1.finalize_key();
    defer envKey1.free_key();
    try envValue1.finalize_value();
    defer envValue1.free_value();

    var envKey2 = EnvKey{};
        try envKey2.init(allocator, key);
        var envValue2 = EnvValue{};
        try envValue2.init(allocator, value);
        defer envValue2.free_interpolation_array();
        //
        //var envPair1 = EnvPair{ .key = &envKey2, .value = &envValue2 };
        std.debug.print("Reading key  \n", .{});
        try nextKey(file.reader(), &envKey2);
        std.debug.print("Read Value  \n", .{});
        try nextValue(file.reader(), &envValue2);
        std.debug.print("Read   \n", .{});
        try envKey2.finalize_key();
        defer envKey2.free_key();
        try envValue2.finalize_value();
        defer envValue2.free_value();
    
    
    
       var items :  []EnvPair = try allocator.alloc(EnvPair,1);
       items[0] = envPair1;
       defer allocator.free(items);
       try envValue2.interpolate_value( items);
    //   std.debug.print("Output:  {s}={s} \n", .{ envKey2.key.*, envValue2.value.* });
    //   try std.testing.expect(std.mem.eql(u8, envValue2.value.*[0..4], "beta"));
}
