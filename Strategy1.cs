using Formula.Interfaces;
using Formula.Objects;

public class Strategy1 : Behavior<Object1>
{
    public override void Execute(Object1 obj, IWorld world)
    {
        obj.X = 1;
        obj.Y = 1;
    }
}