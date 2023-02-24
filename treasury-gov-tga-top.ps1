
# Param($date = (get-previous-weekday))

# Param($date = (&{
#     $i = -1

#     while ($true)
#     {
#         if ('Saturday', 'Sunday' -contains (Get-Date).AddDays($i).DayOfWeek)
#         {
#             $i = $i - 1
#         }
#         else
#         {
#             break
#         }
#     }    
    
#     Get-Date (Get-Date).AddDays($i) -Format 'yyyy-MM-dd'
# }))

Param($date)

# function get-previous-weekday ()
# {
#     $i = -1

#     while ($true)
#     {
#         if ('Saturday', 'Sunday' -contains (Get-Date).AddDays($i).DayOfWeek)
#         {
#             $i = $i - 1
#         }
#         else
#         {
#             return Get-Date (Get-Date).AddDays($i) -Format 'yyyy-MM-dd'
#         }
#     }    
# }


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


# (&{
#     $i = -1

#     while ($true)
#     {
#         if ('Saturday', 'Sunday' -contains (Get-Date).AddDays($i).DayOfWeek)
#         {
#             $i = $i - 1
#         }
#         else
#         {
#             break
#         }
#     }    
    
#     Get-Date (Get-Date).AddDays($i) -Format 'yyyy-MM-dd'
# })


$base = 'https://api.fiscaldata.treasury.gov/services/api/fiscal_service/v1/accounting/dts'

$result_raw = Invoke-RestMethod -Method Get -Uri ($base + '/dts_table_2?filter=record_date:eq:{0}&page[number]=1&page[size]=300' -f $date)


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

exit

# ----------------------------------------------------------------------
# Example invocation

.\treasury-gov-tga-top.ps1               # Default to previous weekday

.\treasury-gov-tga-top.ps1 '2023-02-23'  # Specify date