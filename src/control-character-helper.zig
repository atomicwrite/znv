const EnvValue = @import("env-value.zig").EnvValue;
const std = @import("std");
pub fn processPossibleControlCharacter(self: *EnvValue, value: u8) bool {

    switch(value) {
               't'=>{

                       try self.placeValueCharacter('\t');

               },
               'n'=>{
                     try self.placeValueCharacter('\n');
               },
               'r'=>{
                             try self.placeValueCharacter('\r');
               },
               'f'=>{
                         try self.placeValueCharacter(' ');
               },
               'b'=>{
                             try self.placeValueCharacter(' ');
               },
               '"'=>{
                             try self.placeValueCharacter('"');
               },
               '\''=>{
                             try self.placeValueCharacter('\'');
               },
               'u'=>{
                   //todo: process unicode value
                             try self.placeValueCharacter(' ');
               },
               else =>{
                   return false;
               }
           }
           return false;

}
