
Param($date)

function get-previous-weekday ()
{
    $i = -1

    while ((Get-Date).AddDays($i).DayOfWeek -in 'Saturday', 'Sunday')
    {
        $i = $i - 1
    }    

    Get-Date (Get-Date).AddDays($i) -Format 'yyyy-MM-dd'
}

if ($date -eq $null)
{
    $date = get-previous-weekday
}
# ----------------------------------------------------------------------
$base = 'https://api.fiscaldata.treasury.gov/services/api/fiscal_service/v1/accounting/dts'

$result_raw = Invoke-RestMethod -Method Get -Uri ($base + '/dts_table_2?filter=record_date:eq:{0}&page[number]=1&page[size]=300' -f $date)
# ----------------------------------------------------------------------
$i = -1

while ($true) 
{
    if ($result_raw.data.Count -eq 0)
    {
        Write-Host ('No data found for {0}. Trying earlier date.' -f $date) -ForegroundColor Yellow

        $date = Get-Date (Get-Date $date).AddDays($i) -Format 'yyyy-MM-dd'
      
        $result_raw = Invoke-RestMethod -Method Get -Uri ($base + '/dts_table_2?filter=record_date:eq:{0}&page[number]=1&page[size]=300' -f $date)

        $i = $i - 1
    }
    else
    {
        break
    }
}
# ----------------------------------------------------------------------
foreach ($row in $result_raw.data)
{
    $row.transaction_fytd_amt  = [decimal]$row.transaction_fytd_amt
    $row.transaction_today_amt = [decimal]$row.transaction_today_amt
    $row.transaction_mtd_amt   = [decimal]$row.transaction_mtd_amt    
}

$fields = @('record_date', 
    # 'transaction_type',
    'transaction_catg',
    # 'transaction_catg_desc', 
    'transaction_today_amt', 'transaction_mtd_amt', 'transaction_fytd_amt')
    
Write-Host
Write-Host 'DEPOSITS' -NoNewline
($result_raw.data | Where-Object transaction_type -EQ Deposits    | Sort-Object transaction_today_amt -Descending | Select-Object -First 15) +
'' +
'WITHDRAWALS' +
($result_raw.data | Where-Object transaction_type -EQ Withdrawals | Sort-Object transaction_today_amt -Descending | Select-Object -First 15) | ft $fields
# ----------------------------------------------------------------------
# chart
# ----------------------------------------------------------------------
function chart (
    [ValidateSet('Deposits', 'Withdrawals')]$type,
    [ValidateSet('transaction_today_amt', 'transaction_mtd_amt', 'transaction_fytd_amt')]$property = 'transaction_today_amt', 
    $count = 10)
{
    $items = $result_raw.data | 
        Where-Object transaction_type -EQ $type | 
        Where-Object transaction_catg -NotIn ('null', 'Sub-Total Withdrawals', 'Public Debt Cash Redemp. (Table IIIB)', 'Sub-Total Deposits', 'Public Debt Cash Issues (Table IIIB)') | 
        Sort-Object $property -Descending
    
    $table = $items | Select-Object -First $count
    
    $json = @{
        chart = @{
            type = 'doughnut'
            data = @{
                labels = $table.ForEach({ $_.transaction_catg })
                datasets = @(
                    @{ 
                        # data = $table.ForEach({ $_.$property }) 
                        data = $table.ForEach({ [math]::Round($_.$property / 1000, 1) }) 
                        backgroundColor = @("#4E79A7"
                                            "#F28E2B"
                                            "#E15759"
                                            "#76B7B2"
                                            "#59A14F"
                                            "#EDC948"
                                            "#B07AA1"
                                            "#FF9DA7"
                                            "#9C755F"
                                            "#BAB0AC"
                                            
                                            "#4E79A7"
                                            "#F28E2B"
                                            "#E15759"
                                            "#76B7B2"
                                            "#59A14F"
                                            "#EDC948"
                                            "#B07AA1"
                                            "#FF9DA7"
                                            "#9C755F"
                                            "#BAB0AC"

                                            "#4E79A7"
                                            "#F28E2B"
                                            "#E15759"
                                            "#76B7B2"
                                            "#59A14F"
                                            "#EDC948"
                                            "#B07AA1"
                                            "#FF9DA7"
                                            "#9C755F"
                                            "#BAB0AC"
                                            )
                    }
    
                )
            }
            options = @{
                
                title = @{ display = $true; text = ('TGA {2} (excluding public debt) {1} billions USD : {0} ' -f $items[0].record_date, $property, $type) }
    
                legend = @{ position = 'left' }
    
                plugins = @{
                    datalabels = @{ display = $true }
                }
            }
        }
    } | ConvertTo-Json -Depth 100
    
    $result = Invoke-RestMethod -Method Post -Uri 'https://quickchart.io/chart/create' -Body $json -ContentType 'application/json'
    
    # Start-Process $result.url
    
    $id = ([System.Uri] $result.url).Segments[-1]
    
    Start-Process ('https://quickchart.io/chart-maker/view/{0}' -f $id)
}

chart Deposits    -count 30
chart Withdrawals -count 30

# chart Deposits -count 30

# chart Deposits transaction_fytd_amt 20
# ----------------------------------------------------------------------
exit
# ----------------------------------------------------------------------