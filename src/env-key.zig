const std = @import("std");

const isAlphanumeric = std.ascii.isAlphanumeric;
const isWhitespace = std.ascii.isWhitespace;
pub const EnvKeyError = error{
    KeyStartedWithNumber,
    InvalidKeyCharacter,
};

pub const EnvKey = struct {
    const Self = @This();
    key: []u8 = undefined,
    keyIndex: u32 = 0,
    allocator: *std.mem.Allocator = undefined,

    pub fn init(self: *Self, allocator: *std.mem.Allocator, tmp_buffer: []u8) !void {
        self.keyIndex = 0;
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
        std.debug.print("Placing {c} at {}\n", .{value,self.keyIndex});
        self.key[self.keyIndex] = value;
        self.keyIndex = self.keyIndex + 1;
    }
    fn isPreviousOnlyWhiteSpace(self: *Self) bool{
        var tmp = self.keyIndex;
        while(tmp >= 0) : (tmp = tmp - 1 ) {
            if(!isWhitespace(self.key[tmp])){
                return false;
            }
        }
        return true;
    }
    pub fn processKeyNextValue(self: *Self, value: u8) !bool {
        if (value == '=') {
            std.debug.print("End of key found (=) \n", .{});
            //we hit the end

            return true;
        }
        if (value == '_') {
            self.placeKeyCharacter(value);
            return false;
        }
        if (value == '#'){
            if(self.isPreviousOnlyWhiteSpace()){
                return error.IsACommentLine;
            }
        }
        if(value == '\n'){
            if(self.isPreviousOnlyWhiteSpace()){
                return error.IsABlankLine;
            }
        }
        if(isAlphanumeric(value)){
            self.placeKeyCharacter(value);
            return false;
        }

        std.debug.print("Invalid key character {c} \n", .{value});
        return error.InvalidKeyCharacter;
    }
};
