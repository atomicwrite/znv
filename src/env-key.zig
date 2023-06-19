const std = @import("std");
pub const EnvKeyError = error{
    KeyStartedWithNumber,
    InvalidKeyCharacter,
};

pub const EnvKey = struct {
    const Self = @This();
    key: []u8 = undefined,
    keyIndex: u8 = 0,
    allocator: std.mem.Allocator = undefined,

    pub fn init(self: *Self, allocator: std.mem.Allocator, tmp_buffer: []u8) !void {

        self.key = tmp_buffer;
        self.allocator = allocator;
    }
      pub fn free_key(self: *Self)  void {
                self.allocator.free(self.key);
            }
    pub fn finalize_key(self: *Self ) !void {
        if (self.keyIndex <= 0) {
            return error.ValueWouldBeEmpty;
        }
        std.debug.print("Finalizing Key of length {} \n", .{self.keyIndex});
        var tmp =try self.allocator.alloc(u8,self.keyIndex);

        const bufferSlice = self.key[0..self.keyIndex];
        std.mem.copy(u8, tmp, bufferSlice);
        self.key = tmp;

    }
    fn placeKeyCharacter(self: *Self, value: u8) void {
        // todo: check for overflow and resize array.
        self.key[self.keyIndex] = value;
        self.keyIndex = self.keyIndex + 1;
    }
    pub fn processKeyNextValue(self: *Self, value: u8) !bool {
        if (value == '=') {
            //we hit the end

            return true;
        }
        if (value == '_') {
            self.placeKeyCharacter(value);
            return false;
        }
        if (value < 'A') {
            return EnvKeyError.InvalidKeyCharacter;
        }
        if (value <= 'z') {
            self.placeKeyCharacter(value);
            return false;
        }
        if (value <= '9') {
            if (self.keyIndex != 0) { //can't start with a number
                self.placeKeyCharacter(value);
                return false;
            }
            return EnvKeyError.KeyStartedWithNumber;
        }
        return error.InvalidKeyCharacter;
    }
};
