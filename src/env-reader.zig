const std = @import("std");

const Reader = std.fs.File.Reader;
const EnvPair = @import("env-pair.zig").EnvPair;

const EnvReaderError = error {
    KeyStartedWithNumber,
    InvalidKeyCharacter,
};


      pub fn next(  reader: Reader) !EnvPair {

      const key =  [_]u8{0} ** 32768;
      const value =  [_]u8{0} ** 32768; //still learning. want to create a big buffer for max size
        var pair = EnvPair {
            .key=key,
            .value = value
        };
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
      }
      return pair;

    }


