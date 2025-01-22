
function myFunc()
{
   call printStr("in myFunc,");
   call printStr(" but cannot use args yet!\n");
}

program {
   call myFunc("this", "is a test", 56+45+34);
   call printStr("The expression 392+48+712 evaluates to: ");
   call printInt(392+48+712);
   call printStr("\n\n   Goodbye!\n\n");
}

