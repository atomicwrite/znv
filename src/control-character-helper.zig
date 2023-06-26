const EnvValue = @import("env-value.zig").EnvValue;
const std = @import("std");
const control_code  = std.ascii.control_code;

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
                         try self.placeValueCharacter(control_code.ff);
               },
               'b'=>{
                             try self.placeValueCharacter(control_code.bs);
               },
               '"'=>{
                             try self.placeValueCharacter('"');
               },
               '\''=>{
                             try self.placeValueCharacter('\'');
               },
               'u'=>{
                   //todo: process unicode value
                             try self.placeValueCharacter('\xab');
               },
               else =>{
                   return false;
               }
           }
           return false;

}
