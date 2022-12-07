function y = NormW32(a)   
if (a == 0) return 0;
v = (uint32_t) (a < 0 ? ~a : a);
%     // returns the number of leading zero bits in the argument.
    return (int16_t) (__clz_uint32(v) - 1);