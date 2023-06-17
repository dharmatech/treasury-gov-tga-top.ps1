
Param($date, [switch]$html, [switch]$data, [switch]$charts = $false)

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
# ----------------------------------------------------------------------
if ($data) { $result_raw.data; exit }
# ----------------------------------------------------------------------
# $fields = @('record_date', 
#     # 'transaction_type',
#     'transaction_catg',
#     # 'transaction_catg_desc', 
#     'transaction_today_amt', 'transaction_mtd_amt', 'transaction_fytd_amt')

$fields = @(
    'record_date'
    'transaction_catg'
    @{ Expression = 'transaction_today_amt'; Format = 'N0'}
    @{ Expression = 'transaction_mtd_amt';   Format = 'N0'}
    @{ Expression = 'transaction_fytd_amt';  Format = 'N0'}
)

Write-Host
Write-Host 'DEPOSITS' -NoNewline
($result_raw.data | Where-Object transaction_type -EQ Deposits    | Sort-Object transaction_today_amt -Descending | Select-Object -First 15) +
'' +
'WITHDRAWALS' +
($result_raw.data | Where-Object transaction_type -EQ Withdrawals | Sort-Object transaction_today_amt -Descending | Select-Object -First 15) | ft $fields
# ----------------------------------------------------------------------
$public_debt_issues      = [decimal]($result_raw.data | Where-Object transaction_catg -EQ 'Public Debt Cash Issues (Table IIIB)' )[0].transaction_today_amt
$public_debt_redemptions = [decimal]($result_raw.data | Where-Object transaction_catg -EQ 'Public Debt Cash Redemp. (Table IIIB)')[0].transaction_today_amt

$public_debt_change = $public_debt_issues - $public_debt_redemptions


# ----------------------------------------------------------------------
$sub_total_deposits    = [decimal]($result_raw.data | Where-Object transaction_catg -EQ 'Sub-Total Deposits' )[0].transaction_today_amt
$sub_total_withdrawals = [decimal]($result_raw.data | Where-Object transaction_catg -EQ 'Sub-Total Withdrawals')[0].transaction_today_amt

$sub_total_change = $sub_total_deposits - $sub_total_withdrawals


# ----------------------------------------------------------------------
$total_deposits    = ($result_raw.data | Where-Object transaction_type -EQ Deposits    | Where-Object transaction_catg -EQ 'null')[0].transaction_today_amt
$total_withdrawals = ($result_raw.data | Where-Object transaction_type -EQ Withdrawals | Where-Object transaction_catg -EQ 'null')[0].transaction_today_amt

$total_change = $total_deposits - $total_withdrawals


function val-to-color ($val)
{
    if     ($val -gt 0) { 'Green' }
    elseif ($val -lt 0) { 'Red'   }
    else                { 'White' }
}

Write-Host 'Public debt change:     ' -ForegroundColor Yellow -NoNewline;    Write-Host ('{0,10:N0}' -f $public_debt_change) -ForegroundColor (val-to-color $public_debt_change)
Write-Host 'Deposits - withdrawals: ' -ForegroundColor Yellow -NoNewline;    Write-Host ('{0,10:N0}' -f $sub_total_change  ) -ForegroundColor (val-to-color $sub_total_change)
Write-Host 'Total change:           ' -ForegroundColor Yellow -NoNewline;    Write-Host ('{0,10:N0}' -f $total_change      ) -ForegroundColor (val-to-color $total_change)

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

if ($charts)
{
    chart Deposits    -count 30
    chart Withdrawals -count 30
}


# chart Deposits -count 30

# chart Deposits transaction_fytd_amt 20
# ----------------------------------------------------------------------
# html-tag
# ----------------------------------------------------------------------
function html-tag ($tag_name, $children, $attrs)
{
    $tag = if ($attrs -eq $null)
    {
        '<{0}>' -f $tag_name
    }
    else
    {
        $result = foreach ($item in $attrs.GetEnumerator())
        {
            '{0}="{1}"' -f $item.Name, $item.Value
        }
        
        '<{0} {1}>' -f $tag_name, ($result -join ' ')
    }

    $close = '</{0}>' -f $tag_name

    if ($children -eq $null)
    {
        $tag
        $close
    }
    elseif ($children.GetType().Name -eq 'Object[]')
    {
        $tag
        foreach ($child in $children)
        {
            $child
        }
        $close
    }
    elseif ($children.GetType().Name -eq 'String')
    {
        $tag
        $children
        $close
    }
    else
    {
        $tag
        $children
        $close
    }
}

function h-h1 ($children, $attrs) { html-tag 'h1' $children $attrs }
function h-h2 ($children, $attrs) { html-tag 'h2' $children $attrs }
function h-h3 ($children, $attrs) { html-tag 'h3' $children $attrs }

function h-table ($children, $attrs) { html-tag 'table' $children $attrs }
function h-thead ($children, $attrs) { html-tag 'thead' $children $attrs }
function h-tbody ($children, $attrs) { html-tag 'tbody' $children $attrs }
function h-th ($children, $attrs) { html-tag 'th' $children $attrs }
function h-tr ($children, $attrs) { html-tag 'tr' $children $attrs }
function h-td ($children, $attrs) { html-tag 'td' $children $attrs }
# ----------------------------------------------------------------------
# html
# ----------------------------------------------------------------------
# if ($html)
# {
#     $deposits = ($result_raw.data | Where-Object transaction_type -EQ Deposits | Sort-Object transaction_today_amt -Descending | Select-Object -First 15)

#     # $deposits | ft $fields
            
