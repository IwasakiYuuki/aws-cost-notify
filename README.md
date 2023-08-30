# AWSコストSlack通知ボット
定期的にAWSのコストをSlackへ通知してくれる便利なやつ．
デフォルトでは毎週月曜日の10時にこんな感じでコストを投稿してくれる．

> Period: 2023-08-01 ~ 2023-08-29
> ```
> +------------------------------------+----------+
> | Service                            |   Amount |
> +------------------------------------+----------+
> | AWS Lambda                         | 0.00 USD |
> | EC2 - Other                        | 5.84 USD |
> | Amazon Relational Database Service | 0.05 USD |
> | Amazon Route 53                    | 1.50 USD |
> | Amazon Simple Storage Service      | 0.03 USD |
> | Amazon Virtual Private Cloud       | 0.00 USD |
> | AmazonCloudWatch                   | 0.00 USD |
> | Tax                                | 0.74 USD |
> | ---------------------------------- | -------- |
> | Total                              | 8.15 USD |
> +------------------------------------+----------+
> ```

## TL; DR
- Terraform CLIを使えるようにする
- AWSのCost Explorerを有効化
- 通知したいSlackチャンネルへのWebhook URLを作成
- 以下の環境変数をセット
  - AWS_ACCESS_KEY_ID: アクセスキー
  - AWS_SECRET_ACCESS_KEY: シークレットキー
  - AWS_REGION: リージョン
  - TF_VAR_SLACK_WEBHOOK_URL: 通知先のSlackチャンネルへのWebhook URL

そしたら
```
cd tf
terraform init
terraform apply -auto-approve
```

## 1. 事前設定
### Terraform
Terraform CLIのインストール．（Macの場合）
```shell
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```
他のOSについては[公式のページ](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)を参照．

### AWS
AWSコンソールからコスト計算に使用するCost Explorerの有効化を行う（[参考](https://docs.aws.amazon.com/ja_jp/cost-management/latest/userguide/ce-enable.html)）．  
※ Cost Explorerのページから請求ダッシュボードなどが見える状態になっていれば大丈夫です．

また，Terraformで使用するIAMユーザの認証情報を以下の環境変数へ設定する．

- AWS_ACCESS_KEY_ID: アクセスキー
- AWS_SECRET_ACCESS_KEY: シークレットキー
- AWS_REGION: リージョン

IAMユーザには，IAMポリシー，IAMロール，Lambdaの作成に必要な権限が付与されている必要があります．

### Slack
Slack botを作成し，通知したいチャンネルへのWebhook URLを生成する．  
生成したURLを環境変数`TF_VAR_SLACK_WEBHOOK_URL`へセットする．  
（https://hooks.slack.com/services/XXXX/XXXX/XXXXXXX みたいな形式のURLです．）

## 2. 構築
```shell
cd tf
terraform init
terraform apply -auto-approve
```

## 追加設定
- TF_VAR_SCHEDULE_EXPRESSION: 定期実行の間隔．cron形式で設定してください．（デフォルト："cron(0 10 ? * MON *)"）
