# Day 2: Zoho Webhook Testing Script (PowerShell)
# This script helps test your Zoho SalesIQ webhook integration

param(
    [Parameter(Mandatory=$true)]
    [string]$VMIpAddress
)

Write-Host "🧪 Testing Zoho SalesIQ Webhook Integration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Configuration
$ApiPort = "80"
$WebhookEndpoint = "/webhook/zoho"
$ApiUrl = "http://${VMIpAddress}:${ApiPort}"
$WebhookUrl = "${ApiUrl}${WebhookEndpoint}"

Write-Host "📍 Testing API at: $ApiUrl" -ForegroundColor Yellow
Write-Host "🔗 Webhook URL: $WebhookUrl" -ForegroundColor Yellow
Write-Host ""

# Test 1: Health Check
Write-Host "Test 1: Health Check" -ForegroundColor Green
Write-Host "-------------------" -ForegroundColor Green
Write-Host "🔍 Checking if API is running..."

try {
    $healthResponse = Invoke-RestMethod -Uri "${ApiUrl}/health" -Method Get -TimeoutSec 10
    Write-Host "✅ API is healthy" -ForegroundColor Green
    $healthResponse | ConvertTo-Json -Depth 3
    $healthPassed = $true
} catch {
    Write-Host "❌ API health check failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please ensure your API is running on port $ApiPort" -ForegroundColor Red
    $healthPassed = $false
}

Write-Host ""

# Test 2: Direct Chat Test
Write-Host "Test 2: Direct Chat Test" -ForegroundColor Green
Write-Host "------------------------" -ForegroundColor Green
Write-Host "🤖 Testing direct chat endpoint..."

try {
    $chatBody = @{
        message = "Hello! This is a test message."
    } | ConvertTo-Json

    $chatResponse = Invoke-RestMethod -Uri "${ApiUrl}/chat" -Method Post -Body $chatBody -ContentType "application/json" -TimeoutSec 30
    Write-Host "✅ Direct chat working" -ForegroundColor Green
    Write-Host "Response: $($chatResponse.response)"
    $chatPassed = $true
} catch {
    Write-Host "❌ Direct chat failed: $($_.Exception.Message)" -ForegroundColor Red
    $chatPassed = $false
}

Write-Host ""

# Test 3: Zoho Webhook Test
Write-Host "Test 3: Zoho Webhook Test" -ForegroundColor Green
Write-Host "-------------------------" -ForegroundColor Green
Write-Host "🔗 Testing Zoho webhook endpoint..."

try {
    $webhookBody = @{
        message = @{
            text = "Hello AI! This is a test from Zoho webhook."
            time = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        }
        visitor = @{
            id = "test_visitor_123"
            name = "Test User"
            email = "test@example.com"
        }
        department = @{
            id = "test_dept"
            name = "Support"
        }
        chat = @{
            id = "test_chat_session"
        }
    } | ConvertTo-Json -Depth 3

    $webhookResponse = Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $webhookBody -ContentType "application/json" -TimeoutSec 30
    Write-Host "✅ Zoho webhook working" -ForegroundColor Green
    Write-Host "Response:"
    $webhookResponse | ConvertTo-Json -Depth 3
    $webhookPassed = $true
} catch {
    Write-Host "❌ Zoho webhook failed: $($_.Exception.Message)" -ForegroundColor Red
    $webhookPassed = $false
}

Write-Host ""

# Test 4: Check Stats
Write-Host "Test 4: API Statistics" -ForegroundColor Green
Write-Host "---------------------" -ForegroundColor Green
Write-Host "📊 Checking API usage stats..."

try {
    $statsResponse = Invoke-RestMethod -Uri "${ApiUrl}/stats" -Method Get -TimeoutSec 10
    $statsResponse | ConvertTo-Json -Depth 3
} catch {
    Write-Host "❌ Failed to get stats: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Summary
Write-Host "🎯 Test Summary" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Cyan
Write-Host "Health Check: $(if ($healthPassed) { "✅ PASS" } else { "❌ FAIL" })"
Write-Host "Direct Chat:  $(if ($chatPassed) { "✅ PASS" } else { "❌ FAIL" })"
Write-Host "Zoho Webhook: $(if ($webhookPassed) { "✅ PASS" } else { "❌ FAIL" })"

Write-Host ""

if ($healthPassed -and $chatPassed -and $webhookPassed) {
    Write-Host "🎉 All tests passed! Your API is ready for Zoho integration." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Set up your Zoho SalesIQ account" -ForegroundColor Yellow
    Write-Host "2. Configure webhook URL: $WebhookUrl" -ForegroundColor Yellow
    Write-Host "3. Test with the chat widget" -ForegroundColor Yellow
} else {
    Write-Host "⚠️  Some tests failed. Please check your API configuration." -ForegroundColor Red
}

Write-Host ""
Write-Host "🔍 For detailed logs, check your API server output" -ForegroundColor Blue
Write-Host "📝 Webhook URL to configure in Zoho: $WebhookUrl" -ForegroundColor Blue