#     h-table -attrs @{ class = 'table table-sm'; 'data-toggle' = 'table'; 'data-height' = '500'} -children `
#         (h-thead (h-tr @(
#             foreach ($elt in 'record_date', 'transaction_catg', 'transaction_today_amt', 'transaction_mtd_amt', 'transaction_fytd_amt')
#             {
#                 h-th $elt @{ scope='col' }
#             }
#         ))),
#         (h-tbody @(
#             foreach ($row in $deposits)
#             {
#                 h-tr `
#                     (h-td $row.record_date),
#                     (h-td $row.transaction_catg),
#                     (h-td $row.transaction_today_amt.ToString('N0') @{ class='text-end' }),
#                     (h-td $row.transaction_mtd_amt   @{ class='text-end' }),
#                     (h-td $row.transaction_fytd_amt  @{ class='text-end' })
#             }
#         )) > .\treasury-gov-tga-top-partial.html
# }


function generate-table ($items)
{
    h-table -attrs @{ class = 'table table-sm'; 'data-toggle' = 'table'; 'data-height' = '400'} -children `
        (h-thead (h-tr @(
            foreach ($elt in 'record_date', 'transaction_catg', 'transaction_today_amt', 'transaction_mtd_amt', 'transaction_fytd_amt')
            {
                h-th $elt @{ scope='col' }
            }
        ))),
        (h-tbody @(
            foreach ($row in $items)
            {
                h-tr `
                    (h-td $row.record_date),
                    (h-td $row.transaction_catg),
                    (h-td $row.transaction_today_amt.ToString('N0') @{ class='text-end' }),
                    (h-td $row.transaction_mtd_amt.ToString('N0')   @{ class='text-end' }),
                    (h-td $row.transaction_fytd_amt.ToString('N0')  @{ class='text-end' })
            }
        ))
}



if ($html)
{
    $deposits    = ($result_raw.data | Where-Object transaction_type -EQ Deposits    | Sort-Object transaction_today_amt -Descending)
    $withdrawals = ($result_raw.data | Where-Object transaction_type -EQ Withdrawals | Sort-Object transaction_today_amt -Descending)
    # $deposits | ft $fields
 
 
    (h-h3 'Deposits') + 
    (generate-table $deposits) + 
    (h-h3 'Withdrawals') + 
    (generate-table $withdrawals) > .\treasury-gov-tga-top-partial.html
}
# ----------------------------------------------------------------------
exit
# ----------------------------------------------------------------------
.\treasury-gov-tga-top.ps1 -date '2023-01-24'
.\treasury-gov-tga-top.ps1 -date '2023-04-18'
.\treasury-gov-tga-top.ps1 -date '2023-05-02'



chart Deposits    transaction_fytd_amt 30
chart Withdrawals transaction_fytd_amt 30




Write-Host
Write-Host 'DEPOSITS' -NoNewline
($result_raw.data | Where-Object transaction_type -EQ Deposits    | Sort-Object transaction_today_amt -Descending | Select-Object -First 20) +
'' +
'WITHDRAWALS' +
($result_raw.data | Where-Object transaction_type -EQ Withdrawals | Sort-Object transaction_today_amt -Descending | Select-Object -First 20) | ft $fields





# ----------------------------------------------------------------------
Write-Host
Write-Host 'DEPOSITS' -NoNewline
($result_raw.data | Where-Object transaction_type -EQ Deposits    | Sort-Object transaction_today_amt -Descending | Select-Object -First 15) +
'' +
'WITHDRAWALS' +
($result_raw.data | Where-Object transaction_type -EQ Withdrawals | Sort-Object transaction_today_amt -Descending | Select-Object -First 15) | ft $fields




($result_raw.data | Where-Object transaction_type -EQ Deposits    | Sort-Object transaction_today_amt -Descending | Select-Object -First 15) | ft $fields
($result_raw.data | Where-Object transaction_type -EQ Withdrawals | Sort-Object transaction_today_amt -Descending | Select-Object -First 15) | ft $fields





Write-Host 'DEPOSITS' -NoNewline
($result_raw.data | Where-Object transaction_type -EQ Deposits    | Sort-Object transaction_fytd_amt -Descending | Select-Object -First 15) +
'' +
'WITHDRAWALS' +
($result_raw.data | Where-Object transaction_type -EQ Withdrawals | Sort-Object transaction_fytd_amt -Descending | Select-Object -First 15) | ft $fields




# ----------------------------------------------------------------------
$base = 'https://api.fiscaldata.treasury.gov/services/api/fiscal_service/v1/accounting/dts'

# $rest_url = '/dts_table_2?filter=record_date:gte:{0},transaction_catg:eq:{1}&page[number]=1&page[size]=300'

$rest_url = '/dts_table_2?filter=record_date:gte:{0},transaction_catg:eq:{1},transaction_catg_desc:eq:{2}&page[number]=1&page[size]=300'

# $rest_url = '/dts_table_2?filter=record_date:gte:{0},transaction_catg:eq:{1},transaction_today_amt:gte:{2}&fields=record_date,transaction_type,transaction_catg,transaction_today_amt&page[number]=1&page[size]=900'

$result_raw = Invoke-RestMethod -Method Get -Uri ($base + $rest_url -f '2020-01-01', 'Other Withdrawals', 'Military Retirement (EFT)')



@(
    'record_date:gte:{0}'           -f '2020-01-01'
    'transaction_catg:eq:{0}'       -f 'Other Withdrawals'
    'transaction_catg_desc:eq:{0}'  -f 'Military Retirement (EFT)'
) -join ','

$result_raw


