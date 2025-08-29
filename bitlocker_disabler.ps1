while ($true) {
    $volumes = Get-BitLockerVolume
    
    foreach ($vol in $volumes) {
        $drive = $vol.MountPoint
        $prot = $vol.ProtectionStatus
        $status = $vol.VolumeStatus
        $autoUnlock = $vol.AutoUnlockEnabled

        # Se estiver criptografando, interrompe e força descriptografia
        if ($status -eq 'EncryptionInProgress') {
            Write-Host "BitLocker está criptografando $drive. Interrompendo e iniciando descriptografia..."

            # Se for o drive do sistema (C:), precisa garantir que Auto-Unlock esteja desativado
            if ($drive -eq "C:") {
                Write-Host "Desabilitando Auto-Unlock em todos os volumes antes de desligar o BitLocker no SO..."
                Get-BitLockerVolume | Where-Object { $_.AutoUnlockEnabled -eq $true } | ForEach-Object {
                    Disable-BitLockerAutoUnlock -MountPoint $_.MountPoint
                    Write-Host "Auto-Unlock desabilitado em $($_.MountPoint)"
                }
            }

            Disable-BitLocker -MountPoint $drive
        }
        elseif ($prot -eq 'On' -and $status -ne 'DecryptionInProgress') {
            Write-Host "BitLocker detectado ativo em $drive (Status: $status). Desativando..."

            if ($drive -eq "C:") {
                Write-Host "Desabilitando Auto-Unlock em todos os volumes antes de desligar o BitLocker no SO..."
                Get-BitLockerVolume | Where-Object { $_.AutoUnlockEnabled -eq $true } | ForEach-Object {
                    Disable-BitLockerAutoUnlock -MountPoint $_.MountPoint
                    Write-Host "Auto-Unlock desabilitado em $($_.MountPoint)"
                }
            }

            Disable-BitLocker -MountPoint $drive
        }
        else {
            Write-Host "Drive $drive está em estado: $status (Protection: $prot). Nenhuma ação."
        }
    }

    Start-Sleep -Seconds 30
}
