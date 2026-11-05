MODULE CheckInstallation;
IMPORT Modules, Out;
BEGIN
  ASSERT(Modules.BinaryDir # "");
  Out.String("Windows installation check passed."); Out.Ln
END CheckInstallation.
