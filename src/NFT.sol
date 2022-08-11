// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";
import "openzeppelin-contracts/contracts/utils/Counters.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

error MintPriceNotPaid(uint256 valueSent);
error MaxSupplyReached();
error NonExistentTokenURI(uint256 id);
error WithdrawTransferFailed();

contract NFT is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private currentTokenId;

    string public baseURI;
    uint256 public constant TOTAL_SUPPLY = 10_000;
    uint256 public constant MINT_PRICE = 0.08 ether;

    constructor() ERC721("NFTTutorial", "NFT") {
        baseURI = "https://bafybeif6iuokmmcuwj7jgscybx3gvlcwkb6ybspwcduivl7mbqmgmmxubi.ipfs.dweb.link/metadata/";
    }

    function mintTo(address recipient) external payable returns (uint256) {
        if (msg.value != MINT_PRICE) revert MintPriceNotPaid(msg.value);

        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        if (newItemId > TOTAL_SUPPLY) revert MaxSupplyReached();

        _safeMint(recipient, newItemId);
        return newItemId;
    }

    function withdrawPayments(address payable payee) external onlyOwner {
        (bool status, ) = payee.call{value: address(this).balance}("");
        if (!status) revert WithdrawTransferFailed();
    }

    function currentNFTTokenId() external view returns (uint256 currId) {
        return currentTokenId.current();
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if (ownerOf(id) == address(0)) {
            revert NonExistentTokenURI(id);
        }
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, id.toString()))
                : "";
    }
}
