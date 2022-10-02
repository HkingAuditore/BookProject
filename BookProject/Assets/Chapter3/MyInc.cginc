half4 OnlyRedAlpha(half4 col)
{
    return half4(col.r,0,0,col.a);
}