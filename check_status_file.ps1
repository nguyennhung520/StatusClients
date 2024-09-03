# Đường dẫn đến file log
$logFile = "F:\IT_SYNOPEX\CheckStatus\check_status_file_log.txt"

# Hàm ghi log
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "MM/dd/yyyy HH:mm:ss"
    "$timestamp - $message" | Out-File -FilePath $logFile -Append
}

# Định nghĩa cổng và địa chỉ IP mà server sẽ lắng nghe
$port = 8080
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://+:$port/")

# Bắt đầu server
try {
    $listener.Start()
    Write-Log "HTTP Server is running on port $port..."

    # Hàm xử lý yêu cầu HTTP
    function Handle-Request {
        param (
            [System.Net.HttpListenerContext]$context
        )

        $directoryPath = "F:\IT_Share"
        $folders = Get-ChildItem -Path $directoryPath -Directory

        $fileStatuses = $folders | ForEach-Object {
            [PSCustomObject]@{
                FileName     = $_.Name
                LastModified = $_.LastWriteTime.ToString("MM-dd-yyyy HH:mm:ss")
            }
        }

        # Chuyển đổi dữ liệu thành JSON
        $jsonResponse = $fileStatuses | ConvertTo-Json -Depth 2

        # Cài đặt mã trạng thái HTTP 200 (OK) và nội dung trả về là JSON
        $context.Response.StatusCode = 200
        $context.Response.ContentType = "application/json"
        
        # Thêm header CORS
        $context.Response.Headers.Add("Access-Control-Allow-Origin", "*")

        # Viết JSON vào stream của HTTP response
        $responseStream = [System.IO.StreamWriter]::new($context.Response.OutputStream)
        $responseStream.Write($jsonResponse)
        $responseStream.Flush()
        $responseStream.Close()
    }

    # Vòng lặp chính để xử lý các yêu cầu HTTP
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        Handle-Request -context $context
    }
} catch {
    Write-Log "Server error: $_"
} finally {
    # Đảm bảo server được dừng lại khi script kết thúc
    $listener.Stop()
    Write-Log "HTTP Server stopped."
}
