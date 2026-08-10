static class Program
{
    [STAThread]
    static void Main()
    {
        ApplicationConfiguration.Initialize();

        var map = new Scene1();
        map.Run();
    }
}