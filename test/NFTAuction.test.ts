import { expect } from "chai";
import { network } from "hardhat";

describe("NFTAuction", function () {
  let ethers: any;
  let owner: any;
  let seller: any;
  let bidder: any;

  let auction: any;
  let nft: any;
  let token: any;
  let feed: any;

  beforeEach(async function () {
    ({ ethers } = await network.connect());
    [owner, seller, bidder] = await ethers.getSigners();

    const MockERC721 = await ethers.getContractFactory("MockERC721");
    nft = await MockERC721.deploy();

    const MockERC20 = await ethers.getContractFactory("MockERC20");
    token = await MockERC20.deploy();

    const MockFeed = await ethers.getContractFactory("MockPriceFeed");
    feed = await MockFeed.deploy(8, 2000_00000000n);

    const NFTAuction = await ethers.getContractFactory("NFTAuction");
    auction = await NFTAuction.deploy();
    await auction.initialize();

    await auction.setPriceFeed(await token.getAddress(), await feed.getAddress());

    await (nft as any).mint(seller.address, 1);
    await (token as any).mint(bidder.address, 10_000n * 10n ** 18n);
  });

  it("create auction", async function () {
    await (nft as any).connect(seller).approve(await auction.getAddress(), 1);

    await auction.connect(seller).createAuction(
      await nft.getAddress(),
      1,
      await token.getAddress(),
      100n * 10n ** 18n,
      3600
    );

    const id = await auction.nftaddress2auctionId(await nft.getAddress(), 1);
    const data = await auction.auctionData(id);

    expect(data.seller).to.equal(seller.address);
    expect(data.tokenId).to.equal(1);
  });

  it("bid auction", async function () {
    await (nft as any).connect(seller).approve(await auction.getAddress(), 1);

    await auction.connect(seller).createAuction(
      await nft.getAddress(),
      1,
      await token.getAddress(),
      100n * 10n ** 18n,
      3600
    );

    await (token as any).connect(bidder).approve(
      await auction.getAddress(),
      200n * 10n ** 18n
    );

    await auction.connect(bidder).bidAuction(1, 200n * 10n ** 18n);

    const data = await auction.auctionData(1);
    expect(data.highestBidder).to.equal(bidder.address);
  });

  it("end auction", async function () {
    await (nft as any).connect(seller).approve(await auction.getAddress(), 1);

    await auction.connect(seller).createAuction(
      await nft.getAddress(),
      1,
      await token.getAddress(),
      100n * 10n ** 18n,
      1
    );

    await (token as any).connect(bidder).approve(
      await auction.getAddress(),
      200n * 10n ** 18n
    );

    await auction.connect(bidder).bidAuction(1, 200n * 10n ** 18n);

    await ethers.provider.send("evm_increaseTime", [2]);
    await ethers.provider.send("evm_mine", []);

    await auction.connect(bidder).endAuction(1);

    const ownerOfNFT = await (nft as any).ownerOf(1);
    expect(ownerOfNFT).to.equal(bidder.address);
  });

  it("cancel auction", async function () {
    await (nft as any).connect(seller).approve(await auction.getAddress(), 1);

    await auction.connect(seller).createAuction(
      await nft.getAddress(),
      1,
      await token.getAddress(),
      100n * 10n ** 18n,
      3600
    );

    await auction.connect(seller).cancelAuction(1);

    const ownerOfNFT = await (nft as any).ownerOf(1);
    expect(ownerOfNFT).to.equal(seller.address);
  });
});
