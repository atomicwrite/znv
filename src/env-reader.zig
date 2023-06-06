const std = @import("std");

const Reader = std.fs.File.Reader;
const EnvKey = @import("env-key.zig").EnvKey;
const EnvValue = @import("env-value.zig").EnvValue;

const EnvReaderError = error{
    KeyStartedWithNumber,
    InvalidKeyCharacter,
};
pub fn nextValue(
    reader: Reader,
    value: *EnvValue,
) !void {
    var end = false;

    while (!end) {
        const byte = reader.readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => |e| return e,
        };

        end = value.processValueNextValue(byte) catch |err| switch (err) {
            error.InvalidKeyCharacter => break,
            error.KeyStartedWithNumber => break,
        };
    }
}

pub fn nextKey(
    reader: Reader,
    key: *EnvKey,
) !void {
    while (true) {
        const byte = reader.readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => |e| return e,
        };
        const isLastKeyValue = key.processKeyNextValue(byte) catch |err| switch (err) {
            error.InvalidKeyCharacter => break,
            error.KeyStartedWithNumber => break,
        };
        std.debug.print("Is Last? :  {any}   \n", .{isLastKeyValue});
        if (isLastKeyValue) {
            break;
        }
    }
}
