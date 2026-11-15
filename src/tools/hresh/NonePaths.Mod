MODULE NonePaths;

IMPORT SharedModules;

PROCEDURE Get*(VAR path: ARRAY OF CHAR);
BEGIN COPY(SharedModules.path, path)
END Get;

END NonePaths.
