using Formula.Objects;

public class Object1 : BaseOBject
{
    public Object1(double x, double y, int z = 0, Color? color = null, IBehavior? behavior = null, string? label = null) : base(x, y, z, color, behavior, label)
    {
    }
}