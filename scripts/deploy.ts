import { network } from "hardhat";

async function main() {
  const { ethers } = await network.connect();
  const [deployer] = await ethers.getSigners();

  console.log("Deploying with:", deployer.address);

  const NFTAuction = await ethers.getContractFactory("NFTAuction");
  const auction = await NFTAuction.deploy();
  await auction.initialize();

  console.log("NFTAuction deployed to:", await auction.getAddress());
}

main();
