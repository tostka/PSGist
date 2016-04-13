function Remove-Gist {
    [CmdletBinding(
        ConfirmImpact = 'High', 
        SupportsShouldProcess = $true
    )]
    [OutputType(
        [Void]
    )]

    Param (
        [Parameter(
            Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true
        )]
        [String[]] 
        $Id
    )
    
    Process {
        foreach ($item in $Id) {
            if ($PSCmdlet.ShouldProcess($item)) {
                $apiCall = @{
                    #Body = ''
                    RestMethod = 'gists/{0}' -f $item
                    Method = 'DELETE'
                }
    
                Invoke-GistApi @apiCall
            }
        }
    }
}
