#!/bin/bash
# Quick Service Fix - Run this on the VM
echo "🚀 Quick Service Fix"
echo "==================="

# Upload and run the corrected fix
echo "📥 Downloading corrected fix script..."
wget -O fix_service_corrected.sh https://raw.githubusercontent.com/user/repo/main/fix_service_corrected.sh 2>/dev/null || {
    echo "❌ Cannot download script. Please upload fix_service_corrected.sh manually."
    echo ""
    echo "🔧 Manual fix steps:"
    echo "1. Upload fix_service_corrected.sh to your VM"
    echo "2. chmod +x fix_service_corrected.sh"
    echo "3. ./fix_service_corrected.sh"
    exit 1
}

chmod +x fix_service_corrected.sh
./fix_service_corrected.sh
