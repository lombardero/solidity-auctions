pragma solidity ^0.5.16;

import "./TestFramework.sol";
import "./Bidders.sol";

contract VickreyAuctionTestBasic {

    VickreyAuction testAuction;
    VickreyAuctionBidder alice;
    VickreyAuctionBidder bob;
    VickreyAuctionBidder carol;
    uint bidderCounter;

    Timer t;

    // Adjust this to change the test code's initial balance
    uint public initialBalance = 1000000000 wei;

    //can receive money
    function() external payable {}
    constructor() public payable {}

    function setupContracts() public {
        t = new Timer(0);
        testAuction = new VickreyAuction(address(this), address(0), address(t), 300, 10, 10, 1000);
        bidderCounter += 1;
        alice = new VickreyAuctionBidder(testAuction, bytes32(bidderCounter));
        bidderCounter += 1;
        bob = new VickreyAuctionBidder(testAuction, bytes32(bidderCounter));
        bidderCounter += 1;
        carol = new VickreyAuctionBidder(testAuction, bytes32(bidderCounter));
    }

    function commitBid(
        VickreyAuctionBidder bidder,
        uint bidValue,
        uint bidTime,
        bool expectedResult,
        string memory message
    ) internal {

        uint oldTime = t.getTime();
        t.setTime(bidTime);
        uint initialAuctionBalance = address(testAuction).balance;

        address(bidder).transfer(testAuction.bidDepositAmount());
        bool result = bidder.commitBid(bidValue);

        if (expectedResult == false) {
            Assert.isFalse(result, message);
        }
        else {
            Assert.isTrue(result, message);
            Assert.equal(address(testAuction).balance, initialAuctionBalance + testAuction.bidDepositAmount(), "auction should retain deposit");
        }
        t.setTime(oldTime);
    }

    function revealBid(
        VickreyAuctionBidder bidder,
        uint bidValue,
        uint bidTime,
        bool expectedResult,
        string memory message
    ) internal {

        uint oldTime = t.getTime();
        t.setTime(bidTime);

        address(bidder).transfer(bidValue);
        bool result = bidder.revealBid(bidValue);

        if (expectedResult == false) {
            Assert.isFalse(result, message);
        }
        else {
            Assert.isTrue(result, message);
        }
        t.setTime(oldTime);
    }


    function testCreateVickreyAuction() public {
        setupContracts();
        //do nothing, just verify that the constructor actually ran
    }

    function testCommitBids() public {
        setupContracts();
        commitBid(alice, 10, 1, true, "valid bid commitment should be accepted");
        commitBid(bob, 1000, 2, true, "valid bid commitment should be accepted");
        commitBid(carol, 340, 7, true, "valid bid commitment should be accepted");
    }

    function testLateBidCommitments() public {
        setupContracts();
        commitBid(carol, 340, 7, true, "valid bid commitment should be accepted");
        commitBid(alice, 300, 10, false, "late bid commitment should be rejected");
        commitBid(bob, 3000, 100, false, "late bid commitment should be rejected");
    }

    function testExcessBidDeposit() public {
        setupContracts();
        address(alice).transfer(1067);
        Assert.isFalse(alice.commitBid(1000, 1067), "bid with excess deposit should be rejected");
        Assert.equal(address(alice).balance, 1067, "bid with excess deposit should be rejected");
    }

    function testChangeBidCommitmentRefund() public {
        setupContracts();
        address(alice).transfer(2548);
        Assert.isTrue(alice.commitBid(500, 1000), "valid bid should be accepted");
        t.setTime(1);
        Assert.isTrue(alice.commitBid(550, 0), "valid bid change #1 should be accepted");
        t.setTime(2);
        Assert.isTrue(alice.commitBid(450, 0), "valid bid change #2 should be accepted");
        t.setTime(3);
        Assert.isFalse(alice.commitBid(300, 1000), "invalid bid #3 change should be rejected");

        Assert.equal(address(testAuction).balance, 1000, "bid changes should still capture deposit");
        Assert.equal(address(alice).balance, 1548, "bid changes should not capture additional deposit");
    }

    function testEarlyReveal() public {
        setupContracts();
        commitBid(alice, 340, 7, true, "valid bid commitment should be accepted");
        revealBid(alice, 340, 9, false, "early bid reveal should be rejected");
    }

    function testLateReveal() public {
        setupContracts();
        commitBid(alice, 340, 7, true, "valid bid commitment should be accepted");
        revealBid(alice, 340, 20, false, "early bid reveal should be rejected");
    }

    function testInvalidReveal() public {
        setupContracts();
        commitBid(alice, 340, 7, true, "valid bid commitment should be accepted");
        commitBid(bob, 380, 8, true, "valid bid commitment should be accepted");
        revealBid(alice, 320, 14, false, "incorrect bid reveal should be rejected");
        bidderCounter += 1;
        bob.setNonce(bytes32(bidderCounter));
        revealBid(bob, 380, 16, false, "incorrect bid reveal should be rejected");
    }

}
