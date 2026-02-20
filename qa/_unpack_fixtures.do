*! _unpack_fixtures.do
*! Extract YAML fixtures from fixtures.zip if not present
*! Called automatically by run_tests.do on first run
*! Date: 20Feb2026

* Check if fixtures need unpacking (use block_scalars.yaml as sentinel)
local qadir "`c(pwd)'/qa"
capture confirm file "`qadir'/fixtures/block_scalars.yaml"
if _rc != 0 {
    di as text "Extracting QA fixtures from fixtures.zip..."
    
    * Use PowerShell on Windows, unzip on Unix
    if "`c(os)'" == "Windows" {
        local cmd `"powershell -Command "Expand-Archive -Path '`qadir'/fixtures/fixtures.zip' -DestinationPath '`qadir'/fixtures' -Force""'
    }
    else {
        local cmd `"unzip -o '`qadir'/fixtures/fixtures.zip' -d '`qadir'/fixtures'"'
    }
    
    shell `cmd'
    
    * Verify extraction
    capture confirm file "`qadir'/fixtures/block_scalars.yaml"
    if _rc != 0 {
        di as error "ERROR: Failed to extract fixtures from fixtures.zip"
        di as error "Please manually extract qa/fixtures/fixtures.zip"
        error 601
    }
    
    di as result "Fixtures extracted successfully."
}
