# Sample Hardhat Project

- 该项目是一个去中心化的 NFT 交易市场，包含两个主要合约：NFT 和 NFTMarket。通过两个合约的结合，用户可以在链上铸造、上架、购买和转售自己的 NFT。

**Deploying to Avalanche testnet**

- NFTMarket deployed to: 0x9178A9f814D209A1eFECA14eE056e224676184B4
- Testnet address：https://testnet.snowtrace.io/address/0x9178A9f814D209A1eFECA14eE056e224676184B4#code

- NFT deployed to: 0xbDd763bCc0d23b6FF2518Afbb0Ae1E7baddc94d0
- Testnet address：https://testnet.snowtrace.io/address/0xbDd763bCc0d23b6FF2518Afbb0Ae1E7baddc94d0#code

## Overview

1. NFT 合约

- NFT 合约用于创建符合 ERC721 标准的 NFT 代币，并与 NFTMarket 合约配合使用。用户可以铸造新的 NFT，并将其授权给市场合约 NFTMarket，使得 NFT 可在市场上上架并进行交易。

2. NFTMarket 合约

- NFTMarket 合约实现了 NFT 的市场功能，支持 NFT 的上架、购买和转售等操作，同时支持查询市场中未售出的商品和用户持有的 NFT 列表。用户支付一定的挂单费用，就可以将自己的 NFT 上架到市场中进行交易。

## Usage

1. 首先部署 NFTMarket 合约并记录下该合约的地址 -- 0x9178A9f814D209A1eFECA14eE056e224676184B4

2. 部署 NFT 合约，并将 NFTMarket 合约的地址作为参数传入 NFT 合约的构造函数，以初始化 NFT 合约地址。这样生成的 NFT 会自动授权给 NFTMarket 合约，可以直接上架进行交易。

3. 使用 NFT 合约合约的 createToken 函数，创建 NFT，并记录下返回的 tokenId。然后调用 NFTMarket 合约的 mintNFT 函数，将 NFT 的 合约地址、tokenId 和价格传入，即可上架交易。
