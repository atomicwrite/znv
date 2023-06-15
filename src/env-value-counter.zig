const EnvPair = @import("env-pair.zig").EnvPair;
const std = @import("std");
pub const EnvValueCounter = struct {
    const Self = @This();

    openBraces: u8 = 0,
    openQuote: u8 = 0,

    pub fn incrementInterpolDepth(self: *Self) !void {

        self.isParsingVariable = true;
    }
    pub fn decrementInterpolDepth(self: *Self) !void {
        self.isParsingVariable = false;
    }

};


pub const EnvValueInterpolation  = struct {
   const Self = @This();
    key:  *[]u8,
    start: u8,
    end: u8,
    value:  ?*[]u8,
    // find the envPair if it exists, otherwise error no such key
    // if it isn't resolve, check to see if it is already resolving, if it is throw an error
    // otherwise resolve it using existing resolved or other pairs and place it in resolving until it's resolved
    //
    // pub fn resolve(self: *Self,envPairs: *[]EnvPair,resolved: *[]EnvValueInterpolation,resolving: *[]EnvValueInterpolation) !void{
    //         for(  envPairs) |pair| {
    //                 if(std.mem.eql(u8, pair.key, self.key)){
    //                     //here is what we need to resolve
    //
    //                 }
    //         }
    //         return error.NoSuchEnv;
    // }
};