# Real-time Webhook Monitor for Day 2 Testing
# This script helps monitor webhook activity during Zoho integration testing

param(
    [Parameter(Mandatory=$true)]
    [string]$VMIpAddress,
    [int]$RefreshInterval = 5
)

Write-Host "🔍 Real-time Webhook Monitor" -ForegroundColor Cyan
Write-Host "VM IP: $VMIpAddress" -ForegroundColor Yellow
Write-Host "Refresh every $RefreshInterval seconds" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow
Write-Host "=" * 50

$ApiUrl = "http://${VMIpAddress}:5000"
$previousStats = $null

while ($true) {
    try {
        Clear-Host
        Write-Host "🔍 Personal AI Assistant - Webhook Monitor" -ForegroundColor Cyan
        Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
        Write-Host "API: $ApiUrl" -ForegroundColor Gray
        Write-Host "=" * 60

        # Get current stats
        $currentStats = Invoke-RestMethod -Uri "${ApiUrl}/stats" -Method Get -TimeoutSec 5
        
        # Display key metrics
        Write-Host "📊 API Statistics:" -ForegroundColor Green
        Write-Host "  Total Requests: $($currentStats.total_requests)" -ForegroundColor White
        Write-Host "  Successful: $($currentStats.successful_requests)" -ForegroundColor Green
        Write-Host "  Failed: $($currentStats.failed_requests)" -ForegroundColor $(if ($currentStats.failed_requests -gt 0) { "Red" } else { "White" })
        Write-Host "  Active Sessions: $($currentStats.active_sessions)" -ForegroundColor Cyan
        
        # Calculate request rate if we have previous stats
        if ($previousStats) {
            $requestDiff = $currentStats.total_requests - $previousStats.total_requests
            $rate = $requestDiff / $RefreshInterval
            Write-Host "  Request Rate: $([math]::Round($rate, 2)) req/sec" -ForegroundColor Yellow
        }
        
        Write-Host ""
        
        # Memory usage
        if ($currentStats.memory_usage) {
            Write-Host "💾 Memory Usage:" -ForegroundColor Blue
            Write-Host "  Conversations: $($currentStats.memory_usage.active_conversations)" -ForegroundColor White
            Write-Host "  Total Messages: $($currentStats.memory_usage.total_messages)" -ForegroundColor White
        }
        
        Write-Host ""
        
        # Health check
        Write-Host "❤️  Health Status:" -ForegroundColor Magenta
        try {
            $health = Invoke-RestMethod -Uri "${ApiUrl}/health" -Method Get -TimeoutSec 3
            Write-Host "  API: ✅ Healthy" -ForegroundColor Green
            Write-Host "  Model: $($health.model)" -ForegroundColor White
            Write-Host "  Uptime: $($health.uptime)" -ForegroundColor White
        } catch {
            Write-Host "  API: ❌ Unhealthy" -ForegroundColor Red
        }
        
        Write-Host ""
        
        # Recent activity indicator
        if ($previousStats -and $currentStats.total_requests -gt $previousStats.total_requests) {
            Write-Host "🟢 NEW ACTIVITY DETECTED!" -ForegroundColor Green -BackgroundColor Black
            Write-Host "   $(($currentStats.total_requests - $previousStats.total_requests)) new requests in last $RefreshInterval seconds"
        } else {
            Write-Host "🔵 Waiting for webhook activity..." -ForegroundColor Blue
        }
        
        Write-Host ""
        Write-Host "=" * 60
        Write-Host "💡 Testing Tips:" -ForegroundColor Yellow
        Write-Host "  • Send test messages through Zoho chat widget"
        Write-Host "  • Run: .\test_zoho_webhook.ps1 $VMIpAddress"
        Write-Host "  • Check browser console for widget errors"
        Write-Host "  • Monitor failed_requests for issues"
        
        $previousStats = $currentStats
        
    } catch {
        Write-Host "❌ Failed to connect to API: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   Please check if API is running on $ApiUrl" -ForegroundColor Red
    }
    
    # Wait before next refresh
    Start-Sleep -Seconds $RefreshInterval
}
