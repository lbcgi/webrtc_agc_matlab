function y = NormW32(a)   
if (a == 0) 
% v = (uint32_t) (a < 0 ? ~a : a);
 y = 0;
end
if(a<0)
    a = 1 - a;
end
%     // returns the number of leading zero bits in the argument.
   y = NormU32(int32(a)) - 1;