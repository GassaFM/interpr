module preprocess;
import language;
import std.stdio;

int depth;
void replaceFor(ref Statement[] list, int t)
{
    auto f = cast(ForBlock) list[t];
    BinaryOpExpression len;
    BinaryOpExpression.Type comp, op;
    AssignStatement.Type as;
    switch (f.style)
    {
    case ForStyle.until:
        len = new BinaryOpExpression(BinaryOpExpression.Type.subtract, f.finish, f.start);
        comp = BinaryOpExpression.Type.less;
        as = AssignStatement.Type.assignAdd;
        op = BinaryOpExpression.Type.add;
        break;
    case ForStyle.rangeto:
        len = new BinaryOpExpression(BinaryOpExpression.Type.subtract, f.finish, f.start);
        comp = BinaryOpExpression.Type.lessEqual;
        as = AssignStatement.Type.assignAdd;
        op = BinaryOpExpression.Type.add;
        break;
    case ForStyle.downto:
        len = new BinaryOpExpression(BinaryOpExpression.Type.subtract, f.start, f.finish);
        comp = BinaryOpExpression.Type.greaterEqual;
        as = AssignStatement.Type.assignSubtract;
        op = BinaryOpExpression.Type.subtract;
        break;
    default:
        break;
    }
    Statement[] b = list[0 .. t], e = list[t + 1 .. list.length];
    auto mod = new BinaryOpExpression(BinaryOpExpression.Type.modulo, len, new ConstExpression(
            depth));
    auto it = new VarExpression(f.name, null);
    auto cond1 = new BinaryOpExpression(comp, it, new BinaryOpExpression(op, f.start, mod));
    auto cond2 = new BinaryOpExpression(comp, it, f.finish);
    auto incrIt = new AssignStatement(f.lineId, as, it, new ConstExpression(1));
    auto while1 = new WhileBlock(f.lineId, cond1);
    while1.statementList = f.statementList;
    while1.statementList ~= incrIt;
    auto while2 = new WhileBlock(f.lineId, cond2);
    for (int i = 0; i < depth; i++)
    {
        while2.statementList ~= f.statementList;
        while2.statementList ~= incrIt;
    }
    b ~= new AssignStatement(f.lineId, AssignStatement.Type.assign, it, f.start);
    b ~= while1;
    b ~= while2;
    b ~= e;
    list = b;
}

void apply (ref Statement [] List){
    for (int i = 0; i < List.length; i++)
    {
        findFor(List[i]);
        auto temp = cast(ForBlock) List[i];
        if (temp !is null)
        {
            replaceFor(List, i);
        }
    }
}
Statement findFor(Statement now)
{
    auto cur0 = cast(FunctionBlock)(now);
    if (cur0 !is null)
        with (cur0)
        {
            apply(statementList);
            now = cur0;
        }
    auto cur1 = cast(ForBlock)(now);
    if (cur1 !is null)
        with (cur1)
        {
            apply(statementList);
            now = cur1;
        }
    auto cur2 = cast(WhileBlock)(now);
    if (cur2 !is null)
        with (cur2)
        {
            apply(statementList);
            now = cur2;
        }
    auto cur3 = cast(IfBlock)(now);
    if (cur3 !is null)
        with (cur3)
        {
            apply(statementListTrue);
            apply(statementListFalse);
            now = cur3;
        }
    return now;
}
