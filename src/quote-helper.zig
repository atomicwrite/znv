const std = @import("std");
const EnvPair = @import("env-pair.zig").EnvPair;
const EnvValue = @import("env-value.zig").EnvValue;
const processPossibleControlCharacter = @import("control-character-helper.zig").processPossibleControlCharacter;
pub fn walkBackSlashes(self: *EnvValue, value: u8) bool {
    if (self.backSlashStreak % 2 == 0) {
        return false; // we have a complete paired set of back slashes

    }
    //we have an attempt at a control character, evaluate value
    return processPossibleControlCharacter(self,value);

}
pub fn walkSingleQuotes(self: *EnvValue) bool {
    if (self.quoted) {
        return true; // we have a single unescaped quote ending a quoted string at the start

    }
    const quotesStartAtStartOfString = self.valueIndex == self.singleQuoteStreak;
    switch (self.singleQuoteStreak) {
        1 => {
            if (quotesStartAtStartOfString) {
                self.quoted = true;
                self.valueIndex = self.valueIndex - 1;
            }
            self.singleQuoteStreak = 0;

            return false;
        },
        3 => {
            if (self.tripleQuoted) {
                self.singleQuoteStreak = 0;
                return true; // we have the end of a triple quoted here doc
            }
            if (quotesStartAtStartOfString) {
                self.tripleQuoted = true;
                self.valueIndex = self.valueIndex - 3;
            }
            self.singleQuoteStreak = 0;
        },
        else => {
            // if (self.singleQuoteStreak > 3) {
            //     self.tripleQuoted = true;
            //     self.valueIndex = self.valueIndex - self.singleQuoteStreak;
            // }
            if (self.singleQuoteStreak > 5) {
                self.valueIndex = self.valueIndex - self.singleQuoteStreak;
                self.singleQuoteStreak = 0;
                return true; // ends the quote streak.
            }
            //what happens if we have 5? process it as 3 and then 2 more or
        },
    }
    return false;
}
pub fn walkDoubleQuotes(self: *EnvValue) bool {
    if (self.doubleQuoted) {
        return true; // we have a single unescaped double quote ending a double Quoted string at the start

    }
    return false;
}
