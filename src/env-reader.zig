const std = @import("std");
const File = std.fs.File;
const EnvPair = @import("env-pair.zig").EnvPair;
pub const EnvReader =  struct {
    file: ? File = null,


    pub fn init(self:*Self,file:File) !void{
         self.file = file;
    }

     pub const Self = @This();

      pub fn next(self: *Self) !EnvPair {
        const pair = EnvPair {

        };
        const byte = try self.file.readByte() catch |x| {

            return x; //for now, we want to check for a few errors later
        };
        pair.processKeyNextValue(byte);
    }

};
