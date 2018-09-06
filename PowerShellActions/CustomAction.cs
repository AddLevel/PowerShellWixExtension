using System;
using System.Collections.Generic;
using System.Text;
using System.Xml.Linq;
using Microsoft.Deployment.WindowsInstaller;

using View = Microsoft.Deployment.WindowsInstaller.View;

namespace PowerShellActions
{
    public class CustomActions
    {
        public const uint TickIncrement = 10000;

        // Specify or calculate the total number of ticks the custom action adds to the length of the ProgressBar
        public const uint TotalTicks = TickIncrement * NumberItems;
        private const uint NumberItems = 100;
        private const string PowerShellFilesElevatedDeferredProperty = "PowerShellFilesElevatedDeferred";
        private const string PowerShellFilesDeferredProperty = "PowerShellFilesDeferred";
        private const string PowerShellScriptsElevatedDeferredProperty = "PowerShellScriptsElevatedDeferred";
        private const string PowerShellScriptsDeferredProperty = "PowerShellScriptsDeferred";
        private const string PowerShellUninstallFilesDeferredProperty = "PowerShellUninstallFilesDeferred";
        private const string PowerShellUpgradeFilesDeferredProperty = "PowerShellUpgradeFilesDeferred";

        private const string InstallActionNew = "Install";
        private const string InstallActionUpgrade = "Upgrade";
        private const string InstallActionRemove = "Uninstall";

        [CustomAction]
        public static ActionResult GetScriptFilesBasedOnFeature(Session session)
        {
            var installAction = session["InstallAction"];
            var installXmlDataProperty = string.Format("{0}XmlDataProperty", installAction);

            session.Log("GetScriptFilesBasedOnFeature start");
            session.Log("InstallAction: {0}", installAction);
            session.Log("XmlDataProperty: {0}", installXmlDataProperty);

            return GetScriptFilesFromMsiDatabase(session, 0, installXmlDataProperty, installAction);
        }

        [CustomAction]
        public static ActionResult ExecuteScriptFilesBasedOnFeature(Session session)
        {
            var installXmlDataProperty = string.Format("{0}XmlDataProperty", session.CustomActionData["InstallAction"]);

            session.Log("CustomActionData Count: {0}", session.CustomActionData.Count.ToString());
            IEnumerator<KeyValuePair<string,string>> e = session.CustomActionData.GetEnumerator();
            while (e.MoveNext())
            {
                session.Log("{0} {1}", e.Current.Key, e.Current.Value);
            }

            session.Log("Install Actions Deferred start with property: {0}", installXmlDataProperty);

            return ExecuteScriptFilesFromXmlDataProperty(session, installXmlDataProperty, nameof(ExecuteScriptFilesBasedOnFeature));
        }

        [CustomAction]
        public static ActionResult PowerShellFilesImmediate(Session session) 
        {
            return GetScriptFilesFromMsiDatabase(session, 0, PowerShellFilesDeferredProperty, InstallActionNew);
        }

        [CustomAction]
        public static ActionResult PowerShellFilesElevatedImmediate(Session session)
        {
            return GetScriptFilesFromMsiDatabase(session, 1, PowerShellFilesElevatedDeferredProperty, InstallActionNew);
        }

        [CustomAction]
        public static ActionResult PowerShellFilesDeferred(Session session)
        {
            session.Log("PowerShellFilesDeferred start");

            return ExecuteScriptFilesFromXmlDataProperty(session, PowerShellFilesDeferredProperty, InstallActionNew);
        }

        [CustomAction]
        public static ActionResult PowerShellFilesElevatedDeferred(Session session)
        {
            session.Log("PowerShellFilesElevatedDeferred start");

            return ExecuteScriptFilesFromXmlDataProperty(session, PowerShellFilesElevatedDeferredProperty, InstallActionNew);
        }

        [CustomAction]
        public static ActionResult PowerShellScriptsImmediate(Session session)
        {
            return GetScriptsFromMsiDatabase(session, 0, PowerShellScriptsDeferredProperty, InstallActionNew);
        }

        [CustomAction]
        public static ActionResult PowerShellScriptsElevatedImmediate(Session session)
        {
            return GetScriptsFromMsiDatabase(session, 1, PowerShellScriptsElevatedDeferredProperty, InstallActionNew);
        }

        [CustomAction]
        public static ActionResult PowerShellScriptsDeferred(Session session)
        {
            return ExecuteScriptsFromXmlDataProperty(session, PowerShellScriptsDeferredProperty, InstallActionNew);
        }

        [CustomAction]
        public static ActionResult PowerShellScriptsElevatedDeferred(Session session)
        {
            return ExecuteScriptsFromXmlDataProperty(session, PowerShellScriptsElevatedDeferredProperty, InstallActionNew);
        }

        [CustomAction]
        public static ActionResult PowerShellUpgradeFilesImmediate(Session session)
        {
            session.Log("Upgrade PowerShellFilesImmediate start");
            return GetScriptFilesFromMsiDatabase(session, 0, PowerShellUpgradeFilesDeferredProperty, InstallActionUpgrade);
        }

