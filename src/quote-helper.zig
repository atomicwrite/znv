const std = @import("std");
const EnvPair = @import("env-pair.zig").EnvPair;
const EnvValue = @import("env-value.zig").EnvValue;
const processPossibleControlCharacter = @import("control-character-helper.zig").processPossibleControlCharacter;
pub fn walkBackSlashes(self: *EnvValue, value: u8) bool {
    if (self.backSlashStreak % 2 == 0) {
        self.valueIndex = self.valueIndex - self.backSlashStreak/2;
        return false; // we have a complete paired set of back slashes, walk the buffer back backSlashStreak/2

    }
    //we have an attempt at a control character, evaluate value
    return processPossibleControlCharacter(self,value);

}
pub fn walkSingleQuotes(self: *EnvValue) bool {
    if (self.quoted) {
        std.debug.print("Ending single quote found\n", .{});
        return true; // we have a single unescaped quote ending a quoted string at the start

    }
    const quotesStartAtStartOfString = self.valueIndex == 0;
    std.debug.print("Quote(s) is at start? {} - {} {} \n", .{self.valueIndex,self.singleQuoteStreak, quotesStartAtStartOfString});
    switch (self.singleQuoteStreak) {
        1 => {
            if (quotesStartAtStartOfString) {
                self.quoted = true;
            }
            self.singleQuoteStreak = 0;

            return false;
        },
        3 => {
            if (self.tripleQuoted) {
                self.singleQuoteStreak = 0;
                std.debug.print("Ending triple quote found\n", .{});
                return true; // we have the end of a triple quoted here doc
            }
            if (quotesStartAtStartOfString) {
                self.tripleQuoted = true;

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
            std.debug.print("Ending double quote found\n", .{});
            return true; // we have a single unescaped quote ending a quoted string at the start

        }
        const quotesStartAtStartOfString = self.valueIndex == 0;
        std.debug.print("double Quote(s) is at start? {} - {} {} \n", .{self.valueIndex,self.singleQuoteStreak, quotesStartAtStartOfString});
        switch (self.doubleQuoteStreak) {
            1 => {
                if (quotesStartAtStartOfString) {
                    self.doubleQuoted = true;
                }
                self.doubleQuoteStreak = 0;

                return false;
            },
            3 => {
                if (self.tripleDoubleQuoted) {
                    self.doubleQuoteStreak = 0;
                    std.debug.print("ending double-heredoc \n", .{});
                    return true; // we have the end of a triple quoted here doc
                }
                if (quotesStartAtStartOfString) {
                 std.debug.print("starting double-heredoc \n", .{});
                    self.tripleDoubleQuoted = true;

                }
                self.doubleQuoteStreak = 0;
            },
            else => {
                // if (self.singleQuoteStreak > 3) {
                //     self.tripleQuoted = true;
                //     self.valueIndex = self.valueIndex - self.singleQuoteStreak;
                // }
                if (self.doubleQuoteStreak > 5) {
                    self.valueIndex = self.valueIndex - self.doubleQuoteStreak;
                    self.doubleQuoteStreak = 0;
                    return true; // ends the quote streak.
                }
                //what happens if we have 5? process it as 3 and then 2 more or
            },
        }
        return false;
}
