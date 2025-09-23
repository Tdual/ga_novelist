#!/bin/bash

# GA Novelist RDS 超簡単デプロイスクリプト

echo "🚀 GA Novelist RDS デプロイ開始"

# デフォルトVPCのIDを取得
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query "Vpcs[0].VpcId" --output text)
echo "📍 VPC ID: $VPC_ID"

# デフォルトサブネットを取得（2つ以上のAZ）
SUBNETS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "Subnets[*].SubnetId" \
    --output text | tr '\t' ',' | cut -d',' -f1,2)
echo "📍 Subnets: $SUBNETS"

# CloudFormationスタック作成
echo "🔨 RDSインスタンス作成中..."
aws cloudformation create-stack \
    --stack-name ga-novelist-rds \
    --template-body file://rds-ultra-minimal.yaml \
    --parameters \
        ParameterKey=DBMasterPassword,ParameterValue=GaNovelist2024! \
    --on-failure DELETE

# スタック作成を待つ
echo "⏳ 作成完了まで待機中（約5-10分）..."
aws cloudformation wait stack-create-complete --stack-name ga-novelist-rds

# 接続情報を取得
if [ $? -eq 0 ]; then
    echo "✅ RDS作成完了！"
    
    # エンドポイント取得
    ENDPOINT=$(aws cloudformation describe-stacks \
        --stack-name ga-novelist-rds \
        --query "Stacks[0].Outputs[?OutputKey=='QuickStart'].OutputValue" \
        --output text)
    
    echo "$ENDPOINT"
    
    # 接続情報をファイルに保存
    echo "$ENDPOINT" > db_connection_info.txt
    echo "📝 接続情報を db_connection_info.txt に保存しました"
    
else
    echo "❌ RDS作成に失敗しました"
    exit 1
fi

echo "
========================================
💰 コスト情報
========================================
月額: 約$15（約2,250円）
- バックアップなし
- 監視なし
- 開発専用

⚠️ 削除方法:
aws cloudformation delete-stack --stack-name ga-novelist-rds
"