pub const EnvValueCounter = struct {
    const Self = @This();
    interPolDepth: u8 = 0,
    openBraces: u8 = 0,
    openQuote: u8 = 0,

    pub fn incrementInterpolDepth(self: *Self) void {
        self.interPolDepth = self.interPolDepth + 1;
    }
    pub fn decrementInterpolDepth(self: *Self) void {
        self.interPolDepth = self.interPolDepth - 1;
    }

};


pub const EnvValueInterpolation  = struct {
    key:  *[]u8,
    start: u8,
    end: u8,
    value:  ?*[]u8,
    /// find the envPair if it exists, otherwise error no such key
    /// if it isn't resolve, check to see if it is already resolving, if it is throw an error
    // otherwise resolve it using existing resolved and place it in resolving until it's resolved
    ///
    pub fn resolve(envPairs: *[]EnvPair,resolved: *[]EnvValueInterpolation,resolving: *[]EnvValueInterpolation) !void{
            for(  envPairs) |pair| {
                    if(std.mem.eql(u8, pair.key, self.key)){
                        //here is what we need to resolve

                    }
            }
            return error.NoSuchEnv;
    }
};