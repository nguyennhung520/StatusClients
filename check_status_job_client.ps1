# Danh sách các máy client
$clientNames = @("01.PRINTER", "02.MOUNTER-1", "03.MOUNTER-2", "04.REFLOW-1", "05.SELECTIVE SOLDERING", "06.Soler Dispensing", "07.COATING MC-1", "08.UV CURING", "09.SPI", "10.AOI", "11.SELECTIVE VISION", "12.COATING INSPECTION", "13.BSI", "14.PCI")  # Thay bằng tên các máy client thực tế

# Đường dẫn đến script task
$taskName = "F:\IT_SYNOPEX\Server1ToServer2\Server1ToServer2\server1upload.ps1"

# Thời gian bắt đầu kiểm tra (ví dụ: 5 phút trước)
$startTime = (Get-Date).AddMinutes(-5)

foreach ($clientName in $clientNames) {
    try {
        # Lấy các sự kiện Task Scheduler từ client
        $logs = Get-WinEvent -ComputerName $clientName -LogName "Microsoft-Windows-TaskScheduler/Operational" `
            -FilterXPath "*[System[Provider[@Name='Microsoft-Windows-TaskScheduler'] and (EventID=100 or EventID=200)] and EventData[Data[@Name='TaskName'] and (Data='$taskName')]]" `
            -MaxEvents 10

        if ($logs) {
            # Lọc các sự kiện đã xảy ra trong khoảng thời gian kiểm tra
            $recentLogs = $logs | Where-Object { $_.TimeCreated -ge $startTime }
            
            if ($recentLogs) {
                # Lấy thời gian chạy gần nhất của job
                $lastRunEvent = $recentLogs | Sort-Object TimeCreated -Descending | Select-Object -First 1
                $lastRunTime = $lastRunEvent.TimeCreated
                Write-Host "Last run time for task $taskName on $clientName: $lastRunTime"
            } else {
                Write-Host "Task $taskName on $clientName has not run in the last 5 minutes."
            }
        } else {
            Write-Host "No logs found for task $taskName on $clientName."
        }
    } catch {
        Write-Host "Failed to retrieve logs from $clientName. Error: $_"
    }
}