        [CustomAction]
        public static ActionResult PowerShellUpgradeFilesDeferred(Session session)
        {
            session.Log("Upgrade PowerShellFilesDeferred start");
            return ExecuteScriptFilesFromXmlDataProperty(session, PowerShellUpgradeFilesDeferredProperty, InstallActionUpgrade);
        }

        [CustomAction]
        public static ActionResult PowerShellUninstallFilesImmediate(Session session)
        {
            session.Log("Uninstall PowerShellFilesImmediate start");
            return GetScriptFilesFromMsiDatabase(session, 0, PowerShellUninstallFilesDeferredProperty, InstallActionRemove);
        }

        [CustomAction]
        public static ActionResult PowerShellUninstallFilesDeferred(Session session)
        {
            session.Log("Uninstall PowerShellFilesDeferred start");
            return ExecuteScriptFilesFromXmlDataProperty(session, PowerShellUninstallFilesDeferredProperty, InstallActionRemove);
        }

        private static ActionResult GetScriptsFromMsiDatabase(Session session, int elevated, string XmlDataProperty, string installAction)
        {
            Database db = session.Database;

            if (!db.Tables.Contains("PowerShellScripts"))
                return ActionResult.Success;

            try
            {
                CustomActionData data;
                using (View view = db.OpenView(string.Format("SELECT `Id`, `Script` FROM `PowerShellScripts` WHERE `Elevated` = {0}", elevated)))
                {
                    view.Execute();

                    data = new CustomActionData();

                    Record row = view.Fetch();

                    while (row != null)
                    {
                        string script = Encoding.Unicode.GetString(Convert.FromBase64String(row["Script"].ToString()));
                        script = session.Format(script);
                        script = Convert.ToBase64String(Encoding.Unicode.GetBytes(script));

                        data.Add(row["Id"].ToString(), script);
                        session.Log("Adding {0} to CustomActionData", row["Id"]);

                        row = view.Fetch();
                    }
                }

                session[XmlDataProperty] = data.ToString();

                // Tell the installer to increase the value of the final total
                // length of the progress bar by the total number of ticks in
                // the custom action.
                MessageResult iResult;
                using (var hProgressRec = new Record(2))
                {
                    hProgressRec[1] = 3;
                    hProgressRec[2] = TotalTicks;
                    iResult = session.Message(InstallMessage.Progress, hProgressRec);
                }

                if (iResult == MessageResult.Cancel)
                {
                    return ActionResult.UserExit;
                }

                return ActionResult.Success;
            }
            catch (Exception ex)
            {
                session.Log(ex.ToString());
                return ActionResult.Failure;
            }
            finally
            {
                db.Close();
            }
        }

        private static ActionResult ExecuteScriptsFromXmlDataProperty(Session session, string XmlDataProperty, string installAction)
        {
            MessageResult iResult;
            using (var hActionRec = new Record(3))
            {
                hActionRec[1] = XmlDataProperty;
                hActionRec[2] = "Setup Scripts";
                hActionRec[3] = "[1] of [2], [3]";
                iResult = session.Message(InstallMessage.ActionStart, hActionRec);
            }

            if (iResult == MessageResult.Cancel)
            {
                return ActionResult.UserExit;
            }

            // Tell the installer to use explicit progress messages.
            using (var hProgressRec = new Record(3))
            {
                hProgressRec[1] = 1;
                hProgressRec[2] = 1;
                hProgressRec[3] = 0;
                iResult = session.Message(InstallMessage.Progress, hProgressRec);
            }

            if (iResult == MessageResult.Cancel)
            {
                return ActionResult.UserExit;
            }

            try
            {
                CustomActionData data = session.CustomActionData;

                foreach (var datum in data)
                {
                    string script = Encoding.Unicode.GetString(Convert.FromBase64String(datum.Value));
                    session.Log("Executing PowerShell script:\n{0}", script);

                    using (var task = new PowerShellTask(script, session))
                    {
                        var result = task.Execute();
                        session.Log("PowerShell non-terminating errors: {0}", !result);

                        if (!result)
                        {
                            session.Log("Returning Failure");

                            return ActionResult.Failure;
                        }
                    }
                }

                return ActionResult.Success;
            }
            catch (Exception ex)
            {
                session.Log("PowerShell terminating error, returning Failure");
                session.Log(ex.ToString());
                return ActionResult.Failure;
            }
        }

