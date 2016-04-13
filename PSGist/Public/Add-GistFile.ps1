Function New-Gist {
    [CmdletBinding(
        DefaultParameterSetName = '__AllParameterSets'
    )]
    [OutputType(
        [Gist]
    )]

    Param (
        [Parameter(
            Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true
        )]
        [String[]]
        $Id,

        [Parameter(
            HelpMessage = 'Path to file(s) where the content will be used for the Gist.', 
            Mandatory = $true, 
            ParameterSetName = 'Files', 
            ValueFromPipeline = $true
        )]
        [ValidateScript({ 
            if (Test-Path -Path $_) { 
                $true 
            } else { 
                throw "Cannot find path: '$_' because it does not exist." 
            }
        })]
        # TODO: Perhaps allow a path to a folder, and then create one Gist with all the files in the top level of the directory?  Just a thought, but for now, no folders.
        # Get-ChildItem -Path $_ -File
        [ValidateScript({ 
            if (-not (Get-Item -Path $_).PSIsContainer) { 
                $true 
            } else { 
                throw "Path must be to a file." 
            }
        })]
        [String[]]
        $Path,

        [Parameter()]
        [Switch]
        $UriToClip
    )

    DynamicParam {
        # Only present this parameter set if running the PowerShell ISE.
        if ($psISE -ne $null) {
            # Build Attributes for the IseScriptPane Parameter.
            $iseScriptPaneAttributes = New-Object -TypeName System.Management.Automation.ParameterAttribute -Property @{
                HelpMessage = 'Captures the current active ISE Script Pane as Gist content.'
                Mandatory = $true
                ParameterSetName = 'IseScriptPane'
            }
            # Build Collection Object to hold Parameter Attributes.
            $iseScriptPaneCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
            $iseScriptPaneCollection.Add($iseScriptPaneAttributes)
            # Build Runtime Parameter with Collection Parameter Attributes.
            $iseScriptPaneParameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter  -ArgumentList ('IseScriptPane', [Switch], $iseScriptPaneCollection)

            # Build Attributes for GistFileName Parameter.
            $gistFileNameAttributes = New-Object -TypeName System.Management.Automation.ParameterAttribute -Property @{
                HelpMessage = 'The name of the Gist file.'
                ParameterSetName = 'IseScriptPane'
            }
            # Build Collection Object to hold Parameter Attributes. 
            $gistFileNameCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
            $gistFileNameCollection.Add($gistFileNameAttributes)
            # Build Runtime Parameter with Collection Parameter Attributes.
            $gistFileNameParameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList ('GistFileName', [String], $gistFileNameCollection)
            
            # Build Runtime Dictionary and add Runtime Parameters to it.
            $dictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
            $dictionary.Add('IseScriptPane', $iseScriptPaneParameter)
            $dictionary.Add('GistFileName', $gistFileNameParameter)
            # Return dictionary of Runtime Paramters to the PSCmdlet.
            return $dictionary
        }
    }
    
    Process {
        foreach ($item in $Id) {
            [HashTable]$body = @{
                files = @{}
            }

            if ($PSCmdlet.ParameterSetName -ne 'IseScriptPane') {
                foreach ($file in $Path) {
                    $body.files.Add($(Split-Path -Path $file -Leaf), @{ content = ((Get-Content -Path $file -Raw).PSObject.BaseObject) })
                }
            } else {
                if ([String]::IsNullOrEmpty($PSBoundParameters.GistFileName)) {
                    $PSBoundParameters.GistFileName = $psISE.CurrentPowerShellTab.Files.SelectedFile.DisplayName.TrimEnd('*')
                }
                $body.files.Add($PSBoundParameters.GistFileName, @{ content = $psISE.CurrentPowerShellTab.Files.SelectedFile.Editor.Text })
            }

            $apiCall = @{
                Body = ConvertTo-Json -InputObject $body
                RestMethod = 'gists/{0}' -f $item
                Method = 'PATCH'
            }
        
            $gist = [Gist]::new((Invoke-GistApi @apiCall))

            if ($UriToClip.IsPresent) {
                $gist | Select-Object -ExpandProperty AbsoluteUri | Clip
            }

            Write-Output $gist
        }
    }
}
