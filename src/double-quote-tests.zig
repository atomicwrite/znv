const std = @import("std");
const EnvValue = @import("env-value.zig").EnvValue;
const EnvKey = @import("env-key.zig").EnvKey;
const nextKey = @import("env-reader.zig").nextKey;
const nextValue = @import("env-reader.zig").nextValue;

const testing = std.testing;

test "simple single quoted key value" {
    const file =
        try std.fs.cwd().openFile("test-files/sample-double-quote.env", .{});
    defer file.close();
    //todo: use allocation. but this is ok for now.
    var key = [_]u8{0} ** 32768;
    var value = [_]u8{0} ** 32768; //still learning. want to create a big buffer for max size

    var envKey = EnvKey{ .key = &key };
    var envValue = EnvValue{ .value = &value };

    nextKey(file.reader(), &envKey) catch |x| {
        return x;
    };
    nextValue(file.reader(), &envValue) catch |x| {
        return x;
    };
    std.debug.print("Output:  {s}={s} \n", .{ envKey.key, envValue.value });
    try std.testing.expect(std.mem.eql(u8, envValue.value[0..4], "beta"));
}
