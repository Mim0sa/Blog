# IAP 订阅调研

## iap 订阅的流程

1. 向苹果获取商品
2. 用户购买商品，并生成相关收据
   1. 不管是否是有效购买
   2. 可以添加标识符 applicationUsername
3. 将收据 Base64 加密发送给后端
4. 后端发送该收据给 Apple 验证
   1. 后端需要判断 是否已经存在或验证过，然后存储该 Receipt

5. 完成交易



## 购买商品生成收据

 base64 加密后的 Receipt exp：（省略）

```
MIAGCSqGSIb3DQEHAqCAMIACAQExDzACAQAwGwIBAgQQWFhQyMDIyLTAzLTExVDAyOjM0OjM4WjAMAgIGqQIBAQQDDAEwMB8CAgaqAgEBBBYWFDIwMjIt......JyNcrHR7sK5EFpz1PMOt7TDdCaN4aLAHlbQmuv+817FTXkAsfRU654doGmcwU072ZRSYU5GMelpKw69jS/fBh0ct+1tBWU9g1hFNohHZwAAAAAAAA==
```



## 传给 Apple 的验证服务器

`https://sandbox.itunes.apple.com/verifyReceipt` 是沙盒环境的验证地址。
`https://buy.itunes.apple.com/verifyReceipt` 是正式环境的验证地址

  ```
  // Post 请求的 body
	body：{"receipt-data": "base64 加密后的收据"}
	
	// Apple 返回的 json
	{
		"status": 0,
		"environment": "Sandbox"
		"receipt": {
    	"receipt_type": "ProductionSandbox",
    	"adam_id": 0,
    	"app_item_id": 0,
    	"bundle_id": "com.BlueMobi.Phonics",
    	"application_version": "1.5.0",
    	"download_id": 0,
    	"version_external_identifier": 0,
    	"receipt_creation_date": "2018-06-28 14:08:26 Etc/GMT",
   		"receipt_creation_date_ms": "1530194906000",
    	"receipt_creation_date_pst": "2018-06-28 07:08:26 America/Los_Angeles",
    	"request_date": "2018-08-05 04:50:58 Etc/GMT",
    	"request_date_ms": "1533444658147",
    	"request_date_pst": "2018-08-04 21:50:58 America/Los_Angeles",
    	"original_purchase_date": "2013-08-01 07:00:00 Etc/GMT",
    	"original_purchase_date_ms": "1375340400000",
    	"original_purchase_date_pst": "2013-08-01 00:00:00 America/Los_Angeles",
    	"original_application_version": "1.0",
    	"in_app": [
        {
            "quantity": "1",
            "product_id": "*******",
            "transaction_id": "1000000404314890", //这个苹果的交易唯一标识符, 后端验证
            "original_transaction_id": "1000000404314890",
            "purchase_date": "2018-06-04 09:58:41 Etc/GMT",
            "purchase_date_ms": "1528106321000",
            "purchase_date_pst": "2018-06-04 02:58:41 America/Los_Angeles",
            "original_purchase_date": "2018-06-04 09:58:41 Etc/GMT",
            "original_purchase_date_ms": "1528106321000",
            "original_purchase_date_pst": "2018-06-04 02:58:41 America/Los_Angeles",
            "is_trial_period": "false"
        },
        {
            "quantity": "1",
            "product_id": "*******",
            "transaction_id": "1000000404523773",
            "original_transaction_id": "1000000404523773",
            "purchase_date": "2018-06-05 02:21:26 Etc/GMT",
            "purchase_date_ms": "1528165286000",
            "purchase_date_pst": "2018-06-04 19:21:26 America/Los_Angeles",
            "original_purchase_date": "2018-06-05 02:21:26 Etc/GMT",
            "original_purchase_date_ms": "1528165286000",
            "original_purchase_date_pst": "2018-06-04 19:21:26 America/Los_Angeles",
            "is_trial_period": "false"
        }
      ]
    }
}

// Status
21000    App Store 不能读取你提供的JSON对象
21002    receipt-data 域的数据有问题
21003    receipt 无法通过验证
21004    提供的 shared secret 不匹配你账号中的 shared secret
21005    receipt 服务器当前不可用
21006    receipt 合法, 但是订阅已过期. 服务器接收到这个状态码时, receipt 数据仍然会解码并一起发送
21007    receipt 是 Sandbox receipt, 但却发送至生产系统的验证服务
21008    receipt 是生产 receipt, 但却发送至 Sandbox 环境的验证服务
  ```



## 关于如何及时得知订阅结束或者变更

1. **客户端主动上报**，Apple 每期自动扣款后，会生成一笔新的 Receipt，客户端获取后发送给 server 校验后就可更新。
2. **状态变更通知后端**，用于自动续订订阅的服务器到服务器通知服务，可以在苹果后台配置通知地址，状态变更时，server 会收到通知。这里是 [Feature 文档](https://developer.apple.com/documentation/appstoreservernotifications/receiving_app_store_server_notifications) 和 [Response 文档](https://developer.apple.com/documentation/appstoreservernotifications/responsebodyv1)。
3. **后端主动查询**，自动续订类型的收据，每一期的 latest_receipt_info 中都会记录所有的交易（包含历史和新增），可以轮询任意一期的 Receipt，通过 latest_receipt_info 解析出用户最新的订阅状态。[具体文档](https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html#//apple_ref/doc/uid/TP40010573-CH106-SW2)（还没验证）。

三种方案的特点：

|     | 特点 | 缺点 |
|  :---  | ----  |  ----  |
| *客户端主动上报* | 一定会有一次（首次订阅） | 续费的收据需要用户打开一次 app 才能获得<br />取消订阅之后不能及时知晓 |
| *状态变更通知后端* | 可以获取到用户取消订阅的通知 | 貌似会丢失通知<br />取消订阅之后不能及时知晓 |
| *后端主动查询* | 只要有收据，基本什么都能查到 | 得先有一张首次购买收据<br />用户多了之后主动查询有成本 |

### 具体策略

都用



# 本地验证方式

官方文档 [Validating Receipts on the Device](https://developer.apple.com/documentation/appstorereceipts/validating_receipts_on_the_device)

暂时没弄清楚，看起来只能验证收据的真实性，无法获取其他信息。和我们的需求不符。



# 待解决问题

* IAP 账号和 Ins 账号的关联
* 没真机昂
* 壳子用什么逻辑

























