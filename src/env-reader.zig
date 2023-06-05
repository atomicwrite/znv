const std = @import("std");

const Reader = std.fs.File.Reader;
const EnvPair = @import("env-pair.zig").EnvPair;

const EnvReaderError = error{
    KeyStartedWithNumber,
    InvalidKeyCharacter,
};
pub fn nextValue(
    reader: Reader,
    pair: *EnvPair,
) !void {
    var end = false;

    while (!end) {
        const byte = reader.readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => |e| return e,
        };

        end = pair.processValueNextValue(byte) catch |err| switch (err) {
            error.InvalidKeyCharacter => break,
            error.KeyStartedWithNumber => break,
        };
    }
}

pub fn nextKey(
    reader: Reader,
    pair: *EnvPair,
) !void {
    while (true) {
        const byte = reader.readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => |e| return e,
        };
        const isLastKeyValue = pair.processKeyNextValue(byte) catch |err| switch (err) {
            error.InvalidKeyCharacter => break,
            error.KeyStartedWithNumber => break,
        };
        std.debug.print("Is Last? :  {any}   \n", .{isLastKeyValue});
        if (isLastKeyValue) {
            break;
        }
    }
}
