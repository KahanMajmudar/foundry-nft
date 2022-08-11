// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/NFT.sol";

contract ERC721Recipient is ERC721TokenReceiver {
    address public operator;
    address public from;
    uint256 public id;
    bytes public data;

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _id,
        bytes calldata _data
    ) public virtual override returns (bytes4) {
        operator = _operator;
        from = _from;
        id = _id;
        data = _data;

        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

contract NonERC721Recipient {}

contract NFTTest is Test {
    using stdStorage for StdStorage;

    NFT private nft;

    function setUp() public {
        nft = new NFT();
    }

    function testDeployment() public {
        assertEq(nft.name(), "NFTTutorial");
        assertEq(nft.symbol(), "NFT");
    }

    function testFailMintPriceNotPaid() public {
        nft.mintTo(address(1));
    }

    function testMintPricePaid() public {
        nft.mintTo{value: nft.MINT_PRICE()}(address(1));
    }

    function testFailMaxSupplyReached() public {
        uint256 slot = stdstore
            .target(address(nft))
            .sig("currentNFTTokenId()")
            .find();

        bytes32 loc = bytes32(slot);
        bytes32 mockTokenId = bytes32(abi.encode(10_000));

        vm.store(address(nft), loc, mockTokenId);

        nft.mintTo{value: nft.MINT_PRICE()}(address(2));
    }

    function testNFTMintForOwner() public {
        nft.mintTo{value: nft.MINT_PRICE()}(address(0xabcd));

        uint256 ownerSlot = stdstore
            .target(address(nft))
            .sig(nft.ownerOf.selector)
            .with_key(1)
            .find();

        address ownerOfTokenIdOne = address(
            uint160(
                uint256(vm.load(address(nft), bytes32(abi.encode(ownerSlot))))
            )
        );

        assertEq(ownerOfTokenIdOne, address(0xabcd));
    }

    function testFailMintToZeroAddress() public {
        nft.mintTo{value: nft.MINT_PRICE()}(address(0));
    }

    function testBalanceUpdates() public {
        nft.mintTo{value: nft.MINT_PRICE()}(address(0xabcd));

        uint256 ownerSlot = stdstore
            .target(address(nft))
            .sig(nft.balanceOf.selector)
            .with_key(address(0xabcd))
            .find();

        uint256 balanceOfFirstMint = uint256(
            uint256(vm.load(address(nft), bytes32(ownerSlot)))
        );

        assertEq(balanceOfFirstMint, 1);

        nft.mintTo{value: nft.MINT_PRICE()}(address(0xabcd));

        uint256 balanceOfSecondMint = uint256(
            vm.load(address(nft), bytes32(ownerSlot))
        );

        assertEq(balanceOfSecondMint, 2);
    }

    function testNFTRecipientContract() public {
        ERC721Recipient receiver = new ERC721Recipient();

        nft.mintTo{value: nft.MINT_PRICE()}(address(receiver));

        uint256 slotBalance = stdstore
            .target(address(nft))
            .sig(nft.balanceOf.selector)
            .with_key(address(receiver))
            .find();

        uint256 balanceOfReceiver = uint256(
            vm.load(address(nft), bytes32(slotBalance))
        );
        assertEq(balanceOfReceiver, 1);
    }

    function testFailNonNFTRecipientContract() public {
        NonERC721Recipient nonReceiver = new NonERC721Recipient();

        nft.mintTo{value: nft.MINT_PRICE()}(address(nonReceiver));
    }

    function testWithdrawalByOwner() public {
        address payable payee = payable(address(1));
        uint256 payeeBalBefore = payee.balance;

        nft.mintTo{value: nft.MINT_PRICE()}(address(2));

        assertEq(address(nft).balance, nft.MINT_PRICE());

        uint256 nftBal = address(nft).balance;

        nft.withdrawPayments(payee);
        assertEq(payee.balance, payeeBalBefore + nftBal);
    }

    function testWithdrawFailByNotOwnerUser() public {
        address payable payee = payable(address(0xdead));

        nft.mintTo{value: nft.MINT_PRICE()}(address(2));

        assertEq(address(nft).balance, nft.MINT_PRICE());

        vm.expectRevert("Ownable: caller is not the owner");
        vm.startPrank(payee);
        nft.withdrawPayments(payee);
        vm.stopPrank();
    }

    function testWithdrawFailByNotOwnerUserFuzz(address who) public {
        address payable payee = payable(address(who));

        nft.mintTo{value: nft.MINT_PRICE()}(address(2));

        assertEq(address(nft).balance, nft.MINT_PRICE());

        vm.expectRevert("Ownable: caller is not the owner");
        vm.startPrank(payee);
        nft.withdrawPayments(payee);
        vm.stopPrank();
    }
}
