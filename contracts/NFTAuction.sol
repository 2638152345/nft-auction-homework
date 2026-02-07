// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract NFTAuction is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    struct Auction {
        address nftAddress;
        uint256 tokenId;
        address seller;
        address bidToken;
        uint256 highestBid;
        address highestBidder;
        uint256 endTime;
        bool ended;
    }

    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed nftAddress,
        address indexed seller,
        uint256 tokenId,
        address bidToken,
        uint256 startPrice,
        uint256 endTime
    );

    event AuctionBid(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 amount
    );

    event AuctionEnded(
        uint256 indexed auctionId,
        address indexed winner,
        uint256 finalPrice
    );

    event AuctionCancelled(uint256 indexed auctionId);

    uint256 public auctionCount;
    mapping(address => mapping(uint256 => uint256)) public nftaddress2auctionId;
    mapping(uint256 => Auction) public auctionData;
    mapping(address => address) public priceFeeds;

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setPriceFeed(address token, address feed) external onlyOwner {
        priceFeeds[token] = feed;
    }

    function _getUSDPrice(address token) internal view returns (uint256) {
        address feed = priceFeeds[token];
        require(feed != address(0));
        AggregatorV3Interface aggr = AggregatorV3Interface(feed);
        (, int256 price,,,) = aggr.latestRoundData();
        uint8 decimals = aggr.decimals();
        require(price > 0);
        return uint256(price) * (10 ** (18 - decimals));
    }

    function _toUSD(address token, uint256 amount) internal view returns (uint256) {
        uint256 price = _getUSDPrice(token);
        return amount * price / 1e18;
    }

    function createAuction(
        address nftAddress,
        uint256 tokenId,
        address bidToken,
        uint256 startPrice,
        uint256 duration
    ) external {
        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender);
        require(nftaddress2auctionId[nftAddress][tokenId] == 0);
        require(startPrice > 0);
        require(duration > 0);

        auctionCount++;
        uint256 auctionId = auctionCount;

        auctionData[auctionId] = Auction({
            nftAddress: nftAddress,
            tokenId: tokenId,
            seller: msg.sender,
            bidToken: bidToken,
            highestBid: startPrice,
            highestBidder: address(0),
            endTime: block.timestamp + duration,
            ended: false
        });

        nftaddress2auctionId[nftAddress][tokenId] = auctionId;
        nft.transferFrom(msg.sender, address(this), tokenId);

        emit AuctionCreated(
            auctionId,
            nftAddress,
            msg.sender,
            tokenId,
            bidToken,
            startPrice,
            auctionData[auctionId].endTime
        );
    }

    function bidAuction(uint256 auctionId, uint256 bidAmount) external payable {
        Auction storage auction = auctionData[auctionId];
        require(!auction.ended);
        require(block.timestamp < auction.endTime);
        require(bidAmount > auction.highestBid);

        uint256 newUSD = _toUSD(auction.bidToken, bidAmount);
        uint256 oldUSD = _toUSD(auction.bidToken, auction.highestBid);
        require(newUSD > oldUSD);

        if (auction.bidToken == address(0)) {
            require(msg.value == bidAmount);
        } else {
            require(msg.value == 0);
            IERC20 token = IERC20(auction.bidToken);
            require(token.balanceOf(msg.sender) >= bidAmount);
            require(token.allowance(msg.sender, address(this)) >= bidAmount);
            token.transferFrom(msg.sender, address(this), bidAmount);
        }

        address prevBidder = auction.highestBidder;
        uint256 prevBid = auction.highestBid;

        auction.highestBid = bidAmount;
        auction.highestBidder = msg.sender;

        if (prevBidder != address(0)) {
            if (auction.bidToken == address(0)) {
                (bool ok,) = prevBidder.call{value: prevBid}("");
                require(ok);
            } else {
                IERC20(auction.bidToken).transfer(prevBidder, prevBid);
            }
        }

        emit AuctionBid(auctionId, msg.sender, bidAmount);
    }

    function endAuction(uint256 auctionId) external {
        Auction storage auction = auctionData[auctionId];
        require(!auction.ended);
        require(block.timestamp >= auction.endTime);
        require(msg.sender == auction.highestBidder);

        auction.ended = true;
        nftaddress2auctionId[auction.nftAddress][auction.tokenId] = 0;

        IERC721(auction.nftAddress).transferFrom(
            address(this),
            auction.highestBidder,
            auction.tokenId
        );

        if (auction.bidToken == address(0)) {
            (bool ok,) = auction.seller.call{value: auction.highestBid}("");
            require(ok);
        } else {
            IERC20(auction.bidToken).transfer(
                auction.seller,
                auction.highestBid
            );
        }

        emit AuctionEnded(
            auctionId,
            auction.highestBidder,
            auction.highestBid
        );
    }

    function cancelAuction(uint256 auctionId) external {
        Auction storage auction = auctionData[auctionId];
        require(msg.sender == auction.seller);
        require(!auction.ended);
        require(auction.highestBidder == address(0));

        auction.ended = true;
        nftaddress2auctionId[auction.nftAddress][auction.tokenId] = 0;

        IERC721(auction.nftAddress).transferFrom(
            address(this),
            auction.seller,
            auction.tokenId
        );

        emit AuctionCancelled(auctionId);
    }
}
