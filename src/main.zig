const std = @import("std");

const EnvPair = @import("env-pair.zig").EnvPair;
const next = @import("env-reader.zig").next;

const testing = std.testing;








test "open test file and read one character" {
    const file =
        try std.fs.cwd().openFile("test-files/sample.env", . {});
    defer file.close() ;



    const kvPair = next(file.reader()) catch |x| {
        return x;
    };
           std.debug.print("Error reader init:  {s}={s} \n", .{kvPair.key,kvPair.value});
}