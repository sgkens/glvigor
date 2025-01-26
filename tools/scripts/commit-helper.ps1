<# Commit Fusion template file use to create large detailed commits #>
$params = @{
  Type              = "";
  # Scope             = "";
  Description       = "update gita|github repository registration cmdlets and mirror config cmdlets";
  Notes            = @()
  # Footer=$true
  GitUser           = "sgkens";
  GitGroup          = "phellams";
  # FeatureAdditions  = @()
  # BugFixes          = @();
  # BreakingChanges   = @();
  # FeatureNotes      = @();
  # AsString          = $true #Default is $true
  # footer            = $true
}

# ACTIONS
# -------

# ConventionalCommit with params sent commit
New-Commit @params

# ConventionalCommit with params sent commit
#New-Commit @Params | Set-Commit -Confirm

# ConventionalCommit with params, written to changelog and sent commit
#New-Commit @Params | Format-FusionMD | Update-ChangeLog -logfile .\changelog.md | Set-Commit -confirm