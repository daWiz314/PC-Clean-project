$test = @(
"Verification 98% complete.",
"Verification 99% complete.",
"Verification 99% complete.",
"Verification 100% complete.",
"Windows Resource Protection did not find any integrity violations.")

$cleaned_test = @()

foreach ($message in $test) {
    if ($message -match "(Verification \d{1,3}% complete\.)") {
        Write-Host "Matched: $($matches[0])"
    } else {
        $cleaned_test += $message
    }
}

foreach ($message in $cleaned_test) {
    Write-Host "Cleaned: $message"
}