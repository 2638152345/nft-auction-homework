# NFTAuction (Hardhat)

一个基于 Solidity + Hardhat 的 NFT 拍卖合约项目，支持使用 ETH 或 ERC20 代币进行竞拍，并通过 Chainlink 价格预言机将出价统一换算为 USD 进行比较。本项目完成了合约实现、单元测试、测试覆盖率统计，并已部署至 Sepolia 测试网。

---

## 一、项目功能说明

### 1. 核心功能

- NFT 拍卖创建
- 使用 ETH 或 ERC20 代币进行竞拍
- 通过 Chainlink Price Feed 将不同代币价格统一换算为 USD
- 自动记录最高出价与竞拍者
- 拍卖结束后自动结算 NFT 与资金
- 支持拍卖取消（无出价情况下）
- 合约支持 UUPS 可升级模式

### 2. 合约功能概览

| 函数名 | 功能说明 |
|------|--------|
| `initialize` | 初始化合约（UUPS） |
| `setPriceFeed` | 设置代币价格预言机 |
| `createAuction` | 创建 NFT 拍卖 |
| `bidAuction` | 参与竞拍 |
| `endAuction` | 结束拍卖并结算 |
| `cancelAuction` | 取消拍卖 |

---

## 二、项目结构说明

```text
nft-auction-homework/
├── contracts/
│   ├── NFTAuction.sol
│   └── mocks/
│       ├── MockERC20.sol
│       ├── MockERC721.sol
│       └── MockV3Aggregator.sol
├── test/
│   └── NFTAuction.test.ts
├── scripts/
│   └── deploy.ts
├── .env.example
├── .gitignore
├── hardhat.config.ts
├── package.json
└── README.md

## 三、开发环境

- Node.js >= 18
- Hardhat
- Solidity ^0.8.28
- OpenZeppelin Contracts
- Chainlink Contracts
- Ethers v6
- TypeScript

## 四、环境变量配置

### 1. 创建 `.env` 文件

在项目根目录执行：

```bash
cp .env.example .env

SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_API_KEY
SEPOLIA_PRIVATE_KEY=0xYOUR_PRIVATE_KEY
###说明：

SEPOLIA_RPC_URL：Infura 提供的 Sepolia RPC 地址

SEPOLIA_PRIVATE_KEY：MetaMask 钱包私钥（必须包含 0x 前缀）

⚠️ .env 文件已加入 .gitignore，不会被提交到 GitHub


---

## 五、安装与编译

### 1. 安装依赖

```bash
npm install
npx hardhat compile

---

## 六、测试说明

### 1. 运行单元测试

```bash
npx hardhat test
测试内容覆盖：

.拍卖创建

.ETH / ERC20 竞拍

.USD 价格比较逻辑

.拍卖结束流程

.拍卖取消流程

.异常与失败场景
###测试覆盖率
npx hardhat coverage


###覆盖率报告生成在：

coverage/

---

## 七、部署到 Sepolia 测试网

### 1. 部署命令

```bash
npx hardhat run scripts/deploy.ts --network sepolia
###2. 部署脚本说明
部署脚本位于：
scripts/deploy.ts
部署流程：

1.使用部署者账户

2.部署 NFTAuction 合约

3.调用 initialize()

4.输出部署地址
###3. 已部署地址（Sepolia）
NFTAuction: 0x2Ba8Eb0aa6E5Afc8d9A4B5678924aF7B7bb59DAb

---

## 八、Mock 合约说明（测试使用）

| 合约名 | 用途 |
|------|------|
| MockERC20 | 模拟 ERC20 竞拍代币 |
| MockERC721 | 模拟 NFT |
| MockV3Aggregator | 模拟 Chainlink 价格预言机 |
## 九、安全与限制说明

- 本项目为课程作业用途
- 不建议直接用于生产环境

## 十、提交内容说明

本项目提交内容包括：

- 完整 Hardhat 项目代码
- 单元测试与集成测试
- 测试覆盖率报告
- Sepolia 测试网部署地址
- 项目 README 文档
