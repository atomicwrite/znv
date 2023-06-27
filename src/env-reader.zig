const std = @import("std");
const EnvPair = @import("env-pair.zig").EnvPair;
const Reader = std.fs.File.Reader;
const EnvKey = @import("env-key.zig").EnvKey;
const EnvValue = @import("env-value.zig").EnvValue;
const EnvGroup = @import("env-group.zig").EnvGroup;

const EnvReaderError = error{
    KeyStartedWithNumber,
    InvalidKeyCharacter,
};
pub fn freePairs(self: *EnvGroup) void {
    self.allocator.free(self.keys);
    self.allocator.free(self.values);
    self.allocator.free(self.pairs);
}

pub fn preInitPairs(self: *EnvGroup, amount: usize,reusable_buffer: []u8) !void {
    self.pairs = try self.allocator.alloc(EnvPair, amount);
    self.keys = try self.allocator.alloc(EnvKey, amount);
    self.values = try self.allocator.alloc(EnvValue, amount);
    var tmp: u8 = 0;
    while (tmp < amount) : (tmp = tmp + 1) {
        self.pairs[tmp].key = &self.keys[tmp];
        std.debug.print("Placing  {}\n", .{  self.pairs[tmp].key.keyIndex});
        try self.pairs[tmp].key.init(self.allocator,reusable_buffer);
        self.pairs[tmp].value = &self.values[tmp];
        try self.pairs[tmp].value.init(self.allocator,reusable_buffer);
    }
}
pub fn nextPair(reader: Reader, pair: *EnvPair) !void {

    std.debug.print("Reading Key  \n", .{});
    try nextKey(reader, pair.key);
    try pair.key.finalize_key();
    std.debug.print("Reading Value  \n", .{});
    try nextValue(reader, pair.value);
    try pair.value.finalize_value();
    std.debug.print("Read   \n", .{});
}
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

        end = try value.processValueNextValue(byte);
    }
    std.debug.print("End of Value \n", .{});
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
            error.InvalidKeyCharacter => {
                std.debug.print("Invalid Character :  {c}   \n", .{byte});
                return err;
            },

            else => |e| return e,
        };
        std.debug.print("Is Last? :  {any}   \n", .{isLastKeyValue});
        if (isLastKeyValue) {
            break;
        }
    }
}
