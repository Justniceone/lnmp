function list($token, $image, $ref, $header, $registry = "registry.hub.docker.com", $raw = $true, $return_digest_only = $false) {
  $manifest_header = "application/vnd.docker.distribution.manifest.v2+json"
  $manifest_list_header = "application/vnd.docker.distribution.manifest.list.v2+json"

  if (!$header) { $header = $manifest_list_header }

  $type = "manifest"

  if ($header -eq $manifest_list_header) { $type = "manifest list" }

  Write-host "==> Get [ $image $ref ] $type ..." -ForegroundColor Blue

  . $PSScriptRoot/../cache/cache.ps1

  if (!($ref -is [string])) {
    $ref = $ref.toString()
  }

  New-Item -force -type Directory (getCachePath manifests) | out-null
  $cache_file = getCachePath "manifests/$($ref.replace('sha256:','')).json"

  try {
    $result = Invoke-WebRequest `
      -Authentication OAuth `
      -Token (ConvertTo-SecureString $token -Force -AsPlainText) `
      -Headers @{"Accept" = "$header" } `
      "https://$registry/v2/$image/manifests/$ref" `
      -PassThru `
      -OutFile $cache_file `
      -UserAgent "Docker-Client/19.03.5 (Windows)"
  }
  catch {
    $result = $_.Exception.Response

    Write-Host "==> [error] Get [ $image $ref ] $type error [ $($result.StatusCode) ]" -ForegroundColor Red

    return $false
  }

  if ($result.Headers.'Content-Type' -ne $header) {
    Write-Host "==> [error] Get [ $image $ref ] $type error" -ForegroundColor Red

    return $false
  }

  write-host "==> $type digest is $($result.Headers.'Docker-Content-Digest')" -ForegroundColor Green

  if ($return_digest_only) {
    return $result.Headers.'Docker-Content-Digest'
  }

  if ($raw) {
    return ConvertFrom-Json (Get-Content $cache_file -Raw)
  }

  return $cache_file
}
