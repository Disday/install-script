string[] compList = ["comp1", "comp2", "comp3"];
Installer.Install(compList);


class Logger(string logPath = "log.log")
{
    public void Log(string message, string compName)
    {
        string entry = $"{DateTime.Now} - {compName} - {message}\n";
        File.AppendAllText(logPath, entry);
    }
}

class Installer
{
    public static void Install(string[] compList)
    {
        Logger logger = new("new.log");

        foreach (var compName in compList)
        {
            logger.Log("some text", compName);
        }
    }
}
