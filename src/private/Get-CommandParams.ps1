Function Get-CommandParams {
    <#
    .SYNOPSIS
        Get available parameters for a command.
    .DESCRIPTION
        Get available parameters for a command. This skips default parameters.
    #>
    [System.Diagnostics.DebuggerStepThrough()]
    param(
        # The name of the command being proxied.
        [System.String]
        $CommandName,

        # The type of the command being proxied. Valid values include 'Cmdlet' or 'Function'.
        [System.Management.Automation.CommandTypes]
        $CommandType
    )
    try {
        # Look up the command being proxied.
        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand($CommandName, $CommandType)

        #If the command was not found, throw an appropriate command not found exception.
        if (-not $wrappedCmd) {
            $PSCmdlet.ThrowCommandNotFoundError($CommandName, $PSCmdlet.MyInvocation.MyCommand.Name)
        }

        # Lookup the command metadata.
        (New-Object -TypeName System.Management.Automation.CommandMetadata -ArgumentList $wrappedCmd).Parameters.Keys
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}