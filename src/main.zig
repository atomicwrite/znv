const std = @import("std");

const EnvPair = @import("env-pair.zig").EnvPair;
const EnvReader = @import("env-reader.zig").EnvReader;

const testing = std.testing;








test "open test file and read one character" {
    const file =
        try std.fs.cwd().openFile("test-files/sample.env", . {});
    defer file.close() ;
    var reader = EnvReader{

    };
    reader.init(file) catch |x| {
          std.debug.print("Error reader init:  {} {} .\n", .{x});
            //todo: handle these errors
             return x;
    };


}