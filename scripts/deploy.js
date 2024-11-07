const hre = require("hardhat");
const { ethers } = require("hardhat");

async function main() {
  const NFTMarket = await ethers.getContractFactory("NFTMarket");
  const nftMarket = await NFTMarket.deploy();
  await nftMarket.waitForDeployment();
  console.log("NFTMarket deployed to: ", nftMarket.target);

  const NFT = await ethers.getContractFactory("NFT");
  const nft = await NFT.deploy(nftMarket.target);
  await nft.waitForDeployment(6);
  console.log("NFT deployed to: ", nft.target);

  if (hre.network.config.chainId == 43113) {
    await hre.run("verify:verify", {
      address: nftMarket.target, // 合约地址
      constructorArguments: [], // 合约构造函数的参数
    });
    console.log("nftMarket 验证成功");

    console.log("等待nft 合约验证...");

    await hre.run("verify:verify", {
      address: nft.target, // 合约地址
      constructorArguments: [nftMarket.target], // 合约构造函数的参数
    });
    console.log("verification successfully");
  } else {
    console.log("verification skipped...");
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
