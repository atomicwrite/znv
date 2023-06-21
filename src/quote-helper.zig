const std = @import("std");
const EnvPair = @import("env-pair.zig").EnvPair;
const EnvValue = @import("env-value.zig").EnvValue;
pub fn processDoubleQuote(self: *EnvValue) bool {
    const streak = self.previousDoubleQuoteCount();

    if (streak == 0) {
        if (self.isAtStart()) {
            self.doubleQuoted = true;
            return false;
        }
        if (!self.tripleDoubleQuoted) {
            return false;
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
pub fn processValueInsideQuoted(self: *EnvValue, value: u8) !bool {
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
    try self.placeValueCharacter(value);
    return false;
}
pub fn previousIsSingleQuote(self: *EnvValue) !bool {
    if (self.valueIndex == 0) {
        return false;
    }
    return self.value[self.valueIndex - 1] == '\'';
}
