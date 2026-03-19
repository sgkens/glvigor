function Register-LabelSet {
    
    param(
        [parameter(Mandatory=$true)]
        [int]$ProjectID,
        [string]$gitlab_host
    )
    
    begin {
        # Define local function to convert RGB array to HEX code
        function Convert-RGBToHex {
            param ([int[]]$RGB)
            return "#{0:X2}{1:X2}{2:X2}" -f $RGB[0], $RGB[1], $RGB[2]
        }
    }

    process {

        # Define your GitLab instance details
        if(!$gitlab_host) { $gitlab_host = 'gitlab.com'}
        
        $GitLabUrl = "https://$gitlab_host"
        $AccessToken = $ENV:GITLAB_API_KEY

        # Load the labels with colors from the JSON file
        $LabelsFile = ".\gitlab_labels_with_colors.json"
        $Labels = Get-Content -Path $LabelsFile | ConvertFrom-Json

        # Iterate over each category and label to add them to the GitLab project
        foreach ($Category in $Labels.PSObject.Properties.Name) {
            foreach ($Label in $Labels.$Category.PSObject.Properties.Name) {
                $RGBColor = $Labels.$Category.$Label
                $HexColor = Convert-RGBToHex -RGB $RGBColor

                # Create the label
                $LabelData = @{
                    name  = $Label
                    color = $HexColor
                }

                $Response = Invoke-RestMethod -Method Post -Uri "$GitLabUrl/api/v4/projects/$ProjectId/labels" -Headers @{
                    "PRIVATE-TOKEN" = $AccessToken
                } -Body ($LabelData | ConvertTo-Json -Depth 10) -ContentType "application/json"

                if ($Response) {
                    [Console]::WriteLine("Label '$Label' created successfully with color '$HexColor' for projectid '$projectid'")
                }
                else {
                    [Console]::WriteLine("Failed to create label '$Label'.")
                }
            }
        }

        [Console]::WriteLine("All labels created successfully.")

    }
}

Register-LabelSet -ProjectID 76097034