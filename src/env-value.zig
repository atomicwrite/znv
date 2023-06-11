const std = @import("std");
const EnvValueCounter = @import("env-value-counter.zig").EnvValueCounter;
pub const MAX_ENV_VALUE_LENGTH = 32768;

pub const EnvValue = struct {
    const Self = @This();
    value: *[MAX_ENV_VALUE_LENGTH]u8,
    quoted: bool = false,
    envValueCounter: EnvValueCounter = EnvValueCounter{},
    tripleQuoted: bool = false,
    doubleQuoted: bool = false,
    tripleDoubleQuoted: bool = false,
    valueIndex: u8 = 0,
    interpolation: bool = false,
    didOverFlow : bool =false,
    fn placeValueCharacter(self: *Self, value: u8) void {

        if(self.valueIndex>=MAX_ENV_VALUE_LENGTH){
            //emit warning we are over allowed buffer length
            std.debug.print("Value {c} can not be stored. ENV has a max size. \n", .{value});
            self.didOverFlow = true;
            return;
            //todo: handle overflow -- probably will just ignore. ENV can't hold more than 32k on linux.
            //return;
        }
        self.value[self.valueIndex] = value;
        self.valueIndex = self.valueIndex + 1;
    }
    pub fn processValueNextValue(self: *Self, value: u8) !bool {
        if(self.didOverFlow){
            //we've told the user they overflowed. Just return; Nothing else can be processed.
            return;
        }
        if (self.quoted) { // process value if we have detected this is a single quoted value
            return self.processValueInsideQuoted(value);
        }
        if (value == '\'') { //single quote
            if (self.isAtStart()) { //at the start
                self.quoted = true;
                return false;
            }
        }
        if (value == '{') { //ok we have either no double quote or are double quoted, process if we find ${}
            if (self.previousIsDollarSign()) {
                self.envValueCounter.incrementInterpolDepth();
                return false;
            }
        }
        if (value == '}') {
            if (self.envValueCounter.interPolDepth > 0) {
                self.envValueCounter.decrementInterpolDepth();
                return false;
            }
        }

        // ok so it's not a single quoted string and not a quote
        if (value != '"') {
            //todo: check for escape (prob in placeValueCharacter)
            self.placeValueCharacter(value);
            return false;
        }
        // ok it's a double quote
        return self.processDoubleQuote();
    }
    fn processDoubleQuote(self: *Self) bool {
        const streak = self.previousDoubleQuoteCount();

        if (streak == 0) {
            if (self.isAtStart()) {
                self.doubleQuoted = true;
                return false;
            }
            if (!self.tripleDoubleQuoted) {
                return true;
            }
        }
        if (streak != 3) {
            return false;
        }
        if (self.tripleDoubleQuoted) {
            if (self.fourCharactersAgoNewline()) {
                return true;
            }
            return false;
        }
        if (self.fourCharactersAgoStart()) {
            self.tripleDoubleQuoted = true;
        }
        return false;
    }
    pub fn processValueInsideQuoted(self: *Self, value: u8) !bool {
        std.debug.print("Inside Single Quote {c} \n", .{value});
        if (value == '\'') {
            const streak = self.previousSingleQuoteCount();
            std.debug.print("Is a single quote with streak {} \n", .{streak});
            if (streak == 3) {
                if (self.fourCharactersAgoStart()) {
                    self.tripleQuoted = true;
                    return false;
                }
                if (self.fourCharactersAgoNewline()) {
                    return true;
                }
            }
            return true;
        }
        if (value == '\r') {
            return false;
        }
        if (value == '\n') {
            return true;
        }
        self.placeValueCharacter(value);
        return false;
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
    pub fn previousSingleQuoteCount(self: *Self) u8 {
        var tmp = self.valueIndex;
        var count: u8 = 0;
        while (tmp > 0) {
            if (self.value[tmp - 1] == '\'') {
                count = count + 1;
            }
            if (count >= 3) {
                //avoid """"""""""""""""""""""""
                break;
            }
            tmp = tmp - 1;
        }
        return count;
    }
    pub fn previousDoubleQuoteCount(self: *Self) u8 {
        var tmp = self.valueIndex;
        var count: u8 = 0;
        while (tmp > 0) {
            if (self.value[tmp - 1] == '"') {
                count = count + 1;
            }
            if (count >= 3) {
                //avoid """"""""""""""""""""""""
                break;
            }
            tmp = tmp - 1;
        }
        return count;
    }
    pub fn isAtStart(self: *Self) bool {
        return self.valueIndex == 0;
    }
    pub fn fourCharactersAgoStart(self: *Self) bool {
        return self.valueIndex == 3;
    }
    pub fn previousIsDollarSign(self: *Self) bool {
        if (self.valueIndex == 0) {
            return false;
        }
        return self.value[self.valueIndex - 1] == '$';
    }
};