        private static ActionResult GetScriptFilesFromMsiDatabase(Session session, int elevated, string XmlDataProperty, string installAction)
        {
            Database db = session.Database;

            const string tableName = "PowerShellFiles";
            if (!db.Tables.Contains(tableName))
                return ActionResult.Success;

            try
            {
                XDocument doc;
                using (View view = db.OpenView(string.Format("SELECT `Id`, `File`, `Arguments`, `IgnoreErrors`, `InstallAction` FROM `{0}` WHERE `Elevated` = {1}", tableName, elevated)))
                {
                    view.Execute();

                    doc = new XDocument(new XDeclaration("1.0", "utf-16", "yes"), new XElement("r"));

                    foreach (Record row in view)
                    {
                        var args = session.Format(row["Arguments"].ToString());
                        var instAction = session.Format(row["InstallAction"].ToString());
                        var IgnoreErrors = session.Format(row["IgnoreErrors"].ToString());

                        session.Log("args '{0}'", args);
                        session.Log("InstallAction '{0}'", installAction);
                        session.Log("InstallAction in file '{0}'", instAction);

                        if (instAction == installAction)
                        {
                            session.Log("Adding InstallAction in file '{0}'", instAction);

                            doc.Root.Add(new XElement("d", 
                                new XAttribute("Id", row["Id"]),
                                new XAttribute("file", session.Format(row["File"].ToString())), 
                                new XAttribute("args", args), 
                                new XAttribute("IgnoreErrors", IgnoreErrors), 
                                new XAttribute("InstallAction", instAction)));
                        }
                    }
                }

                var cad = new CustomActionData { { "xml", doc.ToString() } };

                session[XmlDataProperty] = cad.ToString();

                // Tell the installer to increase the value of the final total
                // length of the progress bar by the total number of ticks in
                // the custom action.
                MessageResult iResult;
                using (var hProgressRec = new Record(2))
                {
                    hProgressRec[1] = 3;
                    hProgressRec[2] = TotalTicks;
                    iResult = session.Message(InstallMessage.Progress, hProgressRec);
                }

                if (iResult == MessageResult.Cancel)
                {
                    return ActionResult.UserExit;
                }

                return ActionResult.Success;
            }
            catch (Exception ex)
            {
                session.Log(ex.Message);
                return ActionResult.Failure;
            }
            finally
            {
                db.Close();
            }
        }

        private static ActionResult ExecuteScriptFilesFromXmlDataProperty(Session session, string XmlDataProperty, string installAction)
        {

            // Installer is executing the installation script. Set up a
            // record specifying appropriate templates and text for
            // messages that will inform the user about what the custom
            // action is doing. Tell the installer to use this template and
            // text in progress messages.
            MessageResult iResult;
            using (var hActionRec = new Record(3))
            {
                hActionRec[1] = XmlDataProperty;
                hActionRec[2] = "Setup Files";
                hActionRec[3] = "[1] of [2], [3]";
                iResult = session.Message(InstallMessage.ActionStart, hActionRec);
            }

            if (iResult == MessageResult.Cancel)
            {
                return ActionResult.UserExit;
            }

            // Tell the installer to use explicit progress messages.
            using (var hProgressRec = new Record(3))
            {
                hProgressRec[1] = 1;
                hProgressRec[2] = 1;
                hProgressRec[3] = 0;
                iResult = session.Message(InstallMessage.Progress, hProgressRec);
            }

            if (iResult == MessageResult.Cancel)
            {
                return ActionResult.UserExit;
            }

            try
            {
                if (!session.CustomActionData.ContainsKey("xml"))
                {
                    session.Log("Skipping as no CustomActionData key 'xml'");
                    return ActionResult.NotExecuted;
                }

                string content = session.CustomActionData["xml"];

                XDocument doc = XDocument.Parse(content);

                foreach (XElement row in doc.Root.Elements("d"))
                {
                    string file = row.Attribute("file").Value;

                    string arguments = row.Attribute("args").Value;
                    string IgnoreErrors = row.Attribute("IgnoreErrors").Value;
                    string action = row.Attribute("InstallAction").Value;

                    //if (action == installAction)
                    //{
                        using (var task = new PowerShellTask(file, arguments, session))
                        {
                            try
                            {
                                bool result = task.Execute();
                                session.Log("PowerShell non-terminating errors: {0}", !result);
                                if (!result)
                                {
                                    if (!IgnoreErrors.Equals("0"))
                                    {
                                        session.Log("Ignoring failure due to 'IgnoreErrors' marking");
                                    }
                                    else
                                    {
                                        session.Log("Returning Failure");
                                        return ActionResult.Failure;
                                    }
                                }
                            }
                            catch (Exception ex)
                            {
                                if (!IgnoreErrors.Equals("0"))
                                {
                                    session.Log("Ignoring PowerShell error due to 'IgnoreErrors' marking");
                                    session.Log(ex.ToString());
                                }
                                else
                                {
                                    session.Log("PowerShell terminating error, returning Failure");
                                    session.Log(ex.ToString());
                                    return ActionResult.Failure;
                                }
                            }
                        }
                    }
                //}

                return ActionResult.Success;
            }
            catch (Exception ex)
            {
                session.Log("PowerShell terminating error, returning Failure");
                session.Log(ex.ToString());
                return ActionResult.Failure;
            }
        }

    }
}