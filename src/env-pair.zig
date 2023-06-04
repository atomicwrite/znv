pub const EnvPairError = error{
    KeyStartedWithNumber,
    InvalidKeyCharacter,
};
//
pub const EnvValueCounter = struct {
    const Self = @This();
    interPolDepth: u8 = 0,
    openBraces: u8 = 0,
    openQuote: u8 = 0,

    pub fn incrementInterpolDepth() void {
        self.interPolDepth = interPolDepth + 1;
    }
    pub fn decrementInterpolDepth() void {
        self.interPolDepth = interPolDepth - 1;
    }
    // fn isInDoubleQuotesHereDoc(self:*Self) !bool{
    //
    //            }
    //    fn isInSingleQuotesHereDoc(self:*Self) !bool{
    //
    //                }
    //
    //    fn isInSingleQuotes(self:*Self) !bool{
    //
    //            }
    //
    //        fn isInBraces(self:*Self) !bool{
    //
    //                }
    //
    //        fn isInDoubleQuotes(self:*Self) !bool{
    //
    //        }
};

pub const EnvPair = struct {
    const Self = @This();
    key: *[32768]u8,
    envValueCounter: EnvValueCounter = EnvValueCounter{},
    keyIndex: u8 = 0,
    value: *[32768]u8,
    quoted = false,
    tripleQuoted = false,
    doubleQuoted = false,
    tripleDoubleQuoted = false,
    valueIndex: u8 = 0,
    interpolation: bool = false,

    pub fn placeValueCharacter(self: *Self, value: u8) void {
        // todo: check for overflow and resize array.
        self.value[self.valueIndex] = value;
        self.valueIndex = self.valueIndex + 1;
    }
    pub fn previousIsSingleQuote(self: *Self) !bool {
        if (self.valueIndex == 0) {
            return false;
        }
        return self.value[self.valueIndex - 1] == '\'';
    }
    pub fn fourCharactersAgoNewline(self: *Self) bool {
        if (self.valueIndex < 4) {
            return false;
        }
        return self.value[self.valueIndex - 4] == '\n';
    }
    pub fn previousDoubleQuoteCount(self: *Self) !u8 {
        var tmp = self.valueIndex;
        var count = 0;
        while (tmp > 0) {
            if (self.value[tmp - 1] == '"') {
                count = count + 1;
            }
        }
        return count;
    }
    pub fn isAtStart(self: *Self) u8 {
        return self.valueIndex == 0;
    }
    pub fn previousIsDollarSign(self: *Self) !bool {
        if (self.valueIndex == 0) {
            return false;
        }
        return self.value[self.valueIndex - 1] == '$';
    }
    pub fn processValueNextValue(self: *Self, value: u8) !bool {
        if (self.quoted) {
            return self.processValueInsideQuoted(value);
        }

            if (value == '{') {
                if (self.previousIsDollarSign()) {
                    self.envValueCounter.incrementInterpolDepth();
                }
            }
            if (value == '}') {
                if (self.interPolDepth > 0) {
                    self.envValueCounter.decrementInterpolDepth();
                }
            }
            if (value == '"') {
                const streak = self.previousDoubleQuoteCount();

                if (streak == 0) {
                    if (self.isAtStart()) {
                        self.doubleQuoted = true;
                    }
                }
                if (streak == 3) {
                    if (self.isAtStart()) {
                        self.tripleDoubleQuoted = true;
                    }
                    if (self.tripleDoubleQuoted) {
                        if (self.fourCharactersAgoNewline()) {
                            return true;
                        }
                    }
                }
            }



    }
    pub fn processValueInsideQuoted() !bool{
        if (value == '\'') {}
            if (value == '\r') {}
            if (value == '\n') {}
    }

    pub fn processKeyNextValue(self: *Self, value: u8) !bool {
        if (value == '=') {
            //we hit the end
            //todo: shink arrays
            return true;
        }
        if (value == '_') {
            self.placeKeyCharacter(value);
            return false;
        }
        if (value < 'A') {
            return EnvPairError.InvalidKeyCharacter;
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
            return EnvPairError.KeyStartedWithNumber;
        }
        return error.InvalidKeyCharacter;
    }
};
