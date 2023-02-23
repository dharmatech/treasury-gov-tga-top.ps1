
$base = 'https://api.fiscaldata.treasury.gov/services/api/fiscal_service/v1/accounting/dts'

# $date = '2022-09-01'

# $date = '2022-12-01'
# $date = '2022-12-15'
# $date = '2022-12-16'

# $date = '2022-12-19'

$date = '2023-02-22'

$result_raw = Invoke-RestMethod -Method Get -Uri ($base + '/dts_table_2?filter=record_date:eq:{0}&page[number]=1&page[size]=300' -f $date)

foreach ($row in $result_raw.data)
{
    $row.transaction_fytd_amt  = [decimal]$row.transaction_fytd_amt
    $row.transaction_today_amt = [decimal]$row.transaction_today_amt
    $row.transaction_mtd_amt   = [decimal]$row.transaction_mtd_amt    
}

# $result_raw.data | ft *

# $result_raw.data | Where-Object transaction_type -EQ Deposits    | Sort-Object transaction_today_amt -Descending | ft *
# $result_raw.data | Where-Object transaction_type -EQ Withdrawals | Sort-Object transaction_today_amt -Descending | ft *
# 
# $result_raw.data | Where-Object transaction_type -EQ Deposits    | Sort-Object transaction_fytd_amt -Descending | ft *
# $result_raw.data | Where-Object transaction_type -EQ Withdrawals | Sort-Object transaction_fytd_amt -Descending | ft *

# $result_raw.data | Where-Object transaction_type -EQ Deposits    | Sort-Object transaction_today_amt -Descending | Select-Object -First 10 | ft *
# $result_raw.data | Where-Object transaction_type -EQ Withdrawals | Sort-Object transaction_today_amt -Descending | Select-Object -First 10 | ft *

# ($result_raw.data | Where-Object transaction_type -EQ Deposits    | Sort-Object transaction_today_amt -Descending | Select-Object -First 15) +
# '' +
# ($result_raw.data | Where-Object transaction_type -EQ Withdrawals | Sort-Object transaction_today_amt -Descending | Select-Object -First 15) | ft *

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