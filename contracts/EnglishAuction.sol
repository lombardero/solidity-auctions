pragma solidity ^0.5.16;

import "./Auction.sol";

contract EnglishAuction is Auction {

    uint public initialPrice;
    uint public biddingPeriod;
    uint public minimumPriceIncrement;

    uint internal currentBlockNum;
    uint internal currentPrice;
    address internal currentWinner;
    mapping (address => uint) auctionPrices;

    // constructor
    constructor(address _sellerAddress,
                          address _judgeAddress,
                          address _timerAddress,
                          uint _initialPrice,
                          uint _biddingPeriod,
                          uint _minimumPriceIncrement) public
             Auction (_sellerAddress, _judgeAddress, _timerAddress) {

        initialPrice = _initialPrice;
        biddingPeriod = _biddingPeriod;
        minimumPriceIncrement = _minimumPriceIncrement;

    }

    function bid() public payable{

        // Step 1: Check the amount sent by bidder is enough
        if (currentPrice != 0){
            require(msg.value >= currentPrice + minimumPriceIncrement);
        } else {
            require(msg.value >= initialPrice);
        }
        // Step 2: Checking the bid has been placed within the accepted time
        if (currentBlockNum != 0){
            require(time() + 1 < currentBlockNum + biddingPeriod);
        }
         // If there was a previous winning bidder, make his balance available for withdrawal
        if (currentWinner != address(0)){
            winnerAddress = currentWinner;
            winningPrice = currentPrice;
        }
        // make the funds available for previous winners for withdrawal
        auctionPrices[currentWinner] += currentPrice;

        // Update contract data with new provisional auction winner
        currentPrice = msg.value;
        currentBlockNum = time() + 1; // we add 1 to avoid "uninitialized" times
        currentWinner = msg.sender;
    }

    // Need to override the default implementation
    function getWinner() public view returns (address winner){
        // To get a winner, the auction needs to be over (which means it should have timed out)
        if(time() + 1 >= currentBlockNum + biddingPeriod){
            return currentWinner;
        } else {
            return address(0);
        }
    }

    // Reimplementing "withdraw" to accept multiple winners
    function withdraw() public payable {
        require(auctionPrices[msg.sender] != 0);
        msg.sender.transfer(auctionPrices[msg.sender]);
    }
}
