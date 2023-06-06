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
