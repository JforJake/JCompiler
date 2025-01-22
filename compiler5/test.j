global int x;
global int y;

function makePattern(string s1, string s2, int val)
{
   call printStr("Printing a pattern\n");
   while (x != 0) do {
      y = 0;
      while (y < x) do {
         call printStr("*");
         y = y + 1;
      }
      call printStr("\n");
      x = x - 1;
   }
}

program {
   call printStr("Enter value for x: ");
   call readInt();
   x = returnvalue;
   if (x > 100) then {
      call printStr("x is over 100!\n");
   } else {
      call printStr("x is 100 or less!\n");
   }
   call makePattern();
   call printStr("Program done.\n");
}