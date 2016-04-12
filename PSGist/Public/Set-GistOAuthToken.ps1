Function Set-GistOAuthToken {
    [CmdletBinding()]

    Param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [String]
        $Token
    )

    Process {
        try {
            $env:GIST_OAUTH_TOKEN = $Token
            [Environment]::SetEnvironmentVariable('GIST_OAUTH_TOKEN', $Token, 'User')

            Write-Output -InputObject "OAuth Token Value: $env:GIST_OAUTH_TOKEN"
        } catch {
            Write-Error -Message $_.ToString() -ErrorAction Stop
        }
    }
}