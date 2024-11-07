/**
    另一个版本：
    NFTMarketplace 合约是一个支持用户铸造和交易 NFT 的去中心化市场。用户可以将 NFT 上架到市场、出售自己的NFT，购买 NFT，或将购买的 NFT 重新定价转售。此外，该市场允许合约所有者更新市场挂单费用并提现市场中的 ERC20 代币。
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplace is ERC721URIStorage, ReentrancyGuard {
    using Counters for Counters.Counter;

    // 使用计数器来记录NFT Token的id 和 已经卖掉的NFT数量
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    // 在市场上挂单的费用
    uint256 listingPrice = 0.0025 ether;

    address payable owner;

    // 用一个 id 记录在marketplace上创建的商品
    mapping(uint256 => MarketItem) private idToMarketItem;

    // 商品的详细信息
    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    //  商品创建事件，在商品创建时触发
    event MarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    constructor() ERC721("Crypto Elf", "CElf") {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only contract owner can perform this action"
        );
        _;
    }

    // 更新挂单到市场上的价格，限制只有marketplace的创建者才能更新
    function updateListingPrice(uint _listingPrice) public payable {
        require(
            owner == msg.sender,
            "Only the marketplace owner can update the listing price."
        );
        listingPrice = _listingPrice; //wei
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    //  铸造一个NFT并且上架到marketplace，标价为price（wei）
    function createToken(
        string memory tokenURI,
        uint256 price
    ) public payable nonReentrant returns (uint) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        createMarketItem(newTokenId, price); //调用createMarketItem函数将NFT上架到市场
        return newTokenId;
    }

    //  把新创建的NFT挂单到市场上
    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "Price must be at least 1 wei");
        require(
            msg.value == listingPrice,
            "Price must be equal to the listing price"
        );

        idToMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)), //将NFT转移到市场合约
            price,
            false
        );

        _transfer(msg.sender, address(this), tokenId);
        emit MarketItemCreated(
            tokenId,
            msg.sender,
            address(this),
            price,
            false
        );
    }

    // NFT的拥有者可以以新的价格上架转售已购买的NFT
    function resellToken(
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {
        require(
            idToMarketItem[tokenId].owner == msg.sender,
            "Only the item owner can perform this operation"
        );
        require(
            msg.value == listingPrice,
            "Price must be equal to the listing price"
        );
        idToMarketItem[tokenId].sold = false;
        idToMarketItem[tokenId].price = price;
        idToMarketItem[tokenId].seller = payable(msg.sender); //卖家为当前的调用者
        idToMarketItem[tokenId].owner = payable(address(this));
        _itemsSold.decrement();
        _transfer(msg.sender, address(this), tokenId);
    }

    //  NFT购买函数
    //  处理NFT被购买的销售过程，转移所有权和相应的value，tokenid为被购买的NFT id
    function createMarketSale(uint256 tokenId) public payable nonReentrant {
        uint price = idToMarketItem[tokenId].price;
        require(
            msg.value == price,
            "Please submit the asking price to complete the purchase"
        );
        address seller = idToMarketItem[tokenId].seller;
        idToMarketItem[tokenId].owner = payable(msg.sender);
        idToMarketItem[tokenId].sold = true;
        idToMarketItem[tokenId].seller = payable(address(0));
        _itemsSold.increment();
        _transfer(address(this), msg.sender, tokenId);
        payable(owner).transfer(listingPrice);
        payable(seller).transfer(msg.value);
    }

    //  查看并返回市场上所有还没被卖掉的NFT
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint itemCount = _tokenIds.current();
        uint unsoldItemCount = _tokenIds.current() - _itemsSold.current();
        uint currentIndex = 0;
        MarketItem[] memory items = new MarketItem[](unsoldItemCount);

        for (uint i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(this)) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    //  查看并返回用户自己拥有的所有NFT
    function fetchUserNFTs(
        address _address
    ) public view returns (MarketItem[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == _address) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == _address) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    //  查看该地址用户上架的所有NFT
    function fetchItemsListed(
        address _address
    ) public view returns (MarketItem[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == _address) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == _address) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // 允许用户提现自己的ERC20 token
    function ownerWithdraw(
        address tokenAddress,
        uint256 amount
    ) external onlyOwner nonReentrant {
        if (isERC20(tokenAddress)) {
            require(
                amount <= IERC20(tokenAddress).balanceOf(address(this)),
                "Not enough balance in the contract"
            );
            require(
                IERC20(tokenAddress).transfer(owner, amount),
                "Transfer failed"
            );
        } else if (isERC721(tokenAddress)) {
            revert(
                "ERC721 tokens cannot be withdrawn by the contract owner to prevent potential manipulation of users' NFTs"
            );
        } else {
            revert("Unsupported token type");
        }
    }

    // 检查给定的地址是否是一个有效的ERC20代币合约
    function isERC20(address tokenAddress) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(tokenAddress)
        }
        return size > 0 && IERC20(tokenAddress).totalSupply() > 0;
    }

    // 检查给定的地址是否是一个有效的ERC721代币合约
    function isERC721(address tokenAddress) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(tokenAddress)
        }
        return size > 0 && IERC721(tokenAddress).supportsInterface(0x80ac58cd);
    }
}
